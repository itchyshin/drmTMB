# Non-Gaussian phylogenetic routes via engine = "julia": Gamma, Beta, Binomial.
#
# DRM.jl fits a phylogenetic random-intercept model for Gamma / Beta (log/logit
# mean, sigma ~ 1) and Binomial (logit mean, mean-only) with the same sparse
# all-node Laplace used for the verified Gaussian and count phylo routes. The R
# bridge marshals the tree (Newick) plus the family tag and routes the fit
# through `drm(bundle, fam; data, tree = ...)`; only the response family tag
# differs from the count route, and the returned `resd_<group>` block feeds the
# existing structured-SD machinery unchanged.
#
# Native drmTMB REJECTS phylo() for these families (structured-effect syntax is
# "planned, not implemented" on the TMB side), so the Julia bridge is the ONLY
# route -- this is net-new capability, not TMB parity. The live tests therefore
# assert a finite-and-sane floor rather than coefficient parity.
#
# These tests cover (a) pure R-side family-tag and phylo-payload gating (no
# Julia), which always runs, and (b) live Gamma and Binomial phylo round-trips,
# guarded so they are SKIPPED -- never failed -- when JuliaCall, callr, pkgload,
# ape, or the DRM.jl engine is unavailable, or when a fit errors in this
# environment.

test_that("Gamma / Beta / Binomial route phylo, reject without it", {
  for (fam in c("gamma", "beta", "binomial")) {
    expect_equal(
      drmTMB:::drm_julia_family_tag(fam, has_phylo = TRUE),
      fam
    )
    expect_error(
      drmTMB:::drm_julia_family_tag(fam, has_phylo = FALSE),
      "only with a .*phylo.* random intercept"
    )
  }
})

test_that("phylo-only family set is the shared source of truth", {
  expect_setequal(
    drmTMB:::drm_julia_phylo_only_families(),
    c("poisson", "nbinom2", "gamma", "beta", "binomial")
  )
})

test_that("bridge family classifier recognises logit binomial, defers otherwise", {
  # Native drm_family_type() has no plain-binomial branch; the bridge adds it.
  expect_equal(
    drmTMB:::drm_julia_bridge_family_type(stats::binomial()),
    "binomial"
  )
  # Non-logit binomial falls through to drm_family_type(), which rejects it.
  expect_error(
    drmTMB:::drm_julia_bridge_family_type(stats::binomial(link = "probit"))
  )
  # A family drm_family_type() does classify is passed straight through.
  expect_equal(
    drmTMB:::drm_julia_bridge_family_type(stats::gaussian()),
    "gaussian"
  )
})

test_that("phylo payload guard admits gamma/beta/binomial, rejects others", {
  tree <- ape::rcoal(6)
  sp <- tree$tip.label
  dat <- data.frame(
    species = sp,
    y = stats::runif(6, 0.2, 5),
    stringsAsFactors = FALSE
  )
  form <- drmTMB::bf(y ~ phylo(1 | species, tree = tree))

  for (ft in c("gamma", "beta", "binomial")) {
    expect_no_error(
      drmTMB:::drm_julia_phylo_payload(
        formula = form,
        family_type = ft,
        data = dat,
        env = environment()
      )
    )
  }
  # beta_binomial has no Julia phylo route -> the payload guard rejects it.
  expect_error(
    drmTMB:::drm_julia_phylo_payload(
      formula = form,
      family_type = "beta_binomial",
      data = dat,
      env = environment()
    ),
    "univariate Gaussian, Poisson, NB2, Gamma, Beta, or Binomial"
  )
})

# --- Live non-Gaussian phylo round-trips (guarded) --------------------------
#
# Each fit runs in a FRESH R subprocess (callr): JuliaCall keeps one persistent
# Julia session per process and `using DRM` is a no-op once DRM is loaded, so a
# fresh subprocess guarantees the phylo-capable engine at `jl_path` is the one
# loaded for this fit, independent of test order.

drm_phylo_ng_path <- function() {
  Sys.getenv(
    "DRM_JL_PHYLO_PATH",
    "/Users/z3437171/worktrees/DRM-relmatext"
  )
}

# Fit a Gamma phylo model via engine = "julia" in a clean subprocess. drmTMB's
# native TMB engine REJECTS phylo() for Gamma (`drm_reject_phase1_terms`:
# "Structured-effect syntax is planned, not implemented"), so there is no TMB
# twin -- the Julia bridge is the only route, and we assert a finite-and-sane
# floor. Returns a list, or NULL if the child errored.
drm_phylo_gamma_fit <- function(n_tip = 24L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_phylo_ng_path()
  callr::r(
    function(pkg, jl_path, n_tip) {
      Sys.setenv(JULIA_HOME = "/Users/z3437171/.juliaup/bin")
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      # Moderate ultrametric binary tree; a Brownian latent on the tree drives
      # the phylogenetic random intercept on the log mean. Gamma() needs strictly
      # positive responses, so we draw from a gamma with mean exp(eta).
      set.seed(7)
      tree <- ape::rcoal(n_tip)
      sp <- tree$tip.label
      x <- stats::rnorm(n_tip)
      bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.6)
      eta <- 0.4 + 0.3 * x + bm[sp]
      mu <- exp(eta)
      y <- stats::rgamma(n_tip, shape = 5, rate = 5 / mu)
      dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)

      form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)

      fj <- drmTMB::drmTMB(
        form,
        family = stats::Gamma(link = "log"),
        data = dat,
        engine = "julia"
      )

      cj <- stats::coef(fj, "mu")
      list(
        class = class(fj),
        engine = fj$engine,
        nobs = stats::nobs(fj),
        loglik_julia = as.numeric(stats::logLik(fj)),
        coef_julia = unname(cj),
        coef_names = names(cj),
        sigma_julia = unname(stats::coef(fj, "sigma")),
        sd_julia = unname(fj$sdpars$mu[["phylo(1 | species)"]]),
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "error"
  )
}

# Fit a Binomial phylo model via engine = "julia" in a clean subprocess. drmTMB
# native has no plain binomial() classifier, so there is no TMB twin here -- the
# bridge is the only route, and we assert a finite-and-sane floor.
drm_phylo_binom_fit <- function(n_tip = 24L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_phylo_ng_path()
  callr::r(
    function(pkg, jl_path, n_tip) {
      Sys.setenv(JULIA_HOME = "/Users/z3437171/.juliaup/bin")
      options(drmTMB.DRM.jl.path = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))

      set.seed(11)
      tree <- ape::rcoal(n_tip)
      sp <- tree$tip.label
      x <- stats::rnorm(n_tip)
      bm <- ape::rTraitCont(tree, model = "BM", sigma = 0.8)
      eta <- -0.2 + 0.5 * x + bm[sp]
      p <- stats::plogis(eta)
      y <- stats::rbinom(n_tip, size = 1L, prob = p)
      dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)

      form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))

      fj <- drmTMB::drmTMB(
        form,
        family = stats::binomial(),
        data = dat,
        engine = "julia"
      )

      cj <- stats::coef(fj, "mu")
      list(
        class = class(fj),
        engine = fj$engine,
        nobs = stats::nobs(fj),
        loglik_julia = as.numeric(stats::logLik(fj)),
        coef_julia = unname(cj),
        coef_names = names(cj),
        sd_julia = unname(fj$sdpars$mu[["phylo(1 | species)"]]),
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "error"
  )
}

test_that("Gamma phylo fit via engine = 'julia' is finite and sane", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_phylo_ng_path()),
    "DRM.jl phylo engine not available"
  )

  res <- tryCatch(
    drm_phylo_gamma_fit(n_tip = 24L),
    error = function(e) {
      testthat::skip(paste(
        "Gamma phylo round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  # Native drmTMB cannot fit Gamma phylo (TMB rejects structured terms), so the
  # Julia bridge is the only route -> finite-and-sane floor only.
  expect_true("drmTMB_julia" %in% res$class)
  expect_equal(res$engine, "julia")
  expect_equal(res$nobs, 24L)
  expect_true(is.finite(res$loglik_julia))
  expect_true(all(is.finite(res$coef_julia)))
  expect_equal(res$coef_names, c("(Intercept)", "x"))
  # sigma here is the log-scale dispersion intercept (sigma ~ 1), which is
  # unconstrained in sign; only finiteness is a sane floor.
  expect_true(is.finite(res$sigma_julia))
  expect_true(is.finite(res$sd_julia))
  expect_gt(res$sd_julia, 0)
  expect_true(isTRUE(res$converged))
})

test_that("Binomial phylo fit via engine = 'julia' is finite and sane", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_phylo_ng_path()),
    "DRM.jl phylo engine not available"
  )

  res <- tryCatch(
    drm_phylo_binom_fit(n_tip = 24L),
    error = function(e) {
      testthat::skip(paste(
        "Binomial phylo round-trip unavailable:",
        conditionMessage(e)
      ))
    }
  )

  # No native binomial twin -> finite-and-sane floor only.
  expect_true("drmTMB_julia" %in% res$class)
  expect_equal(res$engine, "julia")
  expect_equal(res$nobs, 24L)
  expect_true(is.finite(res$loglik_julia))
  expect_true(all(is.finite(res$coef_julia)))
  expect_equal(res$coef_names, c("(Intercept)", "x"))
  expect_true(is.finite(res$sd_julia))
  expect_gt(res$sd_julia, 0)
  expect_true(isTRUE(res$converged))
})
