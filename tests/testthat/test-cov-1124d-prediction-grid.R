# Prediction-grid helpers. Reference values are the first factor level,
# the mean of a date, or the first observed logical value.

test_that("prediction_grid reserves dots and requires a drmTMB fit", {
  fake <- structure(list(data = data.frame(x = 1:3)), class = "drmTMB")
  expect_error(
    prediction_grid(fake, surprise = 1),
    "reserved for future options"
  )
  expect_error(
    drmTMB:::validate_prediction_grid_fit(data.frame(x = 1)),
    "must be a"
  )
})

test_that("reference values follow the column type", {
  habitat <- factor(c("b", "a", "b"), levels = c("b", "a"))
  expect_identical(
    drmTMB:::prediction_grid_reference_value(habitat, "habitat"),
    factor("b", levels = c("b", "a"))
  )

  day <- as.Date(c("2020-01-01", "2020-01-03"))
  expect_identical(
    drmTMB:::prediction_grid_reference_value(day, "day"),
    as.Date(mean(as.numeric(day)), origin = "1970-01-01")
  )

  instant <- as.POSIXct(
    c("2020-01-01 00:00:00", "2020-01-01 02:00:00"),
    tz = "UTC"
  )
  referenced <- drmTMB:::prediction_grid_reference_value(instant, "instant")
  expect_s3_class(referenced, "POSIXct")
  expect_equal(as.numeric(referenced), mean(as.numeric(instant)))

  expect_identical(
    drmTMB:::prediction_grid_reference_value(c(TRUE, FALSE, TRUE), "flag"),
    TRUE
  )
  expect_identical(
    drmTMB:::prediction_grid_reference_value(c("q", "r"), "lab"),
    factor("q", levels = c("q", "r"))
  )
  expect_error(
    drmTMB:::prediction_grid_reference_value(c(NA_character_, NA_character_), "lab"),
    "no non-missing fitted values"
  )
})

test_that("empty grids and condition values keep the requested row count", {
  empty_grid <- drmTMB:::prediction_grid_expand(list())
  expect_s3_class(empty_grid, "data.frame")
  expect_identical(nrow(empty_grid), 1L)
  expect_identical(ncol(empty_grid), 0L)

  focal_grid <- data.frame(x = 1:2)
  mean_grid <- drmTMB:::prediction_grid_mean_reference(
    data = data.frame(y = 1),
    predictors = character(),
    focal = character(),
    focal_grid = focal_grid,
    condition = list()
  )
  expect_identical(nrow(mean_grid), 2L)
  expect_identical(ncol(mean_grid), 0L)

  empirical <- drmTMB:::prediction_grid_empirical(
    data = data.frame(x = 1:3),
    predictors = "x",
    focal = character(),
    focal_grid = data.frame(z = 1),
    condition = list()
  )
  expect_equal(empirical$x, 1:3)

  expect_error(
    drmTMB:::prediction_grid_condition_value(c(1, 2), 1:3, "x"),
    "length 1"
  )
  expect_error(
    drmTMB:::prediction_grid_condition_value(NA_real_, 1:3, "x"),
    "cannot be missing"
  )
  expect_identical(
    drmTMB:::prediction_grid_condition_value(4, c(1, 2, 3), "x"),
    4
  )
})
