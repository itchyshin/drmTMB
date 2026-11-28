# Joint-route detection in R/julia-joint-call.R (no Julia runtime).

test_that("drm_julia_joint_requested() detects mi() and missing control", {
  form <- bf(y ~ z + mi(x), sigma ~ 1)
  expect_true(drmTMB:::drm_julia_joint_requested(form, impute = NULL, missing = NULL))
  expect_true(
    drmTMB:::drm_julia_joint_requested(
      bf(y ~ z, sigma ~ 1),
      impute = NULL,
      missing = miss_control(predictor = "model")
    )
  )
  expect_false(
    drmTMB:::drm_julia_joint_requested(
      bf(y ~ z, sigma ~ 1),
      impute = NULL,
      missing = miss_control()
    )
  )
  expect_true(
    drmTMB:::drm_julia_joint_requested(
      bf(y ~ z, sigma ~ 1),
      impute = list(foo = 1),
      missing = NULL
    )
  )
})

test_that("drm_julia_call_joint() errors when JuliaCall is unavailable", {
  if (requireNamespace("JuliaCall", quietly = TRUE)) {
    skip("JuliaCall is installed; skip missing-package guard")
  }
  expect_error(drmTMB:::drm_julia_call_joint(list()), "JuliaCall")
})