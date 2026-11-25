# Missing-data input guards. These stop before a likelihood is built.

test_that("miss_control accepts only the laplace engine", {
  expect_s3_class(miss_control(), "drm_missing_control")
  expect_error(
    miss_control(engine = 1),
    "single character string"
  )
  expect_error(
    miss_control(engine = "em"),
    "reserved, not implemented"
  )
  expect_error(
    miss_control(engine = "custom"),
    "only supports"
  )
})

test_that("predictor-fail bookkeeping follows the explicit attribute", {
  control <- miss_control()
  attr(control, "explicit") <- NULL
  expect_true(drmTMB:::drm_missing_explicit_predictor_fail(control))

  expect_null(
    drmTMB:::drm_validate_complete_predictors(
      bf(y ~ 1),
      data.frame(y = 1:3)
    )
  )
  expect_error(
    drmTMB:::drm_parse_missing_control("drop"),
    "must be created with"
  )
})

test_that("the missing-response sentinel must be one finite number", {
  withr::with_options(
    list(drmTMB.missing_response_sentinel = Inf),
    expect_error(
      drmTMB:::drm_missing_response_sentinel(),
      "finite numeric"
    )
  )
})

test_that("bivariate missing-response masks must have the same length", {
  control <- miss_control(response = "include")
  expect_error(
    drmTMB:::new_drm_biv_missing_data(
      control,
      original_row = 1:2,
      model_row = 1:2,
      observed_y1 = c(TRUE, FALSE),
      observed_y2 = TRUE
    ),
    "different lengths"
  )

  stored <- drmTMB:::new_drm_biv_missing_data(
    control,
    original_row = 1:2,
    model_row = 1:2,
    observed_y1 = c(TRUE, FALSE),
    observed_y2 = c(TRUE, TRUE)
  )
  expect_s3_class(stored, "drm_missing_data")
  expect_identical(stored$response_pattern, c("both_observed", "y2_observed"))
  expect_identical(stored$counts$y2_only, 1L)
  expect_identical(stored$counts$likelihood_rows, 2L)
})

test_that("impute_model rejects the wrong formula, family, or trials argument", {
  expect_error(
    impute_model(~ z),
    "two-sided formula"
  )
  expect_error(
    impute_model(x ~ z, family = base::beta),
    "Euler beta function",
    class = "drmTMB_base_beta_family_error"
  )
  expect_error(
    impute_model(x ~ z, family = gaussian(link = "log")),
    "identity link"
  )
  expect_error(
    impute_model(x ~ z, family = binomial(link = "probit")),
    "link = \"logit\""
  )
  expect_error(
    impute_model(x ~ z, family = poisson(link = "identity")),
    "poisson\\(link = \"log\"\\)"
  )
  expect_error(
    impute_model(x ~ z, family = Gamma(link = "inverse")),
    "Gamma\\(link = \"log\"\\)"
  )
  expect_error(
    impute_model(x ~ z, family = quasipoisson()),
    "Unsupported missing-predictor family"
  )
  expect_error(
    impute_model(x ~ z, trials = n),
    "only used for"
  )
  expect_error(
    drmTMB:::drm_standardize_impute_model(list(formula = quote(x ~ z))),
    "formulas or objects created by"
  )
})
