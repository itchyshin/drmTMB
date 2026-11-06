tweedie_sd_recovery_data <- function(groups = 42L, repeats = 8L,
                                    slope = 0.4, seed = 20261027L) {
  set.seed(seed)
  id_index <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- stats::rnorm(length(id_index))
  group_sd <- exp(-0.6 + slope * w_group)
  b <- stats::rnorm(groups, sd = group_sd)
  mu <- exp(0.25 + 0.25 * x + b[id_index])
  sigma <- 0.55
  power <- 1.5
  y <- drmTMB:::rtweedie_compound(
    length(mu), mu = mu, phi = sigma^2, power = power
  )
  list(
    data = data.frame(y, x, w, id = factor(id_index)),
    slope = slope,
    w_group = w_group
  )
}

tweedie_sd_slope_recovery_data <- function(groups = 48L, repeats = 8L,
                                           slope = 0.45,
                                           seed = 202610201L) {
  set.seed(seed)
  id_index <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  x_within <- seq(-1, 1, length.out = repeats)
  x <- rep(x_within, times = groups)
  w <- rep(w_group, each = repeats)
  slope_sd <- exp(-0.65 + slope * w_group)
  b <- stats::setNames(stats::rnorm(groups, sd = slope_sd), seq_len(groups))
  mu <- exp(0.3 + 0.25 * x + x * b[as.character(id_index)])
  y <- drmTMB:::rtweedie_compound(
    length(mu), mu = mu, phi = 0.55^2, power = 1.5
  )
  list(
    data = data.frame(y, x, w, id = factor(id_index)),
    slope = slope,
    w_group = w_group
  )
}

test_that("Tweedie SD regression recovers a synthetic group-scale trend", {
  sim <- tweedie_sd_recovery_data()
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w),
    family = tweedie(), data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )

  estimate <- stats::coef(fit, dpar = "sd(id)")[["w"]]
  vc <- stats::vcov(fit)
  label <- grep("w$", colnames(vc), value = TRUE)
  expect_length(label, 1L)
  se <- sqrt(vc[label, label])
  expect_true(is_converged(fit))
  expect_true(is.finite(se) && se > 0)
  expect_lt(abs(estimate - sim$slope), 2.5 * se)
  expect_identical(fit$model$random_scale$mu$target_identity[["sd(id)"]]$group,
                   "id")
  predicted <- predict(fit, dpar = "sd(id)")
  expect_equal(length(predicted), length(sim$w_group))
  expect_true(all(is.finite(predicted) & predicted > 0))
  expect_gt(predicted[[length(predicted)]], predicted[[1L]])
  expect_equal(nrow(simulate(fit, nsim = 1L, seed = 20261028L)),
               nrow(sim$data))
  restored_path <- tempfile(fileext = ".rds")
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_equal(predict(restored, dpar = "sd(id)"), predicted)
  unlink(restored_path)
})

test_that("Tweedie slope SD regression recovers a group-scale trend", {
  sim <- tweedie_sd_slope_recovery_data()
  dpar <- 'sd(id, coef = "x")'
  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, coef = "x") ~ w),
    family = tweedie(), data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )

  estimate <- stats::coef(fit, dpar = dpar)[["w"]]
  vc <- stats::vcov(fit)
  label <- paste0(dpar, ":w")
  se <- sqrt(vc[label, label])
  expect_true(is_converged(fit))
  expect_true(is.finite(se) && se > 0)
  expect_lt(abs(estimate - sim$slope), 2.5 * se)
  expect_identical(
    fit$model$random_scale$mu$target_identity[[dpar]]$coef,
    "x"
  )
  predicted <- predict(fit, dpar = dpar)
  expect_equal(length(predicted), length(sim$w_group))
  expect_true(all(is.finite(predicted) & predicted > 0))
  expect_gt(predicted[[length(predicted)]], predicted[[1L]])
  expect_equal(nrow(simulate(fit, nsim = 1L, seed = 202610203L)),
               nrow(sim$data))

  restored_path <- tempfile(fileext = ".rds")
  on.exit(unlink(restored_path), add = TRUE)
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_equal(predict(restored, dpar = dpar), predicted)
})

test_that("constant Tweedie slope SD matches the existing random-slope model", {
  sim <- tweedie_sd_slope_recovery_data(
    groups = 32L, repeats = 7L, slope = 0, seed = 202610202L
  )
  dpar <- 'sd(id, coef = "x")'
  ordinary <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1),
    family = tweedie(), data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )
  scaled <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, coef = "x") ~ 1),
    family = tweedie(), data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )

  expect_true(is_converged(ordinary))
  expect_true(is_converged(scaled))
  expect_equal(as.numeric(logLik(scaled)), as.numeric(logLik(ordinary)),
               tolerance = 1e-5)
  expect_equal(
    unname(predict(scaled, dpar = dpar)),
    rep(unname(ordinary$sdpars$mu[["(0 + x | id)"]]),
        nlevels(sim$data$id)),
    tolerance = 1e-5
  )
})

test_that("constant Tweedie SD formula matches the existing random-intercept model", {
  sim <- tweedie_sd_recovery_data(
    groups = 32L, repeats = 7L, slope = 0, seed = 20261029L
  )
  ordinary <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1),
    family = tweedie(), data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )
  scaled <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ 1),
    family = tweedie(), data = sim$data,
    control = drm_control(optimizer_preset = "careful")
  )

  expect_equal(ordinary$opt$convergence, 0L)
  expect_true(is_converged(scaled))
  expect_equal(as.numeric(logLik(scaled)), as.numeric(logLik(ordinary)),
               tolerance = 1e-5)
  expect_equal(
    unname(predict(scaled, dpar = "sd(id)")),
    rep(unname(ordinary$sdpars$mu[["(1 | id)"]]), length(sim$w_group)),
    tolerance = 1e-5
  )
})
