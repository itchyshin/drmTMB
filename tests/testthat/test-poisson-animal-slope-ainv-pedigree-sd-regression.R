# Poisson animal slope-only SD regression for the Ainv, A and pedigree providers.
#
# Primary check: a dense, drmTMB-independent Laplace marginal likelihood (the
# helper is copied from test-poisson-phylo-relmat-slope-sd-regression.R). The
# slope effect for level i is sd_i * u_i with u ~ N(0, K); with
# eta_ij = b0 + b1 * x_ij + sd_i * x_ij * u_i the Laplace value is
#   ll(u*) - u*' K^-1 u* / 2 - logdet(I + K W) / 2,
# W = diag(sum_j exp(eta_ij) (sd_i x_ij)^2) at the inner mode u*.
# The oracle SD vector is built from the fitted SD coefficients and the
# fixture's own group predictor looked up BY LEVEL NAME, not from predict(), so
# a level-to-row misalignment inside the package changes the fitted likelihood
# but not the oracle. K is non-unit-diagonal (Ainv: 1.7 * 0.35^|i-j|; pedigree:
# full-sib matings, diag(A) = 1.25 for inbred animals) so that an accidental
# K-to-correlation conversion shows. The data factor levels are in a different
# order from rownames(K) in both tests.
# Tolerances fixed before the first run: oracle agreement 1e-4 absolute on the
# log-likelihood; A vs Ainv/pedigree agreement 1e-4 relative; constant-SD
# equivalence 2e-5 relative; recovery of the SD slope on z within 0.4 (sanity
# band only; the oracle is the primary check; kept at 0.4 because 20 scratch
# fits over 10 other seeds per test gave a maximum error of 0.32).
# Sensitivity, shown in a scratch script (real-fit gap 1e-9 to 1e-12; every
# perturbation gap below is at least 0.06, so far above 1e-4): level k given the
# z of rownames(K)[k] (oracle 0.22 Ainv, 1.37 pedigree; refit on that z 0.065,
# 0.65); K rows taken in factor-level order (8.0, 28.8); cov2cor(K) (5.9, 1.4);
# sign-flipped z (9.8, 5.3); swapped SD intercept/slope (32, 28).

prs_dense_laplace_loglik <- function(y, x, idx, beta, sd_by_level, K) {
  n <- nrow(K)
  Kinv <- solve(K)
  eta0 <- beta[[1L]] + beta[[2L]] * x
  s <- sd_by_level[idx] * x
  logjoint <- function(u) {
    eta <- eta0 + s * u[idx]
    sum(stats::dpois(y, exp(eta), log = TRUE)) - 0.5 * sum(u * (Kinv %*% u))
  }
  u <- rep(0, n)
  for (iter in seq_len(200L)) {
    mu <- exp(eta0 + s * u[idx])
    grad <- as.vector(rowsum(s * (y - mu), idx, reorder = TRUE)) -
      as.vector(Kinv %*% u)
    W <- as.vector(rowsum(mu * s^2, idx, reorder = TRUE))
    step <- as.vector(solve(diag(W, n) + Kinv, grad))
    scale <- 1
    f0 <- logjoint(u)
    while (logjoint(u + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    u <- u + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  mu <- exp(eta0 + s * u[idx])
  W <- as.vector(rowsum(mu * s^2, idx, reorder = TRUE))
  logjoint(u) -
    0.5 * as.numeric(determinant(diag(n) + K %*% diag(W, n))$modulus)
}

# |logLik(fit) - oracle| at the fitted coefficients, SDs from coefficients and
# the fixture group predictor by level name.
animal_oracle_gap <- function(fit, fx, K, z_by_level = fx$z_id[rownames(K)]) {
  sd_coef <- coef(fit, "sd_animal(id)")
  sd_by_level <- exp(sd_coef[["(Intercept)"]] + sd_coef[["z"]] * z_by_level)
  names(sd_by_level) <- rownames(K)
  oracle <- prs_dense_laplace_loglik(
    y = fx$data$y,
    x = fx$data$x,
    idx = match(as.character(fx$data$id), rownames(K)),
    beta = fit$coefficients$mu[c("(Intercept)", "x")],
    sd_by_level = sd_by_level,
    K = K
  )
  abs(as.numeric(logLik(fit)) - oracle)
}

poisson_animal_slope_provider_fixture <- function(A, seed, n_each = 16L) {
  set.seed(seed)
  id_levels <- rownames(A)
  n_id <- length(id_levels)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), id_levels)
  alpha <- c(`(Intercept)` = log(0.7), z = 0.35)
  slope <- as.vector(t(chol(A)) %*% stats::rnorm(n_id)) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[id_levels])
  names(slope) <- id_levels
  id <- factor(rep(id_levels, each = n_each), levels = id_levels)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  z <- unname(z_id[as.character(id)])
  eta <- 0.25 + 0.2 * x + slope[as.character(id)] * x
  list(
    data = data.frame(y = stats::rpois(length(eta), exp(eta)), id, x, z),
    alpha = alpha,
    z_id = z_id
  )
}

poisson_slope_sd_checks <- function(fit, fx, K) {
  provider_order <- rownames(K)
  expect_equal(fit$opt$convergence, 0L)
  expect_lt(animal_oracle_gap(fit, fx, K), 1e-4)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha[["z"]]), 0.4)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_setequal(names(sd_prediction), levels(fx$data$id))
  expect_named(sd_prediction, provider_order)
  sd_coef <- coef(fit, "sd_animal(id)")
  expect_equal(
    unname(sd_prediction),
    unname(exp(sd_coef[["(Intercept)"]] +
      sd_coef[["z"]] * fx$z_id[names(sd_prediction)])),
    tolerance = 1e-8
  )
  invisible(fit)
}

test_that("Poisson animal slope SDs can depend on group predictors with Ainv", {
  skip_on_cran()
  n_id <- 96L
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  id_levels <- paste0("id", seq_len(n_id))
  # Non-unit covariance scale detects accidental conversion to a correlation.
  A_base <- 1.7 * 0.35^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(A_base) <- list(id_levels, id_levels)
  A <- A_base[order, order]
  Q <- solve(A)
  dimnames(Q) <- dimnames(A)
  expect_false(identical(rownames(Q), levels(factor(id_levels))))
  fx <- poisson_animal_slope_provider_fixture(A, seed = 20261101L)
  fx$data$id <- factor(fx$data$id, levels = id_levels)

  fit_ainv <- drmTMB(
    bf(y ~ x + animal(0 + x | id, Ainv = Q), sd(id, level = "animal") ~ z),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  poisson_slope_sd_checks(fit_ainv, fx, A)

  fit_A <- drmTMB(
    bf(y ~ x + animal(0 + x | id, A = A), sd(id, level = "animal") ~ z),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit_A$opt$convergence, 0L)
  expect_lt(animal_oracle_gap(fit_A, fx, A), 1e-4)
  expect_equal(
    as.numeric(logLik(fit_ainv)), as.numeric(logLik(fit_A)), tolerance = 1e-4
  )

  constant_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, Ainv = Q), sd(id, level = "animal") ~ 1),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, Ainv = Q)),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})

test_that("Poisson animal slope SDs can depend on group predictors with a pedigree", {
  skip_on_cran()
  # Per family: two founders, two full sibs, four offspring of the full sibs
  # (inbreeding F = 0.25, so diag(A) = 1.25 for those animals).
  n_family <- 12L
  n_inbred <- 4L
  fam <- sprintf("%02d", seq_len(n_family))
  ped_rows <- function(f) {
    data.frame(
      id = c(paste0("sire", f), paste0("dam", f), paste0("fsm", f),
             paste0("fsf", f), sprintf("inbred%s_%d", f, seq_len(n_inbred))),
      dam = c(NA, NA, rep(paste0("dam", f), 2L),
              rep(paste0("fsf", f), n_inbred)),
      sire = c(NA, NA, rep(paste0("sire", f), 2L),
               rep(paste0("fsm", f), n_inbred)),
      stringsAsFactors = FALSE
    )
  }
  pedigree <- do.call(rbind, lapply(fam, ped_rows))
  A_base <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  expect_equal(max(diag(A_base)), 1.25, tolerance = 1e-12)
  expect_equal(sum(diag(A_base) > 1), n_family * n_inbred)
  fx <- poisson_animal_slope_provider_fixture(A_base, seed = 20261102L)
  # Data factor levels in lexical order, deliberately not the provider order.
  fx$data$id <- factor(as.character(fx$data$id), levels = sort(rownames(A_base)))
  expect_false(identical(levels(fx$data$id), rownames(A_base)))

  fit_ped <- drmTMB(
    bf(y ~ x + animal(0 + x | id, pedigree = pedigree),
       sd(id, level = "animal") ~ z),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  poisson_slope_sd_checks(fit_ped, fx, A_base)

  A <- A_base
  fit_A <- drmTMB(
    bf(y ~ x + animal(0 + x | id, A = A), sd(id, level = "animal") ~ z),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit_A$opt$convergence, 0L)
  expect_lt(animal_oracle_gap(fit_A, fx, A_base), 1e-4)
  expect_equal(
    as.numeric(logLik(fit_ped)), as.numeric(logLik(fit_A)), tolerance = 1e-4
  )

  constant_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, pedigree = pedigree),
       sd(id, level = "animal") ~ 1),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, pedigree = pedigree)),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})
