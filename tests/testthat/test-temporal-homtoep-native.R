pkgload::load_all(".", compile = TRUE, quiet = TRUE)

source(testthat::test_path("helper-temporal-homtoep-reference.R"))

homtoep_native_data <- function() {
  set.seed(20260910)
  dat <- expand.grid(id = sprintf("s%02d", 1:20), occasion = c(0L, 2L, 4L, 6L))
  dat$x <- rep(c(-1, 1), length.out = nrow(dat))
  dat$y <- 0.3 + 0.4 * dat$x + rnorm(nrow(dat), sd = 0.7)
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

homtoep_native_fit <- function(dat = homtoep_native_data()) {
  drmTMB::drmTMB(
    drmTMB::bf(
      y ~ x + temporal(1 | id, time = occasion, structure = "homtoep"),
      sigma ~ 1
    ),
    data = dat, family = gaussian(), REML = FALSE
  )
}

test_that("homtoep fit exposes free lag correlations and matches marginal dense likelihood", {
  dat <- homtoep_native_data()
  fit <- homtoep_native_fit(dat)
  rho <- c(1, unname(fit$corpars$temporal))
  expect_identical(names(fit$corpars$temporal), paste0("cor_lag", 1:3))
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_false("temporal" %in% names(fit$random_effects))
  expect_gt(min(eigen(stats::toeplitz(rho), symmetric = TRUE, only.values = TRUE)$values), 0)
  expect_equal(
    -as.numeric(stats::logLik(fit)),
    homtoep_dense_marginal_nll(
      dat$y, stats::model.matrix(~ x, dat), unname(stats::coef(fit)$mu),
      dat$id, dat$occasion, unname(stats::sigma(fit)[[1L]]), rho
    ),
    tolerance = 1e-6
  )
})

test_that("homtoep marginal score and Hessian match an independent dense reference", {
  fit <- homtoep_native_fit()
  objective <- function(par) homtoep_dense_marginal_nll_at(fit, par)
  opt_par <- fit$opt$par
  score <- numDeriv::grad(objective, opt_par, method.args = list(eps = 1e-6))
  hessian_1 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-4))
  hessian_2 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-5))
  observed_hessian <- solve(fit$sdr$cov.fixed)
  expect_equal(unname(as.vector(fit$obj$gr(opt_par))), score, tolerance = 1e-5)
  expect_equal(hessian_1, hessian_2, tolerance = 1e-4)
  expect_equal(unname(observed_hessian), unname(hessian_1), tolerance = 1e-4)
})

test_that("homtoep methods use marginal means and correlated residual draws", {
  dat <- homtoep_native_data()
  fit <- homtoep_native_fit(dat)
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  expect_equal(stats::fitted(fit), fixed_mu, tolerance = 1e-10)
  expect_equal(stats::residuals(fit), fit$model$y - fixed_mu, tolerance = 1e-10)
  expect_error(
    stats::predict(fit, newdata = dat[1L, , drop = FALSE]),
    "fitted observations"
  )
  expect_error(stats::vcov(fit), "Toeplitz coefficient covariance is not yet qualified")
  expect_error(stats::confint(fit, method = "wald"), "Toeplitz mean-coefficient Wald intervals")
  expect_error(stats::confint(fit, method = "profile"), "Toeplitz profile intervals")
  temporal_check <- drmTMB::check_drm(fit)
  temporal_wald <- temporal_check[temporal_check$check == "temporal_mean_wald", , drop = FALSE]
  expect_identical(temporal_wald$status, "note")
  expect_match(temporal_wald$value, "toeplitz_calibration_deferred")
  direct <- drmTMB:::drm_summary_direct_parameters(fit)
  toeplitz_rows <- direct[direct$dpar == "temporal", , drop = FALSE]
  expect_true(all(toeplitz_rows$component == "temporal-correlation"))
  expect_true(all(toeplitz_rows$profile_note == "toeplitz_correlation_intervals_deferred"))
  root <- chol(stats::sigma(fit)[[1L]]^2 * stats::toeplitz(c(1, fit$corpars$temporal)))
  temporal <- fit$model$structured$temporal_mu
  expected <- fixed_mu
  set.seed(202609101L)
  standardized <- numeric(nrow(dat))
  for (series in seq_len(temporal$n_series)) {
    nodes <- seq.int(temporal$series_start0[[series]] + 1L, temporal$series_start0[[series + 1L]])
    rows <- order(temporal$observation_node_index)[nodes]
    standardized[rows] <- forwardsolve(t(root), fit$model$y[rows] - fixed_mu[rows])
    expected[rows] <- fixed_mu[rows] + as.vector(t(root) %*% stats::rnorm(length(rows)))
  }
  expect_equal(stats::residuals(fit, type = "pearson"), standardized, tolerance = 1e-10)
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 202609101L)[[1L]]),
    expected,
    tolerance = 1e-10
  )
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 202609101L, re.form = NA)[[1L]]),
    expected,
    tolerance = 1e-10
  )
})
