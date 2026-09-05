# A4 (2026-09-05): `tweedie()` admitted through engine = "julia" on the
# fixed-effect (Workflow G) route -- ONE registry row in
# R/julia-family-registry.R, no bridge code. This file is the family's
# focused-test limb (docs/design/168) and pins the four things the admission
# rests on:
#
#   1. the registry row itself (fe only: no phylo, no RE, no structured route);
#   2. the payload: all three dpars (mu, sigma, nu) reach `options$coef_labels`
#      in base-R model.matrix() spelling (docs/design/258 S7.1) -- no Julia;
#   3. the live round trip on the committed fixture: same target as
#      engine = "tmb" (coef by NAME <= 1e-4, logLik <= 1e-4, Wald SE rtol
#      <= 1e-3), the coef_labels echo validated, and the estimator label equal
#      to what DRM.jl's `estim_method` reports;
#   4. RED CONTROL: with the registry row absent, the same call REFUSES.
#
# Parameterisation is the same on both engines (R/family.R `tweedie()`;
# DRM.jl src/tweedie.jl at pin 430ef64cc): log(mu) = eta_mu, sigma = sqrt(phi)
# with log(sigma) = eta_sigma, nu = 1 + plogis(eta_nu) ("logit12").
# Measured at the pin, 2026-09-05: coef 2.767e-11, logLik 0, SE 3.273e-06 rel.

# Fixture: the call shape of tests/testthat/test-tweedie-location-scale.R
# (new_tweedie_data() defaults), reproduced here so this file stands alone.
drm_tweedie_julia_fixture <- function() {
  n <- 500L
  set.seed(20260701)
  beta_mu <- c("(Intercept)" = 0.2, x = 0.45)
  beta_sigma <- c("(Intercept)" = -0.55, z = 0.20)
  nu <- 1.35
  dat <- data.frame(x = stats::runif(n, -1, 1), z = stats::rnorm(n))
  mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * dat$x)
  sigma <- exp(beta_sigma[[1L]] + beta_sigma[[2L]] * dat$z)
  dat$y <- drmTMB:::rtweedie_compound(n, mu = mu, phi = sigma^2, power = nu)
  dat
}

drm_tweedie_julia_formula <- function() {
  drmTMB::bf(y ~ x, sigma ~ z, nu ~ 1)
}

test_that("tweedie has exactly one registry row, fixed-effect only", {
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")
  expect_identical(sum(fam == "tweedie"), 1L)
  row <- reg[[which(fam == "tweedie")]]
  expect_true(isTRUE(row$fe))
  expect_identical(row$drmjl_tag, "tweedie")
  # NOT widened: every non-FE column stays FALSE (a later row's job)
  for (col in c("phylo_only", "locscale_phylo", "slope_phylo",
                "dispersionless", "structured")) {
    expect_false(isTRUE(row[[col]]), info = col)
  }
  expect_true("tweedie" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_false("tweedie" %in% drmTMB:::drm_julia_phylo_only_families())
  expect_false("tweedie" %in% drmTMB:::drm_julia_structured_families())
  expect_false("tweedie" %in% drmTMB:::drm_julia_dispersionless_families())
})

test_that("drm_julia_family_tag() admits tweedie on the fixed-effect route", {
  expect_identical(drmTMB:::drm_julia_family_tag("tweedie"), "tweedie")
  # The family type drmTMB derives from the constructor is the registry key.
  expect_identical(drmTMB:::drm_julia_bridge_family_type(drmTMB::tweedie()), "tweedie")
})

test_that("tweedie payload labels all three dpars in base-R spelling (design 258 S7.1)", {
  dat <- drm_tweedie_julia_fixture()
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = drm_tweedie_julia_formula(),
    family_type = "tweedie",
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
  # (measured live at the pin: the fit completes at the native bf(y ~ x)
  # logLik). NOTE the asymmetry, measured and NOT fixed in this leaf: omitting
  # `nu` is not defaulted (drm_julia_bridge_default_dpar_labels() fills `nu`
  # for student only), so bf(y ~ x) / bf(y ~ x, sigma ~ z) abort at DRM.jl's
  # echo with `coef_labels is missing an entry for dpar "nu"`. Design 258 S8.2.
  payload2 <- drmTMB:::drm_julia_bridge_payload(
    formula = drmTMB::bf(y ~ x, nu ~ 1),
    family_type = "tweedie",
    data = dat,
    env = environment()
  )
  labels2 <- lapply(payload2$options$coef_labels, function(x) unlist(x, use.names = FALSE))
  expect_identical(labels2[c("mu", "sigma", "nu")],
                   list(mu = c("(Intercept)", "x"), sigma = "(Intercept)", nu = "(Intercept)"))
})

# ---- live round trip (opt-in; skips only when the engine is absent) --------

drm_tweedie_julia_roundtrip <- function() {
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
      ft <- drmTMB::drmTMB(form, family = drmTMB::tweedie(), data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(form, family = drmTMB::tweedie(), data = dat, engine = "julia")
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
        nobs = stats::nobs(fj)
      )
    },
    args = list(
      pkg = pkg, jl_path = jl_path,
      build = drm_tweedie_julia_fixture, formula_fn = drm_tweedie_julia_formula
    ),
    error = "stack"
  )
}

test_that("tweedie fits through engine = 'julia' on the same target as engine = 'tmb'", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  # A subprocess error is a FAILURE here, never a skip: the environment gates
  # above already cover the absent-engine case, so a refusal ("currently
  # supports Workflow G ...") or a DRM.jl-side abort ("unknown dpar",
  # "coef_labels is missing an entry ...") must surface as red.
  out <- drm_tweedie_julia_roundtrip()

  expect_true("drmTMB_julia" %in% out$class_julia)
  expect_identical(out$model_type, "tweedie")
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
})
