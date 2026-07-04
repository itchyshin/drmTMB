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

test_that("log-sigma intercept start keeps the moment scale and slopes ignore the log-bias constant (issue #710.2)", {
  # The scale-slope regression uses log|resid| as its response. Its slopes are
  # invariant to any additive constant on the response, so no log-scale bias
  # correction is needed for them; and the baseline log-sigma intercept is kept
  # from the caller's moment start log(sigma0), not from the (constant-sensitive)
  # regression intercept. This sidesteps the old 0.5*log(pi/2) bug, which corrected
  # the mean scale rather than the log scale and biased the regression intercept
  # ~0.41 low on the log scale.
  set.seed(7102)
  n <- 4000
  z <- stats::rnorm(n)
  X_sigma <- cbind(`(Intercept)` = 1, z = z)
  sigma0 <- 0.8
  # heteroscedastic residuals so the recovered slope is non-trivial
  resid <- stats::rnorm(n, 0, exp(log(sigma0) + 0.4 * z))
  start <- gaussian_sigma_fixed_start(
    resid = resid,
    X_sigma = X_sigma,
    sigma0 = sigma0,
    sigma_floor = 1e-6,
    observed_y = rep(TRUE, n)
  )
  # Intercept is the caller's moment start log(sigma0), independent of the response
  # constant (no downward bias from a log/mean scale mismatch).
  expect_equal(unname(start[["(Intercept)"]]), log(sigma0), tolerance = 1e-10)
  # Slope recovers the true 0.4 log-sigma trend and is constant-invariant.
  expect_gt(start[["z"]], 0.2)
  expect_lt(abs(start[["z"]] - 0.4), 0.1)
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
