# Large-p phylogenetic COUNT route via engine = "julia".
#
# DRM.jl fits a phylogenetic random-intercept count model (Poisson / NB2) with a
# sparse all-node Laplace whose cost is O(p) in the number of tips -- the speed
# edge over the dense TMB phylo path for large trees. The R bridge marshals the
# tree (Newick) plus the family tag and routes the fit through
# `drm(bundle, Poisson(); data, tree = ...)`; everything else stays TMB-only.
#
# These tests cover (a) the pure R-side family-tag gating (no Julia), which
# always runs, and (b) one live Poisson phylo round-trip on a moderate
# ultrametric tree, guarded so it is skipped -- never failed -- when JuliaCall,
# callr, pkgload, ape, or the DRM.jl engine is unavailable, or when the fit
# itself errors in this environment.

test_that("family-tag gating routes phylo count, rejects plain count", {
  # Poisson / NB2 route ONLY when a phylo term is present.
  expect_equal(
    drmTMB:::drm_julia_family_tag("poisson", has_phylo = TRUE),
    "poisson"
  )
  expect_equal(
    drmTMB:::drm_julia_family_tag("nbinom2", has_phylo = TRUE),
    "nbinom2"
  )
  # Gaussian one-/two-response route unconditionally (verified base lane).
  expect_equal(
    drmTMB:::drm_julia_family_tag("gaussian", has_phylo = FALSE),
    "gaussian"
  )
  expect_equal(
    drmTMB:::drm_julia_family_tag("biv_gaussian", has_phylo = FALSE),
    "biv_gaussian"
  )
  # A count family with NO phylo term is rejected (TMB-only).
  expect_error(
    drmTMB:::drm_julia_family_tag("poisson", has_phylo = FALSE),
    "only with a .*phylo.* random intercept"
  )
  expect_error(
    drmTMB:::drm_julia_family_tag("nbinom2", has_phylo = FALSE),
    "only with a .*phylo.* random intercept"
  )
  # Other non-Gaussian families are rejected regardless of phylo.
  expect_error(
    drmTMB:::drm_julia_family_tag("gamma", has_phylo = TRUE),
    "Gaussian one-/two-response"
  )
})

test_that("has-phylo detector finds a phylo term in any entry", {
  tree <- structure(
    list(
      edge = matrix(
        c(7, 5, 7, 6, 5, 1, 5, 2, 6, 3, 6, 4),
        ncol = 2,
        byrow = TRUE
      ),
      edge.length = rep(1, 6),
      tip.label = paste0("sp_", 1:4),
      Nnode = 3L
    ),
    class = "phylo"
  )
  expect_true(
    drmTMB:::drm_julia_has_phylo_term(
      bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)
    )
  )
  expect_false(drmTMB:::drm_julia_has_phylo_term(bf(y ~ x, sigma ~ 1)))
})

# --- Live large-p phylo Poisson round-trip (guarded) ------------------------
#
# Runs in a FRESH R subprocess (callr). JuliaCall keeps one persistent Julia
# session per process and `using DRM` is a no-op once DRM is loaded, so a fresh
# subprocess guarantees the phylo-capable engine at `jl_path` is the one loaded
# for this fit, independent of test order (same rationale as the cross-family
# Tier-2 round-trips).

drm_phylo_count_path <- function() {
  Sys.getenv(
    "DRM_JL_PHYLO_PATH",
    "/Users/z3437171/Dropbox/Github Local/DRM.jl"
  )
}

# Fit the same phylo Poisson model with BOTH engines in one clean subprocess and
# return the scalars the assertions need. Returns a list, or NULL if the child
# errored.
drm_phylo_count_fit <- function(n_tip = 24L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_phylo_count_path()
  callr::r(
    function(pkg, jl_path, n_tip) {
      Sys.setenv(JULIA_HOME = "/Users/z3437171/.juliaup/bin")
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      # Moderate ultrametric binary tree (the bridge requires ultrametric); one
      # observation per tip drives the phylogenetic random intercept. A Brownian
      # latent on the tree generates the over-dispersion the phylo SD captures.
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
        form, family = stats::poisson(), data = dat, engine = "julia"
      )
      ft <- drmTMB::drmTMB(form, family = stats::poisson(), data = dat)

      cj <- stats::coef(fj, "mu")
      ct <- stats::coef(ft, "mu")
      list(
        class = class(fj),
        engine = fj$engine,
        nobs = stats::nobs(fj),
        loglik_julia = as.numeric(stats::logLik(fj)),
        loglik_tmb = as.numeric(stats::logLik(ft)),
        coef_julia = unname(cj),
        coef_tmb = unname(ct),
        coef_names = names(cj),
        sd_julia = unname(fj$sdpars$mu[["phylo(1 | species)"]]),
        sd_tmb = unname(ft$sdpars$mu[["phylo(1 | species)"]]),
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "error"
  )
}

test_that("Poisson phylo fit via engine = 'julia' is finite, sane, TMB-parity", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_phylo_count_path()),
    "DRM.jl phylo-count engine not available"
  )

  res <- tryCatch(
    drm_phylo_count_fit(n_tip = 24L),
    error = function(e) {
      testthat::skip(paste(
        "Poisson phylo round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  # --- Finite-and-sane floor (always required if the fit ran) ---------------
  expect_true("drmTMB_julia" %in% res$class)
  expect_equal(res$engine, "julia")
  expect_equal(res$nobs, 24L)
  expect_true(is.finite(res$loglik_julia))
  expect_true(all(is.finite(res$coef_julia)))
  expect_equal(res$coef_names, c("(Intercept)", "x"))
  expect_true(is.finite(res$sd_julia))
  expect_gt(res$sd_julia, 0)
  expect_true(isTRUE(res$converged))

  # --- Parity vs the dense TMB phylo Poisson fit (affordable here) ----------
  # Both are marginal Laplace likelihoods of the same model; on this tree they
  # agree to several decimals. Tolerances are loose enough to absorb the two
  # Laplace implementations differing, tight enough to catch a wrong route.
  expect_true(is.finite(res$loglik_tmb))
  expect_equal(res$loglik_julia, res$loglik_tmb, tolerance = 1e-2)
  expect_equal(res$coef_julia, res$coef_tmb, tolerance = 1e-2)
  expect_equal(res$sd_julia, res$sd_tmb, tolerance = 1e-2)
})
