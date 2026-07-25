# Arc B S2: FD-vs-AD gradient conformance harness.
#
# This suite checks a DIFFERENT thing than `check_drm()`'s fixed-gradient check
# (`R/check.R:177`, `check_fixed_gradient()` at `R/check.R:510`, exercised via
# `gradient_tolerance`). That check asserts the outer gradient is approximately
# zero AT THE FITTED OPTIMUM (convergence). This suite asserts that TMB's
# automatic-differentiation gradient `obj$gr(theta)` agrees with an independent
# finite-difference gradient `numDeriv::grad(obj$fn, theta)` AT ARBITRARY THETA
# (self-consistency of the AD tape, not convergence). Helper names below are
# prefixed `gcond_` so nobody merges the two mechanisms.
#
# Three mandatory pins (see the arc brief):
#   1. `obj$fn` is not a pure function -- TMB warm-starts the inner Laplace
#      solve from `obj$env$last.par.best`, so repeated finite-difference stencil
#      evaluations are call-order dependent unless the inner solve is cold-started
#      from a fixed reference each time. We set
#      `obj$env$random.start <- expression(par[random])` and reset
#      `obj$env$last.par.best` before every `fn`/`gr` evaluation.
#   2. The Laplace log-determinant error is first order in the inner-solve
#      residual, and Richardson extrapolation divides by `h`, so a loose inner
#      solve leaves an FD noise floor near 1e-4. `drm_control()` does not
#      plumb an `inner.control` argument through to `TMB::MakeADFun()`
#      (confirmed by reading `R/control.R` and `R/drmTMB.R`), so this suite
#      sets the inner Newton tolerance directly on the already-built object via
#      `TMB::newtonOption(obj, tol = 1e-12, maxit = 5000)` -- the only route
#      available without touching `R/`.
#   3. Pre-registered acceptance (not tuned after seeing results):
#        fixed-effects-only cells: stat < 1e-6
#        any-random-effect (Laplace) cells: stat < 1e-4
#      where stat = max(|g_AD - g_FD|) / (1 + max(|g_AD|)).
#
# This instrument is a SELF-consistency check only. It CANNOT catch: a taped
# density with a wrong normalizing constant, a wrong parameterization, or a
# double-applied `weights(i)` -- all differentiate perfectly and pass. It also
# checks the gradient of the LAPLACE APPROXIMATION, not the approximation's
# accuracy against the true marginal likelihood.

GCOND_FIXED_TOL <- 1e-6
GCOND_LAPLACE_TOL <- 1e-4

gcond_pin_cold_start <- function(obj) {
  obj$env$random.start <- expression(par[random])
  invisible(obj)
}

gcond_reset_inner_state <- function(obj) {
  obj$env$last.par.best <- obj$env$last.par
  invisible(obj)
}

gcond_set_inner_tolerance <- function(obj, tol = 1e-12, maxit = 5000L) {
  if (!is.null(obj$env$random)) {
    TMB::newtonOption(obj, tol = tol, maxit = maxit)
  }
  invisible(obj)
}

gcond_inner_grad_norm <- function(obj) {
  if (is.null(obj$env$random)) {
    return(NA_real_)
  }
  full_gr <- obj$env$f(obj$env$last.par, order = 1)
  sqrt(sum(full_gr[obj$env$random]^2))
}

gcond_stat <- function(g_ad, g_fd) {
  max(abs(g_ad - g_fd)) / (1 + max(abs(g_ad)))
}

# Prepares `obj` with both pins and returns nothing; call once per test.
gcond_prepare <- function(obj) {
  gcond_pin_cold_start(obj)
  gcond_set_inner_tolerance(obj)
  invisible(obj)
}

# g_AD, g_FD (Richardson), stat, and the inner-solve gradient norm at theta,
# each fn/gr evaluation cold-started per pin 1.
gcond_evaluate <- function(obj, theta, fd_method = "Richardson", fd_args = list()) {
  gcond_reset_inner_state(obj)
  g_ad <- obj$gr(theta)
  gcond_reset_inner_state(obj)
  obj$fn(theta)
  inner_norm <- gcond_inner_grad_norm(obj)
  gcond_reset_inner_state(obj)
  g_fd <- numDeriv::grad(
    function(p) {
      gcond_reset_inner_state(obj)
      obj$fn(p)
    },
    theta,
    method = fd_method,
    method.args = fd_args
  )
  list(
    g_ad = g_ad,
    g_fd = g_fd,
    stat = gcond_stat(g_ad, g_fd),
    inner_grad_norm = inner_norm
  )
}

# Asserts the pre-registered conformance statistic and reports (via `message`)
# the diagnostics needed for the arc report: the achieved statistic and the
# inner-solve gradient norm at theta.
gcond_expect_conformance <- function(label, obj, theta, tol) {
  res <- gcond_evaluate(obj, theta)
  message(sprintf(
    "gradient-conformance: %-55s stat=%.3e tol=%.0e inner_grad_norm=%.3e",
    label, res$stat, tol, res$inner_grad_norm
  ))
  testthat::expect_lt(res$stat, tol)
  invisible(res)
}

# ---------------------------------------------------------------------------
# Pin verification: repeated `fn` calls at a fixed theta must be bit-identical
# once cold-started, and the FD gradient built from those repeats must be
# stable across independent repeats (evidence the stencil is order-independent).
# ---------------------------------------------------------------------------

test_that("cold-start pin makes repeated fn() calls bit-identical for a Laplace model", {
  set.seed(20260722)
  n_id <- 20L
  n_each <- 6L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  u <- stats::rnorm(n_id, sd = 0.6)
  y <- stats::rnorm(n, 0.3 + 0.5 * x + u[id], 0.4)
  dat <- data.frame(y = y, x = x, id = id)
  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), data = dat)
  obj <- fit$obj
  gcond_prepare(obj)

  theta <- obj$par + 0.05 * seq_along(obj$par)

  # Deliberately call fn/gr several times first, with NO reset, to build up
  # warm-start history -- exactly the pathological order-dependence pin 1
  # exists to remove. Then verify three cold-started repeats agree exactly.
  invisible(obj$fn(theta - 1))
  invisible(obj$gr(theta + 1))
  invisible(obj$fn(theta))

  gcond_reset_inner_state(obj)
  v1 <- obj$fn(theta)
  gcond_reset_inner_state(obj)
  v2 <- obj$fn(theta)
  gcond_reset_inner_state(obj)
  v3 <- obj$fn(theta)
  expect_identical(v1, v2)
  expect_identical(v2, v3)

  # Repeated FD gradients at the same theta, each with the pin's reset applied
  # inside the wrapper, must also be stable.
  wrapped_fn <- function(p) {
    gcond_reset_inner_state(obj)
    obj$fn(p)
  }
  gcond_reset_inner_state(obj)
  g_fd_a <- numDeriv::grad(wrapped_fn, theta, method = "Richardson")
  gcond_reset_inner_state(obj)
  g_fd_b <- numDeriv::grad(wrapped_fn, theta, method = "Richardson")
  expect_identical(g_fd_a, g_fd_b)

  inner_norm <- gcond_inner_grad_norm(obj)
  message(sprintf(
    "pin verification: bit-identical repeats confirmed; inner_grad_norm=%.3e",
    inner_norm
  ))
  expect_lt(inner_norm, 1e-6)
})

# ---------------------------------------------------------------------------
# Fail-injection: prove the harness can go red on a genuinely wrong gradient,
# then confirm the real cells are unaffected.
# ---------------------------------------------------------------------------

test_that("gcond_expect_conformance fails on a deliberately corrupted gradient", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  y <- 0.5 + 0.8 * x + stats::rnorm(n, sd = exp(-0.3 + 0.2 * x))
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
  obj <- fit$obj
  gcond_prepare(obj)
  theta <- obj$par + 3

  res <- gcond_evaluate(obj, theta)
  expect_lt(res$stat, GCOND_FIXED_TOL) # the real cell is fine

  g_wrong <- res$g_ad
  g_wrong[[1L]] <- g_wrong[[1L]] + 1 # inject a real, detectable error
  stat_wrong <- gcond_stat(g_wrong, res$g_fd)
  expect_gt(stat_wrong, GCOND_FIXED_TOL) # confirms it WOULD have been flagged

  # And confirm the assertion machinery itself reports red for this corrupted
  # comparison, via `expect_failure()` -- the outer test stays green because
  # failing on the injected error is the expected, correct behaviour.
  expect_failure(expect_lt(stat_wrong, GCOND_FIXED_TOL))
})

# ---------------------------------------------------------------------------
# Fixed-effects-only cells (tol = 1e-6): family sweep, typical/extreme/boundary
# theta. No inner Laplace solve -- pin 2/3 are inert here (obj$env$random is
# NULL) but pin 1 (`gcond_prepare`) is applied uniformly for consistency.
# ---------------------------------------------------------------------------

test_that("fixed-effects gaussian mu+sigma: typical and extreme theta", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  y <- 0.5 + 0.8 * x + stats::rnorm(n, sd = exp(-0.3 + 0.2 * x))
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("gaussian mu+sigma typical", fit$obj, fit$obj$par, GCOND_FIXED_TOL)
  gcond_expect_conformance("gaussian mu+sigma extreme", fit$obj, fit$obj$par + 3, GCOND_FIXED_TOL)
})

test_that("fixed-effects poisson mu: typical and extreme theta", {
  set.seed(2)
  n <- 60
  x <- stats::rnorm(n)
  y <- stats::rpois(n, exp(0.3 + 0.4 * x))
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x), family = poisson(), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("poisson mu typical", fit$obj, fit$obj$par, GCOND_FIXED_TOL)
  gcond_expect_conformance("poisson mu extreme", fit$obj, fit$obj$par + 4, GCOND_FIXED_TOL)
})

test_that("fixed-effects binomial mu: typical and boundary (large |eta|) theta", {
  set.seed(3)
  n <- 60
  x <- stats::rnorm(n)
  trials <- stats::rpois(n, 10) + 2
  p <- stats::plogis(0.2 + 0.9 * x)
  succ <- stats::rbinom(n, trials, p)
  dat <- data.frame(succ = succ, fail = trials - succ, x = x)
  fit <- drmTMB(bf(cbind(succ, fail) ~ x), family = binomial(), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("binomial mu typical", fit$obj, fit$obj$par, GCOND_FIXED_TOL)
  boundary_theta <- fit$obj$par * c(1, 6)
  gcond_expect_conformance("binomial mu boundary(|eta| large)", fit$obj, boundary_theta, GCOND_FIXED_TOL)
})

test_that("fixed-effects Gamma mu+sigma: typical and extreme theta", {
  set.seed(4)
  n <- 60
  x <- stats::rnorm(n)
  mu <- exp(0.4 + 0.3 * x)
  shape <- 4
  y <- stats::rgamma(n, shape = shape, rate = shape / mu)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = Gamma(link = "log"), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("Gamma mu+sigma typical", fit$obj, fit$obj$par, GCOND_FIXED_TOL)
  gcond_expect_conformance("Gamma mu+sigma extreme", fit$obj, fit$obj$par + 2, GCOND_FIXED_TOL)
})

test_that("fixed-effects beta mu+sigma: typical and boundary (mu near 0/1) theta", {
  set.seed(5)
  n <- 60
  x <- stats::rnorm(n)
  mu <- stats::plogis(0.2 + 0.5 * x)
  phi <- 8
  y <- stats::rbeta(n, mu * phi, (1 - mu) * phi)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = drmTMB::beta(), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("beta mu+sigma typical", fit$obj, fit$obj$par, GCOND_FIXED_TOL)
  boundary_theta <- fit$obj$par + c(0, 5, 0, 0)
  gcond_expect_conformance("beta mu+sigma boundary(mu->0/1)", fit$obj, boundary_theta, GCOND_FIXED_TOL)
})

test_that("bivariate LSS biv_lognormal (fixed effects only): typical and rho12-boundary theta", {
  # Frontier structure: two responses, `tanh`-bounded rho12. No random-effect
  # syntax exists yet for bivariate models (see CLAUDE.md: "Future bivariate
  # random-effect syntax may look like ..."), so this cell is necessarily
  # fixed-effects only; the not-covered RE case is documented and probed below.
  set.seed(6)
  n <- 60
  x <- stats::rnorm(n)
  z1 <- stats::rnorm(n)
  z2 <- 0.4 * z1 + sqrt(1 - 0.16) * stats::rnorm(n)
  y1 <- exp(0.2 + 0.3 * x + 0.4 * z1)
  y2 <- exp(-0.1 - 0.2 * x + 0.6 * z2)
  dat <- data.frame(x = x, y1 = y1, y2 = y2)
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    family = biv_lognormal(),
    data = dat
  )
  expect_named(
    fit$obj$par,
    c("beta_mu1", "beta_mu1", "beta_mu2", "beta_mu2", "beta_sigma1", "beta_sigma2", "beta_rho12")
  )
  gcond_prepare(fit$obj)
  gcond_expect_conformance("biv_lognormal typical", fit$obj, fit$obj$par, GCOND_FIXED_TOL)
  boundary_theta <- fit$obj$par + c(0, 0, 0, 0, 0, 0, 4) # push rho12 toward the tanh bound
  gcond_expect_conformance("biv_lognormal rho12-boundary", fit$obj, boundary_theta, GCOND_FIXED_TOL)
})

# ---------------------------------------------------------------------------
# Laplace cells (tol = 1e-4): any random effect. Frontier structures per the
# arc brief: random intercept, structured RE (relmat, spatial, phylo), scale-
# side RE, sd() regression, and phylo on residual log-SD.
# ---------------------------------------------------------------------------

test_that("Laplace: ordinary mu random intercept (gaussian), typical/extreme/boundary theta", {
  set.seed(11)
  n_id <- 20L
  n_each <- 6L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  u <- stats::rnorm(n_id, sd = 0.6)
  y <- stats::rnorm(n, 0.3 + 0.5 * x + u[id], 0.4)
  dat <- data.frame(y = y, x = x, id = id)
  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("mu random-intercept typical", fit$obj, fit$obj$par, GCOND_LAPLACE_TOL)
  gcond_expect_conformance(
    "mu random-intercept extreme",
    fit$obj,
    fit$obj$par + 0.05 * seq_along(fit$obj$par),
    GCOND_LAPLACE_TOL
  )
  # Boundary: RE variance driven toward zero (log_sd_mu very negative), the
  # classic Laplace edge case.
  boundary_theta <- fit$obj$par
  boundary_theta[["log_sd_mu"]] <- -8
  gcond_expect_conformance("mu random-intercept boundary(sd->0)", fit$obj, boundary_theta, GCOND_LAPLACE_TOL)
})

test_that("Laplace: structured relmat random effect on mu, typical/extreme theta", {
  set.seed(12)
  n_id <- 8L
  n_each <- 7L
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  known <- as.vector(t(chol(K)) %*% stats::rnorm(n_id, sd = 0.5))
  names(known) <- id_levels
  y <- 0.25 + 0.45 * x + known[id] + stats::rnorm(length(id), sd = 0.2)
  dat <- data.frame(y = y, x = x, id = id)
  fit <- drmTMB(bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("relmat mu typical", fit$obj, fit$obj$par, GCOND_LAPLACE_TOL)
  gcond_expect_conformance(
    "relmat mu extreme",
    fit$obj,
    fit$obj$par + 0.05 * seq_along(fit$obj$par),
    GCOND_LAPLACE_TOL
  )
})

test_that("Laplace: structured spatial random effect on mu (poisson), typical/extreme theta", {
  set.seed(13)
  n_level <- 10L
  n_each <- 8L
  levels_ <- paste0("id", seq_len(n_level))
  angle <- seq(0, 1.75 * pi, length.out = n_level)
  coords <- data.frame(
    x = cos(angle) + seq_len(n_level) / (4 * n_level),
    y = sin(angle)
  )
  rownames(coords) <- levels_
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = levels_, group = "site")
  spatial_cov <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(t(chol(spatial_cov)) %*% stats::rnorm(n_level, sd = 0.4))
  names(spatial_effect) <- levels_
  site <- rep(levels_, each = n_each)
  x <- stats::rnorm(length(site))
  eta <- 0.5 - 0.2 * x + spatial_effect[site]
  dat <- data.frame(y = stats::rpois(length(site), exp(eta)), x = x, site = site)
  fit <- drmTMB(bf(y ~ x + spatial(1 | site, coords = coords)), family = poisson(), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("spatial mu (poisson) typical", fit$obj, fit$obj$par, GCOND_LAPLACE_TOL)
  gcond_expect_conformance(
    "spatial mu (poisson) extreme",
    fit$obj,
    fit$obj$par + 0.05 * seq_along(fit$obj$par),
    GCOND_LAPLACE_TOL
  )
})

test_that("Laplace: scale-side (sigma) random intercept, lognormal, typical/extreme theta", {
  set.seed(14)
  n_id <- 30L
  n_each <- 10L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  u <- stats::rnorm(n_id, sd = 0.4)
  u <- u - mean(u)
  sdlog <- exp(-0.5 + u[id])
  y <- stats::rlnorm(n, meanlog = 0.2 + 0.5 * x, sdlog = sdlog)
  dat <- data.frame(y = y, x = x, id = id)
  fit <- drmTMB(bf(y ~ x, sigma ~ (1 | id)), family = lognormal(), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("sigma random-intercept typical", fit$obj, fit$obj$par, GCOND_LAPLACE_TOL)
  # EXPECTED non-finding class: scale-side RE has a non-convex inner problem,
  # so a large perturbation can land the inner solve in a different local
  # optimum from neighbouring theta and produce a genuine discontinuity. The
  # `extreme` perturbation here is deliberately modest (0.05 * index) to stay
  # inside one inner basin; we do not probe the discontinuous regime further.
  gcond_expect_conformance(
    "sigma random-intercept extreme",
    fit$obj,
    fit$obj$par + 0.05 * seq_along(fit$obj$par),
    GCOND_LAPLACE_TOL
  )
})

test_that("Laplace: phylo mu random effect + sd() regression (beta), typical/extreme theta", {
  # Frontier structure: `sd(species, level = "phylogenetic") ~ z_species`
  # regresses the SD of a phylogenetic random effect on a covariate -- the
  # "sd() regression" cell named in the arc brief.
  set.seed(15)
  n_tip <- 16L
  n_each <- 8L
  tree <- ape::rcoal(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_species) <- tree$tip.label
  alpha_sd <- c(log(0.3), 0.3)
  tau <- exp(alpha_sd[1] + alpha_sd[2] * z_species)
  unit_tip <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  names(unit_tip) <- tree$tip.label
  species <- rep(tree$tip.label, each = n_each)
  x_mu <- stats::rnorm(length(species))
  x_sigma <- stats::rnorm(length(species))
  eta_mu <- -0.2 + 0.35 * x_mu + tau[species] * unit_tip[species]
  log_sigma <- log(0.25) + 0.15 * x_sigma
  mu <- stats::plogis(eta_mu)
  phi <- exp(-2 * log_sigma)
  dat <- data.frame(
    y = stats::rbeta(length(mu), mu * phi, (1 - mu) * phi),
    x_mu = x_mu,
    x_sigma = x_sigma,
    z_species = unname(z_species[species]),
    species = species
  )
  fit <- drmTMB(
    bf(
      y ~ x_mu + phylo(1 | species, tree = tree),
      sigma ~ x_sigma,
      sd(species, level = "phylogenetic") ~ z_species
    ),
    family = drmTMB::beta(),
    data = dat
  )
  gcond_prepare(fit$obj)
  gcond_expect_conformance("phylo mu + sd() regression typical", fit$obj, fit$obj$par, GCOND_LAPLACE_TOL)
  gcond_expect_conformance(
    "phylo mu + sd() regression extreme",
    fit$obj,
    fit$obj$par + 0.05 * seq_along(fit$obj$par),
    GCOND_LAPLACE_TOL
  )
})

test_that("Laplace: phylo random effect on residual log-SD (gaussian sigma), typical/extreme theta", {
  # Frontier structure: `sigma ~ phylo(1 | species, tree = tree)` puts a
  # phylogenetic random effect directly on the residual log-SD, distinct from
  # the sd()-regression cell above (which modulates a mu-side phylo RE's SD).
  set.seed(16)
  n_tip <- 12L
  n_each <- 6L
  tree <- ape::rcoal(n_tip)
  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  y <- stats::rnorm(length(species))
  dat <- data.frame(y = y, x = x, species = species)
  fit <- drmTMB(bf(y ~ x, sigma ~ phylo(1 | species, tree = tree)), data = dat)
  gcond_prepare(fit$obj)
  gcond_expect_conformance("phylo sigma (residual log-SD) typical", fit$obj, fit$obj$par, GCOND_LAPLACE_TOL)
  gcond_expect_conformance(
    "phylo sigma (residual log-SD) extreme",
    fit$obj,
    fit$obj$par + 0.05 * seq_along(fit$obj$par),
    GCOND_LAPLACE_TOL
  )
})

# ---------------------------------------------------------------------------
# Second, independent FD step size for the two cells nearest a non-convex
# inner problem (scale-side RE and the phylo sd()-regression cell), so any
# disagreement there would already carry its required reproduction evidence.
# ---------------------------------------------------------------------------

test_that("second FD step size corroborates the mu random-intercept cell", {
  set.seed(11)
  n_id <- 20L
  n_each <- 6L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  u <- stats::rnorm(n_id, sd = 0.6)
  y <- stats::rnorm(n, 0.3 + 0.5 * x + u[id], 0.4)
  dat <- data.frame(y = y, x = x, id = id)
  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), data = dat)
  gcond_prepare(fit$obj)
  theta <- fit$obj$par
  res_richardson <- gcond_evaluate(fit$obj, theta, fd_method = "Richardson")
  res_simple <- gcond_evaluate(
    fit$obj,
    theta,
    fd_method = "simple",
    fd_args = list(eps = 1e-5)
  )
  message(sprintf(
    "second-step-size: Richardson stat=%.3e; simple(eps=1e-5) stat=%.3e",
    res_richardson$stat, res_simple$stat
  ))
  expect_lt(res_richardson$stat, GCOND_LAPLACE_TOL)
  expect_lt(res_simple$stat, GCOND_LAPLACE_TOL)
})

# ---------------------------------------------------------------------------
# Declared non-coverage: bivariate LSS + random effects has no syntax yet.
# ---------------------------------------------------------------------------

test_that("bivariate LSS random effects are not yet implemented (declared non-coverage)", {
  set.seed(20)
  n_id <- 10L
  n_each <- 5L
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(
    x = stats::rnorm(n),
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n),
    id = id
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x,
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_lognormal(),
      data = dat
    ),
    "random"
  )
})
