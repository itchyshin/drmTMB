# Coverage for R/fixed-effect-priors.R constructor validation.

test_that("drm_priors() requires valid prior specification objects", {
  expect_error(drm_priors(), "Supply one or more")
  expect_error(drm_priors(1), "prior specifications")
  expect_error(
    drm_priors(list(a = 1)),
    "prior specifications"
  )
})

test_that("drm_prior_sd_gamma() validates its argument contract", {
  expect_error(
    drm_prior_sd_gamma(dpar = "sigma", group = "id", shape = 2, rate = 1),
    "dpar 'mu'"
  )
  expect_error(
    drm_prior_sd_gamma(dpar = "mu", group = "", shape = 2, rate = 1),
    "exact group name"
  )
  expect_error(
    drm_prior_sd_gamma(dpar = "mu", group = "id", coef = "x", shape = 2, rate = 1),
    "Intercept"
  )
  expect_error(
    drm_prior_sd_gamma(dpar = "mu", group = "id", shape = 1, rate = 1),
    "shape > 1"
  )
  expect_error(
    drm_prior_sd_gamma(dpar = "mu", group = "id", shape = 2, rate = 0),
    "rate > 0"
  )
  ok <- drm_prior_sd_gamma(dpar = "mu", group = "site", shape = 2, rate = 3)
  expect_s3_class(ok, "drm_sd_prior")
})