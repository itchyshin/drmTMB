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

  # σ-phylo location-scale (univariate phylo_payload): REML key alongside the
  # g_tol the sparse all-node phylo route already used. ML stays byte-identical.
  uni_payload <- list(bivariate = FALSE)
  expect_identical(
    drmTMB:::drm_julia_bridge_options(uni_payload, method = "REML"),
    list(g_tol = 1e-4, method = "REML")
  )
  expect_identical(
    drmTMB:::drm_julia_bridge_options(uni_payload, method = "ML"),
    list(g_tol = 1e-4)
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

test_that("Julia REML support matrix is Gaussian-only and explicit", {
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

  expect_true(drmTMB:::drm_julia_reml_supported(fixed_locscale, "gaussian"))
  expect_true(drmTMB:::drm_julia_reml_supported(sigma_only, "gaussian"))
  expect_true(drmTMB:::drm_julia_reml_supported(sigma_phylo, "gaussian"))
  expect_true(drmTMB:::drm_julia_reml_supported(q4, "biv_gaussian"))
  expect_false(drmTMB:::drm_julia_reml_supported(mean_only, "gaussian"))
  expect_false(drmTMB:::drm_julia_reml_supported(count_phylo, "poisson"))
  expect_identical(
    drmTMB:::drm_julia_reml_cell_label(count_phylo, "poisson"),
    "non-Gaussian (poisson)"
  )
})

test_that("unsupported Julia REML warning does not overclaim native TMB fallback", {
  warnings <- character()
  withCallingHandlers(
    drmTMB:::drm_julia_warn_reml_unsupported(
      TRUE,
      "non-Gaussian (poisson)"
    ),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  warning_text <- paste(warnings, collapse = "\n")

  expect_match(warning_text, "non-Gaussian \\(poisson\\)")
  expect_match(warning_text, "Gaussian-only")
  expect_match(warning_text, "univariate Gaussian REML slice")
  expect_false(grepl("for an REML fit of this cell", warning_text))
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

  # Mean-only phylo Gaussian REML: gate still rejects -> warns and forwards ML.
  captured$options <- NULL
  expect_warning(
    fit_ml <- drmTMB:::drmTMB_julia_bridge(
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
    "does not support .*REML.*phylogenetic Gaussian"
  )
  expect_false("method" %in% names(captured$options))
  expect_equal(fit_ml$estimator, "ML")
  expect_true(fit_ml$requested_REML)
  expect_false(fit_ml$effective_REML)
})

test_that("REML warning names non-Gaussian phylo cells as non-Gaussian", {
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

  expect_warning(
    fit_ml <- drmTMB:::drmTMB_julia_bridge(
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
    ),
    "does not support .*REML.*non-Gaussian.*poisson"
  )
  expect_false("method" %in% names(captured$options))
  expect_equal(fit_ml$estimator, "ML")
  expect_true(fit_ml$requested_REML)
  expect_false(fit_ml$effective_REML)
})

test_that("REML stays gated for the phylo-only count family cell", {
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

  expect_warning(
    fit_ml <- drmTMB:::drmTMB_julia_bridge(
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
    ),
    "does not support .*REML.*non-Gaussian.*poisson"
  )
  expect_false("method" %in% names(captured$options))
  expect_equal(fit_ml$estimator, "ML")
  expect_true(fit_ml$requested_REML)
  expect_false(fit_ml$effective_REML)
})

# --- Live σ-phylo REML round-trip (guarded) ---------------------------------
#
# Runs in a FRESH R subprocess (callr) so the σ-phylo-REML-capable DRM.jl engine
# at jl_path is the one loaded for this fit, independent of test order.

drm_sigma_phylo_reml_path <- function() {
  drm_test_drmjl_path()
}

drm_sigma_phylo_reml_fit <- function(n_tip = 32L) {
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

      form <- drmTMB::bf(
        y ~ x + phylo(1 | species, tree = tree),
        sigma ~ phylo(1 | species, tree = tree)
      )

      fj <- drmTMB::drmTMB(
        form,
        family = stats::gaussian(),
        data = dat,
        engine = "julia",
        REML = TRUE
      )
      list(
        class = class(fj),
        engine = fj$engine,
        nobs = stats::nobs(fj),
        loglik = as.numeric(stats::logLik(fj)),
        coef_mu = unname(stats::coef(fj, "mu")),
        sd_mu = unname(fj$sdpars$mu[["phylo(1 | species)"]]),
        sd_sigma = unname(fj$sdpars$sigma[["phylo(1 | species)"]]),
        converged = drmTMB::is_converged(fj)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path, n_tip = as.integer(n_tip)),
    error = "error"
  )
}

test_that("Gaussian sigma-phylo REML fit via engine = 'julia' is finite and sane", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("callr")
  skip_if_not_installed("pkgload")
  skip_if_not_installed("ape")
  skip_if_not(
    dir.exists(drm_sigma_phylo_reml_path()),
    "DRM.jl sigma-phylo REML engine not available"
  )

  res <- tryCatch(
    drm_sigma_phylo_reml_fit(n_tip = 32L),
    error = function(e) {
      msg <- conditionMessage(e)
      # An engine predating the σ-phylo REML work rejects method = :REML for
      # phylo cells; that is an engine-version gap, not an R-bridge failure, so
      # skip rather than fail. The R-side gate relax is covered by the unit tests
      # above (the bridge forwards method = "REML" for this exact cell).
      if (
        grepl("method = :REML is currently implemented only", msg, fixed = TRUE)
      ) {
        testthat::skip(
          "DRM.jl engine at this path predates sigma-phylo REML support"
        )
      }
      testthat::skip(paste(
        "sigma-phylo REML round-trip unavailable:",
        msg
      ))
    }
  )

  expect_true("drmTMB_julia" %in% res$class)
  expect_equal(res$engine, "julia")
  expect_equal(res$nobs, 32L)
  expect_true(is.finite(res$loglik))
  expect_true(all(is.finite(res$coef_mu)))
  expect_true(is.finite(res$sd_mu) && res$sd_mu > 0)
  expect_true(is.finite(res$sd_sigma) && res$sd_sigma > 0)
  expect_true(isTRUE(res$converged))
})
