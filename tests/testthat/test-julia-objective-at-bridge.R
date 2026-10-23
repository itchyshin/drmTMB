# DRM.jl bridge counterpart of Objective-At-A-Point (#575 follow-up; A4).
#
# `drm_julia_reml_objective_at(fit, beta, Lambda, rho12 = NULL)` (internal,
# R/julia-bridge.R) rebuilds the bivariate q=4 phylogenetic REML problem from
# a Julia-engine fit's own stored bridge payload and evaluates DRM.jl's
# `reml_objective_at` at a supplied point. See
# docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-02-a5-cross-engine-receipt.R
# for the cross-engine receipt this wrapper feeds.

# The committed DRM.jl fixture is located through the SAME environment variable
# the bridge itself uses (DRM_JL_PATH, a checkout of DRM.jl); never a machine
# path. Live tests skip when it is absent (CI has no DRM.jl); the refuse tests
# below use a synthetic stand-in and run everywhere.
drm_objat_fixture_dir <- function() {
  root <- Sys.getenv("DRM_JL_PATH", "")
  if (!nzchar(root)) return(NA_character_)
  file.path(root, "test", "parity", "q4-reml", "biv-q4-phylo-reml")
}

drm_objat_fixture_formula <- function(tree) {
  bf(
    mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  )
}

drm_objat_fixture_data <- function() {
  dir <- drm_objat_fixture_dir()
  testthat::skip_if(
    is.na(dir) || !file.exists(file.path(dir, "data.csv")),
    "DRM.jl q4 fixture not available (set DRM_JL_PATH to a DRM.jl checkout)"
  )
  dat <- read.csv(file.path(dir, "data.csv"), stringsAsFactors = FALSE)
  tree <- ape::read.tree(file.path(dir, "tree.newick"))
  dat$species <- factor(dat$species, levels = tree$tip.label)
  list(data = dat, tree = tree)
}

# A minimal mock `drmTMB_julia` fit, class/family/dimension/REML-correct, for
# the two refuse tests that must run WITHOUT Julia (a Lambda shape check has
# no business needing a live engine).
# Synthetic stand-in for the fixture (same shape: two responses, one
# predictor, species on a small tree); needs neither DRM.jl nor Julia.
drm_objat_synthetic_data <- function() {
  set.seed(575)
  tree <- ape::rtree(16, tip.label = sprintf("sp%02d", seq_len(16)))
  species <- factor(rep(tree$tip.label, each = 2L), levels = tree$tip.label)
  n <- length(species)
  dat <- data.frame(
    y1 = stats::rnorm(n), y2 = stats::rnorm(n), x = stats::rnorm(n),
    species = species
  )
  list(data = dat, tree = tree)
}

drm_objat_mock_julia_fit <- function() {
  fx <- drm_objat_synthetic_data()
  form <- drm_objat_fixture_formula(fx$tree)
  result <- list(
    coef_names = c(
      "mu1_(Intercept)", "mu1_x", "mu2_(Intercept)", "mu2_x",
      "sigma1_(Intercept)", "sigma2_(Intercept)", "rho12_(Intercept)"
    ),
    coefficients = c(0.73, 0.34, 0.24, 0.47, -1.29, -0.44, 0.0656),
    vcov = diag(7),
    loglik = -219.6,
    aic = 460,
    bic = 480,
    df = 7L,
    nobs = nrow(fx$data),
    converged = TRUE,
    fitted = list(mu1 = fx$data$y1, mu2 = fx$data$y2),
    residuals = list(mu1 = rep(0, nrow(fx$data)), mu2 = rep(0, nrow(fx$data))),
    sigma = list(sigma1 = rep(0.27, nrow(fx$data)), sigma2 = rep(0.64, nrow(fx$data))),
    corpairs = rep(tanh(0.0656), nrow(fx$data))
  )
  fit <- drmTMB:::new_drmTMB_julia(
    result = result,
    call = quote(drmTMB(form, family = biv_gaussian(), data = fx$data, engine = "julia", REML = TRUE)),
    formula = form,
    family = biv_gaussian(),
    data = fx$data,
    family_type = "biv_gaussian",
    bridge_payload = list(
      formula = "placeholder",
      data = fx$data,
      tree = "placeholder",
      options = list()
    ),
    requested_REML = TRUE,
    effective_REML = TRUE
  )
  fit
}

test_that("drm_julia_reml_objective_at refuses a TMB-engine fit", {
  # Any native-engine fit must be refused on its class; no fixture, no Julia.
  set.seed(575)
  dat <- data.frame(y = stats::rnorm(40), x = stats::rnorm(40))
  fit_tmb <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat, engine = "tmb")
  Lambda <- diag(4)
  beta <- list(
    beta_mu1 = c(0, 0), beta_mu2 = c(0, 0),
    beta_sigma1 = 0, beta_sigma2 = 0
  )
  expect_error(
    drmTMB:::drm_julia_reml_objective_at(fit_tmb, beta = beta, Lambda = Lambda),
    class = "rlang_error"
  )
})

test_that("drm_julia_reml_objective_at refuses a non-4x4 or asymmetric Lambda", {
  fit <- drm_objat_mock_julia_fit()
  beta <- list(
    beta_mu1 = c(0, 0), beta_mu2 = c(0, 0),
    beta_sigma1 = 0, beta_sigma2 = 0
  )
  expect_error(
    drmTMB:::drm_julia_reml_objective_at(fit, beta = beta, Lambda = diag(3)),
    class = "rlang_error"
  )
  asymmetric <- diag(4)
  asymmetric[1, 2] <- 0.3
  expect_error(
    drmTMB:::drm_julia_reml_objective_at(fit, beta = beta, Lambda = asymmetric),
    class = "rlang_error"
  )
})

# --- Live Julia (guarded; a skip is a FAILURE under the A4 gates) -----------

test_that("drm_julia_reml_objective_at returns a finite reml_loglik on the fixture", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")

  fx <- drm_objat_fixture_data()
  form <- drm_objat_fixture_formula(fx$tree)
  fit_julia <- drmTMB(
    form,
    family = biv_gaussian(),
    data = fx$data,
    engine = "julia",
    REML = TRUE
  )

  Lambda <- drmTMB:::drm_julia_phylocov_matrix(fit_julia)
  beta <- list(
    beta_mu1 = unname(fit_julia$coefficients$mu1),
    beta_mu2 = unname(fit_julia$coefficients$mu2),
    beta_sigma1 = unname(fit_julia$coefficients$sigma1),
    beta_sigma2 = unname(fit_julia$coefficients$sigma2)
  )
  rho12_hat <- unname(fit_julia$coef_vector[["rho12_(Intercept)"]])

  res <- drmTMB:::drm_julia_reml_objective_at(
    fit_julia,
    beta = beta,
    Lambda = Lambda,
    rho12 = rho12_hat
  )
  expect_true(is.finite(res$reml_loglik))
})

test_that("drm_julia_reml_objective_at reproduces the Julia fit's own reml logLik at its own optimum (anchor)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")

  fx <- drm_objat_fixture_data()
  form <- drm_objat_fixture_formula(fx$tree)
  fit_julia <- drmTMB(
    form,
    family = biv_gaussian(),
    data = fx$data,
    engine = "julia",
    REML = TRUE
  )

  Lambda <- drmTMB:::drm_julia_phylocov_matrix(fit_julia)
  beta <- list(
    beta_mu1 = unname(fit_julia$coefficients$mu1),
    beta_mu2 = unname(fit_julia$coefficients$mu2),
    beta_sigma1 = unname(fit_julia$coefficients$sigma1),
    beta_sigma2 = unname(fit_julia$coefficients$sigma2)
  )

  res <- drmTMB:::drm_julia_reml_objective_at(fit_julia, beta = beta, Lambda = Lambda)

  own_ll <- as.numeric(logLik(fit_julia))
  expect_true(is.finite(res$reml_loglik))
  expect_lt(abs(res$reml_loglik - own_ll), 2e-4)
})
