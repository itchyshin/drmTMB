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

test_that("Gamma phylo random-slope (1 + x | species) via engine = 'julia' is finite and sane", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  testthat::skip_if_not_installed("ape")
  # Engine availability is decided by drm_skip_live_julia() above; an engine
  # error here is a test error, not a skip (#1127, Rose N7 pass 2026-09-03).
  # Was measured broken live on 2026-09-03: DRM.jl 77513aa0 aborted with
  # 'coef_labels is missing an entry for dpar "resd"' because the R-side
  # producer only labelled the resd block of a random-INTERCEPT phylo term.
  # Fixed by N9 (2026-09-03, design 258 S7.7 amendment): DRM.jl's
  # sparse-Laplace GLMM route reports exactly one `resd_<group>` coefficient
  # for a random-slope phylo term too (no separate intercept/slope split),
  # so the same bare-group label now covers it -- see
  # `drm_julia_bridge_payload_coef_labels()`, R/julia-bridge.R.
  res <- drm_phylo_slope_gamma_fit()
  expect_identical(res$engine, "julia")
  expect_true(is.finite(res$loglik_julia))
  expect_gt(res$nobs, 0L)
})
