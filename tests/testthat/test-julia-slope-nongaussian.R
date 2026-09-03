# Non-Gaussian phylogenetic random-SLOPE route via engine = "julia" (cluster 3).
# `phylo(1 + x | species)` — a phylogenetic random slope — is fit by DRM.jl's sparse
# q=2 correlated-locscale Laplace engine; drmTMB's native TMB path rejects structured
# slopes. So the Julia bridge is the only route, and we assert a finite-and-sane floor.

drm_slope_ng_path <- function() {
  drm_test_drmjl_path()
}

drm_phylo_slope_gamma_fit <- function(n_tip = 40L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_slope_ng_path()
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
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      set.seed(7)
      tree <- ape::rcoal(n_tip)
      sp <- tree$tip.label
      x <- stats::rnorm(n_tip)
      bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.6)
      eta <- 0.4 + 0.3 * x + bm[sp]
      mu <- exp(eta)
      y <- stats::rgamma(n_tip, shape = 5, rate = 5 / mu)
      dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)

      form <- drmTMB::bf(y ~ phylo(1 + x | species, tree = tree), sigma ~ 1)
      fj <- drmTMB::drmTMB(
        form,
        family = stats::Gamma(link = "log"),
        data = dat,
        engine = "julia"
      )
      list(
        engine = fj$engine,
        nobs = stats::nobs(fj),
        loglik_julia = as.numeric(stats::logLik(fj)),
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "stack"
  )
}

test_that("Gamma phylo random-slope (1 + x | species) is REFUSED by DRM.jl, in its own words", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("ape")
  # CHANGED BY THE 2026-09-03 RE-PIN (77513aa0 -> e0a65f96b). DRM.jl #621 added
  # `_check_phylo_re_lhs` (src/gaussian_ranef.jl), which REFUSES a phylogenetic
  # random SLOPE on the univariate routes instead of fitting something it does
  # not implement. So this cell no longer produces a fit, and asserting "finite
  # and sane" would assert a number DRM.jl has stopped claiming to produce.
  #
  # The refusal is the CORRECT behaviour and this test now pins it. Verified
  # read-only against both clones: `_check_phylo_re_lhs` exists at the new pin
  # and does NOT exist at 77513aa0, which is exactly why the old pin fitted this
  # silently.
  #
  # The #1127 principle is PRESERVED, not weakened: engine availability is still
  # decided by drm_skip_live_julia() above, an engine error is still a test error
  # rather than a skip, and this does not catch-and-ignore. It asserts DRM.jl's
  # SPECIFIC refusal, so any OTHER engine failure -- a marshalling fault, a
  # coef_labels gap, a numerical abort -- still fails the test rather than being
  # absorbed by a bare expect_error().
  cnd <- tryCatch(drm_phylo_slope_gamma_fit(), error = function(e) e)
  expect_s3_class(cnd, "error")
  msg <- conditionMessage(cnd)

  # DRM.jl's own words, from src/gaussian_ranef.jl `_check_phylo_re_lhs`
  expect_true(grepl("not implemented on the", msg, fixed = TRUE))
  expect_true(grepl("univariate routes", msg, fixed = TRUE))
  expect_true(grepl("only `phylo(1 | species)` (intercept) is", msg, fixed = TRUE))

  # NEGATIVE CONTROLS: the failures this test must NOT silently pass on.
  # `coef_labels` was the previous live breakage on this exact cell (N9,
  # 2026-09-03); a regression there must not be mistaken for the refusal.
  expect_false(grepl("coef_labels", msg, fixed = TRUE))
  expect_false(grepl("Failed to precompile", msg, fixed = TRUE))
  expect_false(grepl("Package DRM not found", msg, fixed = TRUE))
})
