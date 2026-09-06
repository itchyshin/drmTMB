# Zero-inflated NB2 (`family_type` "zi_nbinom2") through engine = "julia".
#
# WHY THERE IS NO REGISTRY ROW HERE. "zi_nbinom2" is not a family in the
# bridge's registry sense on either side. drmTMB reaches it as
# `family = nbinom2()` PLUS a `zi ~ ...` formula part (R/drmTMB.R sets
# `model_type = if (has_zi) "zi_nbinom2" else "nbinom2"`), and DRM.jl reaches it
# as `NegBinomial2()` plus a keyed `zi` formula part (src/negbinomial.jl,
# `_fit_negbin2_zi`). The `nbinom2` registry row already admits the family and
# `zi` is already in `julia_bridge_supported_dpars()`, so the route was
# reachable before this file existed -- with no focused test, no documentation
# and, as it turned out, one silent defect. This file is the missing evidence,
# not a new admission.
#
# PARAMETERISATION, checked for the ZERO-INFLATED variant specifically rather
# than inherited from plain nbinom2:
#   * drmTMB, src/drm_count_kernels.h `drm_nbinom2_log_density`:
#     `alpha = exp(2 * log_sigma)`, i.e. size = 1 / alpha = 1 / sigma^2; the zi
#     mixture in src/drmTMB.cpp is
#     `logspace_add(log_zi, log1m_zi + log_density)` at y == 0 and
#     `log1m_zi + log_density` otherwise, with `zi = 1 / (1 + exp(-eta_zi))`.
#   * DRM.jl, src/negbinomial.jl `_fit_negbin2_zi`: `r = exp(-2 * eta_sigma)`,
#     i.e. size = 1 / sigma^2, `p = r / (r + mu)`; the mixture is
#     `_logaddexp(log_pi, log1m_pi + nb)` at y == 0 and `log1m_pi + nb`
#     otherwise, with `pi = logistic(X_zi * beta_zi)`.
# Identical size mapping, identical mixture algebra, identical logit link.
#
# MEASURED AT THE PIN (2026-09-05, DRM.jl 430ef64cc plus this leaf's
# `_bridge_fitted_marginal` patch; drmTMB 0.7.0; the fixture below):
#   max|d_coef| = 4.56745752330789e-13 over 8 coefficients,
#   |d_logLik| = 1.72803993336856e-11 (-2886.32364387789 native),
#   SE max rel 1.60915216580772e-06 over 8 SEs,
#   max|d_fitted| = 4.83169060316868e-13 (1.3665229755584 BEFORE the patch).

# The committed WORKING native fixture: `new_zi_nbinom2_data()` and the call
# shape from tests/testthat/test-zi-nbinom2.R, so a refusal here can never be a
# malformed call.
drm_zinb2_fixture <- function(n = 1800, seed = 20260613) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    w = stats::rnorm(n),
    habitat = factor(sample(c("open", "edge"), n, replace = TRUE))
  )
  mu <- exp(as.vector(
    stats::model.matrix(~ x + habitat, dat) %*% c(0.45, -0.30, 0.25)
  ))
  sigma <- exp(as.vector(
    stats::model.matrix(~z, dat) %*% c(-0.75, 0.20)
  ))
  zi <- stats::plogis(as.vector(
    stats::model.matrix(~ w + habitat, dat) %*% c(-1.15, 0.45, -0.35)
  ))
  dat$count <- ifelse(
    stats::runif(n) < zi,
    0L,
    stats::rnbinom(n, size = 1 / sigma^2, mu = mu)
  )
  dat
}

drm_zinb2_formula <- function() {
  drm_formula(count ~ x + habitat, sigma ~ z, zi ~ w + habitat)
}

# ---- offline: what the bridge sends, and the tag asymmetry it rests on ------

test_that("the zi route is admitted by the nbinom2 registry row, not a zi_nbinom2 one", {
  reg <- drmTMB:::drm_julia_family_registry()
  families <- vapply(reg, `[[`, character(1L), "family")
  # Deliberate: there is no "zi_nbinom2" row and there must not be one, because
  # `drm_julia_bridge_family_type()` classifies the FAMILY OBJECT (`nbinom2()`),
  # which knows nothing about the `zi` formula part.
  expect_false("zi_nbinom2" %in% families)
  expect_true("nbinom2" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_identical(drmTMB:::drm_julia_bridge_family_type(nbinom2()), "nbinom2")
  expect_identical(drmTMB:::drm_julia_family_tag("nbinom2"), "nbinom2")
  # `zi` is already in the bridge dpar vocabulary; that is what carries the
  # formula part through to DRM.jl's keyed `zi` entry.
  expect_true("zi" %in% drmTMB:::julia_bridge_supported_dpars())
})

test_that("the native engine names this model zi_nbinom2 and links zi by logit", {
  dat <- drm_zinb2_fixture(n = 400, seed = 20260613)
  ft <- drmTMB(drm_zinb2_formula(), family = nbinom2(), data = dat, engine = "tmb")
  expect_identical(ft$model$model_type, "zi_nbinom2")
  expect_identical(ft$model$dpars, c("mu", "sigma", "zi"))
  expect_identical(drmTMB:::drm_dpar_link(ft, "zi"), "logit")
  # drmTMB's contract for this family's fitted mean: the UNCONDITIONAL mean.
  expect_equal(
    fitted(ft),
    (1 - predict(ft, dpar = "zi")) * predict(ft, dpar = "mu"),
    tolerance = 1e-12
  )
})

test_that("the zi payload carries mu + sigma + zi coefficient labels (design 258)", {
  dat <- drm_zinb2_fixture(n = 400, seed = 20260613)
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = drm_zinb2_formula(), data = dat, env = environment(),
    family_type = "nbinom2"
  )
  expect_identical(labels$mu, c("(Intercept)", "x", "habitatopen"))
  expect_identical(labels$sigma, c("(Intercept)", "z"))
  expect_identical(labels$zi, c("(Intercept)", "w", "habitatopen"))
  # sigma omitted: DRM.jl still fits an intercept-only sigma block, so the
  # defaulter must label it or the echo aborts "missing an entry for dpar sigma"
  bare <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = bf(count ~ x, zi ~ w), data = dat, env = environment(),
    family_type = "nbinom2"
  )
  expect_identical(bare$sigma, "(Intercept)")
  expect_identical(bare$zi, c("(Intercept)", "w"))
})

# ---- live: same-target parity, the repaired fitted contract, the refusals ---

# One Julia session for the whole file: three test_that blocks read the same
# converged pair of fits rather than booting the engine three times.
drm_zinb2_live_cache <- new.env(parent = emptyenv())

drm_zinb2_live <- function() {
  if (!is.null(drm_zinb2_live_cache$res)) {
    return(drm_zinb2_live_cache$res)
  }
  drm_zinb2_live_cache$res <- drm_zinb2_live_run()
  drm_zinb2_live_cache$res
}

drm_zinb2_live_run <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      # Inlined, not called from the parent: `callr::r()` evaluates this
      # function in a fresh session where the test file's helpers do not exist.
      # Byte-for-byte the same draw as `drm_zinb2_fixture()` above.
      n <- 1800
      set.seed(20260613)
      dat <- data.frame(
        x = stats::rnorm(n),
        z = stats::rnorm(n),
        w = stats::rnorm(n),
        habitat = factor(sample(c("open", "edge"), n, replace = TRUE))
      )
      mu <- exp(as.vector(
        stats::model.matrix(~ x + habitat, dat) %*% c(0.45, -0.30, 0.25)
      ))
      sigma <- exp(as.vector(
        stats::model.matrix(~z, dat) %*% c(-0.75, 0.20)
      ))
      zi <- stats::plogis(as.vector(
        stats::model.matrix(~ w + habitat, dat) %*% c(-1.15, 0.45, -0.35)
      ))
      dat$count <- ifelse(
        stats::runif(n) < zi,
        0L,
        stats::rnbinom(n, size = 1 / sigma^2, mu = mu)
      )
      fml <- drmTMB::drm_formula(count ~ x + habitat, sigma ~ z, zi ~ w + habitat)
      fam <- drmTMB::nbinom2()
      ft <- drmTMB::drmTMB(fml, family = fam, data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(fml, family = fam, data = dat, engine = "julia")
      se_of <- function(f) {
        V <- as.matrix(stats::vcov(f))
        se <- sqrt(diag(V))
        names(se) <- sub(":", "_", rownames(V), fixed = TRUE)
        se
      }
      err_of <- function(expr) {
        tryCatch({ expr; "" }, error = function(e) conditionMessage(e))
      }
      list(
        engine = fj$engine,
        model_type = fj$model$model_type,
        dpars = fj$model$dpars,
        estimator = fj$estimator,
        engine_estim_method = as.character(fj$bridge$estim_method),
        converged = drmTMB::is_converged(fj),
        coef_labels = fj$bridge_payload$coef_labels,
        coef_names_julia = as.character(fj$bridge$coef_names),
        coef_tmb = unlist(drmTMB::fixef(ft)),
        coef_julia = unlist(drmTMB::fixef(fj)),
        loglik_tmb = as.numeric(stats::logLik(ft)),
        loglik_julia = as.numeric(stats::logLik(fj)),
        se_tmb = se_of(ft),
        se_julia = se_of(fj),
        fitted_tmb = stats::fitted(ft),
        fitted_julia = stats::fitted(fj),
        resid_tmb = stats::residuals(ft),
        resid_julia = stats::residuals(fj),
        mu_tmb = stats::predict(ft, dpar = "mu"),
        zi_tmb = stats::predict(ft, dpar = "zi"),
        sigma_tmb = stats::predict(ft, dpar = "sigma"),
        dpar_mu_julia = fj$bridge$dpars$mu,
        dpar_zi_julia = fj$bridge$dpars$zi,
        dpar_sigma_julia = fj$bridge$dpars$sigma,
        sigma_julia_is_list = is.list(stats::sigma(fj)),
        sigma_julia_names = names(stats::sigma(fj)),
        # KNOWN GAP, pinned so it cannot change silently: the bridge tags the
        # fit "nbinom2", so drm_dpar_link() has no `zi` row for it.
        err_predict_zi = err_of(stats::predict(fj, dpar = "zi")),
        # the engine's own refusals
        err_ranef = err_of(drmTMB::drmTMB(
          drmTMB::bf(count ~ x + (1 | habitat), sigma ~ z, zi ~ w),
          family = fam, data = dat, engine = "julia")),
        err_zi_and_hu = err_of(drmTMB::drmTMB(
          drmTMB::bf(count ~ x, sigma ~ z, zi ~ w, hu ~ w),
          family = fam, data = dat, engine = "julia")),
        err_reml = err_of(drmTMB::drmTMB(
          fml, family = fam, data = dat, engine = "julia", REML = TRUE))
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "stack"
  )
}

test_that("zi_nbinom2 through engine = \"julia\": same target as native TMB (coef, logLik, SE)", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  res <- drm_zinb2_live()

  expect_identical(res$engine, "julia")
  expect_identical(res$dpars, c("mu", "sigma", "zi"))
  expect_true(isTRUE(res$converged))

  # The ENGINE is the authority on the estimator (#1152): compare, do not merely
  # observe that the mislabel guard stayed quiet.
  expect_identical(res$engine_estim_method, "ML")
  expect_identical(res$estimator, res$engine_estim_method)

  # design 258: all three dpar blocks reached the payload and the echo validated
  expect_identical(res$coef_labels$mu, c("(Intercept)", "x", "habitatopen"))
  expect_identical(res$coef_labels$sigma, c("(Intercept)", "z"))
  expect_identical(res$coef_labels$zi, c("(Intercept)", "w", "habitatopen"))
  expect_identical(
    res$coef_names_julia,
    c("mu_(Intercept)", "mu_x", "mu_habitatopen",
      "sigma_(Intercept)", "sigma_z",
      "zi_(Intercept)", "zi_w", "zi_habitatopen")
  )

  # coefficients and logLik, name-matched, within the fixed-effect cohort bar
  expect_identical(names(res$coef_tmb), names(res$coef_julia))
  expect_lt(max(abs(res$coef_tmb - res$coef_julia)), 1e-4)
  expect_lt(abs(res$loglik_tmb - res$loglik_julia), 1e-4)

  # per-coefficient Wald SE, relative, within tools/parity_se.R's bar
  common <- intersect(names(res$se_tmb), names(res$se_julia))
  expect_length(common, 8L)
  a <- res$se_tmb[common]
  b <- res$se_julia[common]
  expect_true(all(is.finite(a)) && all(is.finite(b)) && all(a > 1e-6) && all(b > 1e-6))
  expect_lt(max(abs(a - b) / pmax(abs(a), abs(b))), 1e-3)
})

test_that("zi_nbinom2 through engine = \"julia\": fitted() and residuals() are the UNCONDITIONAL mean on both engines", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  res <- drm_zinb2_live()

  # THE DEFECT THIS FILE EXISTS FOR. DRM.jl's `fitted()` is `means[:mu]`, which
  # for a zero-inflated count fit is the COUNT-COMPONENT mean; drmTMB's is the
  # unconditional `(1 - zi) * mu`. Before DRM.jl's `_bridge_fitted_marginal`
  # this gap was 1.3665229755584 on this very fixture while the coefficients
  # agreed to 4.6e-13 -- invisible to any coefficient or likelihood check.
  expect_lt(max(abs(res$fitted_tmb - res$fitted_julia)), 1e-8)
  expect_lt(max(abs(res$resid_tmb - res$resid_julia)), 1e-8)
  expect_lt(
    max(abs(res$fitted_julia - (1 - res$zi_tmb) * res$mu_tmb)),
    1e-8
  )

  # ... and the repair must NOT have moved the dpar table: `mu` stays the
  # component mean, which is what drmTMB's `predict(dpar = "mu")` reports.
  expect_lt(max(abs(res$dpar_mu_julia - res$mu_tmb)), 1e-8)
  expect_lt(max(abs(res$dpar_zi_julia - res$zi_tmb)), 1e-8)
  expect_lt(max(abs(res$dpar_sigma_julia - res$sigma_tmb)), 1e-8)
})

test_that("zi_nbinom2 through engine = \"julia\": declared limits are refused, not silently fitted", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  res <- drm_zinb2_live()

  # DRM.jl's own words at pin 430ef64cc -- fixed effects only, and zi/hu are
  # mutually exclusive rather than one quietly winning.
  expect_match(
    res$err_ranef,
    "NegBinomial2\\(\\) random effects cannot be combined with `zi`/`hu` yet"
  )
  expect_match(
    res$err_zi_and_hu,
    "`zi` and `hu` cannot both be specified"
  )
  # REML is refused before Julia starts rather than downgraded to ML in silence
  expect_match(res$err_reml, "cannot fit non-Gaussian \\(nbinom2\\) models by")

  # KNOWN GAPS, pinned rather than claimed. Both follow from the bridge tagging
  # this fit "nbinom2": there is no `zi` row in that family's link table, and
  # DRM.jl's `sigma()` returns the whole `scales` Dict once `zi` joins it.
  # Neither is fixed in this leaf -- both live in R/julia-bridge.R and
  # R/methods.R, which this leaf does not own. See NEWS.md.
  expect_match(
    res$err_predict_zi,
    "no canonical prediction link for Julia-engine"
  )
  expect_true(res$sigma_julia_is_list)
  expect_identical(sort(res$sigma_julia_names), c("sigma", "zi"))
})
