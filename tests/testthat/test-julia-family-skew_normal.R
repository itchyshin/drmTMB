# A4 (2026-09-05): `skew_normal()` admitted through engine = "julia" on the
# fixed-effect (Workflow G) route -- ONE registry row in
# R/julia-family-registry.R, no bridge code on the R side. The Julia side
# needed a `_bridge_family("skew_normal") -> SkewNormal()` case (DRM.jl
# src/bridge.jl; its own DRM.jl PR), so at a DRM.jl checkout WITHOUT that case
# the live test below fails at the Julia boundary with
# "drm_bridge: unsupported family `skew_normal`" -- a failure, never a skip.
#
# This file is the family's focused-test limb (docs/design/168) and pins the
# things the admission rests on:
#
#   1. the registry row itself (fe only: no phylo, no RE, no structured route);
#   2. the payload: all three dpars (mu, sigma, nu) reach `options$coef_labels`
#      in base-R model.matrix() spelling (docs/design/258 S7.1) -- no Julia;
#   3. RED CONTROL: with the registry row absent, the same tag REFUSES;
#   4. the live round trip on the committed fixture: same target as
#      engine = "tmb" (coef by NAME <= 1e-4, logLik <= 1e-4, Wald SE rtol
#      <= 1e-3), the coef_labels echo validated, and the estimator label equal
#      to what DRM.jl's `estim_method` reports; plus the predictor-dependent
#      `nu ~ z` shape both engines fit.
#
# Parameterisation is the same on both engines (R/family.R `skew_normal()`;
# DRM.jl src/skewnormal.jl): the PUBLIC moment form mu = E[y] (identity),
# log(sigma) = eta_sigma with sigma = SD[y], nu = Azzalini's slant alpha
# (identity); both map internally to (xi, omega, alpha) via
# delta = nu / sqrt(1 + nu^2), omega = sigma / sqrt(1 - 2 delta^2 / pi),
# xi = mu - omega delta sqrt(2 / pi). Measured 2026-09-05 at DRM.jl pin
# 430ef64cc + the bridge case: coef 1.890e-11, logLik 2.160e-12, SE 1.045e-06
# rel (docs/design/258 S8.3).

# Fixture: the call shape of tests/testthat/test-skew-normal-location-scale.R
# (`skew_normal_test_data()` defaults: n = 500, seed 20260608, nu = 1.6),
# reproduced here so this file stands alone.
drm_skew_normal_julia_fixture <- function(n = 500L, seed = 20260608, nu = 1.6) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  mu <- 0.20 + 0.45 * dat$x
  sigma <- exp(-0.35 + 0.18 * dat$z)
  delta <- nu / sqrt(1 + nu^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- sigma / sqrt(1 - mean_shift^2)
  xi <- mu - omega * mean_shift
  dat$y <- xi + omega * (delta * abs(stats::rnorm(n)) +
    sqrt(1 - delta^2) * stats::rnorm(n))
  dat
}

drm_skew_normal_julia_formula <- function() {
  drmTMB::bf(y ~ x, sigma ~ z, nu ~ 1)
}

test_that("skew_normal has exactly one registry row, fixed-effect only", {
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")
  expect_identical(sum(fam == "skew_normal"), 1L)
  row <- reg[[which(fam == "skew_normal")]]
  expect_true(isTRUE(row$fe))
  expect_identical(row$drmjl_tag, "skew_normal")
  # NOT widened: every non-FE column stays FALSE (a later row's job)
  for (col in c("phylo_only", "locscale_phylo", "slope_phylo",
                "dispersionless", "structured")) {
    expect_false(isTRUE(row[[col]]), info = col)
  }
  expect_true("skew_normal" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_false("skew_normal" %in% drmTMB:::drm_julia_phylo_only_families())
  expect_false("skew_normal" %in% drmTMB:::drm_julia_structured_families())
  expect_false("skew_normal" %in% drmTMB:::drm_julia_dispersionless_families())
})

test_that("drm_julia_family_tag() admits skew_normal on the fixed-effect route", {
  expect_identical(drmTMB:::drm_julia_family_tag("skew_normal"), "skew_normal")
  # The family type drmTMB derives from the constructor is the registry key.
  expect_identical(
    drmTMB:::drm_julia_bridge_family_type(drmTMB::skew_normal()),
    "skew_normal"
  )
})

test_that("RED CONTROL: with the registry row absent, skew_normal is refused at the family gate", {
  reg <- drmTMB:::drm_julia_family_registry()
  without_row <- Filter(function(s) !identical(s$family, "skew_normal"), reg)
  expect_length(without_row, length(reg) - 1L)
  testthat::local_mocked_bindings(
    drm_julia_family_registry = function() without_row,
    .package = "drmTMB"
  )
  expect_false("skew_normal" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_error(
    drmTMB:::drm_julia_family_tag("skew_normal"),
    "currently supports Workflow G"
  )
})

test_that("skew_normal payload labels all three dpars in base-R spelling (design 258 S7.1)", {
  dat <- drm_skew_normal_julia_fixture()
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = drm_skew_normal_julia_formula(),
    family_type = "skew_normal",
    data = dat,
    env = environment()
  )
  expect_identical(payload$formula$mu, "y ~ x")
  expect_identical(payload$formula$sigma, "sigma ~ z")
  expect_identical(payload$formula$nu, "nu ~ 1")
  labels <- lapply(payload$options$coef_labels, function(x) unlist(x, use.names = FALSE))
  expect_identical(
    labels,
    list(mu = c("(Intercept)", "x"), sigma = c("(Intercept)", "z"), nu = "(Intercept)")
  )
  # sigma omitted: the defaulter labels DRM.jl's intercept-only sigma block
  # (measured live: the fit completes at the native bf(y ~ x, nu ~ 1) logLik).
  payload2 <- drmTMB:::drm_julia_bridge_payload(
    formula = drmTMB::bf(y ~ x, nu ~ 1),
    family_type = "skew_normal",
    data = dat,
    env = environment()
  )
  labels2 <- lapply(payload2$options$coef_labels, function(x) unlist(x, use.names = FALSE))
  expect_identical(
    labels2[c("mu", "sigma", "nu")],
    list(mu = c("(Intercept)", "x"), sigma = "(Intercept)", nu = "(Intercept)")
  )
  # The asymmetry, measured and NOT fixed in this leaf: omitting `nu` is not
  # defaulted (drm_julia_bridge_default_dpar_labels() in R/julia-bridge.R
  # fills `nu` for student only), so bf(y ~ x, sigma ~ z) aborts at DRM.jl's
  # echo with `coef_labels is missing an entry for dpar "nu"`. Pinned so the
  # day the defaulter is widened this expectation flips and the docs
  # (docs/design/258 S8.3, NEWS) get updated with it.
  payload3 <- drmTMB:::drm_julia_bridge_payload(
    formula = drmTMB::bf(y ~ x, sigma ~ z),
    family_type = "skew_normal",
    data = dat,
    env = environment()
  )
  expect_false("nu" %in% names(payload3$options$coef_labels))
})

# ---- live round trip (opt-in; skips only when the engine is absent) --------

drm_skew_normal_julia_roundtrip <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path, build, formula_fn) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      dat <- build()
      form <- formula_fn()
      ft <- drmTMB::drmTMB(form, family = drmTMB::skew_normal(), data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(form, family = drmTMB::skew_normal(), data = dat, engine = "julia")
      flat <- function(f) {
        cf <- stats::coef(f)
        out <- numeric()
        for (nm in names(cf)) {
          out <- c(out, stats::setNames(as.numeric(cf[[nm]]), paste0(nm, ":", names(cf[[nm]]))))
        }
        out
      }
      se_of <- function(f) {
        V <- as.matrix(stats::vcov(f))
        stats::setNames(sqrt(diag(V)), sub("_", ":", rownames(V), fixed = TRUE))
      }
      # Predictor-dependent slant: both engines fit `nu ~ z` natively.
      form_z <- drmTMB::bf(y ~ x, sigma ~ z, nu ~ z)
      ftz <- drmTMB::drmTMB(form_z, family = drmTMB::skew_normal(), data = dat, engine = "tmb")
      fjz <- drmTMB::drmTMB(form_z, family = drmTMB::skew_normal(), data = dat, engine = "julia")
      list(
        class_julia = class(fj),
        model_type = fj$model$model_type,
        engine = fj$engine,
        estimator = fj$estimator,
        estim_method = as.character(fj$bridge$estim_method),
        label_contract = fj$bridge_public_coef_labels$contract,
        public_labels = fj$bridge_public_coef_labels$public,
        coef_tmb = flat(ft),
        coef_julia = flat(fj),
        loglik_tmb = as.numeric(stats::logLik(ft)),
        loglik_julia = as.numeric(stats::logLik(fj)),
        se_tmb = se_of(ft),
        se_julia = se_of(fj),
        converged = drmTMB::is_converged(fj),
        nobs = stats::nobs(fj),
        coef_tmb_z = flat(ftz),
        coef_julia_z = flat(fjz),
        loglik_tmb_z = as.numeric(stats::logLik(ftz)),
        loglik_julia_z = as.numeric(stats::logLik(fjz))
      )
    },
    args = list(
      pkg = pkg, jl_path = jl_path,
      build = drm_skew_normal_julia_fixture, formula_fn = drm_skew_normal_julia_formula
    ),
    error = "stack"
  )
}

test_that("skew_normal fits through engine = 'julia' on the same target as engine = 'tmb'", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  # A subprocess error is a FAILURE here, never a skip: the environment gates
  # above already cover the absent-engine case, so a refusal ("currently
  # supports Workflow G ..."), a DRM.jl checkout without the bridge case
  # ("drm_bridge: unsupported family `skew_normal`"), or a DRM.jl-side abort
  # ("coef_labels is missing an entry ...") must surface as red.
  out <- drm_skew_normal_julia_roundtrip()

  expect_true("drmTMB_julia" %in% out$class_julia)
  expect_identical(out$model_type, "skew_normal")
  expect_identical(out$engine, "julia")
  expect_true(isTRUE(out$converged))
  expect_identical(out$nobs, 500L)

  # design 258 S7.2/S7.3: the echo validated and base-R spelling survived
  expect_identical(out$label_contract, "bridge_formula_labels_v1")
  expect_identical(
    out$public_labels,
    c("mu_(Intercept)", "mu_x", "sigma_(Intercept)", "sigma_z", "nu_(Intercept)")
  )

  # Same target: coefficients matched BY NAME (the Julia object orders its
  # dpar blocks mu, nu, sigma; the native object mu, sigma, nu -- a positional
  # comparison would be wrong on both sides of a real disagreement).
  expect_setequal(names(out$coef_julia), names(out$coef_tmb))
  cj <- out$coef_julia[names(out$coef_tmb)]
  expect_lt(max(abs(cj - out$coef_tmb)), 1e-4)
  expect_lt(abs(out$loglik_julia - out$loglik_tmb), 1e-4)

  # SE axis: per-coefficient Wald SE, relative tolerance 1e-3 (tools/parity_se.R)
  expect_setequal(names(out$se_julia), names(out$se_tmb))
  sj <- out$se_julia[names(out$se_tmb)]
  expect_true(all(is.finite(sj)) && all(sj > 1e-6))
  expect_lt(max(abs(sj - out$se_tmb) / pmax(abs(sj), abs(out$se_tmb))), 1e-3)

  # Estimator honesty (#1152): the label equals what the engine reports.
  expect_identical(out$estimator, "ML")
  expect_identical(toupper(out$estim_method), "ML")

  # nu ~ z: six coefficients, same target on both engines.
  expect_setequal(names(out$coef_julia_z), names(out$coef_tmb_z))
  expect_true("nu:z" %in% names(out$coef_tmb_z))
  cjz <- out$coef_julia_z[names(out$coef_tmb_z)]
  expect_lt(max(abs(cjz - out$coef_tmb_z)), 1e-4)
  expect_lt(abs(out$loglik_julia_z - out$loglik_tmb_z), 1e-4)
})
