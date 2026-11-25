# mi() call discovery in R/missing-data.R.

test_that("drm_find_mi_calls() collects bare mi() in an expression tree", {
  rhs <- quote(y ~ x + mi(z) + mi(w))
  calls <- drmTMB:::drm_find_mi_calls(rhs)
  expect_length(calls, 2L)
  expect_true(all(vapply(calls, function(cl) as.character(cl[[1L]]), "") == "mi"))
  expect_length(drmTMB:::drm_find_mi_calls(quote(y ~ x)), 0L)
})

test_that("drm_find_mi_calls() walks nested calls", {
  rhs <- quote(y ~ mi(x) + offset(log(z)))
  expect_length(drmTMB:::drm_find_mi_calls(rhs), 1L)
})

test_that("drm_missing_explicit_predictor_fail() respects explicit attributes", {
  ctl <- miss_control()
  expect_true(drmTMB:::drm_missing_explicit_predictor_fail(ctl))
  ctl2 <- miss_control(response = "include")
  expect_false(drmTMB:::drm_missing_explicit_predictor_fail(ctl2))
  ctl3 <- miss_control(predictor = "fail")
  expect_true(drmTMB:::drm_missing_explicit_predictor_fail(ctl3))
})