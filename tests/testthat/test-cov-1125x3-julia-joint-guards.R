# Extra guards in R/julia-joint-missing.R not covered by test-julia-joint-missing.R.

test_that("drm_julia_joint_default_control() accepts defaults only", {
  f <- drmTMB:::drm_julia_joint_default_control
  expect_true(f(drm_control()))
  expect_true(f(NULL))
  expect_true(f(list()))
  expect_false(f(drm_control(se = FALSE)))
  expect_false(f(list(se = FALSE)))
})

test_that("drm_julia_joint_formula_entries() requires drm_formula", {
  expect_error(drmTMB:::drm_julia_joint_formula_entries(y ~ x), "bf\\(\\)")
  f <- bf(y ~ x + mi(z), sigma ~ 1)
  entries <- drmTMB:::drm_julia_joint_formula_entries(f)
  expect_true(is.list(entries))
  expect_gt(length(entries), 0L)
})

test_that("drm_julia_joint_reject_formula_markers() rejects unsupported dpars", {
  entries <- list(
    list(dpar = "mu", rhs = quote(y ~ 1)),
    list(dpar = "sigma1", rhs = quote(~ 1))
  )
  expect_error(
    drmTMB:::drm_julia_joint_reject_formula_markers(entries),
    "Unsupported parameter"
  )
})

test_that("drm_julia_joint_mi_setup() counts mi() terms from bf() entries", {
  one_mi <- drmTMB:::drm_julia_joint_formula_entries(bf(y ~ z + mi(x), sigma ~ 1))
  setup <- drmTMB:::drm_julia_joint_mi_setup(one_mi)
  expect_identical(setup$variable, "x")
  expect_identical(setup$response, "y")
  two_mi <- drmTMB:::drm_julia_joint_formula_entries(
    bf(y ~ mi(x) + mi(z), sigma ~ 1)
  )
  setup2 <- drmTMB:::drm_julia_joint_mi_setup(two_mi)
  expect_identical(setup2$variable, c("x", "z"))
  expect_error(
    drmTMB:::drm_julia_joint_mi_setup(
      drmTMB:::drm_julia_joint_formula_entries(bf(y ~ 1, sigma ~ 1))
    ),
    "one or two"
  )
  expect_error(
    drmTMB:::drm_julia_joint_mi_setup(
      drmTMB:::drm_julia_joint_formula_entries(bf(y ~ mi(y), sigma ~ 1))
    ),
    "response itself"
  )
})

test_that("drm_julia_joint_numeric_matrix() coerces numeric matrices", {
  m <- drmTMB:::drm_julia_joint_numeric_matrix(matrix(1:4, 2), "demo")
  expect_true(is.matrix(m))
  expect_error(
    drmTMB:::drm_julia_joint_numeric_matrix("a", "demo"),
    "finite numeric"
  )
})