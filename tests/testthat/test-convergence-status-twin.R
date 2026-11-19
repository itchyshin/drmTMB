# FX3b: shared three-valued convergence_status; is_converged := status ==
# "converged". Red-proof: on the pin / FX3 head, a boundary RE-SD fit still
# returned is_converged() TRUE. After this change it is FALSE, while
# convergence_status() is "boundary". Print, summary, and check_drm show the
# status.

test_that("is_converged is TRUE only when status is converged (FX3b red-proof)", {
  set.seed(20261016)
  dat <- data.frame(y = rnorm(40, sd = 0.5), x = rnorm(40))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
  expect_identical(convergence_status(fit), "converged")
  expect_true(is_converged(fit))
  expect_true(converged(fit))

  printed <- paste(utils::capture.output(print(fit), type = "message"), collapse = "\n")
  expect_match(printed, "convergence_status: converged", fixed = TRUE)

  sm <- summary(fit)
  expect_identical(sm$convergence_status, "converged")
  sm_printed <- paste(utils::capture.output(print(sm), type = "message"), collapse = "\n")
  expect_match(sm_printed, "convergence_status: converged", fixed = TRUE)

  chk <- check_drm(fit)
  expect_identical(chk$value[chk$check == "convergence_status"], "converged")
  expect_identical(chk$status[chk$check == "convergence_status"], "ok")

  # On FX3 / the pin, a boundary RE-SD still returned is_converged() TRUE.
  # Mutate a clearly interior random intercept rather than relying on n=40
  # with tiny groups, which can already sit below 1e-4.
  set.seed(20261016)
  g <- factor(rep(seq_len(8), each = 25))
  u <- rnorm(nlevels(g), sd = 0.8)
  re_dat <- data.frame(
    y = rnorm(length(g), sd = 0.4) + u[g],
    x = rnorm(length(g)),
    g = g
  )
  re_fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), data = re_dat)
  expect_identical(convergence_status(re_fit), "converged")
  expect_true(is_converged(re_fit))
  boundary <- re_fit
  stopifnot(length(boundary$sdpars$mu) >= 1L)
  boundary$sdpars$mu[[1L]] <- 1e-8
  expect_identical(convergence_status(boundary), "boundary")
  expect_false(is_converged(boundary))
  expect_false(converged(boundary))
  chk_b <- check_drm(boundary)
  expect_identical(chk_b$value[chk_b$check == "convergence_status"], "boundary")
  expect_identical(chk_b$status[chk_b$check == "convergence_status"], "warning")
})

test_that("twin inflated-SE and rank predicates match the documented constants", {
  expect_identical(drmTMB:::drm_twin_rank_tol, 1e-8)
  expect_identical(drmTMB:::drm_twin_inflated_se_floor, 50)
  expect_identical(drmTMB:::drm_twin_inflated_se_ratio, 1000)
  expect_identical(drmTMB:::drm_twin_re_sd_boundary, 1e-4)
  expect_identical(drmTMB:::drm_twin_rho12_boundary, 0.98)
  expect_identical(drmTMB:::drm_twin_sentinel_loglik, -1e15)

  expect_false(drmTMB:::drm_twin_inflated_se_is_true(c(0.1, 0.2, 0.15)))
  # SE >= 50 and >= 1000 x median of the sub-50 reference.
  expect_true(drmTMB:::drm_twin_inflated_se_is_true(c(0.1, 0.2, 500)))
  # min-SE fallback when every SE is >= 50: ratio against min(SE).
  expect_false(drmTMB:::drm_twin_inflated_se_is_true(c(80, 90, 100)))
  expect_true(drmTMB:::drm_twin_inflated_se_is_true(c(80, 90, 8e5)))
})

test_that("optimizer failure and skipped SEs keep the documented status", {
  dat <- data.frame(y = c(-0.2, 0.1, 0.4, 0.7, 1.0, 1.2), x = c(-1, -0.5, 0, 0.5, 1, 1.5))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(optimizer = list(eval.max = 100, iter.max = 100))
  )
  failed <- fit
  failed$opt$convergence <- 1L
  expect_identical(convergence_status(failed), "not_converged")
  expect_false(is_converged(failed))
  chk <- check_drm(failed)
  expect_identical(chk$value[chk$check == "convergence_status"], "not_converged")
  expect_identical(chk$status[chk$check == "convergence_status"], "warning")

  se_skipped <- fit
  se_skipped$sdr <- NULL
  se_skipped$uncertainty <- list(
    status = "skipped",
    message = "TMB::sdreport() was skipped."
  )
  expect_identical(convergence_status(se_skipped), "converged")
  expect_true(is_converged(se_skipped))
  expect_false(is_converged(se_skipped, include_hessian = TRUE))
})

# Converged rule (SHINICHI-1753-1118): not_converged is split from degenerate,
# boundary is tested before the Hessian, cut-offs are unit-free, and Heywood
# folds into boundary with boundary_params (name, kind).
test_that("convergence_info reports the full field set", {
  set.seed(20261118)
  dat <- data.frame(y = rnorm(60), x = rnorm(60))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
  info <- convergence_info(fit)
  expect_named(
    info,
    c(
      "converged", "convergence_status", "boundary_params", "pd_hessian",
      "max_gradient", "optimizer_code",
      "optimizer_message"
    )
  )
  expect_true(info$converged)
  expect_identical(info$convergence_status, "converged")
  expect_identical(names(info$boundary_params), c("name", "kind"))
  expect_equal(nrow(info$boundary_params), 0L)
  expect_true(info$pd_hessian)
  expect_identical(info$optimizer_code, 0L)
  sm <- summary(fit)
  expect_true(sm$converged)
  expect_identical(sm$pd_hessian, TRUE)
  expect_error(convergence_info(1), "native")
})

test_that("boundary is tested before the Hessian and never reads degenerate", {
  set.seed(20261016)
  g <- factor(rep(seq_len(8), each = 25))
  u <- rnorm(nlevels(g), sd = 0.8)
  re_dat <- data.frame(
    y = rnorm(length(g), sd = 0.4) + u[g],
    x = rnorm(length(g)),
    g = g
  )
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), data = re_dat)
  broken <- fit
  broken$sdpars$mu[[1L]] <- 1e-8
  broken$sdr$pdHess <- FALSE
  expect_identical(convergence_status(broken), "boundary")
  bp <- convergence_info(broken)$boundary_params
  expect_identical(bp$kind, "re_sd")
  expect_identical(bp$name, "(1 | g)")
  expect_false(convergence_info(broken)$pd_hessian)
  # Without a boundary the same non-PD Hessian is degenerate.
  nonpd <- fit
  nonpd$sdr$pdHess <- FALSE
  expect_identical(convergence_status(nonpd), "degenerate")
  # A failed optimiser outranks a boundary.
  failed <- broken
  failed$opt$convergence <- 1L
  expect_identical(convergence_status(failed), "not_converged")
})

test_that("boundary cut-off is unit-free in y", {
  set.seed(20261016)
  g <- factor(rep(seq_len(8), each = 25))
  u <- rnorm(nlevels(g), sd = 0.8)
  re_dat <- data.frame(
    y = rnorm(length(g), sd = 0.4) + u[g],
    x = rnorm(length(g)),
    g = g
  )
  fit <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), data = re_dat)
  expect_identical(convergence_status(fit), "converged")
  # Rescale y and the SD together: the ratio, hence the status, is unchanged.
  scaled <- fit
  k <- 1e-6
  scaled$model$y <- fit$model$y * k
  scaled$sdpars$mu <- fit$sdpars$mu * k
  # The mu coefficient SEs carry the units of y too (inflated-SE rule is
  # unit-free): rescale the mu rows and columns of the covariance with y.
  mu_idx <- which(names(fit$opt$par) == "beta_mu")
  scale_vec <- rep(1, nrow(fit$sdr$cov.fixed))
  scale_vec[mu_idx] <- k
  scaled$sdr$cov.fixed <- fit$sdr$cov.fixed * tcrossprod(scale_vec)
  expect_identical(convergence_status(scaled), "converged")
  chk <- check_drm(scaled)
  expect_identical(
    chk$status[chk$check == "random_effect_sd_boundary"],
    "ok"
  )
  # A genuinely tiny SD relative to the response SD is still a boundary.
  tiny <- fit
  tiny$sdpars$mu[[1L]] <- 1e-6 * stats::sd(fit$model$y)
  expect_identical(convergence_status(tiny), "boundary")
})

test_that("rho12 near +/-1 is a boundary kind with its name", {
  rho_kind <- drmTMB:::drm_boundary_params_from_values(
    re_sd_values = numeric(),
    rho12_values = c(rho12 = 0.995)
  )
  expect_identical(rho_kind$kind, "rho12")
  expect_identical(rho_kind$name, "rho12")
})

test_that("inflated-SE rule is unit-free: y, 1000 y and 1e-6 y agree", {
  expect_false(drmTMB:::drm_twin_inflated_se_is_true(c(152, 0.09), c(1000, 1)))
  expect_true(drmTMB:::drm_twin_inflated_se_is_true(c(8e5, 0.09), c(1000, 1)))

  set.seed(20261119)
  n <- 80
  x <- stats::rnorm(n)
  dat <- data.frame(y0 = stats::rnorm(n) + x, x = x)
  dat$x2 <- x + 1e-4 * stats::rnorm(n)
  status <- function(formula, s) {
    dat$y <- dat$y0 * s
    fit <- suppressWarnings(drmTMB(bf(formula, sigma ~ 1), data = dat))
    convergence_status(fit)
  }
  scales <- c(1, 1e3, 1e-6)
  good <- vapply(scales, function(s) status(y ~ x, s), character(1))
  aliased <- vapply(scales, function(s) status(y ~ x + x2, s), character(1))
  expect_identical(good, rep("converged", 3L))
  expect_identical(aliased, rep("degenerate", 3L))
})
