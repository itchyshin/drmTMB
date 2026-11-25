# prediction_grid validators and helpers from R/prediction-grid.R.

mini_fit <- function() {
  set.seed(11)
  dat <- data.frame(y = rnorm(20), x = rnorm(20), g = gl(4, 5))
  drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE, keep_data = TRUE)
  )
}

test_that("validate_prediction_grid_n() coerces valid n", {
  expect_equal(drmTMB:::validate_prediction_grid_n(5), 5L)
  expect_error(drmTMB:::validate_prediction_grid_n(0), "positive whole")
  expect_error(drmTMB:::validate_prediction_grid_n(1.2), "positive whole")
  expect_error(drmTMB:::validate_prediction_grid_n(NA), "positive whole")
})

test_that("validate_prediction_grid_terms() checks predictor names", {
  fit <- mini_fit()
  preds <- drmTMB:::prediction_grid_predictors(fit)
  expect_true("x" %in% preds)
  expect_identical(
    drmTMB:::validate_prediction_grid_terms(
      "x",
      predictors = preds,
      argument = "focal",
      allow_null = FALSE
    ),
    "x"
  )
  expect_error(
    drmTMB:::validate_prediction_grid_terms(
      "missing_var",
      predictors = preds,
      argument = "focal"
    ),
    "unknown predictor"
  )
  expect_error(
    drmTMB:::validate_prediction_grid_terms(
      NULL,
      predictors = preds,
      argument = "focal",
      allow_null = FALSE
    ),
    "must name predictor"
  )
})

test_that("validate_prediction_grid_list() requires named lists", {
  expect_identical(
    drmTMB:::validate_prediction_grid_list(NULL, "condition"),
    list()
  )
  expect_identical(
    drmTMB:::validate_prediction_grid_list(list(x = 1), "condition"),
    list(x = 1)
  )
  expect_error(
    drmTMB:::validate_prediction_grid_list(c(1, 2), "condition"),
    "named list"
  )
  expect_error(
    drmTMB:::validate_prediction_grid_list(list(1), "condition"),
    "named list"
  )
})

test_that("prediction_grid_expand() and empty frame helpers", {
  empty <- drmTMB:::prediction_grid_empty_data_frame(3L)
  expect_equal(nrow(empty), 3L)
  expect_equal(ncol(empty), 0L)
  grid <- drmTMB:::prediction_grid_expand(list(x = 1:2, y = 3:4))
  expect_equal(nrow(grid), 4L)
  expect_equal(ncol(grid), 2L)
})

test_that("validate_prediction_grid_fit() enforces drmTMB fits with data", {
  fit <- mini_fit()
  expect_invisible(drmTMB:::validate_prediction_grid_fit(fit))
  expect_error(
    drmTMB:::validate_prediction_grid_fit(list()),
    "drmTMB"
  )
})