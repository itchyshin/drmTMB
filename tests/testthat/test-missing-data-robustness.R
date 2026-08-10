# Robustness tests for internal missing-data helpers (issues #709, #713).

test_that("drm_mask_missing_response_values masks the sentinel and errors on length mismatch", {
  object <- list(
    missing_data = list(
      response_policy = "include",
      observed_y = c(TRUE, FALSE, TRUE)
    )
  )

  masked <- drmTMB:::drm_mask_missing_response_values(object, c(1, 2, 3))
  expect_equal(masked, c(1, NA, 3))

  # A length mismatch means the sentinel would otherwise leak; it must abort.
  expect_error(
    drmTMB:::drm_mask_missing_response_values(object, c(1, 2)),
    "length mismatch"
  )
})

test_that("drm_mask_missing_response_values passes through when masking is not required", {
  object <- list(missing_data = list(response_policy = "drop"))
  expect_equal(
    drmTMB:::drm_mask_missing_response_values(object, c(1, 2)),
    c(1, 2)
  )
})

test_that("drm_mask_biv_missing_response_values errors on a row mismatch", {
  object <- list(
    missing_data = list(
      response_policy = "include",
      observed_y1 = c(TRUE, FALSE, TRUE),
      observed_y2 = c(TRUE, TRUE, FALSE)
    )
  )

  value <- cbind(y1 = c(1, 2, 3), y2 = c(4, 5, 6))
  masked <- drmTMB:::drm_mask_biv_missing_response_values(object, value)
  expect_equal(masked[, "y1"], c(1, NA, 3))
  expect_equal(masked[, "y2"], c(4, 5, NA))

  bad <- cbind(y1 = c(1, 2), y2 = c(4, 5))
  expect_error(
    drmTMB:::drm_mask_biv_missing_response_values(object, bad),
    "row mismatch"
  )
})

test_that("drm_imputed_missing_predictor_se selects x_miss positions without the dead clause", {
  object <- list(
    sdr = list(
      par.random = stats::setNames(
        c(0, 0, 0),
        c("b", "x_miss", "x_miss")
      ),
      diag.cov.random = c(4, 9, 16)
    )
  )

  se <- drmTMB:::drm_imputed_missing_predictor_se(
    object,
    predictor = NULL,
    n_missing = 2L,
    se = TRUE,
    fit_status = "ok"
  )
  expect_equal(se, c(3, 4))

  # No random parameters: NA fallback rather than a mismatch.
  object_none <- list(
    sdr = list(
      par.random = stats::setNames(c(0), c("b")),
      diag.cov.random = c(4)
    )
  )
  se_none <- drmTMB:::drm_imputed_missing_predictor_se(
    object_none,
    predictor = NULL,
    n_missing = 1L,
    se = TRUE,
    fit_status = "ok"
  )
  expect_true(is.na(se_none))
})

test_that("drm_imputed_missing_predictor_se withholds std_error when fit_status is not ok", {
  # A route-conditional posterior SD does not itself call sdreport(), so it
  # must still be gated on fit_status; otherwise std_error and
  # uncertainty_status would disagree (a real number next to
  # "sdreport_skipped").
  predictor <- list(
    summary = "conditional_probability",
    conditional_probability = c(0.2, 0.8)
  )
  se_skipped <- drmTMB:::drm_imputed_missing_predictor_se(
    object = list(),
    predictor = predictor,
    n_missing = 2L,
    se = TRUE,
    fit_status = "sdreport_skipped"
  )
  expect_true(all(is.na(se_skipped)))

  se_ok <- drmTMB:::drm_imputed_missing_predictor_se(
    object = list(),
    predictor = predictor,
    n_missing = 2L,
    se = TRUE,
    fit_status = "ok"
  )
  expect_equal(se_ok, sqrt(c(0.2, 0.8) * c(0.8, 0.2)))
})

test_that("count mi support helpers use observed values, not the logical mask", {
  # The observed-value argument must be the actual counts; a large observed
  # count widens the support (renamed argument keeps this behaviour explicit).
  # A logical mask (max == 1) would instead collapse the support to the floor.
  wide <- drmTMB:::drm_poisson_mi_support(lambda = 2, observed_values = 120)
  narrow <- drmTMB:::drm_poisson_mi_support(lambda = 2, observed_values = 1)
  expect_gt(max(wide), max(narrow))
  expect_equal(max(narrow), 50)

  nb <- drmTMB:::drm_nbinom2_mi_support(
    mu = 3,
    sigma = 0.5,
    observed_values = 200
  )
  expect_equal(max(nb), 225)

  trunc <- drmTMB:::drm_truncated_nbinom2_mi_support(
    mu = 3,
    sigma = 0.5,
    observed_values = 200
  )
  expect_equal(min(trunc), 1)
  expect_equal(max(trunc), 225)
})
