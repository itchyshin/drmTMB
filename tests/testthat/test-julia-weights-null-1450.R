test_that("weights = NULL counts as no weights for the Julia bridge (#1450)", {
  expect_true(drm_julia_weights_absent(TRUE, NULL, data.frame(), globalenv()))
  expect_true(drm_julia_weights_absent(FALSE, quote(NULL), data.frame(x = 1), globalenv()))
  w <- NULL
  expect_true(drm_julia_weights_absent(FALSE, quote(w), data.frame(x = 1), environment()))
  expect_false(drm_julia_weights_absent(FALSE, quote(wt), data.frame(wt = 2), globalenv()))
  expect_false(drm_julia_weights_absent(FALSE, quote(nonexistent_col), data.frame(x = 1), globalenv()))
})
