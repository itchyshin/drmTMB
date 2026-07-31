test_that("AOI-2 diagnostic payload preserves an endpoint failure before prediction", {
  components <- list(
    pair_class = "bernoulli_nbinom2",
    descriptor = drmTMB:::drm_pair_descriptor("bernoulli_nbinom2"),
    binary_y = 0L,
    binary_p = 0.2,
    nbinom2_y = 0L,
    nbinom2_mu = 1e-300,
    nbinom2_sigma = 1e-150
  )
  fit <- drmTMB:::drm_pair_fit_eta(components)
  payload <- drmTMB:::drm_pair_aoi2_diagnostic_payload(fit)

  expect_identical(payload$diagnostic_version, "aoi2d0-v1")
  expect_identical(payload$diagnostic_status, "boundary_unresolved")
  expect_true(payload$diagnostic_endpoint_failure)
  expect_true(payload$diagnostic_nonfinite_logLik)
  expect_match(payload$diagnostic_endpoint_failure_message,
    "endpoints are numerically unresolved")
  expect_match(payload$diagnostic_multistart_objectives, "1=")
  expect_match(payload$diagnostic_score, "1=")
})

test_that("AOI-2 diagnostic payload retains every pre-prediction trigger", {
  fit <- list(
    status = "boundary_unresolved",
    association_coefficients = c("(Intercept)" = 8),
    logLik = NA_real_,
    diagnostics = list(
      alpha = c("(Intercept)" = -0.5),
      eta_internal = c("(Intercept)" = -0.46),
      convergence_failure = TRUE,
      multistart_disagreement = TRUE,
      weak_curvature = TRUE,
      score_failure = TRUE,
      endpoint_failure = TRUE,
      optimizer_convergence = 1L,
      optimizer_message = "synthetic diagnostic",
      multistart_objectives = c(start_1 = 1, start_2 = 2),
      multistart_alpha = matrix(c(0, 1), nrow = 1,
        dimnames = list("(Intercept)", c("start_1", "start_2"))),
      score = c("(Intercept)" = 0.01),
      curvature = c("(Intercept)" = -1e-8),
      response_patterns = c(n = 4, zeros = 2),
      count_interval = list(
        endpoint_failure_message = "synthetic endpoint",
        row_numerics = data.frame(
          status = c("ok", "endpoint_failure"),
          relative_integration_error = c(1e-8, NA_real_)
        )
      )
    )
  )
  payload <- drmTMB:::drm_pair_aoi2_diagnostic_payload(fit)

  expect_true(payload$diagnostic_hard_parameter_cap)
  expect_true(payload$diagnostic_nonfinite_logLik)
  expect_true(payload$diagnostic_convergence_failure)
  expect_true(payload$diagnostic_multistart_disagreement)
  expect_true(payload$diagnostic_weak_curvature)
  expect_true(payload$diagnostic_score_failure)
  expect_true(payload$diagnostic_endpoint_failure)
  expect_identical(payload$diagnostic_optimizer_convergence, 1L)
  expect_identical(payload$diagnostic_endpoint_failure_message, "synthetic endpoint")
  expect_match(payload$diagnostic_count_row_status, "endpoint_failure=1")
  expect_identical(payload$diagnostic_count_nonfinite_relative_error, 1L)
  expect_equal(payload$diagnostic_count_max_relative_error, 1e-8)
})
