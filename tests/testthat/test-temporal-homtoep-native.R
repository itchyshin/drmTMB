pkgload::load_all(".", compile = TRUE, quiet = TRUE)

source(testthat::test_path("helper-temporal-homtoep-reference.R"))

homtoep_native_data <- function() {
  set.seed(20260910)
  dat <- expand.grid(id = sprintf("s%02d", 1:10), occasion = c(0L, 2L, 4L, 6L))
  dat$x <- rep(c(-1, 1), length.out = nrow(dat))
  dat$y <- 0.3 + 0.4 * dat$x + rnorm(nrow(dat), sd = 0.7)
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

test_that("homtoep fit exposes lag correlations and agrees with dense Gaussian likelihood", {
  dat <- homtoep_native_data()
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = occasion, structure = "homtoep"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  )
  temporal <- fit$model$structured$temporal_mu
  expect_identical(names(fit$corpars$temporal), paste0("cor_lag", 1:3))
  expect_identical(
    names(fit$temporal_start_attempts)[7:9],
    paste0("partial_autocorrelation_lag", 1:3, "_start")
  )
  expect_equal(
    unname(unlist(fit$temporal_start_attempts[1, 7:9])),
    rep(0.3, 3),
    tolerance = 1e-12
  )
  rho <- c(1, unname(fit$corpars$temporal))
  expect_true(all(is.finite(rho)))
  expect_gt(min(eigen(stats::toeplitz(rho), symmetric = TRUE, only.values = TRUE)$values), 0)

  beta <- unname(stats::coef(fit)$mu)
  X <- model.matrix(~ x, dat)
  nll_dense <- homtoep_dense_gaussian_nll(
    dat$y, X, beta, dat$id, dat$occasion,
    sd_temporal = unname(fit$sdpars$mu[[temporal_mu_sd_label(temporal)]]),
    sigma = unname(stats::sigma(fit)), rho = rho
  )
  expect_equal(-as.numeric(stats::logLik(fit)), nll_dense, tolerance = 1e-6)
  expect_equal(as.numeric(fit$obj$fn(fit$opt$par)), homtoep_dense_nll_at(fit, fit$opt$par), tolerance = 1e-7)
})

test_that("homtoep score, Hessian, and conditional modes match independent dense references", {
  dat <- homtoep_native_data()
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = occasion, structure = "homtoep"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  )
  expect_true(isTRUE(fit$sdr$pdHess))
  objective <- function(par) homtoep_dense_nll_at(fit, par)
  opt_par <- fit$opt$par
  score <- numDeriv::grad(objective, opt_par, method.args = list(eps = 1e-6))
  hessian_1 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-4))
  hessian_2 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-5))
  observed_hessian <- solve(fit$sdr$cov.fixed)
  expect_equal(fit$obj$gr(opt_par), score, tolerance = 1e-5)
  expect_equal(hessian_1, hessian_2, tolerance = 1e-4)
  expect_equal(unname(observed_hessian), unname(hessian_1), tolerance = 1e-4)
  expect_equal(
    unname(fit$random_effects$temporal$latent),
    unname(homtoep_dense_conditional_modes(fit)),
    tolerance = 1e-6
  )
})

test_that("homtoep methods preserve row order and distinguish conditional from fresh simulation", {
  dat <- homtoep_native_data()
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = occasion, structure = "homtoep"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  )
  temporal <- fit$model$structured$temporal_mu
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  conditional_mu <- fixed_mu + drmTMB:::temporal_mu_contribution(fit)

  expect_named(fit$random_effects, "temporal")
  expect_named(fit$random_effects$temporal, c("values", "latent", "terms"))
  expect_named(fit$random_effects$temporal$terms, "homtoep")
  expect_equal(
    unname(drmTMB:::temporal_mu_contribution(fit)),
    unname(fit$random_effects$temporal$values[temporal$observation_node_index])
  )
  expect_equal(stats::fitted(fit), conditional_mu, tolerance = 1e-10)
  expect_equal(stats::residuals(fit), fit$model$y - conditional_mu, tolerance = 1e-10)
  expect_error(
    stats::predict(fit, newdata = dat[1L, , drop = FALSE]),
    "fitted observations"
  )
  expect_error(stats::vcov(fit), "Toeplitz coefficient covariance is not yet qualified")
  expect_error(stats::confint(fit, method = "wald"), "Toeplitz mean-coefficient Wald intervals")
  expect_error(stats::confint(fit, method = "profile"), "Toeplitz profile intervals")
  expect_error(
    summary(fit, conf.int = TRUE, method = "wald"),
    "Toeplitz mean-coefficient Wald intervals"
  )
  temporal_check <- drmTMB::check_drm(fit)
  temporal_wald <- temporal_check[temporal_check$check == "temporal_mean_wald", , drop = FALSE]
  temporal_profile <- temporal_check[temporal_check$check == "temporal_mean_profile", , drop = FALSE]
  expect_identical(temporal_wald$status, "note")
  expect_match(temporal_wald$value, "toeplitz_calibration_deferred")
  expect_identical(temporal_profile$status, "note")
  expect_match(temporal_profile$value, "toeplitz_calibration_deferred")

  set.seed(202609101L)
  expected_conditional <- conditional_mu + stats::rnorm(nrow(dat), sd = stats::sigma(fit))
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 202609101L, re.form = NA)[[1L]]),
    expected_conditional,
    tolerance = 1e-10
  )

  set.seed(202609102L)
  expected_fresh <- stats::rnorm(
    nrow(dat),
    mean = fixed_mu + homtoep_dense_fresh_values(fit),
    sd = stats::sigma(fit)
  )
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 202609102L)[[1L]]),
    expected_fresh,
    tolerance = 1e-10
  )
})
