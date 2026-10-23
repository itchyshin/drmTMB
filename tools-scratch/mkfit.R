# Shared mocked-bridge fixture for the p-route-diagnostics red controls.
# Builds a drmTMB_julia fit through the package's own constructor, so the
# uncertainty/diagnostics slots are the ones new_drmTMB_julia() really writes.
drm_redctl_fit <- function(with_gradient = TRUE, vcov = diag(c(0.01, 0.02, 0.03)),
                           gradient_source = NULL, field = "gradient_source") {
  coef_names <- c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")
  result <- list(
    coef_names = coef_names, coefficients = c(0.5, 1.2, -0.3), vcov = vcov,
    loglik = -20, aic = 46, bic = 49, df = 3L, nobs = 50L, converged = TRUE,
    fitted = rep(1, 50), residuals = rep(0, 50), sigma = rep(0.8, 50),
    corpairs = list()
  )
  if (with_gradient) {
    result$gradient <- c(0.0002, -0.0005, 0.0001)
    result$gradient_names <- coef_names
  }
  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(bf(y ~ x, sigma ~ 1), data = dat, engine = "julia")),
    formula = bf(y ~ x, sigma ~ 1), family = gaussian(),
    data = data.frame(y = rep(1, 50), x = rep(1, 50)), family_type = "gaussian"
  )
  # Injected AFTER construction: `$` partially matches on lists, so a payload
  # with `gradient_source` and no `gradient` makes new_drmTMB_julia()'s
  # `result$gradient` return the provenance string and abort. That hazard is
  # in R/julia-bridge.R, not in the consumer under test.
  if (!is.null(gradient_source)) fit$bridge[[field]] <- gradient_source
  fit
}
