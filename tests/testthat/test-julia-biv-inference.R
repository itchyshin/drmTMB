# Profile / bootstrap interval targets for the RESIDUAL-ONLY bivariate Gaussian
# route through engine = "julia" (leaf A8b; capability row
# `biv_gaussian_residual`).
#
# Before this leaf, `drm_julia_wald_targets()` stamped `profile_ready = FALSE`
# on EVERY row of EVERY bivariate fit, so no parameter of this route had a
# profile or bootstrap target and `confint(method = "profile")` was refused
# R-side before any Julia call. The readiness rule is now a SPLIT: a bivariate
# fit carrying a covariance provider (tree / K / A / coords) is the structured
# route and stays not-ready; one carrying none is the residual route and is
# ready on the same precondition every univariate route uses.
#
# The unit tests below are offline. The live tests are gated by
# drm_skip_live_julia() and are the only ones that touch DRM.jl.

# A synthetic residual-only bivariate Julia fit: five coefficient blocks
# (mu1, mu2, sigma1, sigma2, rho12), a stored bridge payload, and NO covariance
# provider -- the shape `_fit_bivariate_residual` produces on the Julia side.
drm_julia_biv_residual_synthetic_fit <- function(payload_extra = list()) {
  coef_names <- c(
    "mu1_(Intercept)", "mu1_x",
    "mu2_(Intercept)", "mu2_x",
    "sigma1_(Intercept)", "sigma2_(Intercept)",
    "rho12_(Intercept)"
  )
  coefficients <- c(0.30, 0.50, -0.20, 0.80, -0.35, -0.69, 0.35)
  V <- diag(c(0.0025, 0.0044, 0.0013, 0.0022, 0.0028, 0.0028, 0.0056))
  dimnames(V) <- list(coef_names, coef_names)
  result <- list(
    coef_names = coef_names,
    coefficients = coefficients,
    vcov = V,
    loglik = -321.5,
    aic = 657.0,
    bic = 679.4,
    df = 7L,
    nobs = 180L,
    converged = TRUE,
    fitted = rep(0, 180L),
    residuals = rep(0, 180L),
    sigma = exp(-0.35),
    corpairs = list()
  )
  form <- drmTMB::bf(
    mu1 = y1 ~ x, mu2 = y2 ~ x,
    sigma1 = ~1, sigma2 = ~1, rho12 = ~1
  )
  data <- data.frame(y1 = rep(0, 180L), y2 = rep(0, 180L), x = rep(0, 180L))
  # Built without a `tree` element at all -- `list(tree = NULL)` would keep a
  # NULL entry that `$tree` partial-matches ahead of any provider added below.
  payload <- list(
    formula = list(
      mu1 = "y1 ~ x", mu2 = "y2 ~ x",
      sigma1 = "sigma1 ~ 1", sigma2 = "sigma2 ~ 1",
      rho12 = "rho12 ~ 1"
    ),
    data = data,
    options = list()
  )
  for (nm in names(payload_extra)) {
    payload[[nm]] <- payload_extra[[nm]]
  }
  drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, data = dat, engine = "julia")),
    formula = form,
    family = drmTMB::biv_gaussian(),
    data = data,
    family_type = "biv_gaussian",
    bridge_payload = payload
  )
}

test_that("a residual-only bivariate Julia fit reports every fixed-effect target as profile-ready", {
  fit <- drm_julia_biv_residual_synthetic_fit()
  expect_identical(fit$model$model_type, "biv_gaussian")
  targets <- drmTMB:::drm_julia_wald_targets(fit)

  expect_true(all(targets$profile_ready))
  expect_true(all(targets$profile_note == "ready"))
  # mu1, mu2 and rho12 all appear -- the three the leaf's gate names.
  expect_true(all(
    c("fixef:mu1:x", "fixef:mu2:x", "fixef:rho12:(Intercept)") %in% targets$parm
  ))
  expect_setequal(
    unique(targets$dpar),
    c("mu1", "mu2", "sigma1", "sigma2", "rho12")
  )
})

test_that("a bivariate fit carrying a covariance provider stays not-ready", {
  # The structured (q = 4 / q = 2) bivariate route's inference target is the
  # four among-axis SDs, not individual coefficients. Every provider spelling
  # must keep the fixed-effect rows closed -- a tree-only test would wrongly
  # admit the relmat / animal / spatial routes, which carry `matrix`+`kwarg`.
  providers <- list(
    tree = list(tree = "((sp1:1,sp2:1):1,sp3:2);"),
    matrix = list(matrix = diag(3), kwarg = "K"),
    coords = list(matrix = cbind(1:3, 1:3), kwarg = "coords")
  )
  for (nm in names(providers)) {
    fit <- drm_julia_biv_residual_synthetic_fit(payload_extra = providers[[nm]])
    targets <- drmTMB:::drm_julia_wald_targets(fit)
    expect_true(all(!targets$profile_ready), info = nm)
    expect_true(all(targets$profile_note == "missing_tmb_parameter"), info = nm)
  }
})

test_that("a bivariate fit with no bridge payload is still refused", {
  fit <- drm_julia_biv_residual_synthetic_fit()
  fit$bridge_payload <- NULL
  targets <- drmTMB:::drm_julia_wald_targets(fit)
  expect_true(all(!targets$profile_ready))
  expect_true(all(targets$profile_note == "julia_bridge_payload_required"))
})

test_that("the residual bivariate route contributes no duplicate SD rows", {
  # drm_julia_profile_targets_biv() must stay EMPTY here: a residual bivariate
  # fit has no random-effect SD, and the fixed-effect rows already come from
  # drm_julia_wald_targets(). Duplicating them would make the one-row target
  # match in drm_julia_validate_inference_targets() reject a valid `parm`.
  fit <- drm_julia_biv_residual_synthetic_fit()
  expect_equal(nrow(drmTMB:::drm_julia_profile_targets_biv(fit)), 0L)
  expect_equal(nrow(drmTMB:::drm_julia_profile_targets(fit)), 0L)

  union <- drmTMB:::drm_julia_profile_target_union(fit)
  expect_false(any(duplicated(union$parm)))
  for (p in c("fixef:mu1:x", "fixef:rho12:(Intercept)")) {
    matched <- drmTMB:::profile_match_confint_targets(union, p, fixed_only = FALSE)
    expect_equal(nrow(matched), 1L)
    expect_silent(drmTMB:::drm_julia_validate_inference_targets(matched))
  }
})

test_that("the target validator still refuses what the engine cannot profile", {
  fit <- drm_julia_biv_residual_synthetic_fit()
  union <- drmTMB:::drm_julia_profile_target_union(fit)

  # The response-scale sigma1 / sigma2 alias rows are Wald-only and must stay so.
  alias <- union[union$target_class == "distributional-scale", , drop = FALSE]
  expect_gt(nrow(alias), 0L)
  expect_true(all(!alias$profile_ready))
  # Refused by CLASS, before readiness is even consulted: it is neither a
  # fixed-effect coefficient nor an SD row, so it falls to the
  # supported-targets message. The point is that widening the fixed-effect
  # rule did not quietly widen this one.
  expect_error(
    drmTMB:::drm_julia_validate_inference_targets(alias[1L, , drop = FALSE]),
    "currently support one fixed-effect coefficient"
  )

  # A structured bivariate fixed-effect target is still refused, by note.
  structured <- drm_julia_biv_residual_synthetic_fit(
    payload_extra = list(matrix = diag(3), kwarg = "K")
  )
  row <- drmTMB:::drm_julia_wald_targets(structured)
  row <- row[row$parm == "fixef:mu1:x", , drop = FALSE]
  expect_error(
    drmTMB:::drm_julia_validate_inference_targets(row),
    "not ready for profile or bootstrap intervals"
  )
})

test_that("confint() routes a residual bivariate fixed-effect target to the Julia fixef entry point", {
  fit <- drm_julia_biv_residual_synthetic_fit()
  seen <- list()
  testthat::local_mocked_bindings(
    drm_julia_call_fixef_inference = function(
      object, target, method, level, R, seed, threads
    ) {
      seen[[length(seen) + 1L]] <<- list(
        dpar = target$dpar[[1L]], term = target$term[[1L]], method = method
      )
      list(
        lower = 0.19, upper = 0.46, estimate = 0.33, status = "profile",
        message = "profile_result completed", threaded = FALSE,
        worker_threads = 1L, julia_threads = 1L, blas_threads = 1L,
        elapsed = 0.1, used = 1L, failed = 0L, attempted = 1L
      )
    }
  )
  for (p in c("fixef:mu1:x", "fixef:rho12:(Intercept)")) {
    ci <- confint(fit, parm = p, method = "profile")
    expect_equal(nrow(ci), 1L)
    expect_equal(ci$parm, p)
    expect_true(is.finite(ci$lower) && is.finite(ci$upper))
    expect_equal(ci$profile.engine, "julia_profile_result")
  }
  expect_equal(length(seen), 2L)
  expect_equal(seen[[1L]]$dpar, "mu1")
  expect_equal(seen[[1L]]$term, "x")
  expect_equal(seen[[2L]]$dpar, "rho12")
  expect_equal(seen[[2L]]$term, "(Intercept)")
})

# --- live DRM.jl ------------------------------------------------------------

drm_julia_biv_residual_live_data <- function() {
  path <- file.path(
    drm_test_drmjl_path(), "test", "parity", "fixtures",
    "gaussian-bivariate-rho12", "data.csv"
  )
  if (!file.exists(path)) {
    testthat::skip("committed gaussian-bivariate-rho12 fixture not available")
  }
  utils::read.csv(path, stringsAsFactors = FALSE)
}

test_that("live: engine='julia' profiles and bootstraps the residual bivariate fixed effects", {
  drm_skip_live_julia()
  dat <- drm_julia_biv_residual_live_data()
  form <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
  fit_j <- drmTMB(form, family = biv_gaussian(), data = dat, engine = "julia")
  fit_t <- drmTMB(form, family = biv_gaussian(), data = dat, engine = "tmb")

  # Estimator honesty: the oracle read, not the absence of an abort.
  expect_identical(fit_j$estimator, fit_j$bridge$estim_method)

  targets <- profile_targets(fit_j)
  ready <- targets[targets$profile_ready, , drop = FALSE]
  expect_true(all(
    c("fixef:mu1:x", "fixef:mu2:x", "fixef:rho12:(Intercept)") %in% ready$parm
  ))

  for (p in c("fixef:mu1:x", "fixef:rho12:(Intercept)")) {
    prof_j <- confint(fit_j, parm = p, method = "profile")
    prof_t <- confint(fit_t, parm = p, method = "profile")
    expect_true(is.finite(prof_j$lower) && is.finite(prof_j$upper))
    expect_lt(prof_j$lower, prof_j$upper)
    expect_equal(prof_j$conf.status, "profile")
    # Same-target agreement with the native engine on the committed fixture.
    expect_lt(abs(prof_j$lower - prof_t$lower), 1e-4)
    expect_lt(abs(prof_j$upper - prof_t$upper), 1e-4)

    boot_j <- confint(
      fit_j, parm = p, method = "bootstrap", R = 40L, seed = 20260905L
    )
    expect_true(is.finite(boot_j$lower) && is.finite(boot_j$upper))
    expect_lt(boot_j$lower, boot_j$upper)
    expect_equal(boot_j$bootstrap.failed, 0L)
    expect_equal(boot_j$bootstrap.n, 40L)
  }
})
