# #1190 (decision 16, part 2): random-effect correlations use the guard
# 0.99999999 in TMB (rho = 0.99999999 * tanh(eta_cor)) and R reproduces the same
# response-scale value from the same eta. The residual rho12 and phylogenetic
# correlations keep 0.999999. Boundary fits then reach the exact marginal ML to
# ~1e-7 instead of being held 1e-6 short of the correlation boundary.

drm_re_guard_fit <- function() {
  set.seed(1190)
  g <- factor(rep(seq_len(12), each = 8))
  x <- rep(seq(-1, 1, length.out = 8), 12)
  u <- rnorm(12, sd = 1)
  y <- 0.5 + 0.8 * x + u[as.integer(g)] + 0.3 * rnorm(96)
  suppressWarnings(drmTMB(
    bf(y ~ x + (1 + x | g), sigma ~ 1),
    family = gaussian(), data = data.frame(y = y, x = x, g = g)
  ))
}

test_that("R and TMB agree on the random-effect correlation at an extreme eta (#1190)", {
  skip_on_cran()
  fit <- drm_re_guard_fit()
  expect_identical(drmTMB:::DRM_RE_CORR_GUARD, 0.99999999)
  expect_identical(drmTMB:::DRM_CORR_GUARD, 0.999999) # residual/phylo guard unchanged
  par <- fit$obj$env$last.par.best
  nm <- names(par)
  idx <- which(nm == "eta_cor_mu")
  expect_length(idx, 1L)
  for (eta in c(-30, -8, 0.4, 8, 30)) {
    p <- par
    p[idx] <- eta
    tmb_rho <- unname(fit$obj$report(p)$rho_mu_re)
    expect_equal(tmb_rho, 0.99999999 * tanh(eta), tolerance = 1e-14)
    expect_equal(tmb_rho, drmTMB:::rho_response(eta, guard = drmTMB:::DRM_RE_CORR_GUARD),
                 tolerance = 1e-14)
  }
  # The saturated correlation is the new guard, not the old 0.999999.
  p <- par
  p[idx] <- 30
  expect_equal(unname(fit$obj$report(p)$rho_mu_re), 0.99999999, tolerance = 1e-14)
  # R-side reconstruction of the fitted correlation equals TMB's reported value.
  spec <- fit$model
  fixed <- if (length(fit$obj$env$random)) par[-fit$obj$env$random] else par
  rho_r <- unname(drmTMB:::split_tmb_corpars(fit$obj$env$parList(fixed, par), spec)$mu)
  expect_equal(rho_r, unname(fit$obj$report(par)$rho_mu_re), tolerance = 1e-14)
})

test_that("the residual rho12 guard is unchanged at 0.999999 (#1190)", {
  expect_equal(drmTMB:::rho_response(40), 0.999999, tolerance = 1e-14)
})
