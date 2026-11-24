test_that("impute #1749: gaussian(link = \"log\") aborts like drm_family_type guard", {
  expect_error(
    impute_model(m ~ x, family = gaussian(link = "log")),
    regexp = "identity link",
    class = "rlang_error"
  )
  expect_error(
    impute_model(m ~ x, family = gaussian(link = "log")),
    regexp = "Received Gaussian link",
    class = "rlang_error"
  )
})

test_that("impute #1749: plain gaussian() imputation is unchanged", {
  obj <- impute_model(m ~ x, family = gaussian())
  expect_s3_class(obj, "drm_impute_model")
  expect_identical(obj$family_type, "gaussian")
})