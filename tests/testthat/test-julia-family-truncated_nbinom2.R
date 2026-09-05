# A4 (2026-09-05): `truncated_nbinom2()` admitted through engine = "julia" on
# the fixed-effect route -- ONE registry row (R/julia-family-registry.R). Both
# engines fit the SAME zero-truncated NB2 target with the SAME size = 1/sigma^2
# parameterisation (DRM.jl src/negbinomial.jl `TruncatedNegBinomial2`, pin
# 430ef64cc), so the parity bar is the fixed-effect cohort's: coefficients and
# logLik within 1e-4, per-coefficient Wald SE within 1e-3 relative.
#
# Fixture: the SAME draw as tests/testthat/test-family-dpq-batchC.R:304-313,
# the committed WORKING native fit for this family (call shape
# `bf(y ~ x, sigma ~ 1)`), so a refusal here can never be a malformed call.
#
# Measured at the pin (2026-09-05, worktree HEAD 67703f541, native tmb vs engine = "julia"):
#   max|d_coef| = 8.81172357303228e-11, |d_logLik| = 2.8421709430404e-12,
#   SE max rel 2.71330456989773e-07 (mu_(Intercept), mu_x, sigma_(Intercept)),
#   estimator "ML" == DRM.jl estim_method "ML".

drm_tnb2_fixture <- function() {
  set.seed(20260729)
  n <- 300
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.25 * x)
  sigma_true <- 0.6
  p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
  u_true <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
  y <- stats::qnbinom(u_true, size = 1 / sigma_true^2, mu = mu_true)
  data.frame(y = y, x = x, g = factor(rep(seq_len(30), each = 10)))
}

# ---- offline: the registry row and what it derives (no Julia needed) --------

test_that("truncated_nbinom2 is a fixed-effect registry row and drm_julia_family_tag() admits it", {
  reg <- drmTMB:::drm_julia_family_registry()
  row <- Filter(function(s) identical(s$family, "truncated_nbinom2"), reg)
  expect_length(row, 1L)
  row <- row[[1L]]
  expect_true(row$fe)
  expect_identical(row$drmjl_tag, "truncated_nbinom2")
  # fixed effects ONLY in this leaf: no phylo / locscale / slope / structured
  expect_false(row$phylo_only)
  expect_false(row$locscale_phylo)
  expect_false(row$slope_phylo)
  expect_false(row$structured)
  # mu + sigma family: the label defaulter must add DRM.jl's sigma block
  expect_false(row$dispersionless)
  expect_false("truncated_nbinom2" %in% drmTMB:::drm_julia_dispersionless_families())
  expect_identical(drmTMB:::drm_julia_family_tag("truncated_nbinom2"), "truncated_nbinom2")
  expect_true("truncated_nbinom2" %in% drmTMB:::drm_julia_registry_families("fe"))
})

test_that("truncated_nbinom2 payload carries mu + sigma coef_labels, sigma defaulted when absent (design 258)", {
  dat <- drm_tnb2_fixture()
  # sigma written: both blocks labelled from the formula
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = bf(y ~ x, sigma ~ 1), data = dat, env = environment(),
    family_type = "truncated_nbinom2"
  )
  expect_identical(labels$mu, c("(Intercept)", "x"))
  expect_identical(labels$sigma, "(Intercept)")
  # sigma absent: DRM.jl still fits an intercept-only sigma block, so the
  # defaulter must label it or the echo aborts "missing an entry for dpar sigma"
  labels_bare <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = bf(y ~ x), data = dat, env = environment(),
    family_type = "truncated_nbinom2"
  )
  expect_identical(labels_bare$sigma, "(Intercept)")
})

# ---- live: same-target parity and the engine's own refusals -----------------

drm_tnb2_live <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      set.seed(20260729)
      n <- 300
      x <- stats::rnorm(n)
      mu_true <- exp(0.5 + 0.25 * x)
      sigma_true <- 0.6
      p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
      u_true <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
      y <- stats::qnbinom(u_true, size = 1 / sigma_true^2, mu = mu_true)
      dat <- data.frame(y = y, x = x, g = factor(rep(seq_len(30), each = 10)))
      dat_zero <- dat
      dat_zero$y[seq_len(20)] <- 0L
      fml <- drmTMB::bf(y ~ x, sigma ~ 1)
      fam <- drmTMB::truncated_nbinom2()
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
        # the engine's own refusals: nothing is dropped silently
        err_ranef = err_of(drmTMB::drmTMB(
          drmTMB::bf(y ~ x + (1 | g), sigma ~ 1), family = fam, data = dat, engine = "julia")),
        err_hurdle = err_of(drmTMB::drmTMB(
          drmTMB::bf(y ~ x, sigma ~ 1, hu ~ 1), family = fam, data = dat, engine = "julia")),
        err_zero = err_of(drmTMB::drmTMB(fml, family = fam, data = dat_zero, engine = "julia"))
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "stack"
  )
}

test_that("truncated_nbinom2 through engine = \"julia\": same target as native TMB (coef, logLik, SE) and the engine's estimator", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  res <- drm_tnb2_live()

  expect_identical(res$engine, "julia")
  expect_identical(res$model_type, "truncated_nbinom2")
  expect_identical(res$dpars, c("mu", "sigma"))
  expect_true(isTRUE(res$converged))

  # G5: the ENGINE is the authority on the estimator (#1152) -- compare, do not
  # merely observe that the mislabel guard did not fire
  expect_identical(res$engine_estim_method, "ML")
  expect_identical(res$estimator, res$engine_estim_method)

  # G2 / design 258: the family's two dpars reached the payload and the echo
  # validated (the fit completed with the names the R side sent)
  expect_identical(res$coef_labels$mu, c("(Intercept)", "x"))
  expect_identical(res$coef_labels$sigma, "(Intercept)")
  expect_identical(res$coef_names_julia, c("mu_(Intercept)", "mu_x", "sigma_(Intercept)"))

  # G3: coefficients and logLik, name-matched, within the cohort tolerance
  expect_identical(names(res$coef_tmb), names(res$coef_julia))
  expect_lt(max(abs(res$coef_tmb - res$coef_julia)), 1e-4)
  expect_lt(abs(res$loglik_tmb - res$loglik_julia), 1e-4)

  # G4: per-coefficient Wald SE, relative, within tools/parity_se.R's bar
  common <- intersect(names(res$se_tmb), names(res$se_julia))
  expect_identical(sort(common), sort(c("mu_(Intercept)", "mu_x", "sigma_(Intercept)")))
  a <- res$se_tmb[common]
  b <- res$se_julia[common]
  expect_true(all(is.finite(a)) && all(is.finite(b)) && all(a > 1e-6) && all(b > 1e-6))
  expect_lt(max(abs(a - b) / pmax(abs(a), abs(b))), 1e-3)

  # Refusals, in DRM.jl's own words (measured at pin 430ef64cc): the route is
  # fixed effects only, the hurdle dpar is caught by the design-258 echo rather
  # than dropped, and zeros are rejected as they are natively
  expect_match(res$err_ranef, "TruncatedNegBinomial2\\(\\) currently supports fixed effects only")
  expect_match(res$err_hurdle, "coef_labels supplies names for unknown dpar \"hu\"")
  expect_match(res$err_zero, "requires positive integer counts")
})
