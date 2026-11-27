# Fit-free helpers at the end of R/prediction-grid.R not fully covered elsewhere.

test_that("validate_prediction_grid_fit() requires retained model data", {
  bad <- structure(list(), class = "drmTMB")
  expect_error(
    drmTMB:::validate_prediction_grid_fit(bad),
    "must retain its fitted model data"
  )
})

test_that("prediction_grid_values() rejects empty or missing explicit values", {
  expect_error(
    drmTMB:::prediction_grid_values(
      1:3, values = numeric(), n = 3L, term = "x"
    ),
    "must be non-empty and non-missing"
  )
  expect_error(
    drmTMB:::prediction_grid_values(
      1:3, values = c(1, NA), n = 3L, term = "x"
    ),
    "must be non-empty and non-missing"
  )
})

test_that("prediction_grid_attach_metadata() stamps drm_prediction_grid attributes", {
  data <- data.frame(x = 1:2, y = 3:4)
  fake <- structure(
    list(data = data, model = list(terms = list(quote(y ~ x)))),
    class = "drmTMB"
  )
  grid <- data.frame(x = c(1, 2))
  out <- drmTMB:::prediction_grid_attach_metadata(
    grid,
    object = fake,
    focal = "x",
    condition = list(),
    predictors = c("x", "y"),
    margin = "mean",
    weights = "equal"
  )
  expect_s3_class(out, "drm_prediction_grid")
  meta <- attr(out, "prediction_grid")
  expect_equal(meta$focal_terms, "x")
  expect_equal(meta$margin, "mean")
  expect_equal(meta$reference_terms, "y")
  expect_equal(meta$n_grid_rows, 2L)
  expect_equal(meta$n_source_rows, 2L)
})