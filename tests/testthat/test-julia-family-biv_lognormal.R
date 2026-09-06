# `biv_lognormal()` admitted through engine = "julia" on the fixed-effect
# (Workflow G) bivariate-residual route, 2026-09-05. Two changes carry it:
# ONE registry row in R/julia-family-registry.R, and the label defaulter's
# bivariate branch in R/julia-bridge.R widened from an exact `biv_gaussian`
# match to the `biv_` PREFIX. The second change was NOT optional and NOT
# assumed: with the registry row alone, BOTH the full and the short formula
# abort inside DRM.jl with
#   coef_labels supplies names for unknown dpar "sigma";
#   the model has dpars: mu1, mu2, sigma1, sigma2, rho12
# because the univariate branch adds a scalar `sigma` label that a bivariate
# model has no block for. This file is the family's focused-test limb
# (docs/design/168) and pins:
#
#   1. the registry row (fe only -- no phylo, RE, structured, dispersionless);
#   2. the label contract, without Julia: sigma1/sigma2/rho12 defaults and NO
#      scalar `sigma`, for the short AND the full formula;
#   3. the payload scale contract, without Julia: the two responses cross on
#      the RAW positive scale, exactly as the native TMB spec passes them, so
#      the logging happens once, inside the engine;
#   4. RED CONTROLS: with the registry row absent the family tag refuses again,
#      and a `biv_gaussian`-only label branch reintroduces the scalar `sigma`;
#   5. the live round trip: same target as engine = "tmb" (coef by NAME
#      <= 1e-4, logLik <= 1e-4, Wald SE rtol <= 1e-3), AND the scale contract
#      pinned against an INDEPENDENT raw-scale oracle rather than against the
#      other engine alone -- a scale mismatch between the engines would still
#      produce plausible-looking numbers, so engine-vs-engine agreement cannot
#      settle it by itself. Two discriminating controls show the oracle check
#      could have failed.
#
# The parameterisation is the same on both engines (R/family.R
# `biv_lognormal()`; DRM.jl src/bivariate_lognormal.jl at pin 430ef64cc):
# mu1/mu2 are means of log y (identity link), sigma1/sigma2 are SDs of log y
# (log link), rho12 is the log-residual correlation (guarded atanh), and both
# engines add the change-of-variables Jacobian -sum(log y1) - sum(log y2).

# Fixture: the native call shape of tests/testthat/test-biv-lognormal.R,
# reproduced here so this file stands alone. Same draw as the receipt rows
# fe_biv_lognormal / se_biv_lognormal in the DRM.jl evidence tables.
drm_biv_lognormal_julia_fixture <- function(n = 600L, seed = 20260905) {
  set.seed(seed)
  x <- stats::rnorm(n)
  s1 <- 0.5
  s2 <- 0.8
  rho <- 0.6
  z1 <- stats::rnorm(n)
  z2 <- rho * z1 + sqrt(1 - rho^2) * stats::rnorm(n)
  data.frame(
    y1 = exp(0.4 + 0.9 * x + s1 * z1),
    y2 = exp(-0.2 + 0.5 * x + s2 * z2),
    x = x
  )
}

drm_biv_lognormal_julia_formula <- function() {
  drmTMB::bf(
    mu1 = y1 ~ x, mu2 = y2 ~ x,
    sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1
  )
}

# Independent raw-scale oracle, the same density
# tests/testthat/test-biv-lognormal.R pins the NATIVE engine against. It is
# written from the bivariate lognormal definition, not from either engine's
# code, and it carries the Jacobian explicitly in the `- log(y1) - log(y2)`
# term -- which is why it can tell a log-scale fit from a raw-scale one.
drm_biv_lognormal_oracle <- function(y1, y2, mu1, mu2, sigma1, sigma2, rho12) {
  z1 <- (log(y1) - mu1) / sigma1
  z2 <- (log(y2) - mu2) / sigma2
  log_density <- -log(2 * pi) - log(sigma1) - log(sigma2) -
    0.5 * log(1 - rho12^2) -
    0.5 * (z1^2 - 2 * rho12 * z1 * z2 + z2^2) / (1 - rho12^2)
  sum(log_density - log(y1) - log(y2))
}

test_that("biv_lognormal has exactly one registry row, fixed-effect only", {
  reg <- drmTMB:::drm_julia_family_registry()
  fam <- vapply(reg, `[[`, character(1L), "family")
  expect_identical(sum(fam == "biv_lognormal"), 1L)
  row <- reg[[which(fam == "biv_lognormal")]]
  expect_true(isTRUE(row$fe))
  expect_identical(row$drmjl_tag, "biv_lognormal")
  # NOT widened. Native drm_build_biv_lognormal_spec() admits no phylogenetic,
  # random-effect or structured cell for this family, so there is no native
  # comparator for one and nothing here may claim it.
  for (col in c("phylo_only", "locscale_phylo", "slope_phylo", "structured",
                "dispersionless")) {
    expect_false(isTRUE(row[[col]]), info = col)
  }
  expect_true("biv_lognormal" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_false("biv_lognormal" %in% drmTMB:::drm_julia_phylo_only_families())
  expect_false("biv_lognormal" %in% drmTMB:::drm_julia_structured_families())
  expect_false("biv_lognormal" %in% drmTMB:::drm_julia_locscale_phylo_families())
  expect_false("biv_lognormal" %in% drmTMB:::drm_julia_slope_phylo_families())
  expect_false("biv_lognormal" %in% drmTMB:::drm_julia_dispersionless_families())
})

test_that("drm_julia_family_tag() admits biv_lognormal on the fixed-effect route", {
  expect_identical(drmTMB:::drm_julia_family_tag("biv_lognormal"), "biv_lognormal")
  expect_identical(
    drmTMB:::drm_julia_bridge_family_type(drmTMB::biv_lognormal()),
    "biv_lognormal"
  )
})

test_that("RED CONTROL: with the registry row absent the family tag refuses again", {
  original <- drmTMB:::drm_julia_family_registry
  testthat::local_mocked_bindings(
    drm_julia_family_registry = function() {
      Filter(function(s) !identical(s$family, "biv_lognormal"), original())
    },
    .package = "drmTMB"
  )
  expect_false("biv_lognormal" %in% drmTMB:::drm_julia_registry_families("fe"))
  expect_error(
    drmTMB:::drm_julia_family_tag("biv_lognormal"),
    "currently supports Workflow G"
  )
})

test_that("the label defaulter gives biv_lognormal the bivariate blocks and no scalar sigma", {
  # Short formula: every block defaults to an intercept, and the block names
  # are the ones DRM.jl reports for this model (mu1, mu2, sigma1, sigma2,
  # rho12). A `sigma` entry here is what aborted the bridge before the fix.
  short <- drmTMB:::drm_julia_bridge_default_dpar_labels(
    labels = list(mu1 = c("(Intercept)", "x"), mu2 = c("(Intercept)", "x")),
    formula = drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family_type = "biv_lognormal"
  )
  expect_setequal(names(short), c("mu1", "mu2", "sigma1", "sigma2", "rho12"))
  expect_false("sigma" %in% names(short))
  expect_identical(short$sigma1, "(Intercept)")
  expect_identical(short$sigma2, "(Intercept)")
  expect_identical(short$rho12, "(Intercept)")
  # Every default label the function can produce must name a block DRM.jl
  # knows; this is the invariant the abort was telling us about.
  expect_true(all(names(short) %in% drmTMB:::julia_bridge_supported_dpars()))

  # The same holds for the FULL formula, which supplies all five blocks: the
  # defaulter must add nothing at all.
  full <- drmTMB:::drm_julia_bridge_default_dpar_labels(
    labels = list(
      mu1 = c("(Intercept)", "x"), mu2 = c("(Intercept)", "x"),
      sigma1 = "(Intercept)", sigma2 = "(Intercept)", rho12 = "(Intercept)"
    ),
    formula = drm_biv_lognormal_julia_formula(),
    family_type = "biv_lognormal"
  )
  expect_setequal(names(full), c("mu1", "mu2", "sigma1", "sigma2", "rho12"))
  expect_false("sigma" %in% names(full))

  # The branch is matched by PREFIX, so biv_gaussian is unchanged by the
  # widening -- the regression this edit could most easily have caused.
  gauss <- drmTMB:::drm_julia_bridge_default_dpar_labels(
    labels = list(mu1 = c("(Intercept)", "x"), mu2 = c("(Intercept)", "x")),
    formula = drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family_type = "biv_gaussian"
  )
  expect_setequal(names(gauss), c("mu1", "mu2", "sigma1", "sigma2", "rho12"))
  # ... and a univariate family still gets its scalar sigma.
  uni <- drmTMB:::drm_julia_bridge_default_dpar_labels(
    labels = list(mu = c("(Intercept)", "x")),
    formula = drmTMB::bf(y ~ x),
    family_type = "lognormal"
  )
  expect_setequal(names(uni), c("mu", "sigma"))
  expect_identical(uni$sigma, "(Intercept)")
})

test_that("RED CONTROL: a biv_gaussian-only label branch reintroduces the scalar sigma", {
  # The defect the widening removed, planted deliberately: exact-match the old
  # family instead of the `biv_` prefix. The payload then carries a `sigma`
  # block DRM.jl has no home for, which is the abort quoted at the top of this
  # file. This test fails if someone narrows the branch back.
  narrowed <- function(labels, formula, family_type) {
    add_default <- function(dpar) {
      if (is.null(labels[[dpar]])) labels[[dpar]] <<- "(Intercept)"
    }
    if (identical(family_type, "biv_gaussian")) {
      for (dpar in c("sigma1", "sigma2", "rho12")) add_default(dpar)
    } else {
      add_default("sigma")
    }
    labels
  }
  bad <- narrowed(
    labels = list(mu1 = c("(Intercept)", "x"), mu2 = c("(Intercept)", "x")),
    formula = drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family_type = "biv_lognormal"
  )
  expect_true("sigma" %in% names(bad))
  expect_false("sigma1" %in% names(bad))
  # The shipped function must NOT behave that way.
  good <- drmTMB:::drm_julia_bridge_default_dpar_labels(
    labels = list(mu1 = c("(Intercept)", "x"), mu2 = c("(Intercept)", "x")),
    formula = drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
    family_type = "biv_lognormal"
  )
  expect_false(identical(names(good), names(bad)))
})

test_that("the biv_lognormal payload crosses the RAW responses, not logged ones", {
  # THE SCALE CONTRACT AT THE PAYLOAD BOUNDARY. Native drmTMB logs y1/y2 inside
  # drm_build_biv_lognormal_spec() and DRM.jl logs them inside
  # src/bivariate_lognormal.jl. If the bridge logged them too, the engine would
  # fit log(log(y)) and still return finite, plausible-looking numbers -- the
  # exact failure this family is most exposed to. So pin that the bridge passes
  # the response through untouched.
  dat <- drm_biv_lognormal_julia_fixture(n = 40L, seed = 4L)
  payload <- drmTMB:::drm_julia_bridge_payload(
    formula = drm_biv_lognormal_julia_formula(),
    family_type = "biv_lognormal",
    data = dat,
    env = environment()
  )
  expect_identical(payload$data$y1, dat$y1)
  expect_identical(payload$data$y2, dat$y2)
  expect_true(all(payload$data$y1 > 0) && all(payload$data$y2 > 0))
  expect_setequal(
    names(payload$coef_labels),
    c("mu1", "mu2", "sigma1", "sigma2", "rho12")
  )
  expect_false("sigma" %in% names(payload$coef_labels))
  wire <- lapply(payload$options$coef_labels, function(x) unlist(x, use.names = FALSE))
  expect_false("sigma" %in% names(wire))
})

test_that("the julia route refuses exactly the cells native biv_lognormal refuses", {
  # THE ASYMMETRY THIS FENCE EXISTS FOR. Admitting the family with fe = TRUE
  # widened what the bridge will ATTEMPT past what the native engine allows.
  # Measured at the pin with the fence absent: `sigma1 = ~ x` FIT through
  # engine = "julia" (logLik -71.4056477) and so did `rho12 = ~ x`
  # (logLik -70.64289338), while engine = "tmb" refuses both. Two engines
  # disagreeing about which models exist is worse than either restriction, and
  # there is no native comparator for those cells, so nothing could measure
  # them. These refusals are on the R side, before Julia starts, so they hold
  # with no engine installed.
  dat <- drm_biv_lognormal_julia_fixture(n = 40L, seed = 9L)
  dat$id <- rep(1:8, length.out = nrow(dat))
  refuse <- function(form) {
    expect_error(
      drmTMB::drmTMB(form, family = drmTMB::biv_lognormal(), data = dat,
                     engine = "julia"),
      "intercept-only"
    )
    # ... and the native engine refuses the same cell, which is the point.
    expect_error(
      drmTMB::drmTMB(form, family = drmTMB::biv_lognormal(), data = dat,
                     engine = "tmb"),
      "fixed-effect|intercept-only"
    )
  }
  refuse(drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ x))
  refuse(drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma2 = ~ x))
  refuse(drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ x))
  # MERGE NOTE (main, 2026-09-06): the random-effect bar is now caught by the
  # registry-wide drm_julia_refuse_fe_only_random_effects(), which fires ahead of
  # this family's own fence and does not use the word "intercept-only", so it
  # cannot go through refuse() above. The properties that matter are unchanged:
  # the Julia route refuses the bar BEFORE Julia starts and points at engine =
  # "tmb", and the native engine refuses the same cell.
  re_form <- drmTMB::bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x)
  re_msg <- tryCatch(
    drmTMB::drmTMB(re_form, family = drmTMB::biv_lognormal(), data = dat, engine = "julia"),
    error = function(e) conditionMessage(e)
  )
  expect_true(is.character(re_msg))
  expect_match(re_msg, "random-effect")
  expect_match(re_msg, 'engine = "tmb"', fixed = TRUE)
  expect_error(
    drmTMB::drmTMB(re_form, family = drmTMB::biv_lognormal(), data = dat, engine = "tmb"),
    "fixed-effect|intercept-only"
  )

  # The fence is family-specific ON PURPOSE: biv_gaussian legitimately fits
  # every one of these cells, and must be untouched by it.
  expect_null(drmTMB:::drm_julia_refuse_biv_lognormal_unsupported(
    drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ x, rho12 = ~ x),
    "biv_gaussian"
  ))
  # ... and the admitted cell itself passes the fence untouched.
  expect_null(drmTMB:::drm_julia_refuse_biv_lognormal_unsupported(
    drm_biv_lognormal_julia_formula(), "biv_lognormal"
  ))
  expect_null(drmTMB:::drm_julia_refuse_biv_lognormal_unsupported(
    drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x), "biv_lognormal"
  ))
})

# ---- live round trip (opt-in; skips only when the engine is absent) --------

drm_biv_lognormal_julia_roundtrip <- function() {
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
      ft <- drmTMB::drmTMB(form, family = drmTMB::biv_lognormal(), data = dat, engine = "tmb")
      fj <- drmTMB::drmTMB(form, family = drmTMB::biv_lognormal(), data = dat, engine = "julia")
      # DISCRIMINATING CONTROLS, fitted in the same session on the same draw:
      # (a) the same route on the RAW responses under biv_gaussian() -- a
      #     materially different target, so the oracle check below could fail;
      # (b) the same route on the LOGGED responses under biv_gaussian() --
      #     which must equal the biv_lognormal logLik MINUS the Jacobian, the
      #     sharpest available statement of where the scale lives.
      raw_gauss <- drmTMB::drmTMB(form, family = drmTMB::biv_gaussian(), data = dat, engine = "julia")
      logged <- data.frame(y1 = log(dat$y1), y2 = log(dat$y2), x = dat$x)
      log_gauss <- drmTMB::drmTMB(form, family = drmTMB::biv_gaussian(), data = logged, engine = "julia")
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
      dp <- function(f, d) as.numeric(stats::predict(f, dpar = d))
      list(
        class_julia = class(fj),
        model_type = fj$model$model_type,
        dpars = fj$model$dpars,
        engine = fj$engine,
        estimator = fj$estimator,
        estim_method = as.character(fj$bridge$estim_method),
        label_contract = fj$bridge_public_coef_labels$contract,
        public_labels = fj$bridge_public_coef_labels$public,
        coef_tmb = flat(ft), coef_julia = flat(fj),
        loglik_tmb = as.numeric(stats::logLik(ft)),
        loglik_julia = as.numeric(stats::logLik(fj)),
        se_tmb = se_of(ft), se_julia = se_of(fj),
        sigma1_coef_julia = unname(fj$coef_vector[["sigma1_(Intercept)"]]),
        sigma2_coef_julia = unname(fj$coef_vector[["sigma2_(Intercept)"]]),
        mu1_tmb = dp(ft, "mu1"), mu2_tmb = dp(ft, "mu2"),
        sigma1_tmb = dp(ft, "sigma1"), sigma2_tmb = dp(ft, "sigma2"),
        rho12_tmb = as.numeric(drmTMB::rho12(ft)),
        mu1_julia = dp(fj, "mu1"), mu2_julia = dp(fj, "mu2"),
        sigma1_julia = dp(fj, "sigma1"), sigma2_julia = dp(fj, "sigma2"),
        rho12_julia = as.numeric(drmTMB::rho12(fj)),
        loglik_raw_gauss = as.numeric(stats::logLik(raw_gauss)),
        loglik_log_gauss = as.numeric(stats::logLik(log_gauss)),
        y1 = dat$y1, y2 = dat$y2,
        converged = drmTMB::is_converged(fj),
        nobs = stats::nobs(fj)
      )
    },
    args = list(
      pkg = pkg, jl_path = jl_path,
      build = drm_biv_lognormal_julia_fixture,
      formula_fn = drm_biv_lognormal_julia_formula
    ),
    error = "stack"
  )
}

test_that("biv_lognormal fits through engine = 'julia' on the same target as engine = 'tmb'", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("pkgload")

  # A subprocess error is a FAILURE here, never a skip: the environment gates
  # above already cover the absent-engine case, so a refusal ("currently
  # supports Workflow G ...") or a DRM.jl-side abort ("coef_labels supplies
  # names for unknown dpar \"sigma\"") must surface as red.
  out <- drm_biv_lognormal_julia_roundtrip()

  expect_true("drmTMB_julia" %in% out$class_julia)
  expect_identical(out$model_type, "biv_lognormal")
  expect_identical(out$engine, "julia")
  expect_true(isTRUE(out$converged))
  expect_identical(out$nobs, 600L)
  expect_setequal(out$dpars, c("mu1", "mu2", "sigma1", "sigma2", "rho12"))
  expect_identical(out$label_contract, "bridge_formula_labels_v1")
  expect_setequal(
    out$public_labels,
    c("mu1_(Intercept)", "mu1_x", "mu2_(Intercept)", "mu2_x",
      "sigma1_(Intercept)", "sigma2_(Intercept)", "rho12_(Intercept)")
  )

  # Same target: coefficients matched BY NAME, then logLik.
  expect_setequal(names(out$coef_julia), names(out$coef_tmb))
  cj <- out$coef_julia[names(out$coef_tmb)]
  expect_lt(max(abs(cj - out$coef_tmb)), 1e-4)
  expect_lt(abs(out$loglik_julia - out$loglik_tmb), 1e-4)

  # SE axis: per-coefficient Wald SE, relative tolerance 1e-3 (tools/parity_se.R)
  expect_setequal(names(out$se_julia), names(out$se_tmb))
  sj <- out$se_julia[names(out$se_tmb)]
  expect_true(all(is.finite(sj)) && all(sj > 1e-6))
  expect_lt(max(abs(sj - out$se_tmb) / pmax(abs(sj), abs(out$se_tmb))), 1e-3)

  # THE SCALE CONTRACT.
  # (i) the dpars agree ACROSS engines on the transformed scale;
  expect_lt(max(abs(out$mu1_julia - out$mu1_tmb)), 1e-4)
  expect_lt(max(abs(out$mu2_julia - out$mu2_tmb)), 1e-4)
  expect_lt(max(abs(out$sigma1_julia - out$sigma1_tmb)), 1e-4)
  expect_lt(max(abs(out$sigma2_julia - out$sigma2_tmb)), 1e-4)
  expect_lt(max(abs(out$rho12_julia - out$rho12_tmb)), 1e-4)
  # (ii) sigma1/sigma2 are SDs of LOG y, reported on the response scale as the
  #      exponential of the log-link coefficient (so the coefficient itself is
  #      NOT the SD, and a reader of coef() cannot mistake the two);
  expect_equal(unique(out$sigma1_julia), exp(out$sigma1_coef_julia), tolerance = 1e-8)
  expect_equal(unique(out$sigma2_julia), exp(out$sigma2_coef_julia), tolerance = 1e-8)
  expect_true(all(out$sigma1_julia > 0) && all(out$sigma2_julia > 0))
  # (iii) mu lives on the LOG-response scale: with an intercept and a mean-zero
  #       covariate, the fitted mu1 averages to mean(log y1), NOT to mean(y1).
  expect_equal(mean(out$mu1_julia), mean(log(out$y1)), tolerance = 1e-6)
  expect_false(isTRUE(all.equal(mean(out$mu1_julia), mean(out$y1), tolerance = 1e-3)))
  # (iv) BOTH engines equal the INDEPENDENT raw-scale oracle, i.e. both carry
  #      the change-of-variables Jacobian -sum(log y1) - sum(log y2).
  oracle_julia <- drm_biv_lognormal_oracle(
    out$y1, out$y2, out$mu1_julia, out$mu2_julia,
    out$sigma1_julia, out$sigma2_julia, out$rho12_julia
  )
  oracle_tmb <- drm_biv_lognormal_oracle(
    out$y1, out$y2, out$mu1_tmb, out$mu2_tmb,
    out$sigma1_tmb, out$sigma2_tmb, out$rho12_tmb
  )
  expect_equal(out$loglik_julia, oracle_julia, tolerance = 1e-8)
  expect_equal(out$loglik_tmb, oracle_tmb, tolerance = 1e-8)

  # (v) DISCRIMINATING CONTROLS -- the oracle check above could have failed.
  jacobian <- -sum(log(out$y1)) - sum(log(out$y2))
  expect_gt(abs(jacobian), 1)
  # biv_gaussian on the RAW responses is a different target entirely.
  expect_gt(abs(out$loglik_raw_gauss - out$loglik_julia), 1)
  # biv_gaussian on the LOGGED responses is the SAME fit without the Jacobian.
  expect_equal(out$loglik_log_gauss, out$loglik_julia - jacobian, tolerance = 1e-6)

  # Estimator honesty (#1152): the label equals what the engine reports.
  expect_identical(out$estimator, "ML")
  expect_identical(toupper(out$estim_method), "ML")
})
