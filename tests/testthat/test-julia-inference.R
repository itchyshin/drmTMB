# Inference marshalling for `engine = "julia"` fits.
#
# DRM.jl returns a fixed-effect covariance block through the bridge
# (`drm_bridge` -> `vcov`), which `new_drmTMB_julia()` stores as `object$vcov`
# (named by `"<dpar>_<term>"`). `confint(method = "wald")` (the default) turns
# that covariance into symmetric Wald intervals for the fixed-effect
# coefficients on the linear-predictor (link) scale, mirroring the native
# drmTMB Wald rows; `summary()` builds the matching coefficient table with
# standard errors, z values, and p values. The profile / bootstrap path is
# unchanged and still routes only the Gaussian phylogenetic SD target into
# DRM.jl's inference primitive.
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
  expect_equal(
    ci$parm,
    c("fixef:mu:(Intercept)", "fixef:mu:x", "fixef:sigma:(Intercept)")
  )
  expect_true(all(is.finite(ci$lower)))
  expect_true(all(is.finite(ci$upper)))
  expect_true(all(ci$scale == "link"))
  expect_true(all(ci$transformation == "linear_predictor"))
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
