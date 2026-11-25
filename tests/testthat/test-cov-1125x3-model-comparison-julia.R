# Julia and helper branches in R/model-comparison.R.

test_that("drm_fit_estimator() and mean-structure fingerprint", {
  expect_identical(drmTMB:::drm_fit_estimator(list()), "ML")
  expect_identical(drmTMB:::drm_fit_estimator(list(estimator = "REML")), "REML")
  fit <- list(coefficients = list(mu = c("(Intercept)" = 1, x = 0.2), mu2 = c(x = 0.1)))
  ms <- drmTMB:::drm_lrtest_mean_structure(fit)
  expect_true(all(c("mu (Intercept)", "mu x", "mu2 x") %in% ms))
})

test_that("drm_lrtest_reml_guard() aborts on different mean structures under REML", {
  reduced <- list(
    estimator = "REML",
    coefficients = list(mu = c("(Intercept)" = 1))
  )
  full <- list(
    estimator = "REML",
    coefficients = list(mu = c("(Intercept)" = 1, x = 0.2))
  )
  expect_error(
    drmTMB:::drm_lrtest_reml_guard(reduced, full),
    "REML"
  )
  ml <- list(estimator = "ML", coefficients = list(mu = c(x = 1)))
  expect_invisible(drmTMB:::drm_lrtest_reml_guard(ml, ml))
})

test_that("aicc.drmTMB_julia returns the small-sample correction", {
  fit <- structure(
    list(logLik = -10, df = 3, nobs = 50),
    class = c("drmTMB_julia", "drmTMB")
  )
  val <- suppressWarnings(aicc(fit))
  expect_equal(val, drmTMB:::drm_aicc_from_loglik(-10, 3, 50, what = "drmTMB_julia"))
})

test_that("weights.drmTMB_julia returns unit weights", {
  fit <- structure(list(nobs = 7L), class = c("drmTMB_julia", "drmTMB"))
  expect_equal(unname(weights(fit)), rep(1, 7L))
})

test_that("drm_aicc_from_loglik() errors when df or nobs attributes are missing", {
  expect_error(
    drmTMB:::drm_aicc_from_loglik(-1, NULL, 10, what = "dummy"),
    "df"
  )
})