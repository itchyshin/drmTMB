# predict_parameters validators in R/predict-parameters.R.

test_that("validate_predict_parameters_* accept valid scalars", {
  expect_invisible(drmTMB:::validate_predict_parameters_newdata(NULL))
  expect_invisible(
    drmTMB:::validate_predict_parameters_newdata(data.frame(x = 1))
  )
  expect_invisible(drmTMB:::validate_predict_parameters_include_newdata(FALSE))
  expect_invisible(drmTMB:::validate_predict_parameters_conf_int(TRUE))
  expect_invisible(drmTMB:::validate_predict_parameters_conf_level(0.9))
})

test_that("validate_predict_parameters_* reject bad inputs", {
  expect_error(
    drmTMB:::validate_predict_parameters_newdata(1:3),
    "data frame"
  )
  expect_error(
    drmTMB:::validate_predict_parameters_include_newdata(NA),
    "single"
  )
  expect_error(
    drmTMB:::validate_predict_parameters_conf_int(c(TRUE, FALSE)),
    "single"
  )
  expect_error(
    drmTMB:::validate_predict_parameters_conf_level(1),
    "between 0 and 1"
  )
  expect_error(
    drmTMB:::validate_predict_parameters_conf_level(0),
    "between 0 and 1"
  )
})

test_that("drm_dpar_component() maps distributional parameters", {
  cmp <- drmTMB:::drm_dpar_component
  expect_equal(cmp("mu"), "location")
  expect_equal(cmp("sigma1"), "distributional-scale")
  expect_equal(cmp("rho12"), "residual-correlation")
  expect_equal(cmp("nu"), "shape")
  expect_equal(cmp("zi"), "probability")
})

test_that("predict_parameters_order_columns() prefers canonical order", {
  dat <- data.frame(
    estimate = 1,
    dpar = "mu",
    extra = 2L,
    row = 1L
  )
  ordered <- drmTMB:::predict_parameters_order_columns(dat)
  expect_equal(names(ordered)[1:3], c("row", "dpar", "estimate"))
  expect_true("extra" %in% names(ordered))
})

test_that("predict_parameters_row_labels() falls back to row index", {
  expect_equal(
    drmTMB:::predict_parameters_row_labels(NULL, 3L),
    c("1", "2", "3")
  )
  nd <- data.frame(x = 1:2, row.names = c("a", "b"))
  expect_equal(
    drmTMB:::predict_parameters_row_labels(nd, 2L),
    c("a", "b")
  )
  nd2 <- data.frame(x = 1:2)
  expect_equal(
    drmTMB:::predict_parameters_row_labels(nd2, 2L),
    c("1", "2")
  )
})