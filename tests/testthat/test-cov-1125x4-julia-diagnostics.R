# R/julia-diagnostics.R bridge check helpers.

julia_fit <- function(converged = TRUE, grad = NULL, grad_names = NULL) {
  structure(
    list(
      nobs = 10L,
      estimator = "ML",
      model = list(model_type = "gaussian"),
      opt = list(convergence = if (converged) 0L else 1L),
      diagnostics = list(
        converged = converged,
        route = "gaussian_core",
        gradient = grad,
        gradient_names = grad_names
      ),
      uncertainty = list(status = "ok", covariance = diag(2)),
      missing_rows = list(n_dropped = 0L, n_input = 10L)
    ),
    class = c("drmTMB_julia", "drmTMB")
  )
}

test_that("check_drm.drmTMB_julia rejects unknown dots", {
  fit <- julia_fit()
  expect_error(check_drm(fit, gradient_tolerance = 0.01, extra = TRUE), "reserved")
})

test_that("check_julia_engine_route() always emits a note row", {
  row <- drmTMB:::check_julia_engine_route(julia_fit())
  expect_identical(row$check, "engine_route")
  expect_identical(row$status, "note")
  expect_match(row$value, "engine=julia")
})

test_that("check_julia_optimizer_convergence() tracks diagnostics$converged", {
  ok <- drmTMB:::check_julia_optimizer_convergence(julia_fit(TRUE))
  bad <- drmTMB:::check_julia_optimizer_convergence(julia_fit(FALSE))
  expect_identical(ok$status, "ok")
  expect_identical(bad$status, "warning")
})

test_that("drm_julia_grad_source_vocabulary() is stable", {
  voc <- drmTMB:::drm_julia_grad_source_vocabulary()
  expect_true(all(c("stored", "finite", "none") %in% voc))
})

test_that("drm_julia_gradient_source() reports unknown without a gradient", {
  fit <- julia_fit(grad = NULL)
  expect_identical(drmTMB:::drm_julia_gradient_source(fit), "unknown")
  gfit <- julia_fit(grad = c(0.1, -0.2), grad_names = c("mu:(Intercept)", "mu:x"))
  expect_identical(drmTMB:::drm_julia_gradient_source(gfit), "stored")
})

test_that("check_julia_dropped_rows() counts bridge row drops", {
  fit <- julia_fit()
  fit$missing_rows$n_dropped <- 2L
  row <- drmTMB:::check_julia_dropped_rows(fit)
  expect_identical(row$status, "note")
  expect_match(row$value, "dropped=2")
})