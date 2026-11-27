# Whole-package covr lane w6 (27 Nov): ranks 13–15 on main at 2c76be050.
# Targets: julia-joint-missing.R, associate-pairs-sandwich.R, mspl-estimator.R
# (rank-13 temporal.R is in open #1917/#1920 sz lanes; julia-joint-missing is
# the next unclaimed module in that uncovered band.)

w6_pair_association <- function(
  status = "interior",
  coefficients = c("(Intercept)" = 0.2, x = 0.1),
  inference = NULL
) {
  n <- 20L
  design <- cbind(`(Intercept)` = 1, x = seq(-1, 1, length.out = n))
  structure(
    list(
      status = status,
      association_coefficients = coefficients,
      association_design = list(matrix = design),
      components = list(pair_class = "bernoulli_nbinom2"),
      diagnostics = list(near_boundary = status == "near_boundary"),
      alpha_inference = inference
    ),
    class = "drm_pair_association"
  )
}

test_that("julia joint missing adapter validates control and formula entry shape", {
  expect_true(drmTMB:::drm_julia_joint_default_control(NULL))
  expect_true(drmTMB:::drm_julia_joint_default_control(list()))
  expect_false(drmTMB:::drm_julia_joint_default_control(
    drm_control(optimizer_preset = "careful")
  ))
  expect_error(
    drmTMB:::drm_julia_joint_formula_entries(y ~ x),
    "bf\\(\\) or drm_formula"
  )
  entries <- drmTMB:::drm_julia_joint_formula_entries(bf(y ~ mi(x), sigma ~ 1))
  expect_type(entries, "list")
})

test_that("julia joint missing rejects unsupported formula markers and mi placement", {
  entries <- bf(y ~ mi(x), sigma ~ 1)$entries
  expect_error(
    drmTMB:::drm_julia_joint_reject_formula_markers(
      bf(y ~ x + (1 | g), sigma ~ 1)$entries
    ),
    "fixed effects only"
  )
  expect_error(
    drmTMB:::drm_julia_joint_reject_formula_markers(
      bf(y ~ x, zi ~ 1)$entries
    ),
    "mu and sigma formulas"
  )
  expect_error(
    drmTMB:::drm_julia_joint_mi_setup(bf(y ~ z, sigma ~ 1)$entries),
    "mi\\(\\) term"
  )
  expect_error(
    drmTMB:::drm_julia_joint_mi_setup(bf(y ~ mi(x) + mi(x), sigma ~ 1)$entries),
    "distinct"
  )
  expect_error(
    drmTMB:::drm_julia_joint_mi_setup(bf(y ~ y + mi(y), sigma ~ 1)$entries),
    "cannot use the response itself"
  )
})

test_that("julia joint missing numeric matrices and response dropping follow the contract", {
  expect_equal(
    drmTMB:::drm_julia_joint_numeric_matrix(matrix(1:4, 2), "design"),
    matrix(c(1, 2, 3, 4), 2)
  )
  expect_error(
    drmTMB:::drm_julia_joint_numeric_matrix(matrix(NA_real_, 1), "design"),
    "finite numeric"
  )
  dat <- data.frame(y = c(1, NA, 3), x = 1:3)
  kept <- drmTMB:::drm_julia_joint_response_drop(dat, "y", list(response = "drop"))
  expect_identical(kept$original_row, c(1L, 3L))
  expect_identical(nrow(kept$data), 2L)
  expect_error(
    drmTMB:::drm_julia_joint_response_drop(dat, "missing_col", list(response = "drop")),
    "mu response to be a data column"
  )
})

test_that("julia joint impute formulas reject structured and random-effect syntax", {
  spec <- drmTMB:::drm_julia_joint_impute_formula(
    list(x = x ~ z),
    variable = "x",
    n_expected = 1L,
    all_variables = "x"
  )
  expect_true(is.list(spec))
  expect_error(
    drmTMB:::drm_julia_joint_impute_formula(
      list(x = x ~ offset(z)),
      variable = "x"
    ),
    "fixed-effect impute formulas only"
  )
})

test_that("association sandwich control and derivative guards fail closed", {
  control <- drmTMB:::drm_pair_sandwich_control()
  expect_named(control, c("step", "derivative_relative_tolerance",
    "derivative_absolute_tolerance", "rcond_min", "symmetry_tolerance"))
  expect_identical(
    drmTMB:::drm_pair_sandwich_unavailable("reason")$status,
    "unavailable"
  )
  fn <- function(q) NA_real_
  bad <- drmTMB:::drm_pair_sandwich_stable_derivatives(fn, c(0, 0, 0, 0, 0), control)
  expect_identical(bad$status, "unavailable")
  expect_identical(bad$reason, "nonfinite_derivative")
  row_lp <- drmTMB:::drm_pair_sandwich_row_logprob(0L, 1L, 0, 0, 0, 0)
  expect_true(is.finite(row_lp) && row_lp < 0)
})

test_that("association alpha inference helpers format names and enforce availability", {
  obj <- w6_pair_association(
    coefficients = c("(Intercept)" = 0.1, x = -0.05),
    inference = list(
      status = "unavailable",
      reason = "association_step_unstable",
      se = NA_real_
    )
  )
  expect_equal(
    drmTMB:::drm_pair_alpha_coefficient_names(obj),
    c("alpha:(Intercept)", "alpha:x")
  )
  intercept_only <- w6_pair_association(
    coefficients = c("(Intercept)" = 0.3),
    inference = list(
      status = "available",
      se = 0.1,
      covariance = matrix(0.01, 1, 1)
    )
  )
  expect_equal(
    drmTMB:::drm_pair_alpha_coefficient_names(intercept_only),
    "alpha"
  )
  pub <- drmTMB:::drm_pair_public_alpha_inference(intercept_only)
  expect_identical(pub$status, "available")
  expect_error(
    drmTMB:::drm_pair_public_alpha_inference(
      w6_pair_association(status = "boundary_unresolved", inference = list(status = "available"))
    ),
    "not interior"
  )
  expect_error(
    drmTMB:::drm_pair_public_alpha_inference(
      w6_pair_association(inference = NULL)
    ),
    "predates stored"
  )
  expect_warning(
    drmTMB:::drm_pair_warn_alpha_inference(
      w6_pair_association(
        status = "near_boundary",
        inference = list(
          status = "available",
          capability_tier = "interval_feasible",
          se = 0.05,
          covariance = diag(0.0025, 2)
        )
      )
    ),
    class = "drmTMB_association_inference_warning"
  )
})

test_that("MSPL admission filters frequency weights and incompatible requests", {
  dat <- data.frame(y = c(0, 1), x = 0:1)
  expect_equal(
    drmTMB:::drm_mspl_filter_frequency_rows(dat, NULL, "ml")$data,
    dat
  )
  expect_error(
    drmTMB:::drm_mspl_filter_frequency_rows(dat, c(1, -1), "mspl"),
    "integer frequency weights"
  )
  expect_error(
    drmTMB:::drm_mspl_filter_frequency_rows(dat, c(0, 0), "mspl"),
    "positive frequency weight"
  )
  kept <- drmTMB:::drm_mspl_filter_frequency_rows(
    dat, c(0, 2), "mspl"
  )
  expect_identical(kept$kept, 2L)
  expect_identical(nrow(kept$data), 1L)
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", engine = "julia", family = binomial(), family_type = "binomial",
      REML = FALSE, penalty = NULL, impute = NULL,
      missing_control = miss_control(), control = drm_control()
    ),
    "engine = \"tmb\""
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", engine = "tmb", family = gaussian(), family_type = "gaussian",
      REML = FALSE, penalty = NULL, impute = NULL,
      missing_control = miss_control(), control = drm_control()
    ),
    "binomial family"
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", engine = "tmb", family = binomial(), family_type = "binomial",
      REML = TRUE, penalty = NULL, impute = NULL,
      missing_control = miss_control(), control = drm_control()
    ),
    "REML"
  )
  expect_error(
    drmTMB:::drm_validate_mspl_request(
      "mspl", engine = "tmb", family = binomial(), family_type = "binomial",
      REML = FALSE, penalty = 1, impute = NULL,
      missing_control = miss_control(), control = drm_control()
    ),
    "penalty"
  )
})

test_that("MSPL Wald unavailable warning and Q2 slope helpers guard impossible inputs", {
  mock_fit <- structure(
    list(
      estimator = "MSPL",
      opt = list(par = c(beta_mu = 0, beta_mu = 0.1)),
      mspl = list(wald = list(status = "non_spd"))
    ),
    class = "drmTMB"
  )
  expect_warning(
    drmTMB:::warn_mspl_wald_unavailable(mock_fit),
    class = "drmTMB_mspl_wald_unavailable"
  )
  vcov_na <- drmTMB:::drm_mspl_vcov(mock_fit)
  expect_true(all(is.na(vcov_na)))
  expect_identical(
    drmTMB:::drm_binomial_q2_slope_unique_n(c(1, 1), c(1L, 1L)),
    1L
  )
  re <- list(
    coef_names = list("(Intercept)", "x"),
    group_names = list("g", "g"),
    value = matrix(c(0, 0, 1, 1), nrow = 2, ncol = 2),
    index = matrix(c(1L, 1L, 1L, 1L), nrow = 2, ncol = 2)
  )
  expect_error(
    drmTMB:::drm_validate_binomial_q2_slope_variation(re),
    "within-group variation"
  )
})

test_that("MSPL inference abort remains invisible for non-MSPL objects", {
  ml_fit <- list(estimator = "ML")
  expect_false(drmTMB:::drm_is_mspl(ml_fit))
  expect_true(drmTMB:::drm_is_mspl("mspl"))
  expect_invisible(
    drmTMB:::drm_abort_mspl_inference(ml_fit, "profile")
  )
  mspl_fit <- structure(list(estimator = "MSPL"), class = "drmTMB")
  expect_error(
    drmTMB:::drm_abort_mspl_inference(mspl_fit, "profile"),
    "not available for experimental MSPL"
  )
})