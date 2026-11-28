# Prior builders in R/fixed-effect-priors.R.

test_that("drm_priors() bundles valid prior objects", {
  p <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
  expect_s3_class(p, "drm_priors")
  expect_error(drm_priors(list()), "one or more")
  expect_error(drm_priors("x"), "one or more")
})

test_that("drm_prior_sd_gamma() validates target and hyperparameters", {
  ok <- drm_prior_sd_gamma(group = "grp", shape = 2, rate = 1)
  expect_s3_class(ok, "drm_sd_prior")
  expect_error(drm_prior_sd_gamma(group = "grp", shape = 0.5, rate = 1), "shape")
  expect_error(drm_prior_sd_gamma(group = "", shape = 2, rate = 1), "group")
  expect_error(drm_prior_sd_gamma(dpar = "sigma", group = "g", shape = 2, rate = 1), "dpar")
})

test_that("drm_fixed_prior_new() distinguishes normal and ridge priors", {
  n <- drmTMB:::drm_fixed_prior_new("mu", "x", NULL, "normal", 0, 2, NULL)
  expect_equal(n$precision, 0.25)
  r <- drmTMB:::drm_fixed_prior_new("sigma", "all", "exclude", "ridge", 0, NULL, 4)
  expect_equal(r$precision, 4)
  expect_error(
    drmTMB:::drm_fixed_prior_new("nu", "x", NULL, "normal", 0, 2, NULL),
    "dpar"
  )
  expect_error(
    drmTMB:::drm_fixed_prior_new("mu", "all", NULL, "normal", 0, 2, NULL),
    "intercept"
  )
})

test_that("drm_prior_ridge() and drm_prior_normal() are thin wrappers", {
  ridge <- drm_prior_ridge("mu", "x", lambda = 0.5)
  expect_equal(ridge$kind, "ridge")
  normal <- drm_prior_normal("mu", "x", sd = 1)
  expect_equal(normal$kind, "normal")
})