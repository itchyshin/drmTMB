# Two review gaps in the predictor-dependent random-effect SD lane.
#
# (1) Missing responses with slope-only structured SD for Poisson and NB2.
#     Probe result (this file records it): every route below is REFUSED under
#     miss_control(response = "include"), with a family-specific message, so
#     there is nothing to match against a complete-case fit. The tests pin the
#     refusals, and pin that the supported route (the default drop policy)
#     gives the same fit as removing the missing rows by hand.
# (2) Non-unit-diagonal K. Fixtures with diag(K) = 1 cannot tell a fit that
#     uses K as given from one that silently converts K to a correlation
#     matrix. Here diag(K) is 1.7 (Toeplitz) or >= 1.25 (pedigree with
#     inbreeding), and each fit is compared with a dense, drmTMB-independent
#     oracle built from the unconverted K. As a sensitivity check, the same
#     oracle built from cov2cor(K) must give a clearly different value.
#
# Tolerances, fixed before the first run:
#   * Laplace oracle (NB2, Binomial): 1e-4 absolute on the log-likelihood;
#   * Gaussian exact marginal oracle: 1e-6 absolute on the log-likelihood;
#   * K vs Q and A vs Ainv log-likelihood: 1e-4 relative;
#   * correlation-conversion sensitivity: oracle values differ by more than
#     0.05 absolute;
#   * drop policy vs manual complete-case: 1e-8 relative on the log-likelihood.
# No recovery, coverage, calibration or Julia parity claim is made here. The
# oracles are evaluated at the fitted parameters, so they check the likelihood
# surface, not the optimiser's maximum. The pedigree relationship matrix for
# the oracle comes from drmTMB:::drm_pedigree_additive_relationship (the helper
# under test for that route); its inbreeding diagonal is pinned by hand below.

nuk_toeplitz_k <- function(n_id, scale = 1.7, rho = 0.45) {
  ids <- paste0("id", seq_len(n_id))
  # Odd/even interleave so that reading rows by position would be wrong.
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  K <- scale * rho^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K) <- list(ids, ids)
  K[order, order]
}

# ---- dense oracles ----------------------------------------------------------

# Laplace log marginal likelihood for eta = eta0 + s_i u_i, u ~ N(0, K), with
# per-observation weight w (1 for intercepts). family is "nb2" or "binomial".
nuk_laplace_loglik <- function(y, eta0, idx, sd_by_level, K, family,
                               sigma = NULL, w = 1) {
  n <- nrow(K)
  Kinv <- solve(K)
  s <- sd_by_level * w
  s <- s[idx]
  size <- if (identical(family, "nb2")) 1 / sigma^2 else NA_real_
  parts <- function(u) {
    eta <- eta0 + s * u[idx]
    if (identical(family, "nb2")) {
      mu <- exp(eta)
      list(
        ll = sum(stats::dnbinom(y, size = size, mu = mu, log = TRUE)),
        score = size * (y - mu) / (size + mu),
        info = (y + size) * size * mu / (size + mu)^2
      )
    } else {
      p <- stats::plogis(eta)
      list(
        ll = sum(stats::dbinom(y, 1L, p, log = TRUE)),
        score = y - p,
        info = p * (1 - p)
      )
    }
  }
  objective <- function(u) parts(u)$ll - 0.5 * sum(u * (Kinv %*% u))
  u <- rep(0, n)
  for (iter in seq_len(200L)) {
    p <- parts(u)
    grad <- as.vector(rowsum(s * p$score, idx, reorder = TRUE)) -
      as.vector(Kinv %*% u)
    W <- as.vector(rowsum(s^2 * p$info, idx, reorder = TRUE))
    step <- as.vector(solve(diag(W, n) + Kinv, grad))
    scale <- 1
    f0 <- objective(u)
    while (objective(u + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    u <- u + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  p <- parts(u)
  W <- as.vector(rowsum(s^2 * p$info, idx, reorder = TRUE))
  objective(u) -
    0.5 * as.numeric(determinant(diag(n) + K %*% diag(W, n))$modulus)
}

# Exact Gaussian marginal log-likelihood with a group intercept effect.
nuk_gaussian_loglik <- function(y, mu, sigma, idx, sd_by_level, K) {
  n <- nrow(K)
  Z <- matrix(0, length(y), n)
  Z[cbind(seq_along(y), idx)] <- 1
  cov_u <- outer(sd_by_level, sd_by_level) * K
  V <- Z %*% cov_u %*% t(Z) + diag(sigma^2, length(y))
  R <- chol(V)
  r <- backsolve(R, y - mu, transpose = TRUE)
  -0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

nuk_expect_not_correlation <- function(ll_fit, ll_cor) {
  expect_gt(abs(ll_cor - ll_fit), 0.05)
}

# ---- (2a) NB2 relmat intercept, K and Q -------------------------------------

test_that("NB2 relmat intercept SD uses a non-unit-diagonal K as given", {
  skip_on_cran()
  n_id <- 40L
  n_each <- 12L
  K <- nuk_toeplitz_k(n_id)
  Q <- solve(K)
  dimnames(Q) <- dimnames(K)
  expect_equal(unname(diag(K)), rep(1.7, n_id))

  set.seed(20261201L)
  ids <- rownames(K)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), ids)
  sd_true <- exp(log(0.5) + 0.4 * z_id)
  effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_true
  names(effect) <- ids
  id <- factor(rep(ids, each = n_each), levels = ids)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  eta <- 1 + 0.2 * x + effect[as.character(id)]
  dat <- data.frame(
    y = stats::rnbinom(length(eta), mu = exp(eta), size = 1 / 0.4^2),
    id = id, x = x, z = unname(z_id[as.character(id)])
  )

  fit_K <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1,
       sd(id, level = "relmat") ~ z),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )
  fit_Q <- drmTMB(
    bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ 1,
       sd(id, level = "relmat") ~ z),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )
  for (fit in list(fit_K, fit_Q)) {
    expect_equal(fit$opt$convergence, 0L)
    expect_named(coef(fit, "sd_relmat(id)"), c("(Intercept)", "z"))
  }
  expect_equal(
    as.numeric(logLik(fit_Q)), as.numeric(logLik(fit_K)), tolerance = 1e-4
  )

  oracle_args <- function(fit, Kmat) {
    sd_hat <- predict(fit, dpar = "sd_relmat(id)")
    list(
      y = dat$y,
      eta0 = as.vector(fit$coefficients$mu[["(Intercept)"]] +
        fit$coefficients$mu[["x"]] * dat$x),
      idx = match(as.character(dat$id), ids),
      sd_by_level = unname(sd_hat[ids]),
      K = Kmat, family = "nb2",
      sigma = exp(coef(fit, "sigma")[["(Intercept)"]])
    )
  }
  ll_oracle <- do.call(nuk_laplace_loglik, oracle_args(fit_K, K))
  expect_lt(abs(as.numeric(logLik(fit_K)) - ll_oracle), 1e-4)
  ll_cor <- do.call(nuk_laplace_loglik, oracle_args(fit_K, stats::cov2cor(K)))
  nuk_expect_not_correlation(as.numeric(logLik(fit_K)), ll_cor)
  ll_oracle_Q <- do.call(nuk_laplace_loglik, oracle_args(fit_Q, K))
  expect_lt(abs(as.numeric(logLik(fit_Q)) - ll_oracle_Q), 1e-4)
})

# ---- (2b) Gaussian relmat intercept, K and Q --------------------------------

test_that("Gaussian relmat intercept SD uses a non-unit-diagonal K as given", {
  skip_on_cran()
  n_id <- 40L
  n_each <- 10L
  K <- nuk_toeplitz_k(n_id)
  Q <- solve(K)
  dimnames(Q) <- dimnames(K)

  set.seed(20261202L)
  ids <- rownames(K)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), ids)
  sd_true <- exp(log(0.5) + 0.35 * z_id)
  effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_true
  names(effect) <- ids
  id <- factor(rep(ids, each = n_each), levels = ids)
  x <- stats::rnorm(length(id))
  dat <- data.frame(
    y = 0.2 + 0.5 * x + effect[as.character(id)] +
      stats::rnorm(length(id), sd = 0.35),
    id = id, x = x, z = unname(z_id[as.character(id)])
  )

  fit_K <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ z),
    family = stats::gaussian(), data = dat, control = drm_control(se = FALSE)
  )
  fit_Q <- drmTMB(
    bf(y ~ x + relmat(1 | id, Q = Q), sd(id, level = "relmat") ~ z),
    family = stats::gaussian(), data = dat, control = drm_control(se = FALSE)
  )
  for (fit in list(fit_K, fit_Q)) {
    expect_equal(fit$opt$convergence, 0L)
    expect_named(coef(fit, "sd_relmat(id)"), c("(Intercept)", "z"))
  }
  expect_equal(
    as.numeric(logLik(fit_Q)), as.numeric(logLik(fit_K)), tolerance = 1e-4
  )

  oracle <- function(fit, Kmat) {
    sd_hat <- predict(fit, dpar = "sd_relmat(id)")
    nuk_gaussian_loglik(
      y = dat$y,
      mu = as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu")),
      sigma = unname(sigma(fit)),
      idx = match(as.character(dat$id), ids),
      sd_by_level = unname(sd_hat[ids]),
      K = Kmat
    )
  }
  expect_lt(abs(as.numeric(logLik(fit_K)) - oracle(fit_K, K)), 1e-6)
  expect_lt(abs(as.numeric(logLik(fit_Q)) - oracle(fit_Q, K)), 1e-6)
  nuk_expect_not_correlation(
    as.numeric(logLik(fit_K)), oracle(fit_K, stats::cov2cor(K))
  )
})

# ---- (2c) Binomial animal: A, Ainv and an inbred pedigree -------------------

nuk_binomial_data <- function(K, seed, n_each = 12L) {
  set.seed(seed)
  ids <- rownames(K)
  n_id <- length(ids)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), ids)
  sd_true <- exp(log(0.8) + 0.4 * z_id)
  effect <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_true
  names(effect) <- ids
  id <- factor(rep(ids, each = n_each), levels = ids)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  eta <- -0.2 + 0.5 * x + effect[as.character(id)]
  data.frame(
    y = stats::rbinom(length(eta), 1L, stats::plogis(eta)),
    id = id, x = x, z = unname(z_id[as.character(id)])
  )
}

nuk_binomial_oracle <- function(fit, dat, Kmat) {
  ids <- rownames(Kmat)
  sd_hat <- predict(fit, dpar = "sd_animal(id)")
  nuk_laplace_loglik(
    y = dat$y,
    eta0 = as.vector(fit$coefficients$mu[["(Intercept)"]] +
      fit$coefficients$mu[["x"]] * dat$x),
    idx = match(as.character(dat$id), ids),
    sd_by_level = unname(sd_hat[ids]),
    K = Kmat, family = "binomial"
  )
}

test_that("Binomial animal A and Ainv use a non-unit-diagonal relationship matrix as given", {
  skip_on_cran()
  A <- nuk_toeplitz_k(40L)
  Ainv <- solve(A)
  dimnames(Ainv) <- dimnames(A)
  dat <- nuk_binomial_data(A, seed = 20261203L)

  fit_A <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A), sd(id, level = "animal") ~ z),
    family = stats::binomial(), data = dat, control = drm_control(se = FALSE)
  )
  fit_Ainv <- drmTMB(
    bf(y ~ x + animal(1 | id, Ainv = Ainv), sd(id, level = "animal") ~ z),
    family = stats::binomial(), data = dat, control = drm_control(se = FALSE)
  )
  for (fit in list(fit_A, fit_Ainv)) {
    expect_equal(fit$opt$convergence, 0L)
    expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  }
  expect_equal(
    as.numeric(logLik(fit_Ainv)), as.numeric(logLik(fit_A)), tolerance = 1e-4
  )
  expect_lt(
    abs(as.numeric(logLik(fit_A)) - nuk_binomial_oracle(fit_A, dat, A)), 1e-4
  )
  expect_lt(
    abs(as.numeric(logLik(fit_Ainv)) - nuk_binomial_oracle(fit_Ainv, dat, A)),
    1e-4
  )
  nuk_expect_not_correlation(
    as.numeric(logLik(fit_A)),
    nuk_binomial_oracle(fit_A, dat, stats::cov2cor(A))
  )
})

test_that("Binomial animal pedigree with inbreeding keeps A's diagonal above one", {
  skip_on_cran()
  # Per family: two unrelated founders, two full sibs, and three offspring of
  # the sib x sib mating, each with inbreeding coefficient F = 0.25.
  n_fam <- 8L
  rows <- lapply(seq_len(n_fam), function(f) {
    nm <- function(...) sprintf("f%02d_%s", f, c(...))
    data.frame(
      id = c(nm("a", "b", "s1", "s2"), nm("o1", "o2", "o3")),
      dam = c(NA, NA, nm("a")[1L], nm("a")[1L], rep(nm("s1"), 3L)),
      sire = c(NA, NA, nm("b")[1L], nm("b")[1L], rep(nm("s2"), 3L)),
      stringsAsFactors = FALSE
    )
  })
  pedigree <- do.call(rbind, rows)
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  inbred <- grep("_o[123]$", rownames(A), value = TRUE)
  # Hand-derived: offspring of full sibs have F = 1/4, so A_ii = 1.25.
  expect_equal(unname(diag(A)[inbred]), rep(1.25, length(inbred)))
  # Full-sib offspring of sibs: A_o1,o2 = (0.75 + 0.75) / 2 = 0.75.
  expect_equal(unname(A[inbred[1L], inbred[2L]]), 0.75)
  dat <- nuk_binomial_data(A, seed = 20261204L)

  fit <- drmTMB(
    bf(y ~ x + animal(1 | id, pedigree = pedigree),
       sd(id, level = "animal") ~ z),
    family = stats::binomial(), data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(
    abs(as.numeric(logLik(fit)) - nuk_binomial_oracle(fit, dat, A)), 1e-4
  )
  nuk_expect_not_correlation(
    as.numeric(logLik(fit)),
    nuk_binomial_oracle(fit, dat, stats::cov2cor(A))
  )
})

# ---- (1) Poisson and NB2 slope-only structured SD with missing responses ----

nuk_missing_fixture <- function(seed = 20261205L, n_id = 30L, n_each = 16L) {
  set.seed(seed)
  ids <- paste0("id", seq_len(n_id))
  K <- nuk_toeplitz_k(n_id)
  Q <- solve(K)
  dimnames(Q) <- dimnames(K)
  ids <- rownames(K)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), ids)
  id <- factor(rep(ids, each = n_each), levels = ids)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) *
    exp(log(0.5) + 0.3 * z_id)
  names(slope) <- ids
  eta <- 1 + 0.2 * x + slope[as.character(id)] * x
  base <- data.frame(id = id, x = x, z = unname(z_id[as.character(id)]))
  pois <- cbind(base, y = stats::rpois(length(eta), exp(eta)))
  nb2 <- cbind(base, y = stats::rnbinom(length(eta), mu = exp(eta),
                                        size = 1 / 0.3^2))
  hole <- sample.int(length(eta), 60L)
  pois$y[hole] <- NA
  nb2$y[hole] <- NA
  list(pois = pois, nb2 = nb2, K = K, Q = Q, ids = ids)
}

test_that("Poisson and NB2 slope-only structured SD admit missing responses and refuse zero inflation", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- nuk_missing_fixture()
  K <- fx$K
  Q <- fx$Q
  pedigree <- data.frame(id = fx$ids, dam = NA_character_,
                         sire = NA_character_, stringsAsFactors = FALSE)
  set.seed(20261206L)
  tree <- ape::rcoal(length(fx$ids))
  tree$tip.label <- fx$ids
  theta <- seq(0, 2 * pi, length.out = length(fx$ids) + 1L)[-1L]
  coords <- data.frame(x = cos(theta), y = sin(theta), row.names = fx$ids)

  routes <- list(
    list(f = y ~ x + animal(0 + x | id, A = K), lev = "animal"),
    list(f = y ~ x + animal(0 + x | id, Ainv = Q), lev = "animal"),
    list(f = y ~ x + animal(0 + x | id, pedigree = pedigree), lev = "animal"),
    list(f = y ~ x + relmat(0 + x | id, K = K), lev = "relmat"),
    list(f = y ~ x + relmat(0 + x | id, Q = Q), lev = "relmat"),
    list(f = y ~ x + phylo(0 + x | id, tree = tree), lev = "phylogenetic"),
    list(f = y ~ x + spatial(0 + x | id, coords = coords), lev = "spatial")
  )
  sigma_rhs <- sigma ~ 1
  for (route in routes) {
    mu_f <- route$f
    sd_f <- stats::as.formula(sprintf('sd(id, level = "%s") ~ z', route$lev))
    # Admitted since batch 23; fitted evidence (include equals complete-case
    # and a dense Laplace oracle) is in test-count-iid-slope-sd-missing-include.R.
    inc <- miss_control(response = "include")
    expect_no_error(drm_build_poisson_spec(bf(mu_f, sd_f), fx$pois, missing = inc))
    expect_no_error(drm_build_nbinom2_spec(bf(mu_f, sigma_rhs, sd_f), fx$nb2,
                                           missing = inc))
    # Zero inflation stays refused under include.
    expect_error(
      drm_build_poisson_spec(bf(mu_f, zi ~ 1, sd_f), fx$pois, missing = inc),
      "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
    )
    expect_error(
      drm_build_nbinom2_spec(bf(mu_f, sigma_rhs, zi ~ 1, sd_f), fx$nb2,
                             missing = inc),
      "complete\\s+data"
    )
  }
})

test_that("the default drop policy equals manual complete-case for slope-only relmat SD", {
  skip_on_cran()
  fx <- nuk_missing_fixture()
  K <- fx$K
  ctl <- drm_control(se = FALSE)
  sd_f <- sd(id, level = "relmat") ~ z
  sigma_rhs <- sigma ~ 1

  fit_pois <- drmTMB(
    bf(y ~ x + relmat(0 + x | id, K = K), sd_f),
    family = poisson(), data = fx$pois, control = ctl
  )
  fit_pois_cc <- drmTMB(
    bf(y ~ x + relmat(0 + x | id, K = K), sd_f),
    family = poisson(), data = fx$pois[!is.na(fx$pois$y), ], control = ctl
  )
  fit_nb2 <- drmTMB(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma_rhs, sd_f),
    family = nbinom2(), data = fx$nb2, control = ctl
  )
  fit_nb2_cc <- drmTMB(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma_rhs, sd_f),
    family = nbinom2(), data = fx$nb2[!is.na(fx$nb2$y), ], control = ctl
  )
  for (pair in list(list(fit_pois, fit_pois_cc), list(fit_nb2, fit_nb2_cc))) {
    expect_equal(pair[[1L]]$opt$convergence, 0L)
    expect_equal(nobs(pair[[1L]]), nobs(pair[[2L]]))
    expect_equal(nobs(pair[[1L]]), sum(!is.na(fx$pois$y)))
    expect_equal(
      as.numeric(logLik(pair[[1L]])), as.numeric(logLik(pair[[2L]])),
      tolerance = 1e-8
    )
  }
})
