# Additional guards in R/family.R not covered by cov-1125x6-family-call-parts.

test_that("drm_is_bare_euler_beta_call() flags stats::beta()", {
  expect_true(drmTMB:::drm_is_bare_euler_beta_call(quote(stats::beta())))
  expect_true(drmTMB:::drm_is_bare_euler_beta_call(quote(beta())))
  expect_false(drmTMB:::drm_is_bare_euler_beta_call(quote(drmTMB::beta_family())))
  expect_false(drmTMB:::drm_is_bare_euler_beta_call(quote(student())))
})

test_that("drm_is_unexported_drmtmb_beta_call() targets drmTMB::beta", {
  expect_true(drmTMB:::drm_is_unexported_drmtmb_beta_call(quote(drmTMB::beta())))
  expect_false(drmTMB:::drm_is_unexported_drmtmb_beta_call(quote(beta_family())))
  expect_false(drmTMB:::drm_is_unexported_drmtmb_beta_call(quote(stats::beta())))
})

test_that("drm_abort_base_beta_as_family() names beta_family()", {
  expect_error(drmTMB:::drm_abort_base_beta_as_family(), "beta_family")
})

test_that("dispersionless and shape families expose expected dpars", {
  nb <- nbinom2()
  expect_identical(nb$family, "nbinom2")
  expect_true("sigma" %in% nb$dpars)
  tw <- tweedie()
  expect_true("nu" %in% tw$dpars)
  expect_identical(tw$links[["nu"]], "logit12")
  cl <- cumulative_logit()
  expect_identical(cl$family, "cumulative_logit")
  expect_equal(cl$n_response, 1L)
})