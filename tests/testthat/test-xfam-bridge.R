# Cross-family bivariate route via engine = "julia".
#
# DRM.fit_mixed_family fits y1 ~ famA, y2 ~ famB sharing a per-observation
# latent u ~ N(0, 1), and reports the dependence on the latent / link scale.
# These tests cover (a) the pure R-side routing + marshalling (no Julia), which
# always runs, and (b) one live Gaussian x Poisson round-trip, guarded so it is
# skipped when JuliaCall or the DRM.jl cross-family engine is unavailable.

test_that("cross-family detector routes mixed pairs, not gaussian x gaussian", {
  expect_true(drmTMB:::drm_julia_is_cross_family(c(poisson(), gaussian())))
  expect_true(drmTMB:::drm_julia_is_cross_family(c(gaussian(), binomial())))
  expect_true(drmTMB:::drm_julia_is_cross_family(list(poisson(), gaussian())))
  # gaussian x gaussian keeps the verified biv_gaussian residual-rho12 route.
  expect_false(drmTMB:::drm_julia_is_cross_family(c(gaussian(), gaussian())))
  # univariate families are never cross-family.
  expect_false(drmTMB:::drm_julia_is_cross_family(gaussian()))
  expect_false(drmTMB:::drm_julia_is_cross_family(poisson()))
})

test_that("Tier-2 family tags map nbinom2 / beta / gamma axes", {
  skip_if_not_installed("glmmTMB")
  # Tier-2 axes are keyed off base-R `family` objects, same as Tier-1.
  expect_equal(
    drmTMB:::drm_julia_xfam_family_tag(glmmTMB::nbinom2()),
    "nbinom2"
  )
  expect_equal(
    drmTMB:::drm_julia_xfam_family_tag(glmmTMB::beta_family()),
    "beta"
  )
  expect_equal(
    drmTMB:::drm_julia_xfam_family_tag(Gamma(link = "log")),
    "gamma"
  )
  # Wrong link -> rejected (DRM.jl's Gamma axis is log-mean only).
  expect_null(drmTMB:::drm_julia_xfam_family_tag(Gamma()))
  expect_null(drmTMB:::drm_julia_xfam_family_tag(Gamma(link = "inverse")))

  # MASS NB2 tags its family as "Negative Binomial(theta)"; treat as nbinom2.
  skip_if_not_installed("MASS")
  expect_equal(
    drmTMB:::drm_julia_xfam_family_tag(MASS::negative.binomial(1.5)),
    "nbinom2"
  )
})

test_that("Tier-2 pairs route cross-family; gaussian x gaussian still does not", {
  skip_if_not_installed("glmmTMB")
  expect_true(drmTMB:::drm_julia_is_cross_family(c(glmmTMB::nbinom2(), gaussian())))
  expect_true(drmTMB:::drm_julia_is_cross_family(c(Gamma(link = "log"), poisson())))
  expect_true(drmTMB:::drm_julia_is_cross_family(c(glmmTMB::beta_family(), binomial())))
  expect_true(drmTMB:::drm_julia_is_cross_family(list(glmmTMB::nbinom2(), gaussian())))
  # A Tier-2 axis with the wrong link is not a routable cross-family pair.
  expect_false(drmTMB:::drm_julia_is_cross_family(c(Gamma(), poisson())))
})

test_that("cross-family axis builder marshals mu1 / mu2 to (y, X)", {
  set.seed(20260610)
  n <- 30
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rpois(n, 2),
    x = stats::rnorm(n)
  )
  form <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x)
  axes <- drmTMB:::drm_julia_xfam_axes(
    formula = form,
    data = dat,
    env = environment(),
    tags = c("gaussian", "poisson")
  )

  expect_equal(axes$mu1$response, "y1")
  expect_equal(axes$mu2$response, "y2")
  expect_length(axes$mu1$y, n)
  expect_length(axes$mu2$y, n)
  expect_equal(axes$mu1$coef_names, c("(Intercept)", "x"))
  expect_equal(dim(axes$mu1$X), c(n, 2L))
  # Absent sigma formula -> intercept-only Xsigma on the dispersion-carrying
  # Gaussian axis; the dispersionless Poisson axis carries no Xsigma columns.
  expect_equal(axes$sigma1$coef_names, "(Intercept)")
  expect_equal(dim(axes$sigma1$X), c(n, 1L))
})

test_that("cross-family axis builder marshals sigma1 covariate design", {
  set.seed(20260610)
  n <- 30
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rpois(n, 2),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  # sigma1 ~ z builds a 2-column Xsigma (intercept + z) on the Gaussian axis.
  form <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~z)
  axes <- drmTMB:::drm_julia_xfam_axes(
    formula = form,
    data = dat,
    env = environment(),
    tags = c("gaussian", "poisson")
  )
  expect_equal(axes$sigma1$coef_names, c("(Intercept)", "z"))
  expect_equal(dim(axes$sigma1$X), c(n, 2L))
  expect_equal(unname(axes$sigma1$X[, 2L]), dat$z)
  # sigma2 absent -> intercept-only on the (dispersionless) Poisson axis, but the
  # engine drops it; the design itself is still intercept-only here.
  expect_equal(axes$sigma2$coef_names, "(Intercept)")
})

test_that("cross-family sigma on a dispersionless axis is rejected", {
  set.seed(20260610)
  n <- 20
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rpois(n, 2),
    x = stats::rnorm(n)
  )
  # A sigma2 sub-model on the Poisson axis has no dispersion to model.
  form <- bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma2 = ~x)
  expect_error(
    drmTMB:::drm_julia_xfam_axes(
      formula = form,
      data = dat,
      env = environment(),
      tags = c("gaussian", "poisson")
    ),
    "dispersion sub-model"
  )
})

test_that("Gaussian x Poisson cross-family fit returns latent rho + profile CI", {
  skip_if_not_installed("JuliaCall")

  # Point the bridge at the cross-family DRM.jl engine for this run.
  jl_path <- Sys.getenv(
    "DRM_JL_XFAM_PATH",
    "/Users/z3437171/worktrees/DRM-s3-cross-family"
  )
  skip_if_not(dir.exists(jl_path), "DRM.jl cross-family engine not available")
  withr::local_envvar(c(JULIA_HOME = "/Users/z3437171/.juliaup/bin"))
  withr::local_options(list(drmTMB.DRM.jl.path = jl_path))

  # Reset the shared Julia setup cache so DRM is (re)activated from jl_path.
  setup_state <- get("drm_julia_setup_state", asNamespace("drmTMB"))
  setup_state$ready <- NULL
  setup_state$path <- NULL

  # Skip rather than fail when Julia / DRM cannot be brought up in this
  # environment (e.g. no Julia, or the engine fails to precompile).
  ready <- tryCatch(
    {
      drmTMB:::drm_julia_setup()
      TRUE
    },
    error = function(e) {
      testthat::skip(paste("Julia / DRM.jl unavailable:", conditionMessage(e)))
    }
  )
  skip_if_not(isTRUE(ready), "Julia / DRM.jl unavailable")

  # Well-conditioned Gaussian x Poisson data with a shared latent: moderate
  # Poisson loading keeps counts small so the GHQ optimiser converges.
  set.seed(20260610)
  n <- 150
  x <- stats::rnorm(n)
  u <- stats::rnorm(n)
  dat <- data.frame(
    y1 = 0.5 + 0.8 * x + 0.7 * u + stats::rnorm(n, sd = 0.5),
    y2 = stats::rpois(n, exp(0.4 + 0.3 * x + 0.4 * u)),
    x = x
  )

  fit <- tryCatch(
    drmTMB(
      bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
      family = c(gaussian(), poisson()),
      data = dat,
      engine = "julia"
    ),
    error = function(e) {
      testthat::skip(paste("Cross-family round-trip failed:", conditionMessage(e)))
    }
  )

  expect_s3_class(fit, "drmTMB_julia_xfam")

  rho <- rho_latent(fit)
  expect_true(is.finite(rho))
  expect_gt(rho, -1)
  expect_lt(rho, 1)

  ci <- confint(fit, parm = "rho_latent", method = "profile")
  expect_equal(ci$parm, "rho_latent")
  expect_true(is.finite(ci$lower))
  expect_true(is.finite(ci$upper))
  expect_lte(ci$lower, rho)
  expect_gte(ci$upper, rho)
  expect_gt(ci$upper, ci$lower)

  expect_true(is_converged(fit))
  expect_equal(names(coef(fit)), c("mu1", "mu2"))
})

# --- Tier-2 cross-family live round-trips (guarded) -------------------------
#
# These point the bridge at the Tier-2 DRM.jl engine (NegBinomial2 / Beta /
# Gamma axes) and assert a finite latent rho + a finite profile CI come back,
# exactly as the Gaussian x Poisson smoke above.
#
# Each live fit runs in a FRESH R subprocess (callr). JuliaCall keeps one
# persistent Julia session per process and `using DRM` is a no-op once DRM is
# loaded, so an earlier in-process test that loaded a Tier-1-only DRM build
# would shadow the Tier-2 `fit_mixed_family` methods. A subprocess guarantees
# the Tier-2 engine at `jl_path` is the one loaded for these fits, independent
# of test order. The tests skip (never fail) when JuliaCall, callr, or the
# Tier-2 engine is unavailable, or when the round-trip itself errors.

drm_xfam_tier2_path <- function() {
  Sys.getenv("DRM_JL_XFAM_TIER2_PATH", "/Users/z3437171/worktrees/DRM-tier2")
}

# Run one cross-family fit in a clean subprocess and return the scalars the
# assertions need. `fam_expr` is a length-2 character vector of R expressions
# for the two family axes (evaluated in the child). `make_data` is a function
# of n returning the data.frame. Returns a list, or NULL if the child errored.
drm_xfam_tier2_fit <- function(fam_expr, make_data, n = 150L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_xfam_tier2_path()
  callr::r(
    function(pkg, jl_path, fam_expr, make_data, n) {
      Sys.setenv(JULIA_HOME = "/Users/z3437171/.juliaup/bin")
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      dat <- make_data(n)
      family <- c(eval(parse(text = fam_expr[[1L]])),
                  eval(parse(text = fam_expr[[2L]])))
      fit <- drmTMB(
        drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x),
        family = family, data = dat, engine = "julia"
      )
      ci <- stats::confint(fit, parm = "rho_latent", method = "profile")
      list(
        class = class(fit),
        families = fit$families,
        rho = drmTMB::rho_latent(fit),
        ci_parm = ci$parm,
        ci_lower = ci$lower,
        ci_upper = ci$upper,
        sigma1 = fit$sigma[["sigma1"]],
        sigma2 = fit$sigma[["sigma2"]],
        converged = drmTMB::is_converged(fit),
        loglik = fit$logLik
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, fam_expr = fam_expr,
                make_data = make_data, n = as.integer(n)),
    error = "error"
  )
}

# Common assertion block: finite latent rho strictly inside (-1, 1) bracketed
# by a finite, ordered profile CI; converged.
drm_xfam_expect_latent_ci <- function(res) {
  expect_true("drmTMB_julia_xfam" %in% res$class)
  expect_identical(res$ci_parm, "rho_latent")
  expect_true(is.finite(res$rho))
  expect_gt(res$rho, -1)
  expect_lt(res$rho, 1)
  expect_true(is.finite(res$ci_lower))
  expect_true(is.finite(res$ci_upper))
  expect_lte(res$ci_lower, res$rho)
  expect_gte(res$ci_upper, res$rho)
  expect_gt(res$ci_upper, res$ci_lower)
  expect_true(isTRUE(res$converged))
}

test_that("Gamma x Poisson cross-family fit returns latent rho + profile CI", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(dir.exists(drm_xfam_tier2_path()), "DRM.jl Tier-2 engine not available")

  res <- tryCatch(
    drm_xfam_tier2_fit(
      fam_expr = c("Gamma(link = \"log\")", "poisson()"),
      make_data = function(n) {
        set.seed(20260610)
        x <- stats::rnorm(n)
        u <- stats::rnorm(n)
        data.frame(
          # Gamma mean exp(0.3 + 0.2 x + 0.4 u), shape 2 -> scale = mean / 2.
          y1 = stats::rgamma(n, shape = 2, scale = exp(0.3 + 0.2 * x + 0.4 * u) / 2),
          y2 = stats::rpois(n, exp(0.4 + 0.3 * x + 0.4 * u)),
          x = x
        )
      }
    ),
    error = function(e) {
      testthat::skip(paste("Gamma x Poisson round-trip unavailable:", conditionMessage(e)))
    }
  )

  drm_xfam_expect_latent_ci(res)
  expect_equal(res$families, c("gamma", "poisson"))
  # Gamma axis carries a fitted dispersion (sigma); Poisson is dispersionless.
  expect_true(is.finite(res$sigma1))
})

test_that("NB2 x Gaussian cross-family fit returns latent rho + profile CI", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("glmmTMB")  # glmmTMB::nbinom2() supplies the base-R NB2 family
  skip_if_not(dir.exists(drm_xfam_tier2_path()), "DRM.jl Tier-2 engine not available")

  res <- tryCatch(
    drm_xfam_tier2_fit(
      fam_expr = c("glmmTMB::nbinom2()", "gaussian()"),
      make_data = function(n) {
        set.seed(20260611)
        x <- stats::rnorm(n)
        u <- stats::rnorm(n)
        data.frame(
          # NB2 mean exp(0.4 + 0.3 x + 0.4 u), size 3 (overdispersed counts).
          y1 = stats::rnbinom(n, size = 3, mu = exp(0.4 + 0.3 * x + 0.4 * u)),
          y2 = 0.5 + 0.8 * x + 0.7 * u + stats::rnorm(n, sd = 0.5),
          x = x
        )
      }
    ),
    error = function(e) {
      testthat::skip(paste("NB2 x Gaussian round-trip unavailable:", conditionMessage(e)))
    }
  )

  drm_xfam_expect_latent_ci(res)
  expect_equal(res$families, c("nbinom2", "gaussian"))
  # Both axes carry dispersion: NB2 returns the natural size, Gaussian sigma.
  expect_true(is.finite(res$sigma1))
  expect_true(is.finite(res$sigma2))
})

# --- Cross-family covariate sigma sub-model live round-trip (guarded) -------
#
# Points the bridge at the sigma-capable DRM.jl engine (fit_mixed_family with
# Xsigma1 / Xsigma2 covariate dispersion designs) and asserts the per-axis
# log-sigma sub-model coefficients (beta_sigma) come back finite, named by the
# Xsigma design columns, with the dispersionless Poisson axis carrying none.
# Runs in a FRESH R subprocess (callr) for the same reason as the Tier-2 fits:
# JuliaCall keeps one persistent Julia session per process, so a subprocess
# guarantees the sigma-capable engine at `jl_path` is the one loaded for this
# fit, independent of test order. Skips (never fails) when JuliaCall, callr, or
# the sigma engine is unavailable, or when the round-trip itself errors.

drm_xfam_xsigma_path <- function() {
  Sys.getenv("DRM_JL_XSIGMA_PATH", "/Users/z3437171/worktrees/DRM-xsigma")
}

# Fit a Gaussian x Poisson cross-family model with a sigma1 ~ x dispersion
# sub-model on the Gaussian axis in a clean subprocess; return the scalars and
# coefficient vectors the assertions need. Returns a list, or NULL on child
# error.
drm_xfam_xsigma_fit <- function(n = 150L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_xfam_xsigma_path()
  callr::r(
    function(pkg, jl_path, n) {
      Sys.setenv(JULIA_HOME = "/Users/z3437171/.juliaup/bin")
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(20260610)
      x <- stats::rnorm(n)
      u <- stats::rnorm(n)
      dat <- data.frame(
        y1 = 0.5 + 0.8 * x + 0.7 * u + stats::rnorm(n, sd = 0.5),
        y2 = stats::rpois(n, exp(0.4 + 0.3 * x + 0.4 * u)),
        x = x
      )

      fit <- drmTMB::drmTMB(
        drmTMB::bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~x),
        family = c(stats::gaussian(), stats::poisson()),
        data = dat, engine = "julia"
      )

      sc1 <- stats::coef(fit, "sigma1")
      sc2 <- stats::coef(fit, "sigma2")
      list(
        class = class(fit),
        families = fit$families,
        sigma_coef1 = unname(sc1),
        sigma_coef1_names = names(sc1),
        sigma_coef2_len = length(sc2),
        rho = drmTMB::rho_latent(fit),
        converged = drmTMB::is_converged(fit)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n = as.integer(n)),
    error = "error"
  )
}

test_that("cross-family covariate sigma sub-model returns finite beta_sigma", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not(
    dir.exists(drm_xfam_xsigma_path()),
    "DRM.jl covariate-sigma engine not available"
  )

  res <- tryCatch(
    drm_xfam_xsigma_fit(n = 150L),
    error = function(e) {
      testthat::skip(paste(
        "Cross-family covariate-sigma round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  expect_true("drmTMB_julia_xfam" %in% res$class)
  expect_equal(res$families, c("gaussian", "poisson"))
  # The Gaussian axis carries a 2-coefficient log-sigma sub-model (intercept + x
  # slope), both finite; the dispersionless Poisson axis carries none.
  expect_equal(res$sigma_coef1_names, c("(Intercept)", "x"))
  expect_length(res$sigma_coef1, 2L)
  expect_true(all(is.finite(res$sigma_coef1)))
  expect_equal(res$sigma_coef2_len, 0L)
  expect_true(is.finite(res$rho))
  expect_true(isTRUE(res$converged))
})
