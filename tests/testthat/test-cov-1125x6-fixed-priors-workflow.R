# Admission helpers in R/fixed-priors-workflow.R.

test_that("drm_fixed_priors_active() detects non-null priors lists", {
  expect_false(drmTMB:::drm_fixed_priors_active(NULL))
  inactive <- structure(list(list(kind = "ridge", precision = 0)), class = "drm_priors")
  expect_false(drmTMB:::drm_fixed_priors_active(inactive))
  active <- drm_priors(drm_prior_normal("mu", "x", sd = 2))
  expect_true(drmTMB:::drm_fixed_priors_active(active))
})

test_that("drm_prior_control() normalizes drm_control objects", {
  ctl <- drmTMB:::drm_prior_control(drm_control())
  expect_type(ctl, "list")
  expect_true("optimizer" %in% names(ctl))
  raw <- drmTMB:::drm_prior_control(drm_control(se = FALSE))
  expect_true("se" %in% names(raw))
})

test_that("drm_validate_fixed_prior_designs() enforces full column rank", {
  aliased <- cbind(1:5, 1:5)
  expect_error(
    drmTMB:::drm_validate_fixed_prior_designs(list(X = list(mu = aliased))),
    "full column rank"
  )
  spec <- list(X = list(mu = cbind(1, c(1, 2, 3))))
  expect_invisible(drmTMB:::drm_validate_fixed_prior_designs(spec))
})