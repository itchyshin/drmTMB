# #1687 — surface DRM.jl fit_failed payloads on Julia-bridge objects.

julia_synthetic_bridge_result <- function(..., fit_failed = FALSE, fit_failed_message = NULL) {
  result <- list(
    coef_names = c("mu_(Intercept)", "mu_x"),
    coefficients = c(0.5, 0.2),
    vcov = diag(c(0.01, 0.01)),
    loglik = -10,
    aic = 24,
    bic = 26,
    df = 2L,
    nobs = 12L,
    converged = !fit_failed,
    fitted = rep(0, 12L),
    residuals = rep(0, 12L),
    sigma = 1,
    corpairs = list(),
    fit_failed = fit_failed,
    fit_failed_message = fit_failed_message
  )
  list(result = result, ...)
}

julia_synthetic_fit <- function(fit_failed = FALSE, fit_failed_message = NULL) {
  payload <- julia_synthetic_bridge_result(
    fit_failed = fit_failed,
    fit_failed_message = fit_failed_message
  )
  form <- drmTMB::bf(y ~ x)
  drmTMB:::new_drmTMB_julia(
    result = payload$result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = stats::gaussian(),
    data = data.frame(y = rnorm(12), x = rnorm(12)),
    family_type = "gaussian"
  )
}

capture_julia_warning <- function(expr) {
  warns <- list()
  value <- withCallingHandlers(
    eval.parent(substitute(expr)),
    warning = function(w) {
      warns <<- c(warns, list(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = warns)
}

test_that("fit_failed from DRM.jl warns and returns NaN logLik (#1687)", {
  cap <- capture_julia_warning(
    julia_synthetic_fit(
      fit_failed = TRUE,
      fit_failed_message = "optimizer stopped at a singular Hessian"
    )
  )
  fit <- cap$value
  expect_length(cap$warnings, 1L)
  expect_s3_class(cap$warnings[[1]], "drmTMB_julia_fit_failed")
  expect_true(isTRUE(fit$fit_failed))
  expect_match(fit$fit_failed_message, "singular Hessian", fixed = TRUE)
  expect_true(is.nan(as.numeric(logLik(fit))))
  expect_match(fit$opt$message, "failed fit", fixed = TRUE)
})

test_that("a successful Julia bridge payload stays silent about fit_failed", {
  cap <- capture_julia_warning(julia_synthetic_fit(fit_failed = FALSE))
  expect_length(cap$warnings, 0L)
  expect_false(isTRUE(cap$value$fit_failed))
  expect_true(is.finite(as.numeric(logLik(cap$value))))
})

test_that("missing fit_failed key is treated as not failed", {
  result <- julia_synthetic_bridge_result()$result
  result$fit_failed <- NULL
  cap <- capture_julia_warning({
    form <- drmTMB::bf(y ~ x)
    drmTMB:::new_drmTMB_julia(
      result = result,
      call = quote(drmTMB(form, data = dat, engine = "julia")),
      formula = form,
      family = stats::gaussian(),
      data = data.frame(y = rnorm(8), x = rnorm(8)),
      family_type = "gaussian"
    )
  })
  expect_length(cap$warnings, 0L)
  expect_false(isTRUE(cap$value$fit_failed))
})