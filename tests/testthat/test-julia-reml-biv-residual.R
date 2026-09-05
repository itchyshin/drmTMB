# REML parity for the residual-only bivariate Gaussian cell
#   bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
# drmTMB #1142 / DRM.jl #624; docs/design/261 row "biv_gaussian_residual".
#
# Native TMB has always fitted this cell by REML (it hands beta_mu1/beta_mu2 to
# TMB's Laplace approximation, which is EXACT for a likelihood quadratic in
# them). DRM.jl refused it outright and the bridge refused it before Julia even
# started. DRM.jl now fits the same restricted likelihood in closed form and the
# gate below admits it, so the two engines must agree on the same target.
#
# Convention, stated on both sides because a REML log-likelihood is only
# meaningful with one: BOTH engines integrate out exactly {beta_mu1, beta_mu2}
# and BOTH report the NORMALISED Patterson-Thompson value
#   l_R = l_ML(beta_hat, phi) - 0.5 * logdet(sum_i Z_i' S_i^-1 Z_i)
#         + (p_beta / 2) * log(2 * pi),
# TMB because that is what its Laplace approximation computes
# (-log int exp(-f) d beta ~= f(beta_hat) + 0.5 * logdet(H / (2 * pi))), DRM.jl
# because #477 standardised every REML route on that same constant. There is no
# data-independent offset to remove before comparing.

drm_reml_biv_residual_fixture <- function() {
  # The committed fixture: reproduces the RNG stream of
  # docs/dev-log/evidence/julia-r-parity/reml-by-route/native_reml_probe.R
  # exactly, so the logLik recorded in docs/design/261 stays the same number.
  set.seed(1)
  n <- 60
  x <- rnorm(n)
  y <- 0.5 + 0.8 * x + rnorm(n, sd = 0.6)
  y1 <- 0.4 + 0.6 * x + rnorm(n, sd = 0.5)
  y2 <- -0.2 + 0.3 * x + 0.4 * y1 + rnorm(n, sd = 0.5)
  data.frame(y1 = y1, y2 = y2, x = x)
}

drm_reml_biv_residual_formula <- function() {
  bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
}

test_that("the bridge REML gate admits this cell and nothing wider", {
  f <- drm_reml_biv_residual_formula()
  expect_true(drm_julia_reml_supported(f, "biv_gaussian"))
  expect_true(drm_julia_biv_residual_reml_supported(f))

  # A covariate on sigma1 is a shape DRM.jl's closed form covers but nothing
  # here has MEASURED, so the gate keeps refusing it.
  expect_false(drm_julia_biv_residual_reml_supported(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~x, sigma2 = ~1, rho12 = ~1)
  ))
  # A covariate on rho12 likewise.
  expect_false(drm_julia_biv_residual_reml_supported(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~x)
  ))
  # A univariate Gaussian formula is not this route at all.
  expect_false(drm_julia_biv_residual_reml_supported(bf(y ~ x, sigma ~ 1)))
  # The widening did not reach any other family.
  expect_false(drm_julia_reml_supported(f, "biv_lognormal"))
})

test_that("engine='julia' REML matches engine='tmb' REML on this cell", {
  drm_skip_live_julia()
  drm_test_local_julia_home()
  withr::local_envvar(c(
    DRM_JL_PATH = drm_test_drmjl_path(),
    DRM_JL_PHYLO_PATH = drm_test_drmjl_path()
  ))

  d_biv <- drm_reml_biv_residual_fixture()
  f <- drm_reml_biv_residual_formula()

  fit_tmb <- drmTMB(
    f,
    family = biv_gaussian(), data = d_biv, REML = TRUE, engine = "tmb"
  )
  fit_jl <- drmTMB(
    f,
    family = biv_gaussian(), data = d_biv, REML = TRUE, engine = "julia"
  )

  # (1) estimator honesty, read off the objects rather than inferred from the
  # absence of an abort.
  expect_identical(fit_jl$estimator, "REML")
  expect_identical(fit_jl$bridge$estim_method, "REML")
  expect_true(isTRUE(fit_jl$effective_REML))
  expect_identical(fit_tmb$estimator, "REML")

  # (2) same coefficient NAMES, in the same order.
  co_tmb <- summary(fit_tmb)$coefficients
  co_jl <- summary(fit_jl)$coefficients
  nm_tmb <- rownames(co_tmb)
  nm_jl <- paste(co_jl$dpar, co_jl$term, sep = ":")
  expect_identical(nm_jl, nm_tmb)

  # (3) coefficients to 1e-4 (absolute, or relative where |value| > 1).
  est_tmb <- as.numeric(co_tmb[, "estimate"])
  est_jl <- as.numeric(co_jl$estimate)
  scale_est <- pmax(1, abs(est_tmb))
  expect_lt(max(abs(est_jl - est_tmb) / scale_est), 1e-4)

  # (4) the restricted log-likelihood, on the shared convention above.
  ll_tmb <- as.numeric(stats::logLik(fit_tmb))
  ll_jl <- as.numeric(stats::logLik(fit_jl))
  expect_lt(abs(ll_jl - ll_tmb) / max(1, abs(ll_tmb)), 1e-4)
  # It is genuinely the RESTRICTED value on both engines, not ML relabelled.
  ll_ml_tmb <- as.numeric(stats::logLik(drmTMB(
    f,
    family = biv_gaussian(), data = d_biv, REML = FALSE, engine = "tmb"
  )))
  expect_gt(abs(ll_tmb - ll_ml_tmb), 1)
  expect_lt(ll_tmb, ll_ml_tmb)

  # (5) standard errors to rtol 1e-3.
  se_tmb <- as.numeric(co_tmb[, "std_error"])
  se_jl <- as.numeric(co_jl$std.error)
  expect_true(all(is.finite(se_jl)))
  expect_lt(max(abs(se_jl - se_tmb) / abs(se_tmb)), 1e-3)

  # (6) NEGATIVE CONTROL on the SE comparison: perturbing one Julia SE by 10 per
  # cent must break the same check, so a pass above is not vacuous.
  se_bad <- se_jl
  se_bad[1] <- se_bad[1] * 1.10
  expect_gt(max(abs(se_bad - se_tmb) / abs(se_tmb)), 1e-3)

  # (7) the ML route through the same bridge is untouched by this widening.
  ll_ml_jl <- as.numeric(stats::logLik(drmTMB(
    f,
    family = biv_gaussian(), data = d_biv, REML = FALSE, engine = "julia"
  )))
  expect_lt(abs(ll_ml_jl - ll_ml_tmb) / max(1, abs(ll_ml_tmb)), 1e-4)
})
