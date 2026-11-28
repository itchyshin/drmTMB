test_that("Julia prior admission allows correlation rows but keeps unsupported rows native-only", {
  rho12 <- drm_correlation_prior_lkj(dpar = "rho12", eta = 2)
  random_slope <- drm_correlation_prior_lkj(
    dpar = "mu", group = "site", from_coef = "(Intercept)",
    to_coef = "x", eta = 2
  )
  student_t <- drm_prior_student_t(dpar = "mu", coef = "x", scale = 1, df = 4)
  residual_sd <- drm_residual_sd_prior_gamma(shape = 2, rate = 3)
  biv_fixed <- drm_prior_normal(dpar = "mu1", coef = "x", sd = 1)

  expect_false(drm_prior_uses_native_only_targets(list(rho12)))
  expect_false(drm_prior_uses_native_only_targets(list(random_slope)))
  expect_false(drm_prior_uses_native_only_targets(list(student_t)))
  expect_false(drm_prior_uses_native_only_targets(list(residual_sd)))
  expect_false(drm_prior_uses_native_only_targets(list(residual_sd, student_t)))
  expect_false(drm_prior_uses_native_only_targets(list(residual_sd, random_slope)))
  expect_true(drm_prior_uses_native_only_targets(list(residual_sd, rho12)))
  expect_true(drm_prior_uses_native_only_targets(list(biv_fixed)))
  expect_true(drm_prior_uses_native_only_targets(list(rho12, student_t)))
  expect_false(drm_prior_uses_native_only_targets(list(random_slope, student_t)))
})
