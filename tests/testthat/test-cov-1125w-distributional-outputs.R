# Coverage for R/distributional-outputs.R label and response-index helpers.

test_that("drm_quantile_prob_labels() matches stats::quantile percentage columns", {
  f <- drmTMB:::drm_quantile_prob_labels
  expect_identical(f(c(0.025, 0.5, 0.975)), c("2.5%", "50%", "97.5%"))
  expect_identical(f(1), "100%")
  expect_identical(f(0.1), "10%")
})

test_that("drm_biv_gaussian_response_index() maps dpar names to marginal responses", {
  f <- drmTMB:::drm_biv_gaussian_response_index
  expect_identical(f("mu1"), 1L)
  expect_identical(f("sigma1"), 1L)
  expect_identical(f("mu2"), 2L)
  expect_identical(f("sigma2"), 2L)
  expect_error(f("rho12"), 'type = "quantile"')
  expect_error(f("mu"), "identify a response")
})

test_that("drm_predict_quantile() rejects empty or out-of-range probabilities", {
  set.seed(11251125)
  dat <- data.frame(y = stats::rnorm(16), x = stats::rnorm(16))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_error(
    drmTMB:::drm_predict_quantile(fit, newdata = dat, dpar = "mu", prob = 1.5),
    "between 0 and 1"
  )
  expect_error(
    drmTMB:::drm_predict_quantile(fit, newdata = dat, dpar = "mu", prob = numeric(0)),
    "between 0 and 1"
  )
})