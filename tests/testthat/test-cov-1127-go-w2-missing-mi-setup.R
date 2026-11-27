# refs coverage — missing-data.R mi() routing (g–o whole-package pass, 27 Nov).

test_that("drm_find_mi_calls() collects mi() anywhere in the location RHS", {
  f <- drmTMB:::drm_find_mi_calls
  expect_length(f(quote(y ~ x)), 0L)
  inner <- quote(y ~ z + mi(x))
  expect_length(f(inner), 1L)
  nested <- quote(y ~ z + I(mi(x) + 1))
  out <- f(nested)
  expect_length(out, 1L)
  expect_identical(out[[1L]][[1L]], as.name("mi"))
})

test_that("drm_prepare_gaussian_mi_setup() requires predictor=model when mi() is present", {
  prep <- drmTMB:::drm_prepare_gaussian_mi_setup
  rhs <- quote(x + mi(z))
  drop <- miss_control()
  expect_error(prep(rhs, NULL, drop, allow_k2 = FALSE), "predictor = \"model\"")
  expect_error(
    prep(rhs, list(z = impute_model(z ~ 1)), drop, allow_k2 = FALSE),
    "predictor = \"model\""
  )
  empty <- prep(quote(x), NULL, miss_control(), allow_k2 = FALSE)
  expect_false(empty$enabled)
})

test_that("drm_validate_bare_mi_call() enforces bare additive mi() terms", {
  v <- drmTMB:::drm_validate_bare_mi_call
  expect_equal(v(quote(mi(x)), quote(x + mi(x))), "x")
  expect_error(v(quote(mi(x + 1)), quote(x + mi(x + 1))), "bare predictor")
  expect_error(
    v(quote(mi(x)), quote(x + mi(x):z)),
    "simple additive"
  )
})

test_that("drm_mi_setup_variables() lists one or two imputation variables", {
  one <- list(enabled = TRUE, variable = "x", second = NULL)
  expect_equal(drmTMB:::drm_mi_setup_variables(one), "x")
  two <- list(
    enabled = TRUE,
    variable = "x",
    second = list(enabled = TRUE, variable = "w")
  )
  expect_equal(drmTMB:::drm_mi_setup_variables(two), c("x", "w"))
  expect_equal(drmTMB:::drm_mi_setup_variables(list(enabled = FALSE)), character())
})

test_that("categorical() is a documented impute-only family constructor", {
  fam <- categorical()
  expect_s3_class(fam, "drm_impute_family")
  expect_equal(drmTMB:::drm_impute_family_type(fam), "categorical")
})

test_that("drm_impute_family_type() maps known families and rejects bad links", {
  f <- drmTMB:::drm_impute_family_type
  expect_equal(f(gaussian()), "gaussian")
  expect_equal(f(cumulative_logit()), "ordinal")
  expect_equal(f(beta_family()), "beta")
  expect_equal(f(zero_one_beta()), "zero_one_beta")
  expect_error(f(gaussian(link = "log")), "identity link")
  expect_error(f(stats::quasipoisson()), "Unsupported missing-predictor family")
})

test_that("drm_missing_explicit_predictor_fail() respects explicit predictor flags", {
  g <- drmTMB:::drm_missing_explicit_predictor_fail
  expect_false(g(list(response = "drop", predictor = "fail")))
  ctl <- miss_control(predictor = "model")
  expect_false(g(ctl))
  stored <- miss_control()
  attr(stored, "explicit") <- c(response = TRUE, predictor = FALSE, engine = FALSE)
  expect_false(g(stored))
})