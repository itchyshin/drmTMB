make_cmr_methods_fit <- function() {
  set.seed(2026)
  histories <- matrix(0L, 300L, 4L)
  histories[, 1L] <- 1L
  for (i in seq_len(nrow(histories))) {
    alive <- TRUE
    for (t in 2:4) {
      alive <- alive && stats::rbinom(1L, 1L, .82) == 1L
      histories[i, t] <- if (alive) stats::rbinom(1L, 1L, .48) else 0L
    }
  }
  d <- cmr_data(histories, id = paste0("bird", seq_len(nrow(histories))),
                occasions = c(0, 1, 2, 3), intervals = c(1, 1.5, 1),
                units = "years")
  drm_cjs(d, terminal_constraint = list(phi = .7))
}

make_cmr_methods_schema_fit <- function() {
  fit <- make_cmr_methods_fit()
  d <- fit$data
  n <- nrow(d$y)
  p_rows <- expand.grid(t = seq_len(ncol(d$y)), i = seq_len(n))
  p_data <- data.frame(
    id = d$id[p_rows$i], occasion = d$occasions[p_rows$t],
    group = factor(ifelse(p_rows$i %% 2L, "A", "B"), levels = c("A", "B")),
    off = (p_rows$t - 1) * .03
  )
  f_rows <- expand.grid(t = seq_len(ncol(d$y) - 1L), i = seq_len(n))
  phi_data <- data.frame(
    id = d$id[f_rows$i], interval_start = d$occasions[f_rows$t],
    interval_end = d$occasions[f_rows$t + 1L],
    group = factor(ifelse(f_rows$i %% 2L, "A", "B"), levels = c("A", "B")),
    off = (f_rows$t - 1) * .02
  )
  drm_cjs(d, phi = ~ group + offset(off), p = ~ group + offset(off),
          phi_data = phi_data, p_data = p_data,
          terminal_constraint = list(phi = .7))
}

test_that("CJS training prediction returns only contributing keyed rows", {
  fit <- make_cmr_methods_fit()
  pr <- predict(fit, type = "response")
  expect_named(pr, c("phi", "p"))
  expect_true(all(c("id", "interval_start", "interval_end", "interval_length",
                    "phi_unit", "phi_interval") %in% names(pr$phi)))
  expect_true(all(c("id", "occasion", "p") %in% names(pr$p)))
  expect_equal(nrow(pr$phi), sum(fit$phi_active))
  expect_equal(nrow(pr$p), sum(fit$p_active))
  expect_equal(pr$phi$phi_interval, pr$phi$phi_unit ^ pr$phi$interval_length)
  lk <- predict(fit, type = "link")
  expect_true("eta" %in% names(lk$phi))
  expect_true("eta" %in% names(lk$p))
  expect_equal(lk$phi$eta, as.numeric(fit$phi$X[fit$phi_active, , drop = FALSE] %*%
                                        fit$coefficients$phi + fit$phi$offset[fit$phi_active]))
})

test_that("CJS newdata prediction is keyed, schema-checked, and unit-checked", {
  fit <- make_cmr_methods_fit()
  nd <- list(
    phi = data.frame(id = "bird1", interval_start = 0, interval_end = 1,
                     interval_length = 1),
    p = data.frame(id = "bird1", occasion = 1), units = "years"
  )
  pr <- predict(fit, newdata = nd)
  expect_equal(pr$phi$id, "bird1")
  expect_equal(pr$p$occasion, 1)
  expect_error(predict(fit, newdata = within(nd, units <- "days")), "units")
  nd$phi$id <- "not-in-training"
  expect_error(predict(fit, newdata = nd), "id")
  nd$phi$id <- "bird1"
  nd$p$extra <- 1
  expect_error(predict(fit, newdata = nd), "schema")
})

test_that("CJS prediction reuses factor coding and offsets", {
  fit <- make_cmr_methods_schema_fit()
  phi <- fit$training_phi_data[1, c("id", "interval_start", "interval_end", "group", "off")]
  phi$interval_length <- fit$data$delta[1, 1]
  p <- fit$training_p_data[1, c("id", "occasion", "group", "off")]
  nd <- list(phi = phi, p = p, units = fit$data$units)
  eta <- predict(fit, newdata = nd, type = "link")
  expect_true(is.finite(eta$phi$eta))
  expect_true(is.finite(eta$p$eta))
  phi$group <- factor("C")
  nd$phi <- phi
  expect_error(predict(fit, newdata = nd), "level")
  phi$group <- fit$training_phi_data$group[1]
  phi$missing <- 1
  nd$phi <- phi
  expect_error(predict(fit, newdata = nd), "schema")
})

test_that("CJS simulation preserves layouts, expands frequencies, and refits", {
  fit <- make_cmr_methods_fit()
  set.seed(812)
  caller_seed <- .Random.seed
  a <- simulate(fit, nsim = 1, seed = 91)[[1]]
  expect_identical(.Random.seed, caller_seed)
  b <- simulate(fit, nsim = 1, seed = 91)[[1]]
  expect_identical(a$data$y, b$data$y)
  expect_s3_class(a, "cmr_simulation")
  expect_equal(a$data$first, fit$data$first)
  expect_equal(a$data$end, fit$data$end)
  expect_identical(a$data$observed, fit$data$observed)
  expect_equal(nrow(a$data$y), sum(fit$data$frequency))
  expect_true(all(is.na(a$data$y[!a$data$observed])))
  refit <- drm_cjs(a$data, phi = stats::formula(fit$phi$terms),
                   p = stats::formula(fit$p$terms),
                   phi_data = a$phi_data, p_data = a$p_data,
                   terminal_constraint = fit$terminal_constraint)
  expect_s3_class(refit, "drm_cjs")
  set.seed(17)
  before <- .Random.seed
  simulate(fit, nsim = 1)
  expect_false(identical(.Random.seed, before))
})

test_that("CJS Wald inference is guarded and profile intervals are likelihood based", {
  fit <- make_cmr_methods_fit()
  expect_named(coef(fit), colnames(vcov(fit)))
  expect_equal(dim(vcov(fit)), c(length(coef(fit)), length(coef(fit))))
  ci <- confint(fit, method = "wald")
  expect_equal(rownames(ci), names(coef(fit)))
  expect_true(all(c("lower", "upper") %in% colnames(ci)))
  expect_named(attr(ci, "target_status"), names(coef(fit)))
  expect_true(all(attr(ci, "target_status") == "ok"))
  boundary_fit <- fit
  boundary_fit$coefficients$phi[[1L]] <- 50
  guarded <- confint(boundary_fit, parm = names(coef(fit))[[1L]], method = "wald")
  expect_true(is.na(guarded[1L, 1L]))
  expect_match(attr(guarded, "target_status")[[1L]], "unavailable")
  prof <- confint(fit, method = "profile", level = .8)
  expect_equal(rownames(prof), names(coef(fit)))
  expect_true(!is.null(attr(prof, "endpoint_status")))
  expect_named(attr(prof, "target_status"), names(coef(fit)))
})

test_that("CJS bootstrap retains an attempt ledger", {
  fit <- make_cmr_methods_fit()
  ci <- confint(fit, method = "bootstrap", nsim = 2, seed = 24,
                min_usable = 1)
  ledger <- attr(ci, "attempts")
  expect_equal(nrow(ledger), 2L)
  expect_true(all(c("replicate", "status", "converged", "usable", "message") %in% names(ledger)))
  expect_equal(sum(ledger$usable), attr(ci, "n_usable"))
  expect_true(all(c("lower", "upper") %in% colnames(ci)))
  expect_named(attr(ci, "target_status"), names(coef(fit)))
  expect_named(attr(ci, "n_usable_target"), names(coef(fit)))
})
