# Model comparison helpers on fitted objects (R/model-comparison.R).

cov_1125x7_cmp <- function() {
  set.seed(112583)
  dat <- data.frame(y = stats::rnorm(18), x = stats::rnorm(18))
  list(
    full = drmTMB(bf(y ~ x, sigma ~ 1), data = dat, control = drm_control(se = FALSE)),
    null = drmTMB(bf(y ~ 1, sigma ~ 1), data = dat, control = drm_control(se = FALSE))
  )
}

test_that("AIC(), BIC(), and aicc() read df and nobs from drmTMB fits", {
  fits <- cov_1125x7_cmp()
  full <- fits$full
  null <- fits$null
  expect_true(is.finite(AIC(full)))
  expect_true(is.finite(AIC(null)))
  expect_gt(BIC(full), AIC(full) - 2 * full$df)
  expect_gt(aicc(full), AIC(full))
  expect_equal(full$nobs, 18L)
})

test_that("logLik() methods expose dfs for nested Gaussian models", {
  fits <- cov_1125x7_cmp()
  expect_gt(attr(logLik(fits$full), "df"), attr(logLik(fits$null), "df"))
  expect_true(is.finite(logLik(fits$full)))
  expect_true(is.finite(logLik(fits$null)))
})

test_that("aicc() stays finite for Poisson and binomial fits", {
  set.seed(112584)
  dat <- data.frame(y = stats::rbinom(20, 1, 0.5), x = stats::rnorm(20))
  bin <- drmTMB(bf(y ~ x), family = binomial(), data = dat, control = drm_control(se = FALSE))
  expect_true(is.finite(aicc(bin)))
  dat2 <- data.frame(y = stats::rpois(20, 2), x = stats::rnorm(20))
  pois <- drmTMB(bf(y ~ x), family = poisson(), data = dat2, control = drm_control(se = FALSE))
  expect_true(is.finite(aicc(pois)))
})