# Native Gamma slope-only structured SD regression: phylo(0 + x | g), spatial(0 + x | g),
# relmat(0 + x | g) with K and Q, and animal(0 + x | g) with Ainv, each with
# sd(g, level = ...) ~ z. Template: test-poisson-phylo-relmat-slope-sd-regression.R.
#
# Oracle: a dense, drmTMB-independent Laplace marginal likelihood. The slope
# effect for level i is sd_i * x * u_i with u ~ N(0, K). For the Gamma log link
# with coefficient of variation sigma (shape k = 1 / sigma^2),
#   eta_ij = b0 + b1 x_ij + sd_i x_ij u_i,
#   d ll / d eta = k (y / mu - 1),   -d2 ll / d eta2 = k y / mu,
# and the Laplace value is ll(u*) - u*' K^-1 u* / 2 - logdet(I + K W) / 2 with
# W = diag(sum_j (k y_ij / mu_ij) (sd_i x_ij)^2) at the inner mode u*.
# Tolerances are fixed before the first run: oracle agreement 1e-4 absolute on
# the log-likelihood; constant-SD equivalence 1e-4 absolute (the formula-free
# fit is a separate optimisation); K vs Q agreement 1e-4; recovery of the SD
# slope on z within 0.6; emulated-bug sensitivity must exceed 0.05 (500x the
# oracle tolerance).

gss_dense_laplace_loglik <- function(y, x, idx, beta, sigma, sd_by_level, K) {
  n <- nrow(K)
  k <- 1 / sigma^2
  Kinv <- solve(K)
  eta0 <- beta[[1L]] + beta[[2L]] * x
  s <- sd_by_level[idx] * x
  logjoint <- function(u) {
    mu <- exp(eta0 + s * u[idx])
    sum(stats::dgamma(y, shape = k, scale = mu / k, log = TRUE)) -
      0.5 * sum(u * (Kinv %*% u))
  }
  u <- rep(0, n)
  for (iter in seq_len(300L)) {
    mu <- exp(eta0 + s * u[idx])
    grad <- as.vector(rowsum(s * k * (y / mu - 1), idx, reorder = TRUE)) -
      as.vector(Kinv %*% u)
    W <- as.vector(rowsum(k * y / mu * s^2, idx, reorder = TRUE))
    step <- as.vector(solve(diag(W, n) + Kinv, grad))
    scale <- 1
    f0 <- logjoint(u)
    while (logjoint(u + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    u <- u + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  mu <- exp(eta0 + s * u[idx])
  W <- as.vector(rowsum(k * y / mu * s^2, idx, reorder = TRUE))
  logjoint(u) -
    0.5 * as.numeric(determinant(diag(n) + K %*% diag(W, n))$modulus)
}

# Rows are shuffled and the group factor levels follow K's (shuffled) order.
gss_fixture <- function(K, seed, n_each = 12L, alpha_z = 0.5, sigma = 0.35) {
  set.seed(seed)
  levels_id <- rownames(K)
  n_id <- length(levels_id)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), levels_id)
  alpha <- c(`(Intercept)` = log(0.5), z = alpha_z)
  sd_id <- exp(alpha[[1L]] + alpha[[2L]] * z_id[levels_id])
  slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_id
  names(slope) <- levels_id
  id <- factor(rep(levels_id, each = n_each), levels = levels_id)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  mu <- exp(0.3 + 0.2 * x + slope[as.character(id)] * x)
  data <- data.frame(
    y = stats::rgamma(length(mu), shape = 1 / sigma^2, scale = mu * sigma^2),
    id = id,
    x = x,
    z = unname(z_id[as.character(id)])
  )
  stopifnot(all(is.finite(data$y)), all(data$y > 0))
  data <- data[sample(nrow(data)), , drop = FALSE]
  rownames(data) <- NULL
  list(data = data, alpha = alpha, z_id = z_id, K = K)
}

gss_shuffled_kernel <- function(n_id, scale = 1.7, rho = 0.45, prefix = "id") {
  ids <- paste0(prefix, seq_len(n_id))
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  K_base <- scale * rho^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K_base) <- list(ids, ids)
  K_base[order, order]
}

gss_family <- function() stats::Gamma(link = "log")

gss_fit <- function(formula, data) {
  drmTMB(formula, family = gss_family(), data = data,
         control = drm_control(se = FALSE))
}

gss_oracle <- function(fit, fx, sd_by_level = NULL) {
  K <- fx$K
  sd_name <- grep("^sd_", names(fit$coefficients), value = TRUE)[[1L]]
  if (is.null(sd_by_level)) {
    sd_prediction <- predict(fit, dpar = sd_name)
    sd_by_level <- sd_prediction[rownames(K)]
  }
  gss_dense_laplace_loglik(
    y = fx$data$y,
    x = fx$data$x,
    idx = match(as.character(fx$data$id), rownames(K)),
    beta = fit$coefficients$mu[c("(Intercept)", "x")],
    sigma = exp(fit$coefficients$sigma[[1L]]),
    sd_by_level = unname(sd_by_level),
    K = K
  )
}

gss_expect_slope_sd_fit <- function(fit, fx, sd_name) {
  K <- fx$K
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, sd_name), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, sd_name)[["z"]] - fx$alpha[["z"]]), 0.6)
  sd_prediction <- predict(fit, dpar = sd_name)
  expect_setequal(names(sd_prediction), rownames(K))
  sd_coef <- coef(fit, sd_name)
  expect_equal(
    unname(sd_prediction),
    unname(exp(sd_coef[["(Intercept)"]] +
      sd_coef[["z"]] * fx$z_id[names(sd_prediction)])),
    tolerance = 1e-8
  )
  oracle <- gss_oracle(fit, fx, sd_prediction[rownames(K)])
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), 1e-4)

  # Emulated bugs must move the oracle by far more than the tolerance.
  # (a) SD values assigned to the wrong levels (reversed level order).
  misaligned <- gss_oracle(fit, fx, rev(sd_prediction[rownames(K)]))
  expect_gt(abs(misaligned - oracle), 0.05)
  # (b) the SD predictor swapped for an uninformative one (sign flipped z).
  flipped <- exp(sd_coef[["(Intercept)"]] -
    sd_coef[["z"]] * fx$z_id[rownames(K)])
  swapped <- gss_oracle(fit, fx, flipped)
  expect_gt(abs(swapped - oracle), 0.05)
  invisible(sd_prediction)
}

gss_expect_constant_sd_equivalence <- function(formula_sd, formula_base, data) {
  constant_fit <- gss_fit(formula_sd, data)
  base_fit <- gss_fit(formula_base, data)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 1e-4
  )
}

gss_expect_roundtrip <- function(fit, sd_name, sd_prediction, seed) {
  simulated <- simulate(fit, nsim = 1L, seed = seed, re.form = NULL)
  expect_equal(nrow(simulated), nrow(fit$data))
  expect_true(all(is.finite(simulated[[1L]])))
  expect_true(all(simulated[[1L]] > 0))
  saved_fit <- tempfile(fileext = ".rds")
  on.exit(unlink(saved_fit), add = TRUE)
  saveRDS(fit, saved_fit)
  expect_equal(
    predict(readRDS(saved_fit), dpar = sd_name), sd_prediction,
    tolerance = 1e-12
  )
}

test_that("Gamma relmat slope SDs can depend on group predictors (K and Q)", {
  skip_on_cran()
  K <- gss_shuffled_kernel(60L)
  expect_gt(max(diag(K)), 1.5)
  Q <- solve(K)
  dimnames(Q) <- dimnames(K)
  fx <- gss_fixture(K, seed = 20261105L)

  fit_K <- gss_fit(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat") ~ z),
    fx$data
  )
  sd_prediction <- gss_expect_slope_sd_fit(fit_K, fx, "sd_relmat(id)")
  expect_named(sd_prediction, rownames(K))

  fit_Q <- gss_fit(
    bf(y ~ x + relmat(0 + x | id, Q = Q), sigma ~ 1,
       sd(id, level = "relmat") ~ z),
    fx$data
  )
  gss_expect_slope_sd_fit(fit_Q, fx, "sd_relmat(id)")
  expect_lt(abs(as.numeric(logLik(fit_Q)) - as.numeric(logLik(fit_K))), 1e-4)

  gss_expect_roundtrip(fit_K, "sd_relmat(id)", sd_prediction, 20261106L)

  gss_expect_constant_sd_equivalence(
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat") ~ 1),
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1),
    fx$data
  )
  gss_expect_constant_sd_equivalence(
    bf(y ~ x + relmat(0 + x | id, Q = Q), sigma ~ 1,
       sd(id, level = "relmat") ~ 1),
    bf(y ~ x + relmat(0 + x | id, Q = Q), sigma ~ 1),
    fx$data
  )
})

test_that("Gamma animal slope SDs with Ainv match the dense oracle", {
  skip_on_cran()
  A <- gss_shuffled_kernel(50L, scale = 1.4, rho = 0.4, prefix = "a")
  Ainv <- solve(A)
  dimnames(Ainv) <- dimnames(A)
  fx <- gss_fixture(A, seed = 20261110L)
  fit <- gss_fit(
    bf(y ~ x + animal(0 + x | id, Ainv = Ainv), sigma ~ 1,
       sd(id, level = "animal") ~ z),
    fx$data
  )
  sd_prediction <- gss_expect_slope_sd_fit(fit, fx, "sd_animal(id)")
  gss_expect_roundtrip(fit, "sd_animal(id)", sd_prediction, 20261111L)
  gss_expect_constant_sd_equivalence(
    bf(y ~ x + animal(0 + x | id, Ainv = Ainv), sigma ~ 1,
       sd(id, level = "animal") ~ 1),
    bf(y ~ x + animal(0 + x | id, Ainv = Ainv), sigma ~ 1),
    fx$data
  )
})

test_that("Gamma phylo slope SDs can depend on group predictors", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(20261107L)
  n_species <- 40L
  tree <- ape::rcoal(n_species)
  tree$tip.label <- sample(paste0("species_", seq_len(n_species)))
  # Independent covariance: shared root-path length scaled to unit height.
  K <- ape::vcv(tree)
  K <- K / max(diag(K))
  K <- K[sample(n_species), ]
  K <- K[, rownames(K)]
  expect_equal(unname(diag(K)), rep(1, n_species), tolerance = 1e-8)
  fx <- gss_fixture(K, seed = 20261108L)
  fx$data$species <- fx$data$id

  fit <- gss_fit(
    bf(y ~ x + phylo(0 + x | species, tree = tree), sigma ~ 1,
       sd(species, level = "phylogenetic") ~ z),
    fx$data
  )
  sd_prediction <- gss_expect_slope_sd_fit(fit, fx, "sd_phylo(species)")
  expect_length(sd_prediction, n_species)
  gss_expect_roundtrip(fit, "sd_phylo(species)", sd_prediction, 20261109L)
  gss_expect_constant_sd_equivalence(
    bf(y ~ x + phylo(0 + x | species, tree = tree), sigma ~ 1,
       sd(species, level = "phylogenetic") ~ 1),
    bf(y ~ x + phylo(0 + x | species, tree = tree), sigma ~ 1),
    fx$data
  )
})

test_that("Gamma spatial slope SDs can depend on group predictors", {
  skip_on_cran()
  n_site <- 48L
  ids <- sprintf("site%03d", sample(n_site))
  coords <- as.matrix(expand.grid(easting = 0:7, northing = 0:5))
  rownames(coords) <- ids
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance) & distance > 0])
  K <- exp(-distance / range)
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(ids, ids)
  fx <- gss_fixture(K, seed = 20261112L, n_each = 20L)
  fx$data$site <- fx$data$id

  fit <- gss_fit(
    bf(y ~ x + spatial(0 + x | site, coords = coords), sigma ~ 1,
       sd(site, level = "spatial") ~ z),
    fx$data
  )
  sd_prediction <- gss_expect_slope_sd_fit(fit, fx, "sd_spatial(site)")
  gss_expect_roundtrip(fit, "sd_spatial(site)", sd_prediction, 20261113L)
  gss_expect_constant_sd_equivalence(
    bf(y ~ x + spatial(0 + x | site, coords = coords), sigma ~ 1,
       sd(site, level = "spatial") ~ 1),
    bf(y ~ x + spatial(0 + x | site, coords = coords), sigma ~ 1),
    fx$data
  )
})

test_that("Gamma structured slope-only SD keeps neighbouring routes closed", {
  skip_if_not_installed("ape")
  K <- gss_shuffled_kernel(20L)
  fx <- gss_fixture(K, seed = 20261114L, n_each = 6L)
  data <- fx$data
  data$z0 <- data$z
  set.seed(20261115L)
  tree <- ape::rcoal(20L)
  tree$tip.label <- rownames(K)
  coords <- cbind(easting = seq_len(20L), northing = rev(seq_len(20L)) %% 5L)
  rownames(coords) <- rownames(K)
  build <- function(f, ...) {
    drmTMB:::drm_build_gamma_ls_spec(f, data, ...)
  }
  # Two-slope slope-only blocks stay refused for every provider.
  expect_error(build(bf(y ~ x + phylo(0 + x + z0 | id, tree = tree),
                        sigma ~ 1)), "intercept-only")
  expect_error(build(bf(y ~ x + spatial(0 + x + z0 | id, coords = coords),
                        sigma ~ 1)), "intercept-only")
  expect_error(build(bf(y ~ x + relmat(0 + x + z0 | id, K = K),
                        sigma ~ 1)), "reserves only intercept and one-slope")
  expect_error(build(bf(y ~ x + phylo(1 + x + z0 | id, tree = tree),
                        sigma ~ 1)), "intercept-only")
  # Labelled slope-only blocks stay refused.
  expect_error(build(bf(y ~ x + phylo(0 + x | p | id, tree = tree),
                        sigma ~ 1)), "unlabelled|label")
  expect_error(build(bf(y ~ x + relmat(0 + x | p | id, K = K),
                        sigma ~ 1)), "unlabelled|label")
  # No ordinary random layer beside the structured slope.
  expect_error(build(bf(y ~ x + relmat(0 + x | id, K = K) + (1 | id),
                        sigma ~ 1)), "cannot be combined")
  # Complete responses only.
  expect_error(
    build(bf(y ~ x + phylo(0 + x | id, tree = tree), sigma ~ 1),
          missing = miss_control(response = "include")),
    "complete"
  )
  # Mesh spatial slope stays refused.
  expect_error(build(bf(y ~ x + spatial(0 + x | id, mesh = list()),
                        sigma ~ 1)), "intercept-only|mesh")
  # Other positive-continuous families do not inherit the Gamma admission.
  expect_error(
    drmTMB:::drm_build_lognormal_ls_spec(
      bf(y ~ x + phylo(0 + x | id, tree = tree), sigma ~ 1), data),
    "intercept"
  )
  # The SD predictor must be constant within each structured level.
  bad <- data
  bad$z[1L] <- bad$z[1L] + 1
  expect_error(
    drmTMB:::drm_build_gamma_ls_spec(
      bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1,
         sd(id, level = "relmat") ~ z), bad),
    "constant within|varies within"
  )
})
