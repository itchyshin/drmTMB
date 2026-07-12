# DO-T2 tests for R/distributional-outputs.R (predict(type = "quantile"),
# exceedance(), centile_chart()). Built on the FROZEN DO-T0a foundation
# (R/family-dpq.R); see tests/testthat/test-family-dpq.R for the underlying
# fitted_distribution() correctness tests this file does not repeat, and
# tests/testthat/test-adequacy.R for the DO-T1 spike-warning idiom this file
# reuses (drm_warn_adequacy_spike(), drm_reset_adequacy_warning_state()).
#
# Honesty (Fisher): every predict(type = "quantile")/exceedance() result is a
# distributional (plug-in) output at theta_hat, never a calibrated-coverage
# claim -- assertions here check the numeric agreement with a large-n
# simulate() Monte Carlo estimate ("truth" under the fitted model), not
# coverage against unknown truth.
#
# Monte Carlo tolerance: |analytic - MC| <= 3 * MCSE, per the verification
# spec. MCSE for an exceedance/CDF proportion uses the standard binomial
# formula sqrt(p*(1-p)/N); MCSE for a sample quantile uses the standard
# order-statistic asymptotic formula sqrt(p*(1-p)/N) / f(Q_p), with f(Q_p)
# read from fitted_distribution()$d() at the analytic quantile (exact, not
# re-derived). Heavy N draws are gated behind skip_on_cran(), matching the
# repository's existing heavy-simulation convention (e.g.
# test-animal-relmat-gaussian.R, test-control.R).

new_biv_gaussian_quantile_data <- function(n = 400, seed = 20260716) {
  set.seed(seed)
  x <- stats::rnorm(n)
  mu1 <- 0.4 + 0.6 * x
  mu2 <- -0.2 + 0.3 * x
  sigma1 <- 0.8
  sigma2 <- 1.1
  rho12 <- 0.35
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  data.frame(y1 = mu1 + sigma1 * e1, y2 = mu2 + sigma2 * e2, x = x)
}

# ---- (a)/(b) gaussian: predict(quantile)/exceedance() vs simulate() MC -----

test_that("gaussian: predict(type = 'quantile') matches simulate() MC within 3*MCSE", {
  testthat::skip_on_cran()
  set.seed(20260716)
  n <- 8
  x <- seq(-1.5, 1.5, length.out = n)
  dat <- data.frame(y = 0.4 + 0.7 * x + stats::rnorm(n, sd = 0.9), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  prob <- c(0.1, 0.5, 0.9)
  N <- 2e4
  qhat <- predict(fit, type = "quantile", prob = prob)
  expect_equal(dim(qhat), c(n, length(prob)))
  expect_identical(colnames(qhat), c("10%", "50%", "90%"))
  expect_identical(attr(qhat, "calibrated"), FALSE)

  sims <- as.matrix(simulate(fit, nsim = N, seed = 4242))
  fd <- fitted_distribution(fit)

  for (j in seq_along(prob)) {
    p <- prob[[j]]
    mc_q <- apply(sims, 1L, stats::quantile, probs = p, names = FALSE)
    dens_at_q <- fd$d(qhat[, j])
    mcse <- sqrt(p * (1 - p) / N) / dens_at_q
    diff <- abs(qhat[, j] - mc_q)
    expect_true(all(diff <= 3 * mcse))
  }
})

test_that("gaussian: predict(type = 'quantile', prob = 0.5) matches the analytic median", {
  set.seed(1)
  n <- 30
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  qmed <- predict(fit, type = "quantile", prob = 0.5)
  expect_equal(as.numeric(qmed[, 1L]), predict(fit, dpar = "mu"), tolerance = 1e-8)
})

test_that("gaussian: exceedance() matches simulate() MC within 3*MCSE, both tails", {
  testthat::skip_on_cran()
  set.seed(20260717)
  n <- 8
  x <- seq(-1.5, 1.5, length.out = n)
  dat <- data.frame(y = 0.2 + 0.5 * x + stats::rnorm(n, sd = 1.1), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  N <- 2e4
  threshold <- 0.3
  exc <- exceedance(fit, threshold = threshold)
  exc_lower <- exceedance(fit, threshold = threshold, lower.tail = TRUE)
  expect_identical(attr(exc, "calibrated"), FALSE)
  expect_equal(as.numeric(exc) + as.numeric(exc_lower), rep(1, n))

  sims <- as.matrix(simulate(fit, nsim = N, seed = 99))
  mc_exc <- rowMeans(sims > threshold)
  mcse <- sqrt(exc * (1 - exc) / N)
  expect_true(all(abs(as.numeric(exc) - mc_exc) <= 3 * mcse))
})

# ---- tweedie atom: exceedance() correctly includes the mass at y = 0 -------

test_that("tweedie spike: exceedance(c = 0) correctly handles the zero atom vs simulate() MC", {
  testthat::skip_on_cran()
  testthat::skip_if_not_installed("tweedie")
  drm_reset_adequacy_warning_state()
  set.seed(20260714)
  n <- 40
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.3 * x)
  y <- rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat)

  N <- 2e4
  expect_warning(
    exceedance(fit, threshold = 0),
    "feasibility-grade"
  )
  exc0 <- expect_no_warning(exceedance(fit, threshold = 0))
  exc0_atom <- expect_no_warning(exceedance(fit, threshold = 0, lower.tail = TRUE))
  expect_identical(attr(exc0, "calibrated"), FALSE)
  # complement identity: Pr(Y > 0) + Pr(Y <= 0) == 1
  expect_equal(as.numeric(exc0) + as.numeric(exc0_atom), rep(1, n))
  # external cross-check: the atom mass equals tweedie::dtweedie() at y = 0
  # (same identity test-family-dpq.R verifies for fitted_distribution()$p()).
  mu_hat <- predict(fit, dpar = "mu")
  sigma_hat <- predict(fit, dpar = "sigma")
  nu_hat <- predict(fit, dpar = "nu")
  atom_mass <- tweedie::dtweedie(rep(0, n), mu = mu_hat, phi = sigma_hat^2, power = nu_hat[1])
  expect_equal(as.numeric(exc0_atom), atom_mass)

  sims <- as.matrix(suppressWarnings(simulate(fit, nsim = N, seed = 321)))
  mc_exc0 <- rowMeans(sims > 0)
  mc_atom0 <- rowMeans(sims <= 0)
  mcse_exc0 <- sqrt(exc0 * (1 - exc0) / N)
  mcse_atom0 <- sqrt(exc0_atom * (1 - exc0_atom) / N)
  expect_true(all(abs(as.numeric(exc0) - mc_exc0) <= 3 * mcse_exc0))
  expect_true(all(abs(as.numeric(exc0_atom) - mc_atom0) <= 3 * mcse_atom0))
  drm_reset_adequacy_warning_state()
})

# ---- calibrated = FALSE attribute -------------------------------------------

test_that("predict(type = 'quantile') and exceedance() both carry calibrated = FALSE", {
  set.seed(1)
  n <- 20
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  qhat <- predict(fit, type = "quantile")
  exc <- exceedance(fit, threshold = 0)
  expect_identical(attr(qhat, "calibrated"), FALSE)
  expect_identical(attr(exc, "calibrated"), FALSE)
})

# ---- bivariate biv_gaussian: marginal-only quantile scope -------------------

test_that("biv_gaussian: predict(type = 'quantile') returns MARGINAL per-response quantiles", {
  dat <- new_biv_gaussian_quantile_data(n = 400)
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat
  )

  q1 <- predict(fit, dpar = "mu1", type = "quantile", prob = 0.5)
  q2 <- predict(fit, dpar = "mu2", type = "quantile", prob = 0.5)
  # the marginal median of a bivariate normal equals its own marginal mean,
  # regardless of rho12 -- the numerical proof that this is a MARGINAL, not
  # joint, quantile.
  expect_equal(as.numeric(q1[, 1L]), predict(fit, dpar = "mu1"), tolerance = 1e-8)
  expect_equal(as.numeric(q2[, 1L]), predict(fit, dpar = "mu2"), tolerance = 1e-8)
  expect_identical(attr(q1, "calibrated"), FALSE)

  # default dpar (NULL) resolves to the first fitted dpar, i.e. response 1.
  q_default <- predict(fit, type = "quantile", prob = 0.5)
  expect_equal(q_default, q1)

  # a dpar that does not identify a response (e.g. the joint correlation)
  # errors clearly rather than silently guessing a response.
  expect_error(
    predict(fit, dpar = "rho12", type = "quantile"),
    "needs .arg to identify a response|needs.*dpar.*identify a response"
  )
})

test_that("biv_gaussian: exceedance() is out of scope and errors via the frozen registry", {
  dat <- new_biv_gaussian_quantile_data(n = 200)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_gaussian(),
    data = dat
  )
  expect_error(
    exceedance(fit, threshold = 0),
    "does not yet cover model type"
  )
})

# ---- error handling ----------------------------------------------------------

test_that("predict(type = 'quantile') and exceedance() validate their arguments", {
  set.seed(1)
  n <- 20
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.5 + 0.8 * x + stats::rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(predict(fit, type = "quantile", prob = c(-0.1, 0.5)), "between 0 and 1")
  expect_error(predict(fit, type = "quantile", prob = numeric(0)), "between 0 and 1")
  expect_error(exceedance(fit, threshold = NA_real_), "non-missing")
  expect_error(exceedance(fit, threshold = c(1, 2, 3)), "one value per row")
  expect_error(exceedance(fit, threshold = 0, lower.tail = "yes"), "TRUE or FALSE")
})

# ---- centile_chart() ---------------------------------------------------------

test_that("centile_chart() returns a ggplot object with reference-value reporting", {
  testthat::skip_if_not_installed("ggplot2")
  set.seed(20260712)
  n <- 60
  x1 <- stats::rnorm(n)
  x2 <- stats::rnorm(n)
  dat <- data.frame(
    y = 0.5 + 0.8 * x1 - 0.3 * x2 + stats::rnorm(n),
    x1 = x1,
    x2 = x2
  )
  fit <- drmTMB(bf(y ~ x1 + x2, sigma ~ 1), family = gaussian(), data = dat)

  p <- centile_chart(fit, covariate = "x1")
  expect_s3_class(p, "ggplot")
  expect_match(p$labels$subtitle, "NOT a WHO")
  expect_match(p$labels$subtitle, "x2")
})
