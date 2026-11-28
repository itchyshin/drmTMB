# Non-Julia heritability internals in R/heritability.R (beyond print/Julia fence).

mock_fit <- function(random = list(mu = list(n_re = 0L, coef_names = "(Intercept)", labels = "(1 | g)", n_terms = 1L))) {
  structure(
    list(
      model = list(model_type = "gaussian", random = random),
      opt = list(par = c(beta_mu = 0, log_sigma = 0))
    ),
    class = "drmTMB"
  )
}

test_that("drm_variance_ratio_resolve_component() defaults to singleton SDs", {
  sdv <- c(phylo = 0.2)
  expect_identical(
    drmTMB:::drm_variance_ratio_resolve_component(sdv, NULL, "heritability"),
    1L
  )
  expect_error(
    drmTMB:::drm_variance_ratio_resolve_component(c(a = 1, b = 2), NULL, "icc"),
    "structured components"
  )
  expect_identical(
    drmTMB:::drm_variance_ratio_resolve_component(c(a = 1, b = 2), "b", "icc"),
    2L
  )
  expect_error(
    drmTMB:::drm_variance_ratio_resolve_component(c(a = 1), "missing", "icc"),
    "no structured component"
  )
})

test_that("drm_variance_ratio_reject_random_slopes() refuses correlated mu RE", {
  fit <- mock_fit()
  fit$opt$par <- c(fit$opt$par, eta_cor_mu = 0.1)
  expect_error(
    drmTMB:::drm_variance_ratio_reject_random_slopes(fit, "heritability"),
    "correlated random effects"
  )
})

test_that("drm_variance_ratio_reject_random_slopes() refuses random slopes", {
  fit <- mock_fit(
    random = list(
      mu = list(
        n_re = 1L,
        coef_names = c("(Intercept)", "x"),
        labels = c("(1 | g)", "(1 | g)"),
        n_terms = 2L
      )
    )
  )
  expect_error(
    drmTMB:::drm_variance_ratio_reject_random_slopes(fit, "repeatability"),
    "random slopes"
  )
})