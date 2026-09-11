pkgload::load_all(".", compile = FALSE, quiet = TRUE)
source(testthat::test_path("helper-temporal-hetar1-reference.R"))

hetar1_native_data <- function() {
  set.seed(20260911)
  dat <- expand.grid(
    id = sprintf("s%02d", seq_len(24L)),
    occasion = c(0L, 1L, 2L, 3L),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  dat$x <- rep(c(-1, 1), length.out = nrow(dat))
  dat$y <- 0.2 + 0.5 * dat$x + stats::rnorm(nrow(dat), sd = 0.7)
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

hetar1_native_fit <- function(dat = hetar1_native_data()) {
  drmTMB::drmTMB(
    drmTMB::bf(
      y ~ x + temporal(1 | id, time = occasion, structure = "hetar1"),
      sigma ~ 1
    ),
    data = dat, family = gaussian(), REML = FALSE
  )
}

test_that("hetar1 uses a labelled D-R-D covariance with signed AR1 starts", {
  fit <- hetar1_native_fit()
  temporal <- fit$model$structured$temporal_mu
  expect_identical(temporal$structure, "hetar1")
  expect_equal(sort(fit$temporal_start_attempts$persistence_start), c(-0.3, 0.3))
  expect_identical(
    names(fit$sdpars$mu),
    paste0("temporal_sd[", temporal$occasion_levels, "]: ", temporal$label)
  )
  expect_identical(names(fit$corpars$temporal), temporal$label)
  expected_values <- exp(unname(fit$opt$par[names(fit$opt$par) == "log_sd_temporal"]))[
    temporal$occasion_index[order(temporal$observation_node_index)]
  ] * unname(fit$random_effects$temporal$latent)
  expect_equal(unname(fit$random_effects$temporal$values), expected_values)
  covariance <- stats::vcov(fit)
  expect_equal(
    unname(covariance),
    unname(fit$sdr$cov.fixed[seq_len(2L), seq_len(2L)]),
    tolerance = 1e-8
  )
  intervals <- stats::confint(fit, method = "wald")
  expect_true(all(is.finite(intervals$lower) & is.finite(intervals$upper)))
  expect_true(all(intervals$lower < intervals$upper))
  expect_error(stats::confint(fit, method = "profile"), "not yet qualified")
  diagnostics <- drmTMB::check_drm(fit)
  wald_row <- diagnostics[diagnostics$check == "temporal_mean_wald", , drop = FALSE]
  profile_row <- diagnostics[diagnostics$check == "temporal_mean_profile", , drop = FALSE]
  expect_identical(wald_row$value, "available_for_this_fit; coverage=unassessed")
  expect_identical(profile_row$value, "unavailable; reason=hetar1_profile_deferred")
  expect_equal(
    -as.numeric(stats::logLik(fit)),
    hetar1_dense_nll_at(fit, fit$opt$par),
    tolerance = 1e-6
  )
})

test_that("hetar1 native score and observed Hessian match the dense marginal oracle", {
  fit <- hetar1_native_fit()
  objective <- function(par) hetar1_dense_nll_at(fit, par)
  opt_par <- fit$opt$par
  score <- numDeriv::grad(objective, opt_par, method.args = list(eps = 1e-6))
  hessian_1 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-4))
  hessian_2 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-5))
  observed_hessian <- solve(fit$sdr$cov.fixed)
  expect_equal(unname(as.vector(fit$obj$gr(opt_par))), score, tolerance = 1e-5)
  expect_equal(hessian_1, hessian_2, tolerance = 1e-4)
  expect_equal(unname(observed_hessian), unname(hessian_1), tolerance = 1e-4)
})

test_that("hetar1 methods retain labelled conditional effects and seeded simulation", {
  fit <- hetar1_native_fit()
  temporal <- fit$model$structured$temporal_mu
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  conditional_mu <- fixed_mu + temporal_mu_contribution(fit)
  expect_equal(stats::fitted(fit), conditional_mu, tolerance = 1e-10)
  expect_equal(stats::residuals(fit), fit$model$y - conditional_mu, tolerance = 1e-10)

  set.seed(202609113L)
  expected_conditional <- conditional_mu + stats::rnorm(
    nrow(fit$data), sd = observation_sigma(fit)
  )
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 202609113L, re.form = NA)[[1L]]),
    expected_conditional,
    tolerance = 1e-10
  )

  set.seed(202609114L)
  fresh_temporal <- drm_fresh_temporal_mu_values(fit)
  expected_marginal <- fixed_mu + fresh_temporal + stats::rnorm(
    nrow(fit$data), sd = observation_sigma(fit)
  )
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 202609114L)[[1L]]),
    expected_marginal,
    tolerance = 1e-10
  )
  expect_identical(names(fit$random_effects$temporal$terms), "hetar1")
  expect_identical(length(fit$sdpars$mu), temporal$n_occasions)
})
