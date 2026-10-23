# Gaussian σ-phylo location-scale REML via engine = "julia" (Ayumi #2).
#
# DRM.jl now fits Gaussian sigma-phylo location-scale cells -- phylo(1 | g) on
# sigma, with or without a matching mean-side phylo term -- and the bivariate q4
# phylogenetic location-scale model by restricted maximum likelihood
# (`drm(...; method = :REML)`). These are capabilities the native TMB engine
# lacks, so the bridge must let `method = "REML"` through the REML gate for
# THESE cells while still rejecting (warn + fall back to ML) the cells DRM.jl
# does not yet REML-fit:
#   * mean-only phylo Gaussian (phylo on mu, sigma ~ 1)
#   * the phylo-only families (Poisson / NB2 / Gamma / Beta / Binomial)
#   * cross-family and general-covariance (relmat / animal / spatial) routes
#
# The gate-logic tests below need no Julia and always run. The live REML
# round-trip is guarded so it is SKIPPED -- never failed -- when JuliaCall,
# callr, pkgload, ape, or a σ-phylo-REML-capable DRM.jl engine is unavailable.

test_that("sigma-phylo detector fires only for a phylo term on sigma", {
  tree <- ape::rcoal(6)

  sigma_only <- drmTMB::bf(
    y ~ x,
    sigma ~ phylo(1 | species, tree = tree)
  )
  sigma_phylo <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ phylo(1 | species, tree = tree)
  )
  mean_only <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1
  )
  fixed_locscale <- drmTMB::bf(y ~ x, sigma ~ x)

  expect_true(drmTMB:::drm_julia_has_sigma_phylo_term(sigma_only))
  expect_true(drmTMB:::drm_julia_has_sigma_phylo_term(sigma_phylo))
  expect_false(drmTMB:::drm_julia_has_sigma_phylo_term(mean_only))
  expect_false(drmTMB:::drm_julia_has_sigma_phylo_term(fixed_locscale))
})

test_that("Gaussian belongs to the location-scale phylo family set", {
  # The σ-phylo route reuses the cluster ④ location-scale family gate; Gaussian
  # was added so phylo(mu) + phylo(sigma) routes to DRM.jl's separate-block
  # Gaussian location-scale phylo engine.
  expect_true("gaussian" %in% drmTMB:::drm_julia_locscale_phylo_families())
})

test_that("bridge options forward method = REML only when REML is requested", {
  # Non-phylo Gaussian location-scale (no phylo_payload): REML key, no g_tol.
  expect_identical(
    drmTMB:::drm_julia_bridge_options(NULL, method = "REML"),
    list(method = "REML")
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_options(NULL, method = "ML"),
    list()
  )

  # σ-phylo location-scale (univariate GAUSSIAN phylo_payload): REML key
  # alongside the g_tol this route keeps. The payload now says its family
  # explicitly, because the mapping is family-split (2026-08-27): Gaussian
  # σ-phylo/locscale-REML fitters have their OWN convergence criterion and
  # stall short of 1e-8 on the restricted objective, so they keep 1e-4.
  uni_payload <- list(bivariate = FALSE, family_type = "gaussian")
  expect_identical(
    drmTMB:::drm_julia_bridge_options(uni_payload, method = "REML"),
    list(g_tol = 1e-4, method = "REML")
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_options(uni_payload, method = "ML"),
    list(g_tol = 1e-4)
  )
  # Non-Gaussian univariate phylo payloads get DRM.jl's native default 1e-8:
  # their SE parity is banked at 1e-7..5e-6 relative on those routes, and the
  # #491 converged flag honestly reports a 1e-4 request as not at standard —
  # asking for less must not buy a green flag through the bridge either.
  nongauss_payload <- list(bivariate = FALSE, family_type = "poisson")
  expect_identical(
    drmTMB:::drm_julia_bridge_options(nongauss_payload, method = "ML"),
    list(g_tol = 1e-8)
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_options(nongauss_payload, method = "REML"),
    list(g_tol = 1e-8, method = "REML")
  )

  # #527: the phylo_slope Gaussian arm, previously unpinned — it takes the
  # Gaussian-else 1e-4 (its fitter predates the tightened non-Gaussian arm and
  # keeps its verified tolerance).
  slope_payload <- list(bivariate = FALSE, family_type = "gaussian",
                        locscale_mode = "phylo_slope")
  expect_identical(
    drmTMB:::drm_julia_bridge_options(slope_payload, method = "ML"),
    list(g_tol = 1e-4)
  )

  # 2026-08-28: the phylo_hetero_sigma arm — a phylo mean term WITH a
  # predictor-dependent residual scale, previously fenced off entirely
  # (DRM.jl#548 made the Julia route unusable; fixed and parity-verified).
  # It routes to DRM.jl's dense scaled-structure engine and takes the
  # Gaussian-else 1e-4, the tolerance the M-ladder acceptance runs verified.
  hetero_payload <- list(bivariate = FALSE, family_type = "gaussian",
                         locscale_mode = "phylo_hetero_sigma")
  expect_identical(
    drmTMB:::drm_julia_bridge_options(hetero_payload, method = "ML"),
    list(g_tol = 1e-4)
  )

  # #527: a payload with NO family_type is a construction bug and now fails
  # loudly instead of silently taking the non-Gaussian 1e-8 arm (the exact
  # shape that bit this file's own synthetic payload during the 2026-08-27 arc).
  expect_error(
    drmTMB:::drm_julia_bridge_options(list(bivariate = FALSE), method = "ML"),
    "family_type"
  )

  # ML mu+sigma q1 phylo parity uses DRM.jl's coupled covariance block to match
  # native TMB. REML stays on the existing separate-block DRM.jl route because
  # coupled mean-sigma phylo REML is not implemented.
  locscale_payload <- list(
    bivariate = FALSE,
    family_type = "gaussian",
    locscale_mode = "phylo_locscale"
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_options(locscale_payload, method = "ML"),
    list(g_tol = 1e-6, phylo_coupled = TRUE)
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_options(locscale_payload, method = "REML"),
    list(g_tol = 1e-4, method = "REML")
  )

  # Bivariate q4 phylo uses DRM.jl optimizer defaults, but REML is still a real
  # estimator choice and must be forwarded through the bridge.
  biv_payload <- list(bivariate = TRUE)
  expect_identical(
    drmTMB:::drm_julia_bridge_options(biv_payload, method = "REML"),
    list(method = "REML")
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_options(biv_payload, method = "ML"),
    list()
  )
})

# WIDENED 2026-09-04 (#1152). This block used to assert the support matrix was
# GAUSSIAN-ONLY. It is not any more: DRM.jl #624's rewritten refusal enumerates
# what it restricts, and two Poisson cells on that list were verified with #625's
# `estim_method` oracle at pin e0a65f96b -- Poisson `(1 | g)` and Poisson
# `phylo(1 | species)` both report estim_method=:REML with a reml_loglik several
# units from ML. The Gaussian rows below are UNCHANGED; the Poisson rows are new
# and measured, and a genuinely-still-refused family is kept as a negative.
test_that("Julia REML support matrix admits Gaussian and the two measured Poisson cells", {
  tree <- ape::rcoal(8)

  fixed_locscale <- drmTMB::bf(y ~ x, sigma ~ x)
  sigma_only <- drmTMB::bf(
    y ~ x,
    sigma ~ phylo(1 | species, tree = tree)
  )
  sigma_phylo <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ phylo(1 | species, tree = tree)
  )
  mean_only <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1
  )
  q4 <- drmTMB::bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
  count_phylo <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))
  lss_iid <- drmTMB::bf(
    y ~ x + (1 | group),
    sigma ~ x,
    sd(group) ~ z
  )
  lss_phylo <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ x,
    sd(species, level = "phylogenetic") ~ z
  )

  expect_true(drmTMB:::drm_julia_reml_supported(fixed_locscale, "gaussian"))
  expect_true(drmTMB:::drm_julia_reml_supported(sigma_only, "gaussian"))
  expect_true(drmTMB:::drm_julia_reml_supported(sigma_phylo, "gaussian"))
  expect_true(drmTMB:::drm_julia_reml_supported(lss_iid, "gaussian"))
  expect_true(drmTMB:::drm_julia_reml_supported(lss_phylo, "gaussian"))
  expect_true(drmTMB:::drm_julia_reml_supported(q4, "biv_gaussian"))
  # SUPERSEDED 2026-09-05 (drmTMB #1142 / DRM.jl #624 item (c)): the mean-only
  # phylo Gaussian cell is now MEASURED as genuinely REML-capable on the DRM.jl
  # side (sparse location-only Patterson-Thompson restriction; same-target
  # receipt in docs/dev-log/evidence/julia-r-parity/reml/), so this gate must
  # ADMIT it. See tests/testthat/test-julia-reml-phylo-mean.R for the parity
  # assertions and for the adjacent shapes that still refuse.
  expect_true(drmTMB:::drm_julia_reml_supported(mean_only, "gaussian"))
  # MEASURED SUPPORTED (#1152): estim_method=:REML, ml=-74.6002, reml=-79.3865
  expect_true(drmTMB:::drm_julia_reml_supported(count_phylo, "poisson"))
  # still refused, and NOT measured as supported -- keeps this a real matrix
  # rather than a list of passes
  expect_false(drmTMB:::drm_julia_reml_supported(count_phylo, "binomial"))
  expect_false(drmTMB:::drm_julia_reml_supported(count_phylo, "gamma"))
  expect_identical(
    drmTMB:::drm_julia_reml_cell_label(count_phylo, "poisson"),
    "non-Gaussian (poisson)"
  )
})

test_that("the unsupported-REML condition REFUSES and does not overclaim native TMB fallback", {
  # Owner instruction 2026-09-03: the silent ML fallback becomes a refusal.
  # REML = FALSE must stay silent -- the refusal fires only when REML was asked for.
  expect_false(drmTMB:::drm_julia_refuse_reml_unsupported(FALSE, "non-Gaussian (poisson)"))

  cnd <- tryCatch(
    drmTMB:::drm_julia_refuse_reml_unsupported(TRUE, "non-Gaussian (poisson)"),
    condition = function(c) c
  )
  expect_s3_class(cnd, "error")
  expect_false(inherits(cnd, "warning"))
  error_text <- paste(
    c(conditionMessage(cnd), unlist(cnd$message), unlist(cnd$body)),
    collapse = "\n"
  )

  # names the cell, and the two ways forward
  expect_match(error_text, "non-Gaussian \\(poisson\\)")
  expect_match(error_text, "cannot fit")
  expect_match(error_text, "REML = FALSE")
  expect_match(error_text, "documented Gaussian")

  # the TMB pointer stays bounded: TMB does NOT REML-fit every refused cell
  expect_match(error_text, "diagnostic-only binomial REML route")
  expect_match(error_text, "ordinary unlabelled `mu` random intercept or independent slope")
  expect_match(error_text, "does not offer a general REML fit")
  expect_false(grepl("for an REML fit of this cell", error_text))

  # and the old silent-downgrade promise is gone
  expect_false(grepl("fitting by maximum likelihood \\(ML\\) instead", error_text))
})

test_that("REML gate admits Gaussian sigma-phylo, warns for other phylo cells", {
  tree <- ape::rcoal(8)
  sp <- tree$tip.label
  dat <- data.frame(
    species = sp,
    x = stats::rnorm(8),
    y = stats::rnorm(8),
    stringsAsFactors = FALSE
  )

  sigma_phylo <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ phylo(1 | species, tree = tree)
  )
  mean_only <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1
  )

  # Stub the actual Julia call: we are asserting the GATE accepts / rejects, not
  # the engine result. The stub records the options it was handed so we can read
  # off whether method = "REML" was forwarded, then returns a minimal bridge
  # result new_drmTMB_julia() can wrap.
  captured <- new.env(parent = emptyenv())
  fake_result <- list(
    coef_names = c(
      "mu_(Intercept)",
      "mu_x",
      "sigma_(Intercept)",
      "resd_phylo(1 | species)"
    ),
    coefficients = c(0, 0, 0, 0),
    vcov = matrix(NA_real_, 4L, 4L),
    loglik = -10,
    aic = 28,
    bic = 30,
    df = 4L,
    nobs = 8L,
    fitted = rep(0, 8L),
    residuals = rep(0, 8L),
    sigma = rep(1, 8L),
    corpairs = list(),
    converged = TRUE
  )
  testthat::local_mocked_bindings(
    drm_julia_call_bridge = function(formula, family, data, tree, options) {
      captured$options <- options
      fake_result
    },
    # The phylo payload needs a Newick tree; let the real serializer run, but
    # short-circuit the JuliaCall round-trip only.
    .package = "drmTMB"
  )

  # σ-phylo Gaussian REML: passes the gate (no REML-unsupported warning) and the
  # forwarded options carry method = "REML".
  expect_no_warning(
    fit_reml <- drmTMB:::drmTMB_julia_bridge(
      formula = sigma_phylo,
      family = stats::gaussian(),
      data = dat,
      env = environment(),
      weights_missing = TRUE,
      control = NULL,
      impute = NULL,
      missing = drmTMB::miss_control(),
      REML = TRUE,
      call = quote(drmTMB())
    )
  )
  expect_true("method" %in% names(captured$options))
  expect_identical(captured$options$method, "REML")
  expect_equal(fit_reml$estimator, "REML")
  expect_true(fit_reml$REML)
  expect_true(fit_reml$requested_REML)
  expect_true(fit_reml$effective_REML)

  # SUPERSEDED 2026-09-05 (drmTMB #1142 / DRM.jl #624 item (c)). This block used
  # to pin that the mean-only phylo Gaussian cell was REFUSED before reaching
  # Julia. DRM.jl now restricts that cell, so the bridge FORWARDS it, and what
  # is worth pinning is that the request reaches the engine as REML rather than
  # being silently downgraded to ML on the way -- the same shape the Poisson
  # phylo block below took when its cell was admitted.
  captured$options <- NULL
  suppressWarnings(try(
    drmTMB:::drmTMB_julia_bridge(
      formula = mean_only,
      family = stats::gaussian(),
      data = dat,
      env = environment(),
      weights_missing = TRUE,
      control = NULL,
      impute = NULL,
      missing = drmTMB::miss_control(),
      REML = TRUE,
      call = quote(drmTMB())
    ),
    silent = TRUE
  ))
  expect_true("method" %in% names(captured$options))
  expect_identical(captured$options$method, "REML")

  # The refusal that DOES still fire for this shape: an explicit non-default
  # `missing` response engine, which DRM.jl's phylo-mean REML gate excludes.
  captured$options <- NULL
  expect_error(
    drmTMB:::drmTMB_julia_bridge(
      formula = mean_only,
      family = stats::gaussian(),
      data = dat,
      env = environment(),
      weights_missing = TRUE,
      control = NULL,
      impute = NULL,
      missing = drmTMB::miss_control(response = "include"),
      REML = TRUE,
      call = quote(drmTMB())
    ),
    "cannot fit .*phylogenetic Gaussian.*by"
  )
  expect_null(captured$options)
})

# SUPERSEDED 2026-09-04 (#1152): the poisson phylo cell this block asserted was
# refused is now MEASURED as genuinely REML-capable, so it must be FORWARDED,
# not refused. What is still worth pinning is that the request reaches the
# engine as REML rather than being silently downgraded on the way.
test_that("a measured-supported Poisson phylo cell FORWARDS REML rather than refusing", {
  tree <- ape::rcoal(8)
  sp <- tree$tip.label
  dat <- data.frame(
    species = sp,
    x = stats::rnorm(8),
    y = stats::rpois(8, 3),
    stringsAsFactors = FALSE
  )
  count_phylo <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))

  captured <- new.env(parent = emptyenv())
  fake_result <- list(
    coef_names = c("mu_(Intercept)", "mu_x", "resd_phylo(1 | species)"),
    coefficients = c(0, 0, 0),
    vcov = matrix(NA_real_, 3L, 3L),
    loglik = -10,
    aic = 26,
    bic = 28,
    df = 3L,
    nobs = 8L,
    fitted = rep(0, 8L),
    residuals = rep(0, 8L),
    sigma = rep(1, 8L),
    corpairs = list(),
    converged = TRUE
  )
  testthat::local_mocked_bindings(
    drm_julia_call_bridge = function(formula, family, data, tree, options) {
      captured$options <- options
      fake_result
    },
    .package = "drmTMB"
  )

  # Refuses instead of silently forwarding ML, and refuses BEFORE marshalling:
  # `captured$options` stays NULL because the mocked bridge call is never reached.
  captured$options <- NULL
  fit <- drmTMB:::drmTMB_julia_bridge(
    formula = count_phylo,
    family = stats::poisson(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = NULL,
    impute = NULL,
    missing = drmTMB::miss_control(),
    REML = TRUE,
    call = quote(drmTMB())
  )
  # the request must REACH the engine as REML, not be quietly turned into ML
  expect_true("method" %in% names(captured$options))
  expect_identical(captured$options$method, "REML")
  expect_true(fit$requested_REML)
})

# SUPERSEDED 2026-09-04 (#1152), same reason as above.
test_that("the phylo-only count family cell forwards REML (measured supported)", {
  tree <- ape::rcoal(8)
  sp <- tree$tip.label
  dat <- data.frame(
    species = sp,
    x = stats::rnorm(8),
    y = stats::rpois(8, 3),
    stringsAsFactors = FALSE
  )
  count_phylo <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tree))

  captured <- new.env(parent = emptyenv())
  fake_result <- list(
    coef_names = c("mu_(Intercept)", "mu_x", "resd_phylo(1 | species)"),
    coefficients = c(0, 0, 0),
    vcov = matrix(NA_real_, 3L, 3L),
    loglik = -10,
    aic = 26,
    bic = 28,
    df = 3L,
    nobs = 8L,
    fitted = rep(0, 8L),
    residuals = rep(0, 8L),
    sigma = rep(1, 8L),
    corpairs = list(),
    converged = TRUE
  )
  testthat::local_mocked_bindings(
    drm_julia_call_bridge = function(formula, family, data, tree, options) {
      captured$options <- options
      fake_result
    },
    .package = "drmTMB"
  )

  # Refuses instead of silently forwarding ML, and refuses BEFORE marshalling:
  # `captured$options` stays NULL because the mocked bridge call is never reached.
  captured$options <- NULL
  fit <- drmTMB:::drmTMB_julia_bridge(
    formula = count_phylo,
    family = stats::poisson(),
    data = dat,
    env = environment(),
    weights_missing = TRUE,
    control = NULL,
    impute = NULL,
    missing = drmTMB::miss_control(),
    REML = TRUE,
    call = quote(drmTMB())
  )
  # the request must REACH the engine as REML, not be quietly turned into ML
  expect_true("method" %in% names(captured$options))
  expect_identical(captured$options$method, "REML")
  expect_true(fit$requested_REML)
})

# --- Live σ-phylo REML round-trip (guarded) ---------------------------------
#
# Runs in a FRESH R subprocess (callr) so the σ-phylo-REML-capable DRM.jl engine
# at jl_path is the one loaded for this fit, independent of test order.

drm_sigma_phylo_reml_path <- function() {
  drm_test_drmjl_path()
}

drm_sigma_phylo_reml_fits <- function(n_tip = 32L) {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_sigma_phylo_reml_path()
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

      set.seed(202606L)
      tree <- ape::rcoal(n_tip)
      sp <- tree$tip.label
      x <- stats::rnorm(n_tip)
      bm_mu <- ape::rTraitCont(tree, model = "BM", sigma = 0.5)
      bm_sig <- ape::rTraitCont(tree, model = "BM", sigma = 0.4)
      log_sigma <- -0.2 + bm_sig[sp]
      mu <- 0.3 + 0.4 * x + bm_mu[sp]
      y <- stats::rnorm(n_tip, mean = mu, sd = exp(log_sigma))
      dat <- data.frame(species = sp, x = x, y = y, stringsAsFactors = FALSE)

      sigma_only <- drmTMB::bf(
        y ~ x,
        sigma ~ phylo(1 | species, tree = tree)
      )
      mu_sigma <- drmTMB::bf(
        y ~ x + phylo(1 | species, tree = tree),
        sigma ~ phylo(1 | species, tree = tree)
      )

      summarize <- function(form) {
        fj <- drmTMB::drmTMB(
          form,
          family = stats::gaussian(),
          data = dat,
          engine = "julia",
          REML = TRUE
        )
        sd_name <- "phylo(1 | species)"
        sd_mu <- if (sd_name %in% names(fj$sdpars$mu)) {
          fj$sdpars$mu[[sd_name]]
        } else {
          NA_real_
        }
        sd_sigma <- if (sd_name %in% names(fj$sdpars$sigma)) {
          fj$sdpars$sigma[[sd_name]]
        } else {
          NA_real_
        }
        list(
          class = class(fj),
          engine = fj$engine,
          nobs = stats::nobs(fj),
          loglik = as.numeric(stats::logLik(fj)),
          coef_mu = unname(stats::coef(fj, "mu")),
          sd_mu = unname(sd_mu),
          sd_sigma = unname(sd_sigma),
          converged = drmTMB::is_converged(fj),
          requested_REML = isTRUE(fj$requested_REML),
          effective_REML = isTRUE(fj$effective_REML)
        )
      }

      list(
        sigma_only = summarize(sigma_only),
        mu_sigma = summarize(mu_sigma)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "error"
  )
}

test_that("Gaussian sigma-phylo REML fit via engine = 'julia' is finite and sane", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_sigma_phylo_reml_path()),
    "DRM.jl sigma-phylo REML engine not available"
  )

  # sigma-phylo REML round-trip: run bare so an engine error is a test
  # ERROR, not a swallowed skip (#1127). (Previously this also skipped when
  # the engine predated sigma-phylo REML support -- method = :REML is
  # currently implemented only ...; the pinned engine now supports it, per
  # the R-side gate relax covered by the unit tests above.)
  #
  # Previously broken (DRM.jl clone 77513aa0, 2026-09-03, #1127 live run):
  # the coef_labels dpar "resd_sigma" (Julia name
  # resd_sigma_species:sd_sigma) was not covered by the R-side coef_labels
  # dict. Fixed by N9 (2026-09-03, design 258 S7.7 amendment) -- see
  # `drm_julia_bridge_payload_coef_labels()`, R/julia-bridge.R.
  res <- drm_sigma_phylo_reml_fits(n_tip = 32L)

  for (fit in res) {
    expect_true("drmTMB_julia" %in% fit$class)
    expect_equal(fit$engine, "julia")
    expect_equal(fit$nobs, 32L)
    expect_true(is.finite(fit$loglik))
    expect_true(all(is.finite(fit$coef_mu)))
    expect_true(is.finite(fit$sd_sigma) && fit$sd_sigma > 0)
    expect_true(isTRUE(fit$converged))
    expect_true(isTRUE(fit$requested_REML))
    expect_true(isTRUE(fit$effective_REML))
  }
  expect_true(is.na(res$sigma_only$sd_mu))
  expect_true(is.finite(res$mu_sigma$sd_mu) && res$mu_sigma$sd_mu > 0)
})
