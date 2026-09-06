# leaf-biv-animal-reml: admit REML for the bivariate Gaussian animal() q2
# route in drmTMB. Before this leaf, drm_validate_reml_spec_biv() admitted
# phylo(), spatial(1 | p | site, coords = coords), and relmat(1 | p | id,
# K = K) intercepts but refused animal(1 | p | id, A = A) with the same
# shape, purely on the marker NAME (see docs/design/211-structured-reml-
# status.md and the scope note in the admission-matrix design doc). TMB's own
# C++ q2 quadratic-form block is provider-agnostic (no branch on marker
# identity), and DRM.jl's own REML implementation calls the IDENTICAL
# make_coevo_problem_from_covariance() path for animal and relmat -- see the
# same-target receipt below and docs/dev-log/evidence/julia-r-parity/reml/
# biv-animal-q2-receipt.md.
#
# Mirrors the fixture pattern in test-reml-bivariate-relmat-q2.R (x1 != x2
# design, which TMB's own route tolerates); a second, SHARED-x fixture is
# used only for the DRM.jl same-target test, because DRM.jl's own bivariate
# q2 structured route requires mu1 and mu2 to share one fixed-effect design
# ("drm: bivariate q=2 structured Julia route currently requires mu1 and mu2
# to use the same fixed-effect design", DRM.jl src/gaussian_bivariate.jl).

biv_animal_reml_K <- function(g) {
  level <- sprintf("id_%03d", seq_len(g))
  K <- outer(seq_len(g), seq_len(g), function(i, j) 0.4^abs(i - j))
  dimnames(K) <- list(level, level)
  K
}

biv_animal_reml_fixture <- function(seed = 2026071502L, g = 14L, m = 4L) {
  set.seed(seed)
  K <- biv_animal_reml_K(g)
  level <- rownames(K)
  L <- t(chol(K))
  truth <- c(
    tau1 = 0.80,
    tau2 = 0.65,
    rho_K = 0.35,
    sigma1 = 0.30,
    sigma2 = 0.35,
    rho12 = -0.20
  )
  z1 <- stats::rnorm(g)
  z2 <- stats::rnorm(g)
  u1 <- truth[["tau1"]] * as.vector(L %*% z1)
  u2 <- truth[["tau2"]] * as.vector(
    L %*% (
      truth[["rho_K"]] * z1 +
        sqrt(1 - truth[["rho_K"]]^2) * z2
    )
  )
  names(u1) <- names(u2) <- level
  id <- factor(rep(level, each = m), levels = level)
  x1 <- stats::rnorm(length(id))
  x2 <- stats::rnorm(length(id))
  e1 <- stats::rnorm(length(id))
  e2 <- truth[["rho12"]] * e1 +
    sqrt(1 - truth[["rho12"]]^2) * stats::rnorm(length(id))
  data <- data.frame(
    y1 = 0.30 + 0.50 * x1 + u1[as.character(id)] + truth[["sigma1"]] * e1,
    y2 = -0.20 - 0.25 * x2 + u2[as.character(id)] + truth[["sigma2"]] * e2,
    x1 = x1,
    x2 = x2,
    id = id
  )
  list(data = data, K = K, truth = truth)
}

biv_animal_reml_animal_formula <- function(A) {
  force(A)
  bf(
    mu1 = y1 ~ x1 + animal(1 | p | id, A = A),
    mu2 = y2 ~ x2 + animal(1 | p | id, A = A),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
}

biv_animal_reml_relmat_formula <- function(K) {
  force(K)
  bf(
    mu1 = y1 ~ x1 + relmat(1 | p | id, K = K),
    mu2 = y2 ~ x2 + relmat(1 | p | id, K = K),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  )
}

# Dense restricted-likelihood oracle: brute-force GLS/REML on the full
# 2n x 2n covariance V = tau^2 (x) K + sigma^2 (x) I, independent of marker
# name (same construction as test-reml-bivariate-relmat-q2.R's oracle).
biv_animal_reml_problem <- function(fx) {
  dat <- fx$data
  index <- match(as.character(dat$id), rownames(fx$K))
  K_obs <- fx$K[index, index, drop = FALSE]
  n <- nrow(dat)
  X1 <- stats::model.matrix(~x1, dat)
  X2 <- stats::model.matrix(~x2, dat)
  X <- rbind(
    cbind(X1, matrix(0, n, ncol(X2))),
    cbind(matrix(0, n, ncol(X1)), X2)
  )
  y <- c(dat$y1, dat$y2)
  identity_n <- diag(n)

  nll <- function(par) {
    tau1 <- exp(par[[1L]])
    tau2 <- exp(par[[2L]])
    rho_K <- 0.999999 * tanh(par[[3L]])
    sigma1 <- exp(par[[4L]])
    sigma2 <- exp(par[[5L]])
    rho12 <- 0.999999 * tanh(par[[6L]])
    V11 <- tau1^2 * K_obs + sigma1^2 * identity_n
    V22 <- tau2^2 * K_obs + sigma2^2 * identity_n
    V12 <- rho_K * tau1 * tau2 * K_obs + rho12 * sigma1 * sigma2 * identity_n
    V <- rbind(cbind(V11, V12), cbind(V12, V22))
    chol_V <- chol(V)
    ViX <- backsolve(chol_V, forwardsolve(t(chol_V), X))
    Viy <- backsolve(chol_V, forwardsolve(t(chol_V), y))
    XtViX <- crossprod(X, ViX)
    beta <- solve(XtViX, crossprod(X, Viy))
    residual <- y - as.vector(X %*% beta)
    Vir <- backsolve(chol_V, forwardsolve(t(chol_V), residual))
    0.5 * (
      (length(y) - ncol(X)) * log(2 * pi) +
        2 * sum(log(diag(chol_V))) +
        as.numeric(determinant(XtViX, logarithm = TRUE)$modulus) +
        sum(residual * Vir)
    )
  }
  list(nll = nll)
}

biv_animal_reml_tmb_to_common <- function(fit) {
  par <- fit$opt$par
  take <- function(name) unname(par[names(par) == name])
  c(
    take("log_sd_phylo")[[1L]],
    take("log_sd_phylo")[[2L]],
    take("eta_cor_phylo")[[1L]],
    take("beta_sigma1")[[1L]],
    take("beta_sigma2")[[1L]],
    take("beta_rho12")[[1L]]
  )
}

test_that("bivariate animal() A q2 REML is admitted and cross-provider guarded", {
  fx <- biv_animal_reml_fixture()
  fit <- drmTMB(
    biv_animal_reml_animal_formula(fx$K),
    family = biv_gaussian(),
    data = fx$data,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )

  expect_true(drmTMB:::drm_reml_admits_biv_animal_q2_intercept(fit$model))
  for (provider in c("relmat", "spatial", "phylo")) {
    other_provider <- fit$model
    other_provider$structured$phylo_mu$type <- provider
    expect_false(
      drmTMB:::drm_reml_admits_biv_animal_q2_intercept(other_provider),
      info = provider
    )
  }
})

test_that("bivariate animal() A q2 REML matches the relmat() control to 1e-8", {
  fx <- biv_animal_reml_fixture()
  fit_animal <- drmTMB(
    biv_animal_reml_animal_formula(fx$K),
    family = biv_gaussian(),
    data = fx$data,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  fit_relmat <- drmTMB(
    biv_animal_reml_relmat_formula(fx$K),
    family = biv_gaussian(),
    data = fx$data,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )

  expect_identical(fit_animal$estimator, "REML")
  expect_identical(fit_animal$opt$convergence, 0L)
  expect_identical(
    fit_animal$model$tmb_random_names,
    c("u_phylo", "beta_mu1", "beta_mu2")
  )
  # Same K matrix under a different marker name is the SAME mathematics: TMB's
  # q2 quadratic-form block has no branch on provider identity (see the
  # receipt), so the two fits must agree essentially to solver precision, not
  # merely to statistical tolerance.
  expect_equal(fit_animal$opt$objective, fit_relmat$opt$objective, tolerance = 1e-8)
  expect_equal(fit_animal$opt$par, fit_relmat$opt$par, tolerance = 1e-8)
  expect_equal(
    as.numeric(stats::logLik(fit_animal)),
    as.numeric(stats::logLik(fit_relmat)),
    tolerance = 1e-8
  )
  expect_equal(attr(stats::logLik(fit_animal), "df"), length(fit_animal$opt$par) + 4L)
})

test_that("bivariate animal() A q2 REML matches dense restricted likelihood", {
  fx <- biv_animal_reml_fixture()
  fit <- drmTMB(
    biv_animal_reml_animal_formula(fx$K),
    family = biv_gaussian(),
    data = fx$data,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  problem <- biv_animal_reml_problem(fx)
  common <- biv_animal_reml_tmb_to_common(fit)
  expect_equal(problem$nll(common), fit$opt$objective, tolerance = 1e-5)

  truth <- fx$truth
  start <- c(
    log(truth[["tau1"]]),
    log(truth[["tau2"]]),
    atanh(truth[["rho_K"]] / 0.999999),
    log(truth[["sigma1"]]),
    log(truth[["sigma2"]]),
    atanh(truth[["rho12"]] / 0.999999)
  )
  oracle <- stats::optim(
    start,
    problem$nll,
    method = "BFGS",
    control = list(reltol = 1e-12, maxit = 2000L)
  )
  expect_identical(oracle$convergence, 0L)
  expect_equal(common, oracle$par, tolerance = 2e-3)
})

test_that("bivariate animal() A q2 REML reports honest estimator and labels", {
  fx <- biv_animal_reml_fixture()
  fit <- drmTMB(
    biv_animal_reml_animal_formula(fx$K),
    family = biv_gaussian(),
    data = fx$data,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_identical(fit$estimator, "REML")
  expect_named(
    fit$sdpars$mu,
    c("mu1:animal(1 | p | id)", "mu2:animal(1 | p | id)")
  )
  expect_named(
    fit$corpars$animal,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | id)"
  )
  pair <- corpairs(fit, level = "animal")
  expect_equal(pair$estimate, unname(fit$corpars$animal))
})

test_that("bivariate animal() A q2 REML unsupported representations still refuse", {
  fx <- biv_animal_reml_fixture()
  Q_animal <- solve(fx$K)
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x1 + animal(1 | p | id, Ainv = Q_animal),
        mu2 = y2 ~ x2 + animal(1 | p | id, Ainv = Q_animal),
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = fx$data, REML = TRUE
    ),
    "precision"
  )
})

test_that("bivariate animal() A q2 REML matches native DRM.jl REML (same-target receipt)", {
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")

  # Shared-x fixture: DRM.jl's own bivariate q2 structured route requires mu1
  # and mu2 to use the SAME fixed-effect design.
  set.seed(2026090501L)
  g <- 14L
  m <- 4L
  K <- biv_animal_reml_K(g)
  level <- rownames(K)
  L <- t(chol(K))
  truth <- c(
    tau1 = 0.80, tau2 = 0.65, rho_K = 0.35,
    sigma1 = 0.30, sigma2 = 0.35, rho12 = -0.20
  )
  z1 <- stats::rnorm(g)
  z2 <- stats::rnorm(g)
  u1 <- truth[["tau1"]] * as.vector(L %*% z1)
  u2 <- truth[["tau2"]] * as.vector(
    L %*% (truth[["rho_K"]] * z1 + sqrt(1 - truth[["rho_K"]]^2) * z2)
  )
  names(u1) <- names(u2) <- level
  id <- factor(rep(level, each = m), levels = level)
  x <- stats::rnorm(length(id))
  e1 <- stats::rnorm(length(id))
  e2 <- truth[["rho12"]] * e1 +
    sqrt(1 - truth[["rho12"]]^2) * stats::rnorm(length(id))
  dat <- data.frame(
    y1 = 0.30 + 0.50 * x + u1[as.character(id)] + truth[["sigma1"]] * e1,
    y2 = -0.20 - 0.25 * x + u2[as.character(id)] + truth[["sigma2"]] * e2,
    x = x,
    id = id
  )

  fit_tmb <- drmTMB(
    bf(
      mu1 = y1 ~ x + animal(1 | p | id, A = K),
      mu2 = y2 ~ x + animal(1 | p | id, A = K),
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    REML = TRUE,
    control = drm_control(optimizer_preset = "robust")
  )
  expect_identical(fit_tmb$estimator, "REML")

  drmTMB:::drm_julia_setup()
  JuliaCall::julia_command(paste(
    sep = "\n",
    "function drmTMB_test_biv_animal_reml_oracle(y1, y2, x, id, A)",
    "    dat = (y1 = Float64.(y1), y2 = Float64.(y2), x = Float64.(x), id = String.(id))",
    "    form = bf(mu1 = @formula(y1 ~ x + animal(1 | id)),",
    "              mu2 = @formula(y2 ~ x + animal(1 | id)),",
    "              sigma1 = @formula(sigma1 ~ 1),",
    "              sigma2 = @formula(sigma2 ~ 1),",
    "              rho12  = @formula(rho12 ~ 1))",
    "    fit = drm(form, Gaussian(); data = dat, A = Matrix{Float64}(A), method = :REML)",
    "    Dict{String,Any}(",
    "        \"estim_method\" => String(estimation_method(fit)),",
    "        \"converged\" => fit.converged,",
    "        \"reml_loglik\" => reml_loglik(fit),",
    "        \"theta\" => fit.theta,",
    "        \"coefnames_mu1\" => String.(Dict(fit.coefnames)[:mu1]),",
    "        \"coefnames_mu2\" => String.(Dict(fit.coefnames)[:mu2]),",
    "        \"vcov_diag\" => diag(fit.vcov),",
    "    )",
    "end"
  ))
  oracle <- JuliaCall::julia_call(
    "drmTMB_test_biv_animal_reml_oracle",
    dat$y1, dat$y2, dat$x, as.character(dat$id), K
  )

  expect_identical(oracle$estim_method, "REML")
  expect_true(oracle$converged)
  expect_identical(oracle$coefnames_mu1, c("(Intercept)", "x"))
  expect_identical(oracle$coefnames_mu2, c("(Intercept)", "x"))

  expect_equal(
    as.numeric(stats::logLik(fit_tmb)),
    oracle$reml_loglik,
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit_tmb$par$mu1),
    oracle$theta[1:2],
    tolerance = 1e-4
  )
  expect_equal(
    unname(fit_tmb$par$mu2),
    oracle$theta[3:4],
    tolerance = 1e-4
  )
  # DRM.jl returns no vcov for the bivariate q2 structured route (ML or
  # REML) -- this is a pre-existing DRM.jl boundary, not a defect introduced
  # by this leaf, and not something this leaf's Scope covers fixing. See the
  # receipt for the quoted NaN vector.
  expect_true(all(is.nan(oracle$vcov_diag)))
})
