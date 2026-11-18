# Native Poisson slope-only SD regression for the phylo (tree) and relmat
# (K, then Q) providers. Templates: test-poisson-animal-slope-sd-regression.R,
# test-poisson-phylo-sd-regression.R, test-poisson-relmat-sd-regression.R.
#
# Oracle: a dense, drmTMB-independent Laplace marginal likelihood. The slope
# effect for level i is sd_i * u_i with u ~ N(0, K), so with
# eta_ij = b0 + b1 * x_ij + sd_i * x_ij * u_i the Laplace value is
#   ll(u*) - u*' K^-1 u* / 2 - logdet(I + K W) / 2,
# with W = diag(sum_j exp(eta_ij) (sd_i x_ij)^2) at the inner mode u*.
# Tolerances are fixed before the first run: oracle agreement 1e-4 absolute on
# the log-likelihood; constant-SD equivalence 2e-5 relative (as the templates);
# K vs Q agreement 1e-4 relative (as the Ainv template); recovery of the SD
# slope on z within 0.5.

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

prs_slope_fixture <- function(K, seed, n_each = 12L) {
  set.seed(seed)
  levels_id <- rownames(K)
  n_id <- length(levels_id)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), levels_id)
  alpha <- c(`(Intercept)` = log(0.6), z = 0.4)
  sd_id <- exp(alpha[[1L]] + alpha[[2L]] * z_id[levels_id])
  slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_id
  names(slope) <- levels_id
  id <- factor(rep(levels_id, each = n_each), levels = levels_id)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  eta <- 0.3 + 0.2 * x + slope[as.character(id)] * x
  data <- data.frame(
    y = stats::rpois(length(eta), exp(eta)),
    id = id,
    x = x,
    z = unname(z_id[as.character(id)])
  )
  list(data = data, alpha = alpha, z_id = z_id)
}

prs_expect_slope_sd_fit <- function(fit, fx, sd_name, K) {
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, sd_name), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, sd_name)[["z"]] - fx$alpha[["z"]]), 0.5)
  sd_prediction <- predict(fit, dpar = sd_name)
  expect_setequal(names(sd_prediction), rownames(K))
  sd_coef <- coef(fit, sd_name)
  expect_equal(
    unname(sd_prediction),
    unname(exp(sd_coef[["(Intercept)"]] +
      sd_coef[["z"]] * fx$z_id[names(sd_prediction)])),
    tolerance = 1e-8
  )
  oracle <- prs_dense_laplace_loglik(
    y = fx$data$y,
    x = fx$data$x,
    idx = match(as.character(fx$data$id), rownames(K)),
    beta = fit$coefficients$mu[c("(Intercept)", "x")],
    sd_by_level = sd_prediction[rownames(K)],
    K = K
  )
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), 1e-4)
  invisible(sd_prediction)
}

prs_expect_constant_sd_equivalence <- function(formula_sd, formula_base, data) {
  constant_fit <- drmTMB(
    formula_sd, family = stats::poisson(), data = data,
    control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    formula_base, family = stats::poisson(), data = data,
    control = drm_control(se = FALSE)
  )
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
}

test_that("Poisson relmat slope SDs can depend on group predictors (K and Q)", {
  skip_on_cran()
  n_id <- 60L
  id_levels <- paste0("id", seq_len(n_id))
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  # Non-unit covariance scale detects accidental conversion to a correlation.
  K_base <- 1.7 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K_base) <- list(id_levels, id_levels)
  K <- K_base[order, order]
  Q <- solve(K)
  dimnames(Q) <- dimnames(K)
  fx <- prs_slope_fixture(K, seed = 20261105L)

  fit_K <- drmTMB(
    bf(y ~ x + relmat(0 + x | id, K = K), sd(id, level = "relmat") ~ z),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  sd_prediction <- prs_expect_slope_sd_fit(fit_K, fx, "sd_relmat(id)", K)
  expect_named(sd_prediction, rownames(K))

  fit_Q <- drmTMB(
    bf(y ~ x + relmat(0 + x | id, Q = Q), sd(id, level = "relmat") ~ z),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  prs_expect_slope_sd_fit(fit_Q, fx, "sd_relmat(id)", K)
  expect_equal(
    as.numeric(logLik(fit_Q)), as.numeric(logLik(fit_K)), tolerance = 1e-4
  )

  simulated <- simulate(fit_K, nsim = 1L, seed = 20261106L)
  expect_length(simulated[[1L]], nrow(fx$data))
  expect_true(all(simulated[[1L]] >= 0L))
  expect_true(all(simulated[[1L]] == as.integer(simulated[[1L]])))
  saved_fit <- tempfile(fileext = ".rds")
  on.exit(unlink(saved_fit), add = TRUE)
  saveRDS(fit_K, saved_fit)
  expect_equal(
    predict(readRDS(saved_fit), dpar = "sd_relmat(id)"),
    sd_prediction, tolerance = 1e-12
  )

  prs_expect_constant_sd_equivalence(
    bf(y ~ x + relmat(0 + x | id, K = K), sd(id, level = "relmat") ~ 1),
    bf(y ~ x + relmat(0 + x | id, K = K)),
    fx$data
  )
  prs_expect_constant_sd_equivalence(
    bf(y ~ x + relmat(0 + x | id, Q = Q), sd(id, level = "relmat") ~ 1),
    bf(y ~ x + relmat(0 + x | id, Q = Q)),
    fx$data
  )
})

test_that("Poisson phylo slope SDs can depend on group predictors", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(20261107L)
  n_species <- 40L
  tree <- ape::rcoal(n_species)
  tree$tip.label <- paste0("species_", seq_len(n_species))
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  K <- K[tree$tip.label, tree$tip.label]
  expect_equal(unname(diag(K)), rep(1, n_species), tolerance = 1e-8)
  fx <- prs_slope_fixture(K, seed = 20261108L)
  fx$data$species <- fx$data$id

  fit <- drmTMB(
    bf(
      y ~ x + phylo(0 + x | species, tree = tree),
      sd(species, level = "phylogenetic") ~ z
    ),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  fx$data$id <- fx$data$species
  sd_prediction <- prs_expect_slope_sd_fit(fit, fx, "sd_phylo(species)", K)
  expect_length(sd_prediction, n_species)

  simulated <- simulate(fit, nsim = 1L, seed = 20261109L)
  expect_length(simulated[[1L]], nrow(fx$data))
  expect_true(all(simulated[[1L]] == as.integer(simulated[[1L]])))
  saved_fit <- tempfile(fileext = ".rds")
  on.exit(unlink(saved_fit), add = TRUE)
  saveRDS(fit, saved_fit)
  expect_equal(
    predict(readRDS(saved_fit), dpar = "sd_phylo(species)"),
    sd_prediction, tolerance = 1e-12
  )

  prs_expect_constant_sd_equivalence(
    bf(
      y ~ x + phylo(0 + x | species, tree = tree),
      sd(species, level = "phylogenetic") ~ 1
    ),
    bf(y ~ x + phylo(0 + x | species, tree = tree)),
    fx$data
  )
})
