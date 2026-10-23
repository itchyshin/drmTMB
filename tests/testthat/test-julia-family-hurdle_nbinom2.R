# Hurdle NB2 through engine = "julia" (parity leaf fam-hurdle-nbinom2,
# 2026-09-05). `hurdle_nbinom2` is a drmTMB MODEL_TYPE, not a family_type:
# there is no `hurdle_nbinom2()` constructor. The native spelling is
# `family = truncated_nbinom2()` plus an `hu ~ ...` entry, and R/drmTMB.R sets
# `model_type = if (has_hu) "hurdle_nbinom2" else "truncated_nbinom2"`. So the
# bridge needs NO registry row here -- the merged `truncated_nbinom2` fe row
# admits the family and `hu` is already in `julia_bridge_supported_dpars()`.
#
# HURDLE, NOT ZERO-INFLATED, read off both likelihoods before this file existed:
#   drmTMB src/drmTMB.cpp model_type 12:
#     y == 0  ->  nll -= w * log_hu
#     y  > 0  ->  nll -= w * (log_one_minus_hu + log NB2(y) - log1mexp(log NB2(0)))
#   DRM.jl src/negbinomial.jl `_fit_negbin2_hu`: the same two branches.
# Both truncate the count component at zero and give the zeros their own
# logit-linked mass. The zero-INFLATED neighbours (drmTMB model_type 9, DRM.jl
# `_fit_negbin2_zi`) mix a point mass with an UNtruncated count and are a
# different model; both engines refuse `zi` and `hu` together.
#
# What DRM.jl PR #662 changed: `TruncatedNegBinomial2()` now accepts an `hu`
# part and delegates to its `NegBinomial2` hurdle kernel, so ONE identical call
# fits on both engines. Before it, `engine = "tmb"` wanted truncated_nbinom2() +
# hu and `engine = "julia"` wanted nbinom2() + hu, and the bridge's own ledger
# row recorded that a user could not switch `engine =` on one call.
#
# Fixture: the native suite's own hurdle DGP, tests/testthat/test-hurdle-nbinom2.R
# `new_hurdle_nbinom2_data()` (n = 1800, seed 20260623) -- the committed WORKING
# native call shape, so a refusal here can never be a malformed call. Covariates
# on mu, sigma AND hu.
#
# Measured in the leaf run (drmTMB worktree claude/parity-fam-hurdle-nbinom2 with
# devtools::load_all, DRM.jl branch claude/parity-fam-hurdle-nbinom2-drmjl):
#   max|d_coef| = 9.4286800589316e-12 over 8 coefficients,
#   logLik -2941.45558666655 (tmb) vs -2941.45558666657 (julia), |d| 2.183e-11,
#   SE max rel 1.10121323025882e-06 over 8 SEs, estimator "ML" both sides.

drm_hurdle_nb2_fixture <- function(n = 1800, seed = 20260623) {
  set.seed(seed)
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    w = stats::rnorm(n),
    habitat = factor(rep(c("open", "closed"), length.out = n))
  )
  X_mu <- stats::model.matrix(~ x + habitat, dat)
  X_sigma <- stats::model.matrix(~z, dat)
  X_hu <- stats::model.matrix(~ w + habitat, dat)
  mu <- exp(as.vector(X_mu %*% c(0.40, -0.22, 0.20)))
  sigma <- exp(as.vector(X_sigma %*% c(-0.75, 0.18)))
  hu <- stats::plogis(as.vector(X_hu %*% c(-0.85, 0.45, -0.35)))
  p0 <- stats::dnbinom(0, size = 1 / sigma^2, mu = mu)
  positive_u <- p0 + pmax(stats::runif(n), .Machine$double.eps) * (1 - p0)
  dat$count <- ifelse(
    stats::runif(n) < hu,
    0,
    stats::qnbinom(positive_u, size = 1 / sigma^2, mu = mu)
  )
  dat
}

# ---- offline: no Julia needed ----------------------------------------------

test_that("hurdle_nbinom2 needs no registry row: it is truncated_nbinom2 plus an hu entry", {
  reg <- drmTMB:::drm_julia_family_registry()
  families <- vapply(reg, `[[`, character(1L), "family")
  # the model_type is NOT a family in the registry's sense
  expect_false("hurdle_nbinom2" %in% families)
  # the family the native spelling actually uses IS admitted, fixed effects only
  row <- Filter(function(s) identical(s$family, "truncated_nbinom2"), reg)[[1L]]
  expect_true(row$fe)
  expect_identical(row$drmjl_tag, "truncated_nbinom2")
  expect_identical(
    drmTMB:::drm_julia_family_tag("truncated_nbinom2"),
    "truncated_nbinom2"
  )
  # and `hu` is already part of the bridge's dpar vocabulary
  expect_true("hu" %in% drmTMB:::julia_bridge_supported_dpars())
})

test_that("drm_julia_bridge_model_type() reports the NATIVE model_type for a bridge hurdle fit", {
  dat <- drm_hurdle_nb2_fixture(n = 50)
  hurdle <- bf(count ~ x + habitat, sigma ~ z, hu ~ w + habitat)
  plain <- bf(count ~ x + habitat, sigma ~ z)
  expect_identical(
    drmTMB:::drm_julia_bridge_model_type("truncated_nbinom2", hurdle),
    "hurdle_nbinom2"
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_model_type("truncated_nbinom2", plain),
    "truncated_nbinom2"
  )
  # every other family is untouched: model_type IS family_type there
  for (fam in c("gaussian", "nbinom2", "poisson", "beta_binomial")) {
    expect_identical(drmTMB:::drm_julia_bridge_model_type(fam, hurdle), fam)
    expect_identical(drmTMB:::drm_julia_bridge_model_type(fam, plain), fam)
  }
  # and the link table this unlocks is the hurdle one, keyed on model_type
  fake <- structure(
    list(model = list(model_type = "hurdle_nbinom2")),
    class = "drmTMB"
  )
  expect_identical(drmTMB:::drm_dpar_link(fake, "hu"), "logit")
  expect_identical(drmTMB:::drm_dpar_link(fake, "mu"), "log")
  # the RED CONTROL this test stands for: the plain zero-truncated model has no
  # `hu` link, so a bridge fit mislabelled `truncated_nbinom2` cannot predict it
  fake_trunc <- structure(
    list(model = list(model_type = "truncated_nbinom2")),
    class = "drmTMB"
  )
  expect_error(drmTMB:::drm_dpar_link(fake_trunc, "hu"))
})

test_that("hurdle_nbinom2 payload labels mu + sigma + hu (design 258)", {
  dat <- drm_hurdle_nb2_fixture(n = 200)
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = bf(count ~ x + habitat, sigma ~ z, hu ~ w + habitat),
    data = dat, env = environment(), family_type = "truncated_nbinom2"
  )
  expect_identical(labels$mu, c("(Intercept)", "x", "habitatopen"))
  expect_identical(labels$sigma, c("(Intercept)", "z"))
  expect_identical(labels$hu, c("(Intercept)", "w", "habitatopen"))
  # sigma written by neither the user nor this family's own dpar set: DRM.jl
  # still fits an intercept-only sigma block, so the defaulter must label it or
  # the echo aborts "missing an entry for dpar sigma". Measured live: the bare
  # form fits, logLik -923.643378063885 (tmb) vs -923.643378063886 (julia).
  labels_bare <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    formula = bf(count ~ x, hu ~ w),
    data = dat, env = environment(), family_type = "truncated_nbinom2"
  )
  expect_identical(labels_bare$mu, c("(Intercept)", "x"))
  expect_identical(labels_bare$sigma, "(Intercept)")
  expect_identical(labels_bare$hu, c("(Intercept)", "w"))
})

test_that("the hurdle_nbinom2 ledger row names the identical call and stays at partial", {
  caps <- drmTMB:::drm_julia_capability_comparison()
  row <- caps[caps$capability_id == "hurdle_nbinom2", , drop = FALSE]
  expect_identical(nrow(row), 1L)
  # the row's syntax is the call that fits on BOTH engines
  expect_true(grepl("family = truncated_nbinom2()", row$syntax, fixed = TRUE))
  expect_true(grepl("hu ~ 1", row$syntax, fixed = TRUE))
  # the CROSS-SPELLING claim the A3 receipt carried is gone
  expect_false(grepl("bridge spelling", row$syntax, fixed = TRUE))
  expect_false(grepl(
    "no identical call fits on both engines",
    row$claim_boundary, fixed = TRUE
  ))
  # promoted on the wave-1 bar only -- point + SE, never intervals
  expect_identical(row$r_bridge_status, "partial")
  expect_true(grepl("bridge-side inference unqualified (G3)", row$claim_boundary, fixed = TRUE))
  # and the boundary DECLARES the fitted()/residuals() gap rather than hiding it
  expect_true(grepl("fitted() and residuals() DIVERGE", row$claim_boundary, fixed = TRUE))
})

# ---- live: the same call on both engines ------------------------------------

drm_hurdle_nb2_live <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  # The draw is built HERE and shipped to the worker, so the fixture the
  # assertions describe is the object that was fitted -- not a re-typed copy.
  dat <- drm_hurdle_nb2_fixture()
  callr::r(
    function(pkg, jl_path, dat) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      fml <- drmTMB::bf(count ~ x + habitat, sigma ~ z, hu ~ w + habitat)
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
      coef_flat <- function(f) {
        v <- unlist(drmTMB::fixef(f))
        stats::setNames(v, sub(".", "_", names(v), fixed = TRUE))
      }
      list(
        engine = fj$engine,
        model_type_tmb = ft$model$model_type,
        model_type_julia = fj$model$model_type,
        dpars_julia = fj$model$dpars,
        dpars_tmb = names(stats::coef(ft)),
        estimator = fj$estimator,
        engine_estim_method = as.character(fj$bridge$estim_method),
        converged = drmTMB::is_converged(fj),
        n_zero = sum(dat$count == 0),
        n_positive = sum(dat$count > 0),
        coef_labels = fj$bridge_payload$coef_labels,
        coef_names_julia = as.character(fj$bridge$coef_names),
        coef_tmb = coef_flat(ft),
        coef_julia = coef_flat(fj),
        loglik_tmb = as.numeric(stats::logLik(ft)),
        loglik_julia = as.numeric(stats::logLik(fj)),
        aic_tmb = stats::AIC(ft), aic_julia = stats::AIC(fj),
        df_tmb = ft$df, df_julia = fj$df,
        nobs_tmb = stats::nobs(ft), nobs_julia = stats::nobs(fj),
        se_tmb = se_of(ft), se_julia = se_of(fj),
        hu_tmb = stats::predict(ft, dpar = "hu"),
        hu_julia = stats::predict(fj, dpar = "hu"),
        hu_julia_link = stats::predict(fj, dpar = "hu", type = "link"),
        mu_julia = stats::predict(fj, dpar = "mu"),
        sigma_julia = stats::predict(fj, dpar = "sigma"),
        fitted_tmb = stats::fitted(ft),
        fitted_julia = stats::fitted(fj),
        # the engine's own refusals: nothing is dropped silently
        err_zi = err_of(drmTMB::drmTMB(
          drmTMB::bf(count ~ x, sigma ~ 1, zi ~ w),
          family = fam, data = dat, engine = "julia")),
        err_reml = err_of(drmTMB::drmTMB(
          fml, family = fam, data = dat, engine = "julia", REML = TRUE)),
        err_ranef = err_of(drmTMB::drmTMB(
          drmTMB::bf(count ~ x + (1 | habitat), sigma ~ 1, hu ~ w),
          family = fam, data = dat, engine = "julia"))
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, dat = dat),
    error = "stack"
  )
}

test_that("hurdle nbinom2 through engine = \"julia\": ONE call, same target as native TMB", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  res <- drm_hurdle_nb2_live()

  # the fixture really is a hurdle fixture: both zeros and positive counts
  expect_gt(res$n_zero, 0L)
  expect_gt(res$n_positive, 0L)

  expect_identical(res$engine, "julia")
  expect_true(isTRUE(res$converged))

  # THE POINT OF THIS LEAF: one call, and both engines call it the same model
  expect_identical(res$model_type_tmb, "hurdle_nbinom2")
  expect_identical(res$model_type_julia, "hurdle_nbinom2")
  # the bridge's block ORDER is alphabetical where native's is mu, sigma, hu --
  # a pre-existing, family-general bridge property (`split()` on dpar names), so
  # compare the SET and pin the known order difference rather than assert parity
  expect_setequal(res$dpars_julia, c("mu", "sigma", "hu"))
  expect_identical(res$dpars_tmb, c("mu", "sigma", "hu"))

  # the ENGINE is the authority on the estimator (#1152)
  expect_identical(res$engine_estim_method, "ML")
  expect_identical(res$estimator, res$engine_estim_method)

  # design 258: all three dpars reached the payload and the echo validated
  expect_identical(res$coef_labels$mu, c("(Intercept)", "x", "habitatopen"))
  expect_identical(res$coef_labels$sigma, c("(Intercept)", "z"))
  expect_identical(res$coef_labels$hu, c("(Intercept)", "w", "habitatopen"))
  expect_setequal(
    res$coef_names_julia,
    c("mu_(Intercept)", "mu_x", "mu_habitatopen",
      "sigma_(Intercept)", "sigma_z",
      "hu_(Intercept)", "hu_w", "hu_habitatopen")
  )

  # coefficients and logLik, name-matched, within the cohort tolerance
  common <- intersect(names(res$coef_tmb), names(res$coef_julia))
  expect_length(common, 8L)
  expect_lt(max(abs(res$coef_tmb[common] - res$coef_julia[common])), 1e-4)
  expect_lt(abs(res$loglik_tmb - res$loglik_julia), 1e-4)
  expect_lt(abs(res$aic_tmb - res$aic_julia), 1e-4)
  expect_identical(as.integer(res$df_tmb), as.integer(res$df_julia))
  expect_identical(as.integer(res$nobs_tmb), as.integer(res$nobs_julia))

  # per-coefficient Wald SE, relative, on tools/parity_se.R's bar
  se_common <- intersect(names(res$se_tmb), names(res$se_julia))
  expect_length(se_common, 8L)
  a <- res$se_tmb[se_common]
  b <- res$se_julia[se_common]
  expect_true(all(is.finite(a)) && all(is.finite(b)) && all(a > 1e-6) && all(b > 1e-6))
  expect_lt(max(abs(a - b) / pmax(abs(a), abs(b))), 1e-3)

  # the hu dpar is a real, logit-linked probability on the bridge, and agrees
  # with native -- this is what the corrected model_type buys
  expect_true(all(res$hu_julia > 0 & res$hu_julia < 1))
  expect_equal(res$hu_julia, stats::plogis(res$hu_julia_link), tolerance = 1e-10)
  expect_lt(max(abs(res$hu_tmb - res$hu_julia)), 1e-6)
})

test_that("hurdle nbinom2 bridge fit: dpars are right, fitted() is the DECLARED gap", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  res <- drm_hurdle_nb2_live()

  # Native fitted() for a hurdle is (1 - hu) * mu / (1 - P0). DRM.jl's fitted()
  # is means[:mu], the UNtruncated NB2 mean, so the two engines' fitted() do NOT
  # agree on this route. That is an aggregation gap in DRM.jl, not a wrong
  # parameter: the native fitted mean is reproducible EXACTLY from the dpars the
  # bridge returns. Assert the reproduction (durable) and record the gap.
  recon <- drmTMB:::hurdle_nbinom2_mean(
    res$mu_julia, res$sigma_julia, res$hu_julia
  )
  expect_lt(max(abs(recon - res$fitted_tmb)), 1e-6)
  # and the bridge's own fitted() is the mu dpar, which is what makes it differ
  expect_lt(max(abs(res$fitted_julia - res$mu_julia)), 1e-10)
  expect_gt(max(abs(res$fitted_tmb - res$fitted_julia)), 1e-3)
})

test_that("hurdle nbinom2 through engine = \"julia\": the route's own refusals", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  res <- drm_hurdle_nb2_live()

  # DRM.jl PR #662's second half: a formula part this family does not consume is
  # an ERROR, never a silent drop. Before it, `zi` was deleted from the
  # likelihood and the plain zero-truncated model was fitted instead.
  expect_match(res$err_zi, "unsupported formula part `zi`")
  # Fixed effects only on this route. The refusal comes from drmTMB's A4.G17
  # fe-only fence, which runs BEFORE Julia boots, so DRM.jl's own
  # "TruncatedNegBinomial2() currently supports fixed effects only" is no longer
  # what the user sees -- assert the message that actually fires.
  expect_match(res$err_ranef, "only on the `fe`", fixed = FALSE)
  expect_match(res$err_ranef, "random-effect bar term")
  # REML is refused R-side, before Julia boots
  expect_match(res$err_reml, "cannot fit non-Gaussian")
})
