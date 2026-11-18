hurdle_nbinom2_sd_design_data <- function(groups = 12L, repeats = 4L) {
  group <- rep(seq_len(groups), each = repeats)
  data.frame(
    count = rep(seq_len(4L), length.out = length(group)),
    x = sin(seq_along(group) / 3),
    z = seq(-1, 1, length.out = groups)[group],
    id = factor(group)
  )
}

hurdle_nbinom2_sd_recovery_data <- function(
  groups = 100L,
  repeats = 20L,
  seed = 20261021L,
  sd_slope = 0.35
) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  z_group <- seq(-1, 1, length.out = groups)
  z <- z_group[group]
  x <- stats::rnorm(length(group))
  alpha <- c(`(Intercept)` = -1.0, z = sd_slope)
  b <- stats::rnorm(groups, sd = exp(alpha[[1L]] + alpha[[2L]] * z_group))
  mu <- exp(0.55 - 0.2 * x + b[group])
  sigma <- 0.55
  hu <- stats::plogis(-0.9)
  size <- 1 / sigma^2
  p0 <- stats::dnbinom(0, size = size, mu = mu)
  hurdle_zero <- stats::runif(length(group)) < hu
  positive_u <- p0 + pmax(stats::runif(length(group)), .Machine$double.eps) *
    (1 - p0)
  count <- ifelse(
    hurdle_zero,
    0,
    stats::qnbinom(positive_u, size = size, mu = mu)
  )
  list(
    data = data.frame(count = count, x = x, z = z, id = factor(group)),
    alpha = alpha
  )
}

hurdle_nbinom2_slope_sd_recovery_data <- function(
  groups = 120L,
  repeats = 24L,
  seed = 20261023L,
  sd_slope = 0.3
) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  z_group <- seq(-1, 1, length.out = groups)
  z <- z_group[group]
  x <- stats::rnorm(length(group))
  alpha <- c(`(Intercept)` = -1.0, z = sd_slope)
  b <- stats::rnorm(groups, sd = exp(alpha[[1L]] + alpha[[2L]] * z_group))
  eta <- 0.4 + 0.2 * x + b[group] * x
  mu <- exp(eta)
  sigma <- 0.45
  hu <- stats::plogis(-1.1)
  size <- 1 / sigma^2
  p0 <- stats::dnbinom(0, size = size, mu = mu)
  hurdle_zero <- stats::runif(length(group)) < hu
  positive_u <- p0 + pmax(stats::runif(length(group)), .Machine$double.eps) *
    (1 - p0)
  count <- ifelse(
    hurdle_zero,
    0,
    stats::qnbinom(positive_u, size = size, mu = mu)
  )
  list(
    data = data.frame(count = count, x = x, z = z, id = factor(group)),
    alpha = alpha
  )
}

test_that("hurdle NB2 assembles one mu intercept SD regression", {
  dat <- hurdle_nbinom2_sd_design_data()
  spec <- drm_build_truncated_nbinom2_spec(
    bf(count ~ x + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ z),
    dat
  )

  expect_identical(spec$model_type, "hurdle_nbinom2")
  expect_identical(spec$random_scale$mu$dpars, "sd(id)")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$dpar,
                   "mu")
  expect_identical(spec$random_scale$mu$target_identity[["sd(id)"]]$coef,
                   "(Intercept)")
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(id)"]][, "z"]),
    seq(-1, 1, length.out = 12L)
  )
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
  expect_equal(spec$tmb_data$X_sd_mu, spec$random_scale$mu$X,
               ignore_attr = TRUE)
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_null(spec$map$beta_sd_mu)
})

test_that("hurdle NB2 recovers a predictor-dependent mu random-intercept SD", {
  sim <- hurdle_nbinom2_sd_recovery_data()
  fit <- drmTMB(
    bf(count ~ x + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ z),
    family = truncated_nbinom2(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit, "sd(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd(id)")[["z"]] - sim$alpha[["z"]]), 0.25)
  expect_equal(length(predict(fit, dpar = "sd(id)")), 100L)
  expect_true(all(predict(fit, dpar = "sd(id)") > 0))
  expect_equal(length(predict(fit, dpar = "hu")), nrow(sim$data))
  expect_equal(
    unname(predict(fit, dpar = "hu")),
    rep(
      stats::plogis(unname(coef(fit, "hu")[[1L]])),
      nrow(sim$data)
    ),
    tolerance = 1e-8
  )

  conditional <- simulate(fit, nsim = 2L, re.form = NA)
  marginal <- simulate(fit, nsim = 2L, seed = 20261022L)
  expect_equal(dim(conditional), c(nrow(sim$data), 2L))
  expect_equal(dim(marginal), c(nrow(sim$data), 2L))
  expect_true(all(is.finite(as.matrix(conditional))))
  expect_true(all(is.finite(as.matrix(marginal))))

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_equal(coef(restored, "sd(id)"), coef(fit, "sd(id)"))
  expect_equal(
    predict(restored, dpar = "sd(id)"),
    predict(fit, dpar = "sd(id)")
  )
})

test_that("constant hurdle NB2 SD regression matches the constant-SD fit", {
  sim <- hurdle_nbinom2_sd_recovery_data(sd_slope = 0)
  fit_constant <- drmTMB(
    bf(count ~ x + (1 | id), sigma ~ 1, hu ~ 1),
    family = truncated_nbinom2(),
    data = sim$data
  )
  fit_sd_intercept <- drmTMB(
    bf(count ~ x + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ 1),
    family = truncated_nbinom2(),
    data = sim$data
  )

  expect_equal(fit_constant$opt$convergence, 0L)
  expect_equal(fit_sd_intercept$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(fit_sd_intercept)),
    as.numeric(logLik(fit_constant)),
    tolerance = 1e-5
  )
  expect_equal(coef(fit_sd_intercept, "mu"), coef(fit_constant, "mu"),
               tolerance = 1e-4)
  expect_equal(coef(fit_sd_intercept, "sigma"), coef(fit_constant, "sigma"),
               tolerance = 1e-4)
  expect_equal(coef(fit_sd_intercept, "hu"), coef(fit_constant, "hu"),
               tolerance = 1e-4)
  expect_equal(
    unname(predict(fit_sd_intercept, dpar = "sd(id)")),
    rep(unname(fit_constant$sdpars$mu[[1L]]), nlevels(sim$data$id)),
    tolerance = 1e-4
  )
})

test_that("hurdle NB2 SD predictors must be constant within each group", {
  dat <- hurdle_nbinom2_sd_design_data()
  dat$z[[2L]] <- dat$z[[2L]] + 0.1

  expect_error(
    drm_build_truncated_nbinom2_spec(
      bf(count ~ x + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ z),
      dat
    ),
    "varies within id level"
  )
})

test_that("hurdle NB2 assembles a selected independent mu slope SD model", {
  dat <- hurdle_nbinom2_sd_design_data()
  spec <- drm_build_truncated_nbinom2_spec(
    bf(count ~ x + (0 + x | id), sigma ~ 1, hu ~ 1,
       sd(id, coef = "x") ~ z),
    dat
  )

  expect_identical(spec$model_type, "hurdle_nbinom2")
  target <- 'sd(id, coef = "x")'
  expect_identical(spec$random_scale$mu$dpars, target)
  expect_identical(spec$random_scale$mu$target_identity[[target]]$coef, "x")
  expect_equal(
    unname(spec$random_scale$mu$X_list[[target]][, "z"]),
    seq(-1, 1, length.out = 12L)
  )
  expect_length(spec$start$beta_sd_mu, 2L)
  expect_identical(spec$tmb_data$has_sd_mu_model, 1L)
})

test_that("hurdle NB2 recovers a random-slope SD regression", {
  sim <- hurdle_nbinom2_slope_sd_recovery_data()
  fit <- drmTMB(
    bf(count ~ x + (0 + x | id), sigma ~ 1, hu ~ 1,
       sd(id, coef = "x") ~ z),
    family = truncated_nbinom2(),
    data = sim$data
  )
  target <- 'sd(id, coef = "x")'

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit, target), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, target)[["z"]] - sim$alpha[["z"]]), 0.3)
  expect_equal(length(predict(fit, dpar = target)), 120L)
  expect_true(all(predict(fit, dpar = target) > 0))

  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path), add = TRUE)
  saveRDS(fit, path)
  restored <- readRDS(path)
  expect_equal(coef(restored, target), coef(fit, target))
  expect_equal(
    predict(restored, dpar = target),
    predict(fit, dpar = target)
  )
})
