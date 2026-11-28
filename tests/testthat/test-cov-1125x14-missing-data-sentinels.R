# R/missing-data.R small preparer helpers (open coverage PRs already hit mi()
# quadrature paths in integration tests).

test_that("drm_missing_response_families() and predictor families stay in sync", {
  resp <- drmTMB:::drm_missing_response_families()
  pred <- drmTMB:::drm_missing_predictor_families()
  expect_type(resp, "character")
  expect_type(pred, "character")
  expect_true("gaussian" %in% resp)
  expect_true("biv_gaussian" %in% resp)
  expect_true("nbinom2" %in% pred)
  expect_false("cumulative_logit" %in% pred)
})

test_that("drm_parse_missing_control() coerces plain lists", {
  parsed <- drmTMB:::drm_parse_missing_control(list(response = "include"))
  expect_s3_class(parsed, "drm_missing_control")
  expect_equal(parsed$response, "include")
  expect_equal(parsed$predictor, "fail")
  expect_equal(parsed$engine, "laplace")

  round <- drmTMB:::drm_parse_missing_control(miss_control(predictor = "model"))
  expect_equal(round$predictor, "model")
  expect_error(drmTMB:::drm_parse_missing_control("drop"), "miss_control")
})

test_that("drm_default_missing_data() marks every kept row as observed", {
  ctrl <- miss_control(response = "include", predictor = "model")
  keep <- c(TRUE, TRUE, FALSE, TRUE)
  md <- drmTMB:::drm_default_missing_data(ctrl, keep)
  expect_s3_class(md, "drm_missing_data")
  expect_equal(md$original_row, c(1L, 2L, 4L))
  expect_equal(md$model_row, 1:3)
  expect_equal(md$counts$retained_rows, 3L)
  expect_equal(md$counts$observed_response, 3L)
  expect_equal(md$counts$missing_response, 0L)
})

test_that("drm_tmb_observed_y* return masks or unit vectors", {
  spec <- list(
    model_type = "gaussian",
    y = 1:5,
    missing_data = list(observed_y = c(TRUE, FALSE, TRUE, TRUE, FALSE))
  )
  expect_equal(drmTMB:::drm_tmb_observed_y(spec), c(1L, 0L, 1L, 1L, 0L))

  empty <- list(model_type = "gaussian", y = 1:3, missing_data = list())
  expect_equal(drmTMB:::drm_tmb_observed_y(empty), c(1L, 1L, 1L))

  biv <- list(
    model_type = "biv_gaussian",
    y1 = 1:4,
    y2 = 1:4,
    missing_data = list(
      observed_y1 = c(TRUE, FALSE, TRUE, TRUE),
      observed_y2 = c(TRUE, TRUE, FALSE, TRUE)
    )
  )
  expect_equal(drmTMB:::drm_tmb_observed_y1(biv), c(1L, 0L, 1L, 1L))
  expect_equal(drmTMB:::drm_tmb_observed_y2(biv), c(1L, 1L, 0L, 1L))
})

test_that("empty_gaussian_mi_setup() is disabled with zero rows", {
  empty <- drmTMB:::empty_gaussian_mi_setup()
  expect_false(empty$enabled)
  expect_identical(empty$n_mi, 0L)
  expect_identical(empty$family, "none")
})

test_that("drm_mi_setup_variables() collects enabled predictor variables", {
  setup <- list(
    enabled = TRUE,
    variable = "x",
    second = list(enabled = TRUE, variable = "w")
  )
  expect_equal(drmTMB:::drm_mi_setup_variables(setup), c("x", "w"))
  expect_equal(drmTMB:::drm_mi_setup_second(setup)$variable, "w")
  expect_null(drmTMB:::drm_mi_setup_second(list(enabled = TRUE, variable = "x")))
})

test_that("drm_standardize_impute_model() accepts formulas and impute_model()", {
  f <- y ~ x
  std_f <- drmTMB:::drm_standardize_impute_model(f)
  expect_s3_class(std_f, "drm_impute_model")
  obj <- impute_model(y ~ x, family = stats::gaussian())
  expect_identical(drmTMB:::drm_standardize_impute_model(obj), obj)
  expect_error(drmTMB:::drm_standardize_impute_model(1), "impute_model")
})
