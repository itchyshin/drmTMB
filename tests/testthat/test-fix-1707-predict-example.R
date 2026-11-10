# Regression guard for #1707: ?predict.drmTMB must not document a pathological
# n = 6 heteroscedastic Gaussian fit (scale runoff, is_converged() FALSE).

test_that("predict.drmTMB() Rd example converges and predict(sigma) stays finite", {
  set.seed(20261110)
  n <- 120
  x <- seq(-1.5, 1.5, length.out = n)
  sigma <- exp(-0.35 + 0.2 * x)
  dat <- data.frame(
    y = 0.4 + 0.7 * x + stats::rnorm(n, sd = sigma),
    x = x
  )

  fit <- expect_no_warning(
    drmTMB(bf(y ~ x, sigma ~ x), data = dat)
  )
  expect_true(is_converged(fit))

  sig <- predict(fit, dpar = "sigma")
  expect_length(sig, n)
  expect_true(all(is.finite(sig)))
  expect_true(all(sig > 0))
  expect_lt(max(sig) / min(sig), 1e3)

  mu <- predict(fit, dpar = "mu")
  expect_length(mu, n)
  expect_true(all(is.finite(mu)))
})
