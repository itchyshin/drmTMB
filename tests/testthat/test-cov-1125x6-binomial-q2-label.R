# Labelled q2 SD admission in R/binomial-q2-sd.R.

test_that("drm_binomial_labelled_q2_ok() rejects incomplete terms", {
  expect_false(drmTMB:::drm_binomial_labelled_q2_ok(NULL, list(1, 2), "logit"))
  bare <- list(covariance_label = NULL, coef_names = c("(Intercept)", "x"))
  expect_false(drmTMB:::drm_binomial_labelled_q2_ok(bare, list(1, 2), "logit"))
  labelled <- list(covariance_label = "p", coef_names = c("(Intercept)", "x"))
  expect_false(
    drmTMB:::drm_binomial_labelled_q2_ok(labelled, list(1), "logit")
  )
  expect_false(
    drmTMB:::drm_binomial_labelled_q2_ok(labelled, list(1, 2), "probit")
  )
})