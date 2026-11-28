# Lightweight helpers from R/utils.R.

test_that("%||% replaces NULL only", {
  `%||%` <- drmTMB:::`%||%`
  expect_identical(NULL %||% 3, 3)
  expect_identical(NA %||% 3, NA)
  expect_identical(integer() %||% 1L, integer())
  expect_identical(0 %||% 9, 0)
  expect_identical("a" %||% "b", "a")
})

test_that("drm_suggest_closest_name() uses prefix and edit distance", {
  suggest <- drmTMB:::drm_suggest_closest_name
  expect_equal(suggest("sig", c("sigma", "shape")), "sigma")
  expect_equal(suggest("shape", c("sigma", "shape")), "shape")
  expect_equal(suggest("sh", c("sigma", "shape")), "shape")
  expect_null(suggest("", c("sigma")))
  expect_null(suggest(NA_character_, c("sigma")))
  expect_null(suggest("zzzz", c("alpha", "beta")))
  expect_null(suggest("mu", character()))
  expect_null(suggest(1L, c("mu")))
})

test_that("drm_nlminb_control_names() and bridge names are stable character vectors", {
  nlminb <- drmTMB:::drm_nlminb_control_names()
  expect_type(nlminb, "character")
  expect_true("iter.max" %in% nlminb)
  expect_true("eval.max" %in% nlminb)
  expect_true("maxiter" %in% nlminb)
  expect_gt(length(nlminb), 10L)
  julia <- drmTMB:::drm_optimizer_julia_bridge_names()
  expect_identical(julia, c("g_tol", "algorithm", "q4_vcov"))
})