# Family-call parsing guards in R/family.R (not the dpq helpers).

test_that("drm_family_call_parts() recognizes beta and namespaced calls", {
  parts <- drmTMB:::drm_family_call_parts(quote(beta))
  expect_equal(parts$name, "beta")
  expect_null(parts$pkg)
  ns <- drmTMB:::drm_family_call_parts(quote(drmTMB::beta_family))
  expect_equal(ns$pkg, "drmTMB")
  expect_equal(ns$name, "beta_family")
  expect_null(drmTMB:::drm_family_call_parts(quote(gaussian())))
})

test_that("drm_is_bare_euler_beta_call() detects base::beta()", {
  bare <- drmTMB:::drm_is_bare_euler_beta_call(quote(beta()))
  expect_true(bare)
  drm <- drmTMB:::drm_is_bare_euler_beta_call(quote(beta_family()))
  expect_false(drm)
  expect_false(drmTMB:::drm_is_bare_euler_beta_call(quote(drmTMB::beta())))
})

test_that("drm_family_call_parts() handles namespaced operators", {
  parts <- drmTMB:::drm_family_call_parts(quote(stats::gaussian))
  expect_equal(parts$pkg, "stats")
  expect_equal(parts$ns_op, "::")
})

test_that("drm_is_unexported_drmtmb_beta_call() flags drmTMB::beta()", {
  expect_true(drmTMB:::drm_is_unexported_drmtmb_beta_call(quote(drmTMB::beta())))
  expect_false(drmTMB:::drm_is_unexported_drmtmb_beta_call(quote(drmTMB::beta_family())))
})

test_that("drm_eval_family_arg() blocks Euler beta and unexported beta()", {
  expect_error(
    drmTMB:::drm_eval_family_arg(quote(beta()), globalenv()),
    class = "drmTMB_base_beta_family_error"
  )
  expect_error(
    drmTMB:::drm_eval_family_arg(quote(drmTMB::beta()), globalenv()),
    "not an exported"
  )
  fam <- drmTMB:::drm_eval_family_arg(quote(gaussian()), globalenv())
  expect_equal(fam$family, "gaussian")
})

test_that("exported family constructors keep stable family names", {
  expect_equal(student()$family, "student")
  expect_equal(skew_normal()$family, "skew_normal")
  expect_equal(tweedie()$family, "tweedie")
  expect_equal(truncated_nbinom2()$family, "truncated_nbinom2")
  expect_equal(suppressWarnings(beta())$family, beta_family()$family)
})