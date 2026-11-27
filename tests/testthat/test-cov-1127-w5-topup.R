# covr w5 (27 Nov): ranks 10–12 — julia-diagnostics, plot-parameter-surface,
# associate-pairs-sandwich-gaussian-nbinom2.R. Fast contracts and error paths.

w5_julia_diag_fit <- function(
  ...,
  missing_rows = NULL,
  converged_diagnostics = TRUE,
  converged_opt = 0L
) {
  result <- list(
    coef_names = c("mu_(Intercept)", "mu_x"),
    coefficients = c(0.1, 0.2),
    vcov = diag(c(0.04, 0.09)),
    loglik = -10,
    aic = 24,
    bic = 26,
    df = 2L,
    nobs = 20L,
    converged = isTRUE(converged_diagnostics),
    fitted = rep(0, 20),
    residuals = rep(0, 20),
    sigma = rep(1, 20),
    corpairs = list()
  )
  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(bf(y ~ x), engine = "julia")),
    formula = bf(y ~ x),
    family = gaussian(),
    data = data.frame(y = rep(1, 20), x = rep(1, 20)),
    family_type = "gaussian"
  )
  fit$missing_rows <- missing_rows
  if (is.null(converged_diagnostics)) {
    fit$diagnostics$converged <- NULL
    fit$opt <- list(convergence = converged_opt)
  }
  fit
}

test_that("check_julia_dropped_rows() notes plural drops and stays ok", {
  fit <- w5_julia_diag_fit(
    missing_rows = list(n_input = 25L, n_dropped = 2L)
  )
  rows <- drmTMB:::check_julia_dropped_rows(fit)
  expect_identical(rows$status, "note")
  expect_match(rows$message, "dropped 2 incomplete rows", fixed = TRUE)
  out <- drmTMB:::check_drm.drmTMB_julia(fit)
  dropped <- out[out$check == "dropped_rows", ]
  expect_length(dropped$check, 1L)
  expect_true(attr(out, "ok"))
})

test_that("check_julia_optimizer_convergence() falls back to opt$convergence", {
  fit <- w5_julia_diag_fit(converged_diagnostics = NULL, converged_opt = 0L)
  row <- drmTMB:::check_julia_optimizer_convergence(fit)
  expect_identical(row$status, "ok")
  fit_bad <- w5_julia_diag_fit(converged_diagnostics = NULL, converged_opt = 1L)
  row_bad <- drmTMB:::check_julia_optimizer_convergence(fit_bad)
  expect_identical(row_bad$status, "warning")
})

test_that("check_julia_bridge_covariance() maps skipped and unsupported statuses to notes", {
  for (status in c("skipped", "unsupported")) {
    fit <- w5_julia_diag_fit()
    fit$uncertainty <- list(status = status, message = paste("msg", status))
    row <- drmTMB:::check_julia_bridge_covariance(fit)
    expect_identical(row$status, "note")
    expect_match(row$value, paste0("status=", status), fixed = TRUE)
  }
})

test_that("check_julia_fixed_gradient() errors on non-finite gradients", {
  fit <- w5_julia_diag_fit()
  fit$diagnostics$gradient <- c(mu = 0, sigma = Inf)
  names(fit$diagnostics$gradient) <- fit$coef_names
  row <- drmTMB:::check_julia_fixed_gradient(fit, gradient_tolerance = 1e-3)
  expect_identical(row$status, "error")
})

test_that("drm_julia_gradient_source_gloss() covers the unknown fallback", {
  gloss <- drmTMB:::drm_julia_gradient_source_gloss("unknown")
  expect_match(gloss, "unknown", fixed = TRUE)
  expect_match(gloss, "check_drm", fixed = TRUE)
})

test_that("plot_parameter_surface helpers validate dpar and type filters", {
  base <- data.frame(
    dpar = c("mu", "sigma"),
    type = c("response", "response"),
    estimate = c(1, 0.5),
    conf.status = "wald",
    interval_source = "wald",
    x = c(0, 1)
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(base, dpar = "nu", type = NULL),
    "Unknown distributional"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(base, dpar = NULL, type = "link"),
    "Unknown prediction scale"
  )
  expect_error(
    drmTMB:::filter_plot_parameter_surface_data(base, dpar = c(NA, "mu"), type = NULL),
    "non-empty character"
  )
  keep <- drmTMB:::filter_plot_parameter_surface_data(base, dpar = "mu", type = NULL)
  expect_equal(nrow(keep), 1L)
  expect_equal(
    drmTMB:::plot_parameter_surface_y_label(keep),
    "mu estimate (response scale)"
  )
  expect_equal(
    drmTMB:::plot_parameter_surface_y_label(base),
    "Estimate"
  )
})

test_that("plot_parameter_surface() omits faceting when facet is NULL", {
  testthat::skip_if_not_installed("ggplot2")
  pred <- data.frame(
    dpar = "mu",
    type = "response",
    estimate = c(1, 1.2),
    conf.status = "wald",
    interval_source = "wald",
    x = c(0, 1)
  )
  out <- plot_parameter_surface(pred, x = "x", facet = NULL)
  expect_s3_class(out, "ggplot")
  expect_s3_class(out$facet, "FacetNull")
})

test_that("plot_parameter_surface_row_logprob-style internals stay finite for a toy row", {
  val <- drmTMB:::drm_pair_gaussian_nbinom2_sandwich_row_logprob(
    gaussian_y = 0.5,
    nbinom2_y = 3L,
    m = 0.4,
    tau_g = log(0.7),
    xi_n = log(2),
    tau_n = log(0.5),
    a = atanh(0.2)
  )
  expect_true(is.finite(val))
})

test_that("drm_pair_gaussian_nbinom2_eta_sandwich() fails closed on bad inputs", {
  expect_error(
    drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
      list(model = list(model_type = "gaussian")),
      list(model = list(model_type = "gaussian")),
      list()
    ),
    "Gaussian x ordinary-NB2"
  )
  unresolved <- structure(
    list(
      components = list(pair_class = "gaussian_nbinom2"),
      status = "on_boundary"
    ),
    class = "drm_pair_association"
  )
  expect_identical(
    drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
      list(model = list(model_type = "gaussian")),
      list(model = list(model_type = "nbinom2")),
      unresolved
    ),
    drmTMB:::drm_pair_sandwich_unavailable("association_unresolved")
  )
})