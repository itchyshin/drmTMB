# Missing-data helpers in R/missing-data.R not covered by open coverage PRs.

test_that("drm_split_additive_rhs flattens nested plus calls", {
  expr <- quote(x1 + x2 + I(x3))
  parts <- drmTMB:::drm_split_additive_rhs(expr)
  expect_length(parts, 3L)
  expect_equal(as.character(parts[[1]]), "x1")
  rebuilt <- drmTMB:::drm_rebuild_additive_rhs(parts)
  expect_true(is.call(rebuilt))
  expect_equal(as.character(rebuilt[[1]]), "+")

  single <- drmTMB:::drm_rebuild_additive_rhs(list(quote(z)))
  expect_equal(deparse(single), "z")
  expect_equal(deparse(drmTMB:::drm_rebuild_additive_rhs(list())), "1")
})

test_that("drm_unwrap_parentheses and drm_is_one_expr", {
  wrapped <- quote(((x)))
  expect_equal(deparse(drmTMB:::drm_unwrap_parentheses(wrapped)), "x")
  expect_true(drmTMB:::drm_is_one_expr(1))
  expect_true(drmTMB:::drm_is_one_expr(1.0))
  expect_true(drmTMB:::drm_is_one_expr(quote(1)))
  expect_false(drmTMB:::drm_is_one_expr(c(1, 1)))
})

test_that("drm_missing family rosters are stable character vectors", {
  resp <- drmTMB:::drm_missing_response_families()
  pred <- drmTMB:::drm_missing_predictor_families()
  expect_type(resp, "character")
  expect_type(pred, "character")
  expect_true(all(nzchar(resp)))
  expect_true("gaussian" %in% resp)
  expect_true("gaussian" %in% pred)
  expect_identical(anyDuplicated(resp), 0L)
  expect_identical(anyDuplicated(pred), 0L)
})

test_that("drm_missing_response_sentinel reads option or default", {
  old <- getOption("drmTMB.missing_response_sentinel")
  on.exit(options(drmTMB.missing_response_sentinel = old), add = TRUE)
  options(drmTMB.missing_response_sentinel = -999)
  expect_equal(drmTMB:::drm_missing_response_sentinel(), -999)
  options(drmTMB.missing_response_sentinel = NULL)
  expect_equal(drmTMB:::drm_missing_response_sentinel(), 0)
  options(drmTMB.missing_response_sentinel = c(0, 1))
  expect_error(drmTMB:::drm_missing_response_sentinel(), "one finite numeric")
})

test_that("drm_parse_missing_control coerces plain lists", {
  mc <- drmTMB:::drm_parse_missing_control(list(response = "include"))
  expect_s3_class(mc, "drm_missing_control")
  expect_equal(mc$response, "include")
  expect_equal(mc$predictor, "fail")
  expect_equal(mc$engine, "laplace")

  wrapped <- miss_control(response = "drop", predictor = "model", engine = "laplace")
  expect_identical(drmTMB:::drm_parse_missing_control(wrapped), wrapped)
  expect_error(drmTMB:::drm_parse_missing_control("drop"), "miss_control")
})

test_that("drm_standardize_impute_model accepts formulas and drm_impute_model", {
  obj <- impute_model(y ~ x)
  expect_identical(drmTMB:::drm_standardize_impute_model(obj), obj)
  from_f <- drmTMB:::drm_standardize_impute_model(y ~ x)
  expect_s3_class(from_f, "drm_impute_model")
  expect_error(drmTMB:::drm_standardize_impute_model(3), "impute_model")
})

test_that("drm_impute_family_type admits allowed families and fences links", {
  expect_equal(drmTMB:::drm_impute_family_type(stats::gaussian()), "gaussian")
  expect_equal(
    drmTMB:::drm_impute_family_type(stats::binomial(link = "logit")),
    "bernoulli"
  )
  expect_equal(drmTMB:::drm_impute_family_type(cumulative_logit()), "ordinal")
  expect_equal(drmTMB:::drm_impute_family_type(categorical()), "categorical")
  expect_equal(drmTMB:::drm_impute_family_type(beta_family()), "beta")
  expect_equal(drmTMB:::drm_impute_family_type(poisson()), "poisson")
  expect_error(
    drmTMB:::drm_impute_family_type(stats::gaussian(link = "log")),
    "identity link"
  )
  expect_error(
    drmTMB:::drm_impute_family_type(stats::binomial(link = "probit")),
    "logit"
  )
  expect_error(
    drmTMB:::drm_impute_family_type(student()),
    "Unsupported missing-predictor family"
  )
})

test_that("new_drm_missing_data structures counts consistently", {
  ctrl <- miss_control()
  md <- drmTMB:::new_drm_missing_data(
    control = ctrl,
    original_row = c(1L, 2L, 4L),
    model_row = c(1L, 2L, 3L),
    observed_y = c(TRUE, FALSE, TRUE)
  )
  expect_s3_class(md, "drm_missing_data")
  expect_equal(md$counts$retained_rows, 3L)
  expect_equal(md$counts$observed_response, 2L)
  expect_equal(md$counts$missing_response, 1L)
  expect_identical(md$response_policy, ctrl$response)
})

test_that("drm_empty_missing_predictor_model returns disabled scaffold", {
  empty <- drmTMB:::drm_empty_missing_predictor_model(4L)
  expect_false(empty$enabled)
  expect_length(empty$x, 4L)
  expect_identical(empty$family, "none")
})