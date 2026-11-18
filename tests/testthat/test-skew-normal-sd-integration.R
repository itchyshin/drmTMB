skew_normal_slope_sd_data <- function() {
  set.seed(20261020)
  n_group <- 60L
  repeats <- 8L
  id <- factor(rep(seq_len(n_group), each = repeats))
  w_group <- seq(-1, 1, length.out = n_group)
  w <- rep(w_group, each = repeats)
  x <- rep(seq(-1, 1, length.out = repeats), times = n_group)
  slope_sd <- exp(-0.6 + 0.4 * w_group)
  b_slope <- stats::rnorm(n_group, sd = slope_sd)
  mu <- 0.2 + 0.3 * x + x * b_slope[as.integer(id)]
  sigma <- rep(0.65, length(mu))
  nu <- rep(1.1, length(mu))
  native <- skew_normal_public_to_native(mu, sigma, nu)
  y <- native$xi + native$omega * (
    native$delta * abs(stats::rnorm(length(mu))) +
      sqrt(1 - native$delta^2) * stats::rnorm(length(mu))
  )
  data.frame(y, x, w, id)
}

test_that("skew-normal SD regression recovers a synthetic group-scale trend", {
  set.seed(20261019)
  n_group <- 48L
  repeats <- 9L
  id <- factor(rep(seq_len(n_group), each = repeats))
  w_group <- seq(-1, 1, length.out = n_group)
  w <- rep(w_group, each = repeats)
  x <- stats::rnorm(n_group * repeats)
  group_sd <- exp(-0.55 + 0.45 * w_group)
  b <- stats::rnorm(n_group, sd = group_sd)
  mu <- 0.25 + 0.3 * x + b[as.integer(id)]
  sigma <- rep(0.7, length(mu))
  nu <- rep(1.1, length(mu))
  native <- skew_normal_public_to_native(mu, sigma, nu)
  y <- native$xi + native$omega * (
    native$delta * abs(stats::rnorm(length(mu))) +
      sqrt(1 - native$delta^2) * stats::rnorm(length(mu))
  )
  dat <- data.frame(y, x, w, id)

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w),
    family = skew_normal(),
    data = dat,
    control = drm_control(optimizer_preset = "careful")
  )
  estimate <- stats::coef(fit, dpar = "sd(id)")[["w"]]
  vc <- stats::vcov(fit)
  sd_coef_label <- grep("w$", colnames(vc), value = TRUE)
  expect_length(sd_coef_label, 1L)
  se <- sqrt(vc[sd_coef_label, sd_coef_label])

  expect_true(is_converged(fit))
  expect_true(is.finite(se) && se > 0)
  expect_lt(abs(estimate - 0.45), 2.5 * se)
  expect_identical(fit$model$random_scale$mu$target_identity[["sd(id)"]]$group,
                   "id")
  predicted <- predict(fit, dpar = "sd(id)")
  expect_equal(length(predicted), n_group)
  expect_true(all(is.finite(predicted) & predicted > 0))
  expect_gt(predicted[[n_group]], predicted[[1L]])
  expect_true(is.data.frame(stats::simulate(fit, nsim = 1L)))
  roundtrip_path <- tempfile(fileext = ".rds")
  saveRDS(fit, roundtrip_path)
  roundtrip <- readRDS(roundtrip_path)
  expect_identical(
    roundtrip$model$random_scale$mu$target_identity[["sd(id)"]]$group,
    "id"
  )
  expect_equal(
    stats::predict(roundtrip, dpar = "sd(id)"),
    predicted
  )
})

test_that("skew-normal independent slope SD recovers and preserves constant SD", {
  dat <- skew_normal_slope_sd_data()
  base_formula <- bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1)
  slope_formula <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "x") ~ w
  )

  baseline <- drmTMB(
    base_formula, family = skew_normal(), data = dat,
    control = drm_control(optimizer_preset = "careful")
  )
  trend <- drmTMB(
    slope_formula, family = skew_normal(), data = dat,
    control = drm_control(optimizer_preset = "careful")
  )
  constant <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, coef = "x") ~ 1),
    family = skew_normal(), data = dat,
    control = drm_control(optimizer_preset = "careful")
  )

  key <- 'sd(id, coef = "x")'
  estimate <- stats::coef(trend, dpar = key)[["w"]]
  vc <- stats::vcov(trend)
  sd_coef_label <- grep("w$", colnames(vc), value = TRUE)
  expect_length(sd_coef_label, 1L)
  se <- sqrt(vc[sd_coef_label, sd_coef_label])

  expect_true(
    is_converged(baseline),
    info = paste(
      "optimizer convergence:", baseline$opt$convergence,
      "message:", baseline$opt$message,
      "positive-definite Hessian:", baseline$sdr$pdHess,
      "status:", convergence_status(baseline),
      paste(capture.output(print(check_drm(baseline))), collapse = "\n")
    )
  )
  expect_false(
    any(check_drm(baseline)$check == "fixed_effect_rank_deficiency")
  )
  expect_true(is_converged(trend))
  expect_true(is.finite(se) && se > 0)
  expect_lt(abs(estimate - 0.4), 2.5 * se)
  expect_identical(
    trend$model$random_scale$mu$target_identity[[key]]$coef,
    "x"
  )
  predicted <- stats::predict(trend, dpar = key)
  expect_length(predicted, 60L)
  expect_true(all(is.finite(predicted) & predicted > 0))
  expect_gt(predicted[[60L]], predicted[[1L]])
  expect_true(is.data.frame(stats::simulate(trend, nsim = 1L)))

  expect_true(is_converged(constant))
  expect_equal(
    as.numeric(stats::logLik(constant)),
    as.numeric(stats::logLik(baseline)),
    tolerance = 1e-5
  )
})

test_that("constant skew-normal SD formula matches the constant-SD model", {
  set.seed(20261020)
  n_group <- 48L
  repeats <- 9L
  id <- factor(rep(seq_len(n_group), each = repeats))
  x <- stats::rnorm(length(id))
  b <- stats::rnorm(n_group, sd = 0.5)
  mu <- 0.2 + 0.3 * x + b[as.integer(id)]
  sigma <- rep(0.7, length(mu))
  nu <- rep(1.0, length(mu))
  native <- skew_normal_public_to_native(mu, sigma, nu)
  y <- native$xi + native$omega * (
    native$delta * abs(stats::rnorm(length(mu))) +
      sqrt(1 - native$delta^2) * stats::rnorm(length(mu))
  )
  dat <- data.frame(y, x, id)

  ordinary <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1),
    family = skew_normal(), data = dat,
    control = drm_control(optimizer_preset = "careful")
  )
  scaled <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ 1),
    family = skew_normal(), data = dat,
    control = drm_control(optimizer_preset = "careful")
  )

  expect_equal(ordinary$opt$convergence, 0L)
  expect_true(is_converged(scaled))
  expect_equal(as.numeric(stats::logLik(scaled)),
               as.numeric(stats::logLik(ordinary)), tolerance = 1e-5)
  expect_equal(
    unname(stats::predict(scaled, dpar = "sd(id)")),
    rep(unname(ordinary$sdpars$mu[["(1 | id)"]]), n_group),
    tolerance = 1e-5
  )
})
