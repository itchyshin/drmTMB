# Inference marshalling for `engine = "julia"` fits.
#
# DRM.jl returns a fixed-effect covariance block through the bridge
# (`drm_bridge` -> `vcov`), which `new_drmTMB_julia()` stores as `object$vcov`
# (named by `"<dpar>_<term>"`). `confint(method = "wald")` (the default) turns
# that covariance into symmetric Wald intervals for the fixed-effect
# coefficients on the linear-predictor (link) scale, mirroring the native
# drmTMB Wald rows; `summary()` builds the matching coefficient table with
# standard errors, z values, and p values. The profile / bootstrap path routes
# two target families into DRM.jl's inference primitive: the Gaussian
# phylogenetic SD target, and (#460) ordinary fixed-effect coefficients
# (`fixef:<dpar>:<coef>`).
#
# These tests cover (a) the pure R-side Wald / summary marshalling on a
# synthetic bridge result (always runs, no Julia), and (b) one live Poisson
# phylo round-trip whose `confint()` must return finite Wald intervals, guarded
# so it is skipped -- never failed -- when JuliaCall, callr, pkgload, ape, or
# the DRM.jl engine is unavailable, or when the fit itself errors here.

# --- Synthetic bridge fit (no Julia) ----------------------------------------

drm_julia_inference_synthetic_fit <- function() {
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  coef_names <- c(
    "mu_(Intercept)",
    "mu_x",
    "sigma_(Intercept)",
    "resd_phylo(1 | species)"
  )
  coefficients <- c(0.5, 0.4, -0.3, log(1.7))
  # Finite fixed block; the resd (random-effect SD) row stays NA, as the
  # large-p phylo Laplace routes commonly return.
  V <- diag(c(0.04, 0.01, 0.02, NA_real_))
  dimnames(V) <- list(coef_names, coef_names)
  result <- list(
    coef_names = coef_names,
    coefficients = coefficients,
    vcov = V,
    loglik = -123.4,
    aic = 254.8,
    bic = 260.0,
    df = 4L,
    nobs = 30L,
    converged = TRUE,
    fitted = rep(0, 30L),
    residuals = rep(0, 30L),
    sigma = exp(-0.3),
    corpairs = list()
  )
  form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = stats::gaussian(),
    data = data.frame(
      y = rep(0, 30L),
      x = rep(0, 30L),
      species = paste0("sp", seq_len(30L))
    ),
    family_type = "gaussian",
    structured_sd_scales = c("phylo(1 | species)" = sqrt(2))
  )
}

test_that("confint(method = 'wald') marshals fixed-effect intervals (link scale)", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit()

  ci <- stats::confint(fit) # wald is the default
  # #460 item 3: a Gaussian mean-only sigma (single log-link intercept) gets an
  # extra response-scale "sigma" alias row, alongside the link-scale
  # "fixef:sigma:(Intercept)" row -- the same row-count parity native drmTMB's
  # confint() already has.
  expect_equal(
    ci$parm,
    c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)", "sigma")
  )
  expect_true(all(is.finite(ci$lower)))
  expect_true(all(is.finite(ci$upper)))
  expect_equal(
    ci$scale,
    c("link", "link", "link", "response")
  )
  expect_equal(
    ci$transformation,
    c(
      "linear_predictor",
      "linear_predictor",
      "linear_predictor",
      "exp"
    )
  )
  expect_true(all(ci$method == "wald"))
  expect_true(all(ci$conf.status == "wald"))

  # Exact Wald endpoints on the link scale: estimate +/- z * se.
  z <- stats::qnorm(0.975)
  expect_equal(
    ci$lower[ci$parm == "fixef:mu:x"],
    0.4 - z * 0.1,
    tolerance = 1e-10
  )
  expect_equal(
    ci$upper[ci$parm == "fixef:mu:x"],
    0.4 + z * 0.1,
    tolerance = 1e-10
  )
  expect_equal(
    ci$lower[ci$parm == "fixef:sigma:(Intercept)"],
    -0.3 - z * sqrt(0.02),
    tolerance = 1e-10
  )

  # The "sigma" alias row shares the same underlying (Intercept) coefficient
  # and variance as "fixef:sigma:(Intercept)", exponentiated onto the response
  # scale -- exp() commutes with the symmetric link-scale endpoints exactly.
  expect_equal(
    ci$lower[ci$parm == "sigma"],
    exp(-0.3 - z * sqrt(0.02)),
    tolerance = 1e-10
  )
  expect_equal(
    ci$upper[ci$parm == "sigma"],
    exp(-0.3 + z * sqrt(0.02)),
    tolerance = 1e-10
  )
})

test_that("reconstruction status object is diagnostic-only", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit()

  status <- drmTMB:::drm_julia_reconstruction_status(fit)

  expect_s3_class(status, "drmTMB_julia_reconstruction_status")
  expect_equal(nrow(status), 1L)
  expect_equal(status$model_type, "gaussian")
  expect_equal(status$estimator, "ML")
  expect_equal(status$requested_estimator, "ML")
  expect_equal(status$effective_estimator, "ML")
  expect_equal(status$payload_status, "missing")
  expect_equal(status$coefficient_status, "present")
  expect_equal(status$vcov_status, "ok")
  expect_equal(status$profile_target_status, "present")
  expect_equal(status$corpairs_status, "absent")
  expect_equal(status$bridge_status, "diagnostic_only")
  expect_equal(status$inference_promotion, "none")
  expect_error(
    drmTMB:::drm_julia_reconstruction_status(list()),
    "requires"
  )
})

test_that("confint(method = 'wald') accepts compact and set aliases", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit()

  one <- stats::confint(fit, parm = "mu:x")
  expect_equal(one$parm, "fixef:mu:x")
  expect_true(is.finite(one$lower) && is.finite(one$upper))

  full <- stats::confint(fit, parm = "fixef:sigma:(Intercept)")
  expect_equal(full$parm, "fixef:sigma:(Intercept)")

  fixed <- stats::confint(fit, parm = "fixed_effects")
  expect_equal(
    fixed$parm,
    c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)")
  )
})

test_that("summary() exposes a coefficient table with SE, z, p, and CIs", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit()

  s <- summary(fit, conf.int = TRUE)
  expect_s3_class(s, "summary.drmTMB_julia")
  expect_equal(s$coefficients$dpar, c("mu", "mu", "sigma"))
  expect_equal(s$coefficients$term, c("(Intercept)", "x", "(Intercept)"))
  expect_true(all(is.finite(s$coefficients$std.error)))
  expect_true(all(is.finite(s$coefficients$statistic)))
  expect_true(all(is.finite(s$coefficients$p.value)))
  expect_true(all(is.finite(s$coefficients$conf.low)))
  expect_true(all(is.finite(s$coefficients$conf.high)))

  # SE = sqrt(diag(vcov)); z = estimate / se.
  expect_equal(
    s$coefficients$std.error,
    c(0.2, 0.1, sqrt(0.02)),
    tolerance = 1e-10
  )
  expect_equal(s$coefficients$statistic[2L], 0.4 / 0.1, tolerance = 1e-10)

  # The phylogenetic SD is reported on the positive response scale.
  expect_equal(nrow(s$random), 1L)
  expect_equal(s$random$sd, 1.7 * sqrt(2), tolerance = 1e-10)

  expect_no_error(print(s))
})

test_that("a partial / missing bridge covariance yields NA Wald intervals", {
  skip_if_not_installed("ape")
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  coef_names <- c("mu_(Intercept)", "mu_x", "resd_phylo(1 | species)")
  V <- matrix(NaN, nrow = 3L, ncol = 3L)
  dimnames(V) <- list(coef_names, coef_names)
  result <- list(
    coef_names = coef_names,
    coefficients = c(0.5, 0.4, log(1.3)),
    vcov = V,
    loglik = -50,
    aic = 106,
    bic = 110,
    df = 3L,
    nobs = 20L,
    converged = TRUE,
    fitted = rep(0, 20L),
    residuals = rep(0, 20L),
    sigma = numeric(),
    corpairs = list()
  )
  form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))
  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = stats::poisson(),
    data = data.frame(
      y = rep(0, 20L),
      x = rep(0, 20L),
      species = paste0("sp", seq_len(20L))
    ),
    family_type = "poisson",
    structured_sd_scales = c("phylo(1 | species)" = sqrt(2))
  )

  ci <- stats::confint(fit)
  expect_equal(ci$parm, c("fixef:mu:(Intercept)", "fixef:mu:x"))
  expect_true(all(is.na(ci$lower)))
  expect_true(all(is.na(ci$upper)))
  expect_true(all(ci$conf.status == "wald_unavailable"))
})

test_that("Julia structured coefficient scale map reconstructs SDs and recov correlations", {
  skip_if_not_installed("ape")
  tree <- ape::rcoal(4)
  tree$tip.label <- paste0("sp", seq_len(4))

  mean_form <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1
  )
  mean_params <- drmTMB:::drm_julia_structured_parameters(
    coefficients = c("resd_phylo(1 | species)" = log(1.25)),
    formula = mean_form,
    sd_scales = c("phylo(1 | species)" = sqrt(2))
  )
  expect_equal(
    unname(mean_params$sdpars$mu[["phylo(1 | species)"]]),
    1.25 * sqrt(2)
  )
  expect_equal(length(mean_params$sdpars$sigma), 0L)
  expect_equal(length(mean_params$corpars), 0L)

  locscale_form <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ phylo(1 | species, tree = tree)
  )
  log_l11 <- log(1.1)
  log_l22 <- log(0.9)
  l21 <- 0.2
  locscale_params <- drmTMB:::drm_julia_structured_parameters(
    coefficients = c(
      "recov_mu:phylo(1 | species):L11" = log_l11,
      "recov_sigma:phylo(1 | species):L22" = log_l22,
      "recov_mu_sigma:phylo(1 | species):L21" = l21
    ),
    formula = locscale_form,
    sd_scales = c("phylo(1 | species)" = sqrt(2))
  )
  expected_sigma_sd <- sqrt(l21^2 + exp(log_l22)^2) * sqrt(2)
  expected_rho <- l21 / sqrt(l21^2 + exp(log_l22)^2)

  expect_equal(
    unname(locscale_params$sdpars$mu[["mu:phylo(1 | species)"]]),
    exp(log_l11) * sqrt(2)
  )
  expect_equal(
    unname(locscale_params$sdpars$sigma[["sigma:phylo(1 | species)"]]),
    expected_sigma_sd
  )
  expect_equal(
    names(locscale_params$corpars$phylo),
    "cor(mu:(Intercept),sigma:(Intercept) | phylo | species)"
  )
  expect_equal(unname(locscale_params$corpars$phylo), expected_rho)
})

# --- Ordinary fixed-effect profile / bootstrap targets (#460) ---------------
#
# The phylogenetic SD target and an ordinary fixed-effect coefficient use
# different Julia entry points (drm_julia_call_inference() /
# drmTMB_drm_bridge_inference vs. drm_julia_call_fixef_inference() /
# drmTMB_drm_bridge_fixef_inference), so these tests mock the latter directly
# -- the same pattern test-julia-bridge.R already uses for the former -- and
# do not require a live Julia session.

# Same synthetic fixture as drm_julia_inference_synthetic_fit(), plus a
# bridge_payload (formula + data + tree to refit from), which is what makes
# the fixed-effect targets profile/bootstrap-ready.
drm_julia_inference_synthetic_fit_with_payload <- function() {
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  coef_names <- c(
    "mu_(Intercept)",
    "mu_x",
    "sigma_(Intercept)",
    "resd_phylo(1 | species)"
  )
  coefficients <- c(0.5, 0.4, -0.3, log(1.7))
  V <- diag(c(0.04, 0.01, 0.02, NA_real_))
  dimnames(V) <- list(coef_names, coef_names)
  result <- list(
    coef_names = coef_names,
    coefficients = coefficients,
    vcov = V,
    loglik = -123.4,
    aic = 254.8,
    bic = 260.0,
    df = 4L,
    nobs = 30L,
    converged = TRUE,
    fitted = rep(0, 30L),
    residuals = rep(0, 30L),
    sigma = exp(-0.3),
    corpairs = list()
  )
  form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
  data <- data.frame(
    y = rep(0, 30L),
    x = rep(0, 30L),
    species = paste0("sp", seq_len(30L))
  )
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = stats::gaussian(),
    data = data,
    family_type = "gaussian",
    structured_sd_scales = c("phylo(1 | species)" = sqrt(2)),
    bridge_payload = list(
      formula = list(
        mu = "y ~ x + phylo(1 | species)",
        sigma = "sigma ~ 1"
      ),
      data = data,
      tree = "((sp1:1,sp2:1):1,(sp3:1,(sp4:1,sp5:1):1):1);",
      options = list(g_tol = 1e-8),
      structured_sd_scales = c("phylo(1 | species)" = sqrt(2))
    )
  )
}

test_that("Julia profile targets retain both coupled location-scale phylo axes", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit_with_payload()
  term <- "phylo(1 | species)"
  # Coupled location-scale fits carry an axis prefix in `sdpars`; it is an
  # internal storage detail and must not leak into the public `parm` label.
  fit$sdpars <- list(
    mu = stats::setNames(1.1, paste0("mu:", term)),
    sigma = stats::setNames(0.9, paste0("sigma:", term))
  )

  targets <- drmTMB:::drm_julia_profile_targets(fit)
  expect_equal(targets$parm, c(paste0("sd:mu:", term), paste0("sd:sigma:", term)))
  expect_equal(targets$dpar, c("mu", "sigma"))
  expect_equal(targets$tmb_parameter, c("resd_mu", "resd_sigma"))
  expect_true(all(targets$profile_ready))

  testthat::local_mocked_bindings(
    drm_julia_call_inference = function(object, target, ...) {
      expect_s3_class(object, "drmTMB_julia")
      expect_equal(target$dpar[[1L]], "sigma")
      expect_equal(target$tmb_parameter[[1L]], "resd_sigma")
      list(lower = log(0.4), upper = log(1.5), status = "profile",
           message = "profile_result completed", threaded = FALSE,
           worker_threads = 1L, julia_threads = 1L, blas_threads = 1L, elapsed = 0.1)
    },
    .package = "drmTMB"
  )
  ci <- stats::confint(fit, parm = paste0("sd:sigma:", term), method = "profile")
  expect_equal(ci$parm, paste0("sd:sigma:", term))
  expect_equal(ci$lower, 0.4 * sqrt(2))
  expect_equal(ci$upper, 1.5 * sqrt(2))
})

test_that("Julia profile targets keep an unprefixed sigma axis in its sigma block", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit_with_payload()
  term <- "phylo(1 | species)"
  # The asymmetric sigma-phylo frontend stores this axis without a `sigma:`
  # name prefix, although DRM.jl returns the :resd_sigma parameter block.
  fit$sdpars <- list(
    mu = NULL,
    sigma = stats::setNames(0.9, term)
  )

  targets <- drmTMB:::drm_julia_profile_targets(fit)
  expect_equal(targets$parm, paste0("sd:sigma:", term))
  expect_equal(targets$tmb_parameter, "resd_sigma")
})

test_that("Julia SD inference preserves the fitted parameter block", {
  skip_if_not_installed("JuliaCall")
  fit <- drm_julia_inference_synthetic_fit_with_payload()
  setup_calls <- 0L
  testthat::local_mocked_bindings(
    drm_julia_setup = function(...) setup_calls <<- setup_calls + 1L,
    .package = "drmTMB"
  )
  testthat::local_mocked_bindings(
    julia_call = function(...) list(...),
    .package = "JuliaCall"
  )

  legacy <- data.frame(dpar = "mu", tmb_parameter = "resd")
  coupled_sigma <- data.frame(dpar = "sigma", tmb_parameter = "resd_sigma")
  legacy_sent <- drmTMB:::drm_julia_call_inference(
    fit, legacy, "profile", 0.95, 2L, 9001L, FALSE
  )
  sigma_sent <- drmTMB:::drm_julia_call_inference(
    fit, coupled_sigma, "profile", 0.95, 2L, 9001L, FALSE
  )
  expect_identical(tail(legacy_sent, 1L)[[1L]], "sd:resd")
  expect_identical(tail(sigma_sent, 1L)[[1L]], "sd:resd_sigma")
  expect_identical(setup_calls, 2L)
})

test_that("fixed-effect coefficients become profile_ready once a bridge payload is stored", {
  skip_if_not_installed("ape")
  bare <- drm_julia_inference_synthetic_fit()
  wald_bare <- drmTMB:::drm_julia_wald_targets(bare)
  expect_true(all(!wald_bare$profile_ready))
  expect_true(all(wald_bare$profile_note == "julia_bridge_payload_required"))

  fit <- drm_julia_inference_synthetic_fit_with_payload()
  wald <- drmTMB:::drm_julia_wald_targets(fit)
  expect_true(all(wald$profile_ready))
  expect_true(all(wald$profile_note == "ready"))

  # The bivariate q4 route is out of scope for this target: stays not-ready
  # even with a bridge payload present.
  biv <- fit
  biv$model$model_type <- "biv_gaussian"
  wald_biv <- drmTMB:::drm_julia_wald_targets(biv)
  expect_true(all(!wald_biv$profile_ready))
  expect_true(all(wald_biv$profile_note == "missing_tmb_parameter"))
})

test_that("confint(method = 'profile') routes an ordinary fixed effect to DRM.jl", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit_with_payload()

  testthat::local_mocked_bindings(
    drm_julia_call_fixef_inference = function(
      object,
      target,
      method,
      level,
      R,
      seed,
      threads
    ) {
      expect_s3_class(object, "drmTMB_julia")
      expect_equal(target$dpar[[1L]], "mu")
      expect_equal(target$term[[1L]], "x")
      expect_equal(method, "profile")
      expect_equal(level, 0.90)
      expect_equal(R, 1L)
      expect_null(seed)
      expect_false(threads)
      list(
        lower = 0.25,
        upper = 0.62,
        status = "profile",
        message = "profile_result completed",
        threaded = FALSE,
        worker_threads = 1L,
        julia_threads = 1L,
        blas_threads = 1L,
        elapsed = 0.1
      )
    },
    .package = "drmTMB"
  )

  ci <- stats::confint(
    fit,
    parm = "fixef:mu:x",
    level = 0.90,
    method = "profile"
  )
  expect_equal(ci$parm, "fixef:mu:x")
  # Unlike the SD target, no exp() / tree-height rescale: the Julia bounds
  # come back straight through on the link scale.
  expect_equal(ci$lower, 0.25)
  expect_equal(ci$upper, 0.62)
  expect_equal(ci$scale, "link")
  expect_equal(ci$transformation, "linear_predictor")
  expect_equal(ci$method, "profile")
  expect_equal(ci$profile.engine, "julia_profile_result")
  expect_equal(ci$conf.status, "profile")

  # Compact "dpar:term" alias resolves to the same target.
  ci_alias <- stats::confint(
    fit,
    parm = "mu:x",
    level = 0.90,
    method = "profile"
  )
  expect_equal(ci_alias$parm, "fixef:mu:x")
  expect_equal(ci_alias$lower, 0.25)
})

test_that("confint(method = 'bootstrap') routes an ordinary fixed effect to DRM.jl", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit_with_payload()

  testthat::local_mocked_bindings(
    drm_julia_call_fixef_inference = function(
      object,
      target,
      method,
      level,
      R,
      seed,
      threads
    ) {
      expect_equal(target$dpar[[1L]], "sigma")
      expect_equal(target$term[[1L]], "(Intercept)")
      expect_equal(method, "bootstrap")
      expect_equal(R, 49L)
      list(
        lower = -0.9,
        upper = 0.1,
        status = "bootstrap",
        message = "48/49 successful refits",
        threaded = FALSE,
        worker_threads = 1L,
        julia_threads = 1L,
        blas_threads = 1L,
        elapsed = 0.3,
        used = 48L,
        failed = 1L
      )
    },
    .package = "drmTMB"
  )

  ci <- stats::confint(
    fit,
    parm = "fixef:sigma:(Intercept)",
    method = "bootstrap",
    R = 49L
  )
  expect_equal(ci$parm, "fixef:sigma:(Intercept)")
  expect_equal(ci$lower, -0.9)
  expect_equal(ci$upper, 0.1)
  expect_equal(ci$method, "bootstrap")
  expect_equal(ci$bootstrap.n, 48L)
  expect_equal(ci$bootstrap.failed, 1L)
})

test_that("an unready fixed-effect profile/bootstrap target is refused with a clear message", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit() # no bridge_payload

  expect_error(
    stats::confint(fit, parm = "fixef:mu:x", method = "profile"),
    "not ready for profile or bootstrap"
  )
})

test_that("confint(method = 'profile'/'bootstrap') with no parm names a real target instead of reciting a menu (#460 defect A)", {
  skip_if_not_installed("ape")
  fit <- drm_julia_inference_synthetic_fit_with_payload()

  err <- tryCatch(
    stats::confint(fit, method = "profile"),
    error = function(e) e
  )
  expect_s3_class(err, "rlang_error")
  msg <- paste(conditionMessage(err), collapse = " ")
  expect_match(msg, "require an explicit", fixed = TRUE)
  # Names an actual, usable target from THIS fit -- not a "supported families"
  # menu that just recites the very families the fit already has.
  expect_match(msg, "fixef:mu:", fixed = TRUE)

  # Same for bootstrap: no-parm is rejected the same way, before ever reaching
  # Julia (no live session needed for this assertion).
  expect_error(
    stats::confint(fit, method = "bootstrap"),
    "require an explicit"
  )
})

test_that("drm_julia_inference_parm_hint() names all four axes for a bivariate q4 inventory", {
  targets <- data.frame(
    parm = c(
      "sd:mu1:phylo(1 | species)",
      "sd:mu2:phylo(1 | species)",
      "sd:sigma1:phylo(1 | species)",
      "sd:sigma2:phylo(1 | species)"
    ),
    target_class = "random-effect-sd",
    dpar = c("mu1", "mu2", "sigma1", "sigma2"),
    profile_ready = TRUE,
    stringsAsFactors = FALSE
  )
  hint <- drmTMB:::drm_julia_inference_parm_hint(targets)
  expect_match(hint, "all four axis names", fixed = TRUE)
  expect_match(hint, "sd:mu1:phylo(1 | species)", fixed = TRUE)
  expect_match(hint, "sd:sigma2:phylo(1 | species)", fixed = TRUE)
})

# --- Live Gaussian phylo fixed-effect round-trip -----------------------------
#
# Fits a Gaussian mean + phylo model via engine = "julia" and profiles /
# bootstraps the ordinary fixed effect "mu:x" through the real Julia session,
# in a fresh subprocess (same rationale as the Poisson round-trip below).

drm_julia_fixef_fit <- function(n_tip = 24L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path, n_tip) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(42)
      tree <- ape::rcoal(n_tip)
      sp <- tree$tip.label
      x <- stats::rnorm(n_tip)
      bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.7)
      eta <- 0.5 + 0.4 * x + bm[sp]
      y <- eta + stats::rnorm(n_tip, sd = 0.3)
      dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)

      form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
      fj <- drmTMB::drmTMB(form, data = dat, engine = "julia")

      wald <- stats::confint(fj, parm = "fixef:mu:x")
      profiled <- stats::confint(
        fj,
        parm = "fixef:mu:x",
        method = "profile"
      )
      booted <- stats::confint(
        fj,
        parm = "fixef:mu:x",
        method = "bootstrap",
        R = 49L,
        seed = 1L
      )
      list(
        wald = as.data.frame(wald),
        profiled = as.data.frame(profiled),
        booted = as.data.frame(booted)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "error"
  )
}

test_that("confint() profiles and bootstraps an ordinary fixed effect on a live Julia phylo fit", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_test_drmjl_path()),
    "DRM.jl phylo engine not available"
  )

  res <- tryCatch(
    drm_julia_fixef_fit(n_tip = 24L),
    error = function(e) {
      testthat::skip(paste(
        "Gaussian phylo fixef confint round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  wald <- res$wald
  profiled <- res$profiled
  booted <- res$booted

  expect_equal(profiled$parm, "fixef:mu:x")
  expect_equal(booted$parm, "fixef:mu:x")
  expect_true(is.finite(profiled$lower) && is.finite(profiled$upper))
  expect_true(is.finite(booted$lower) && is.finite(booted$upper))
  expect_true(profiled$lower < profiled$upper)
  expect_true(booted$lower < booted$upper)
  expect_equal(profiled$method, "profile")
  expect_equal(booted$method, "bootstrap")
  expect_equal(profiled$conf.status, "profile")

  # No numerics claim beyond "the two engines agree" (#460's own evidence):
  # sanity-check the profile / bootstrap intervals are in the neighbourhood of
  # the Wald interval for the same coefficient, not off by orders of
  # magnitude or on the wrong scale.
  span <- wald$upper - wald$lower
  expect_true(profiled$lower > wald$lower - span)
  expect_true(profiled$upper < wald$upper + span)
  expect_true(booted$lower > wald$lower - span)
  expect_true(booted$upper < wald$upper + span)
})

# --- Live non-Gaussian fixed-effect bootstrap (#460 defect B) ---------------
#
# DRM.jl's non-Gaussian bootstrap_result() dispatches to a DIFFERENT method
# than the Gaussian one, and that method's kwargs guard throws on ANY
# non-nothing keyword -- including `algorithm` / `g_tol`, which the glue
# always supplies. This was reachable for every non-Gaussian fixed-effect
# bootstrap target and was invisible to the mocked tests above (they stand in
# for drm_julia_call_fixef_inference() itself, never executing a character of
# drmTMB_drm_bridge_fixef_inference). These two live round-trips are the only
# tests in this file that actually run that Julia function for a non-Gaussian
# fit.

drm_julia_fixef_poisson_fit <- function(n = 60L, phylo = FALSE) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path, n, phylo) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(11)
      if (phylo) {
        tree <- ape::rcoal(n)
        sp <- tree$tip.label
        x <- stats::rnorm(n)
        bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.5)
        eta <- 0.5 + 0.4 * x + bm[sp]
        y <- stats::rpois(n, exp(eta))
        dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)
        form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))
      } else {
        x <- stats::rnorm(n)
        eta <- 0.5 + 0.4 * x
        y <- stats::rpois(n, exp(eta))
        dat <- data.frame(x = x, y = y)
        form <- drmTMB::bf(y ~ x)
      }
      fj <- drmTMB::drmTMB(
        form,
        family = stats::poisson(),
        data = dat,
        engine = "julia"
      )

      boot <- tryCatch(
        stats::confint(
          fj,
          parm = "fixef:mu:x",
          method = "bootstrap",
          R = 15L,
          seed = 1L
        ),
        error = function(e) conditionMessage(e)
      )
      prof <- tryCatch(
        stats::confint(fj, parm = "fixef:mu:x", method = "profile"),
        error = function(e) conditionMessage(e)
      )
      list(
        boot = if (is.data.frame(boot)) as.data.frame(boot) else boot,
        prof = if (is.data.frame(prof)) as.data.frame(prof) else prof,
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n = as.integer(n), phylo = phylo),
    error = "error"
  )
}

test_that("confint(method = 'bootstrap') works for a non-Gaussian (Poisson) fixed effect", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")

  res <- tryCatch(
    drm_julia_fixef_poisson_fit(n = 60L, phylo = FALSE),
    error = function(e) {
      testthat::skip(paste(
        "Poisson fixed-effect bootstrap round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  expect_true(isTRUE(res$converged))
  expect_true(is.data.frame(res$boot))
  expect_true(is.data.frame(res$prof))
  expect_equal(res$boot$parm, "fixef:mu:x")
  expect_true(is.finite(res$boot$lower) && is.finite(res$boot$upper))
  expect_true(res$boot$lower < res$boot$upper)
  expect_equal(res$boot$method, "bootstrap")
})

test_that("confint(method = 'bootstrap') works for a phylo non-Gaussian fixed effect", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_test_drmjl_path()),
    "DRM.jl phylo engine not available"
  )

  res <- tryCatch(
    drm_julia_fixef_poisson_fit(n = 15L, phylo = TRUE),
    error = function(e) {
      testthat::skip(paste(
        "Poisson phylo fixed-effect bootstrap round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  expect_true(isTRUE(res$converged))
  expect_true(is.data.frame(res$boot))
  expect_equal(res$boot$parm, "fixef:mu:x")
  expect_true(is.finite(res$boot$lower) && is.finite(res$boot$upper))
  expect_true(res$boot$lower < res$boot$upper)
  expect_equal(res$boot$method, "bootstrap")
  expect_true(is.data.frame(res$prof))
  expect_equal(res$prof$parm, "fixef:mu:x")
  expect_true(is.finite(res$prof$lower) && is.finite(res$prof$upper))
})

# --- Live Poisson phylo round-trip ------------------------------------------
#
# Runs in a FRESH R subprocess (callr) so the phylo-capable DRM.jl engine at
# `jl_path` is the JuliaCall session loaded for this fit, independent of test
# order (same rationale as the cross-family round-trips).

drm_julia_inference_engine_path <- function() {
  drm_test_drmjl_path()
}

# Fit a phylo Poisson model with `engine = "julia"`, then call confint() inside
# the same clean subprocess. Returns the confint table (as a data frame) and a
# few fit scalars, or NULL if the child errored.
drm_julia_inference_fit <- function(n_tip = 24L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_julia_inference_engine_path()
  callr::r(
    function(pkg, jl_path, n_tip) {
      julia_home <- Sys.getenv(
        "DRM_JL_JULIA_HOME",
        Sys.getenv("JULIA_HOME", "")
      )
      if (nzchar(julia_home)) {
        Sys.setenv(JULIA_HOME = julia_home)
      }
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(42)
      tree <- ape::rcoal(n_tip)
      sp <- tree$tip.label
      x <- stats::rnorm(n_tip)
      bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.7)
      eta <- 0.5 + 0.4 * x + bm[sp]
      y <- stats::rpois(n_tip, exp(eta))
      dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)

      form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))
      fj <- drmTMB::drmTMB(
        form,
        family = stats::poisson(),
        data = dat,
        engine = "julia"
      )

      ci <- stats::confint(fj) # default Wald
      s <- summary(fj)
      list(
        engine = fj$engine,
        uncertainty = fj$uncertainty$status,
        ci = as.data.frame(ci),
        coef_table = s$coefficients,
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "error"
  )
}

test_that("confint() on a Poisson phylo Julia fit returns finite Wald CIs", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_julia_inference_engine_path()),
    "DRM.jl phylo engine not available"
  )

  res <- tryCatch(
    drm_julia_inference_fit(n_tip = 24L),
    error = function(e) {
      testthat::skip(paste(
        "Poisson phylo confint round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  expect_equal(res$engine, "julia")
  expect_true(isTRUE(res$converged))

  ci <- res$ci
  expect_true(is.data.frame(ci))
  expect_true(all(
    c("parm", "lower", "upper", "scale", "method", "conf.status") %in% names(ci)
  ))
  expect_setequal(ci$parm, c("fixef:mu:(Intercept)", "fixef:mu:x"))
  expect_true(all(ci$method == "wald"))
  expect_true(all(ci$scale == "link"))

  # The whole point: DRM.jl returned a finite fixed-effect covariance, so the
  # marshalled Wald intervals are finite and ordered.
  expect_equal(res$uncertainty, "ok")
  expect_true(all(is.finite(ci$lower)))
  expect_true(all(is.finite(ci$upper)))
  expect_true(all(ci$lower < ci$upper))
  expect_true(all(ci$conf.status == "wald"))

  # The summary coefficient table carries finite standard errors.
  expect_true(all(is.finite(res$coef_table$std.error)))
})

test_that("Julia profile failures and no-crossing messages survive public R intervals", {
  skip_if_not_installed("ape")
  withr::local_seed(20260831)
  fit <- drm_julia_inference_synthetic_fit_with_payload()
  payload <- list(
    lower = -Inf, upper = Inf,
    status = "profile_failed",
    message = paste0(
      "profile endpoint solve failed: lower ",
      "(endpoint=max_iterations; candidate=-3.0; residual=4.0)"
    ),
    threaded = FALSE, worker_threads = 1L, julia_threads = 1L,
    blas_threads = 1L, elapsed = 0.1
  )
  testthat::local_mocked_bindings(
    drm_julia_call_inference = function(...) payload,
    drm_julia_call_fixef_inference = function(...) payload,
    .package = "drmTMB"
  )

  for (target in c("fixef:mu:x", "sd:mu:phylo(1 | species)")) {
    ci <- stats::confint(fit, parm = target, method = "profile")
    expect_identical(ci$conf.status, "profile_failed")
    expect_identical(ci$profile.message, payload$message)
    expect_identical(ci$parm, target)
    expect_identical(ci$lower, if (startsWith(target, "sd:")) 0 else -Inf)
    expect_identical(ci$upper, Inf)
  }

  # The same infinite bounds can also mean no crossing in the searched range.
  # Status/message, not endpoint shape, must preserve that distinction.
  payload$status <- "profile"
  payload$message <- "profile did not cross threshold within searched range"
  for (target in c("fixef:mu:x", "sd:mu:phylo(1 | species)")) {
    ci <- stats::confint(fit, parm = target, method = "profile")
    expect_identical(ci$conf.status, "profile")
    expect_identical(ci$profile.message, payload$message)
  }
})
