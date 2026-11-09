# R-side handling of the Julia bridge `fit_failed` / `fit_failed_message` keys
# (DRModels.jl #1270). Hand-built bridge results; no Julia needed.

failed_fit_gaussian <- function(...) {
  d <- data.frame(y = c(1, 2, 3, 2, 4, 3, 5, 4), x = seq_len(8) / 8)
  form <- drmTMB::bf(y ~ x)
  result <- list(
    coef_names = c("mu_(Intercept)", "mu_x"),
    coefficients = c(1, 2),
    vcov = diag(2),
    loglik = -10, aic = 24, bic = 25, df = 2L, nobs = 8L,
    converged = TRUE,
    fitted = list(mu = d$y), residuals = list(mu = rep(0, 8)),
    sigma = list(sigma = rep(1, 8))
  )
  result <- utils::modifyList(result, list(...))
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(y ~ x, data = d, engine = "julia")),
    formula = form, family = gaussian(), data = d,
    family_type = "gaussian"
  )
}

test_that("a failed Julia fit warns with the Julia message and next steps", {
  expect_warning(
    fit <- failed_fit_gaussian(
      loglik = NaN, aic = NaN, bic = NaN, converged = FALSE,
      fit_failed = TRUE, fit_failed_message = "Hessian not positive definite"
    ),
    "Hessian not positive definite"
  )
  expect_true(is.nan(as.numeric(stats::logLik(fit))))
  expect_true(fit$fit_failed)
  expect_match(fit$opt$message, "failed fit")
  expect_false(grepl("reported no convergence", fit$opt$message))
  out <- paste(testthat::capture_messages(print(fit)), collapse = "\n")
  expect_match(out, "FAILED FIT")
  expect_warning(
    failed_fit_gaussian(loglik = NaN, fit_failed = TRUE),
    "engine = \"tmb\""
  )
})

test_that("a good Julia fit is silent and not marked failed", {
  expect_no_warning(fit <- failed_fit_gaussian(fit_failed = FALSE, fit_failed_message = ""))
  expect_false(fit$fit_failed)
  expect_equal(as.numeric(stats::logLik(fit)), -10)
  expect_false(grepl("FAILED FIT", paste(testthat::capture_messages(print(fit)), collapse = "\n")))
})

test_that("an older Julia package with no fit_failed key is unchanged", {
  expect_no_warning(fit <- failed_fit_gaussian())
  expect_false(fit$fit_failed)
  expect_equal(fit$opt$convergence, 0L)
  expect_match(fit$opt$message, "converged, non-degenerate")
})

xfam_fit_with <- function(...) {
  set.seed(20260724)
  n <- 12L
  x <- seq(-1, 1, length.out = n)
  dat <- data.frame(
    y1 = 0.4 + 0.7 * x + stats::rnorm(n, sd = 0.1),
    y2 = stats::rpois(n, exp(0.2 - 0.3 * x)),
    x = x
  )
  form <- drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x)
  axes <- drmTMB:::drm_julia_xfam_axes(
    formula = form, data = dat, env = environment(),
    tags = c("gaussian", "poisson")
  )
  result <- list(
    rho_latent = 0.2, rho_ci_wald_lower = -0.1, rho_ci_wald_upper = 0.45,
    rho_ci_prof_lower = -0.08, rho_ci_prof_upper = 0.42,
    beta1 = c(0.4, 0.7), beta2 = c(0.2, -0.3),
    sigma_coef1 = c(-0.5), sigma_coef2 = numeric(),
    lambda1 = 0.35, lambda2 = -0.25, sigma1 = 0.6, sigma2 = NaN,
    loglik = -23.75, converged = TRUE
  )
  result <- utils::modifyList(result, list(...))
  drmTMB:::new_drmTMB_julia_xfam(
    result = result, call = quote(drmTMB()), formula = form,
    family = c(gaussian(), poisson()), families = c("gaussian", "poisson"),
    axes = axes, data = dat
  )
}

test_that("a failed cross-family Julia fit warns and sets NaN logLik", {
  expect_warning(
    fit <- xfam_fit_with(
      loglik = NaN, converged = FALSE,
      fit_failed = TRUE, fit_failed_message = "line search failed"
    ),
    "line search failed"
  )
  expect_true(is.nan(fit$logLik))
  expect_true(fit$fit_failed)
  expect_match(fit$opt$message, "failed fit")
  out <- paste(testthat::capture_messages(print(fit)), collapse = "\n")
  expect_match(out, "FAILED FIT")
  expect_no_warning(good <- xfam_fit_with())
  expect_false(good$fit_failed)
})

test_that("the opt slot words failure as a failed fit", {
  slot <- drmTMB:::drm_julia_opt_slot(list(converged = FALSE, fit_failed = TRUE))
  expect_true(slot$fit_failed)
  expect_equal(slot$convergence, 1L)
  expect_match(slot$message, "failed fit")
  slot_old <- drmTMB:::drm_julia_opt_slot(list(converged = FALSE))
  expect_false(slot_old$fit_failed)
  expect_match(slot_old$message, "reported no convergence")
})
