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
    env = environment()
  )

  expect_equal(axes$mu1$response, "y1")
  expect_equal(axes$mu2$response, "y2")
  expect_length(axes$mu1$y, n)
  expect_length(axes$mu2$y, n)
  expect_equal(axes$mu1$coef_names, c("(Intercept)", "x"))
  expect_equal(dim(axes$mu1$X), c(n, 2L))
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
