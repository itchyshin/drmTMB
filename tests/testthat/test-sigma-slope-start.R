# Wave 2 (ML robustness): gaussian_sigma_fixed_start used to discard ALL scale
# slopes when its log-abs-residual heuristic looked too large (predicted spread
# > 8 or |coef| > 5), handing a legitimately strong scale-heterogeneity model a
# flat intercept-only start. It now shrinks an over-large slope start toward zero
# (direction preserved, bounded) instead of zeroing it.

test_that("an extreme scale-slope start is shrunk and bounded, not discarded", {
  set.seed(1)
  n <- 300
  z <- stats::rnorm(n)
  X_sigma <- cbind(`(Intercept)` = 1, z = z)
  # A very strong scale-z relationship makes the raw heuristic exceed the bounds.
  resid <- stats::rnorm(n, 0, exp(-0.5 + 3 * z))
  start <- gaussian_sigma_fixed_start(
    resid = resid,
    X_sigma = X_sigma,
    sigma0 = 0.6,
    sigma_floor = 1e-4,
    observed_y = rep(TRUE, n)
  )
  # the slope is retained (non-zero), not discarded to a flat intercept-only start
  expect_gt(abs(start[["z"]]), 0)
  # but bounded: |slope| <= 5 and the slope-driven predictor spread <= 8
  expect_lte(abs(start[["z"]]), 5 + 1e-8)
  eta_slope <- as.vector(X_sigma[, "z", drop = FALSE] %*% start[["z"]])
  expect_lte(diff(range(eta_slope)), 8 + 1e-6)
})

test_that("a moderate scale-slope start is retained", {
  set.seed(2)
  n <- 300
  z <- stats::rnorm(n)
  X_sigma <- cbind(`(Intercept)` = 1, z = z)
  resid <- stats::rnorm(n, 0, exp(-0.5 + 0.3 * z))
  start <- gaussian_sigma_fixed_start(
    resid = resid,
    X_sigma = X_sigma,
    sigma0 = 0.6,
    sigma_floor = 1e-4,
    observed_y = rep(TRUE, n)
  )
  # a moderate slope is recovered with the expected sign and is not zeroed
  expect_gt(start[["z"]], 0)
})

test_that("log-sigma slope-model intercept start is unbiased on the log scale (issue #710.2)", {
  # The scale regression response is log|resid|, whose expectation is
  # log(sigma) + E[log|Z|] with E[log|Z|] = -0.5*(gamma + log 2). Adding the
  # matching +0.5*(gamma + log 2) makes the intercept start recover log(sigma).
  # The previous 0.5*log(pi/2) constant seated it ~0.41 too low (sigma ~34% small).
  set.seed(7102)
  n <- 4000
  z <- stats::rnorm(n)
  X_sigma <- cbind(`(Intercept)` = 1, z = z)
  sigma_true <- 0.8
  resid <- stats::rnorm(n, 0, sigma_true) # homoscedastic: true slope is 0
  start <- gaussian_sigma_fixed_start(
    resid = resid,
    X_sigma = X_sigma,
    sigma0 = 1,
    sigma_floor = 1e-6,
    observed_y = rep(TRUE, n)
  )
  # The recovered intercept start is close to log(sigma_true), not biased low.
  expect_equal(unname(start[["(Intercept)"]]), log(sigma_true), tolerance = 0.05)
  # The old 0.5*log(pi/2) constant would give an intercept near log(sigma) - 0.41.
  old_constant_intercept <- unname(start[["(Intercept)"]]) -
    0.5 * (-digamma(1) + log(2)) +
    0.5 * log(pi / 2)
  expect_lt(old_constant_intercept, log(sigma_true) - 0.3)
})

test_that("an intercept-only sigma start is returned unchanged", {
  set.seed(3)
  n <- 100
  X_sigma <- cbind(`(Intercept)` = rep(1, n))
  start <- gaussian_sigma_fixed_start(
    resid = stats::rnorm(n, 0, 0.6),
    X_sigma = X_sigma,
    sigma0 = 0.6,
    sigma_floor = 1e-4,
    observed_y = rep(TRUE, n)
  )
  expect_length(start, 1L)
  expect_equal(unname(start[[1L]]), log(0.6))
})
