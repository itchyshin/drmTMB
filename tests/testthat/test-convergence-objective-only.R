test_that("objective-only penalized estimators use optimizer diagnostics without fabricated logLik", {
  fit <- structure(list(
    estimator = "MSPL",
    opt = list(convergence = 0L, objective = 12.5),
    logLik = NA_real_, relative_gradient = 1e-8,
    mspl = list(numerical = list(hessian_positive_definite = TRUE))
  ), class = "drmTMB")
  testthat::local_mocked_bindings(
    drm_convergence_at_boundary = function(object) FALSE,
    drm_fixed_effect_rank_deficient = function(object) FALSE,
    drm_standard_errors_pathological = function(object) FALSE,
    drm_mle_nonexistent_is_true = function(object) TRUE,
    .package = "drmTMB"
  )

  expect_true(is.na(fit$logLik))
  expect_identical(convergence_status(fit), "converged")
  expect_true(is_converged(fit, include_hessian = TRUE))
  fit$mspl$numerical$hessian_positive_definite <- FALSE
  expect_identical(convergence_status(fit), "degenerate")
  fit$mspl$numerical$hessian_positive_definite <- TRUE

  # An ordinary ML fit also applies the MLE-existence screen.
  fit$estimator <- "ML"
  fit$logLik <- -12.5
  fit$pd_hessian <- TRUE
  expect_identical(convergence_status(fit), "degenerate")

  # Prior/MAP fits must still carry the unpenalized data logLik, even though
  # their optimizer objective is finite and their penalized Hessian is PD.
  fit$penalised <- TRUE
  fit$pd_hessian_penalised <- TRUE
  fit$logLik <- NA_real_
  expect_identical(convergence_status(fit), "not_converged")
})
