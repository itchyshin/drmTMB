# Finite-state Julia helpers in R/julia-joint-finite.R.

test_that("drm_julia_finite_factor_data coerces factor levels and rejects extras", {
  dat <- data.frame(z = c("b", "a", NA, "b"), y = 1:4)
  levels <- c("a", "b", "c")
  out <- drmTMB:::drm_julia_finite_factor_data(
    dat, "z", levels = levels, ordered = TRUE, allow_missing = TRUE
  )
  expect_s3_class(out$z, "ordered")
  expect_equal(levels(out$z), levels)
  expect_true(any(is.na(dat$z)) && !any(is.na(out$z)))

  clean <- drmTMB:::drm_julia_finite_factor_data(
    data.frame(z = "a"), "z", levels = levels, ordered = FALSE
  )
  expect_false(is.ordered(clean$z))

  expect_error(
    drmTMB:::drm_julia_finite_factor_data(data.frame(y = 1), "z", levels, FALSE),
    "requires predictor"
  )
  expect_error(
    drmTMB:::drm_julia_finite_factor_data(
      data.frame(z = "d"), "z", levels = levels, ordered = FALSE
    ),
    "fitted levels"
  )
  expect_error(
    drmTMB:::drm_julia_finite_factor_data(
      data.frame(z = NA), "z", levels = levels, ordered = FALSE, allow_missing = FALSE
    ),
    "fitted levels"
  )
})

test_that("drm_julia_finite_joint_payload rejects non-ordinal families early", {
  spec <- list(
    missing_predictor = list(
      family = "gaussian", variable = "z", random = list(enabled = FALSE),
      structured = list(enabled = FALSE), levels = c("a", "b", "c"),
      x = 1, observed = TRUE, X = matrix(1), X_mu_state = matrix(1), X_mu_state = matrix(1)
    ),
    missing_data = list(original_row = 1L, predictors = list()),
    y = 1, X = list(mu = matrix(1), sigma = matrix(1))
  )
  mi <- list(variable = "z")
  drop <- list(original_row = 1L)
  expect_error(
    drmTMB:::drm_julia_finite_joint_payload(spec, mi, drop),
    "ordinal or categorical"
  )
})

test_that("drm_julia_finite_joint_contract rejects unknown schema", {
  prepared <- list(
    payload = list(
      levels = c("a", "b", "c"), predictor = "ordinal", variable = "z",
      mu_names = "mu", sigma_names = "sigma", predictor_names = "pz",
      x = c(1L, 2L), schema = "joint_missing_finite_v1"
    )
  )
  bad <- list(schema = "not_a_schema")
  expect_error(
    drmTMB:::drm_julia_finite_joint_contract(bad, prepared),
    "Unknown finite-state"
  )
})