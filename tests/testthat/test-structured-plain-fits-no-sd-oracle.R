# Plain fits WITHOUT any sd(...) formula that were admitted as a side effect of
# the SD-regression routes (review notes, 2026-11-01):
#   (A) NB2   y ~ x + phylo_interaction(0 + x | plant:pollinator, tree1, tree2)
#   (B) Gamma y ~ x + (1 | g) + animal|phylo|spatial(1 | p, ...)
#   (C) Gamma y ~ x + phylo|spatial|relmat|animal(0 + x | id, ...)
# Each plain model has CONSTANT standard deviations, so the dense, drmTMB-
# independent Laplace marginal likelihood evaluated at the fitted parameters
# (constant SDs) must reproduce logLik(fit), and the plain fit must equal the
# sd(...) ~ 1 fit. Templates: test-nbinom2-phylo-interaction-sd.R,
# test-gamma-ordinary-sd-beside-structured.R, test-gamma-structured-slope-sd.R.
#
# Tolerances fixed before the first run and never loosened:
#   oracle agreement 1e-4 absolute on the log-likelihood (NB2 interaction and
#   slope-only Gamma), 1e-5 for the Gamma intercept routes; plain versus
#   sd ~ 1 fit 1e-4 absolute on logLik and 1e-3 on mu coefficients; each
#   emulated bug must move the oracle by more than 0.05 log-likelihood units.
# Non-unit-diagonal K is used for relmat and animal; phylogenetic and spatial
# providers only supply the correlation form (unit diagonal for trees), as in
# the sibling tests. Group levels are stored in a shuffled order everywhere.

# ---------------------------------------------------------------- Gamma core
spf_gamma_laplace <- function(y, eta, Z, Sigma, shape) {
  q <- ncol(Z)
  Sinv <- solve(Sigma)
  logdet_S <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  b <- rep(0, q)
  joint <- function(b) {
    lin <- eta + as.vector(Z %*% b)
    sum(shape * (log(shape) - lin) + (shape - 1) * log(y) -
          shape * y * exp(-lin) - lgamma(shape)) -
      0.5 * sum(b * (Sinv %*% b)) - 0.5 * logdet_S - 0.5 * q * log(2 * pi)
  }
  grad_fun <- function(b) {
    mu <- exp(eta + as.vector(Z %*% b))
    shape * as.vector(crossprod(Z, y / mu - 1)) - as.vector(Sinv %*% b)
  }
  for (iter in seq_len(300L)) {
    mu <- exp(eta + as.vector(Z %*% b))
    grad <- grad_fun(b)
    H <- shape * crossprod(Z, (y / mu) * Z) + Sinv
    step <- as.vector(solve(H, grad))
    scale <- 1
    while (joint(b + scale * step) < joint(b) - 1e-12 && scale > 1e-8) {
      scale <- scale / 2
    }
    b <- b + scale * step
    if (max(abs(grad)) < 1e-10) break
  }
  mu <- exp(eta + as.vector(Z %*% b))
  H <- shape * crossprod(Z, (y / mu) * Z) + Sinv
  stopifnot(max(abs(grad_fun(b))) < 1e-8)
  joint(b) + 0.5 * q * log(2 * pi) -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

# Cyclic relabelling of K's dimnames: a mislabelled K that, unlike a reversal,
# is not a symmetry of the Toeplitz-type kernels used here.
spf_mislabel <- function(K, shift = 7L) {
  n <- nrow(K)
  nm <- rownames(K)[(seq_len(n) + shift - 1L) %% n + 1L]
  dimnames(K) <- list(nm, nm)
  K
}

spf_kernel <- function(kind, n, ids, seed_order = TRUE) {
  tree <- NULL
  coords <- NULL
  if (identical(kind, "phylo")) {
    tree <- ape::rcoal(n)
    tree$tip.label <- sample(ids)
    K <- ape::vcv(tree)
    K <- K / max(diag(K))
    K <- K[sample(n), ]
    K <- K[, rownames(K)]
  } else if (identical(kind, "spatial")) {
    theta <- seq(0, 2 * pi, length.out = n + 1L)[-1L]
    coords <- data.frame(x = cos(theta), y = sin(theta), row.names = ids)
    coords <- coords[sample(ids), , drop = FALSE]
    precision <- drmTMB:::drm_spatial_coords_precision(
      coords, site = rownames(coords), group = "p"
    )
    K <- solve(as.matrix(precision$precision))
    dimnames(K) <- list(rownames(coords), rownames(coords))
  } else {
    base <- 1.6 * 0.45^abs(outer(seq_len(n), seq_len(n), `-`))
    dimnames(base) <- list(ids, ids)
    ord <- c(seq(1L, n, by = 2L), seq(2L, n, by = 2L))
    K <- base[ord, ord]
  }
  list(K = K, tree = tree, coords = coords)
}

# ------------------------------------------------ (B) Gamma (1 | g) + provider
spf_b_fixture <- function(kind, seed, n_g = 24L, n_p = 20L, reps = 2L,
                          shape = 6) {
  set.seed(seed)
  g_levels <- sprintf("g%02d", seq_len(n_g))
  p_levels <- sprintf("p%02d", seq_len(n_p))
  km <- spf_kernel(kind, n_p, p_levels)
  K <- km$K
  b_g <- stats::setNames(stats::rnorm(n_g, sd = 0.5), g_levels)
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_p))
  names(field) <- rownames(K)
  b_p <- (field * 0.45)[p_levels]
  design <- expand.grid(rep = seq_len(reps), gi = seq_len(n_g),
                        pi = seq_len(n_p))
  dat <- data.frame(
    x = stats::rnorm(nrow(design)),
    g = factor(g_levels[design$gi], levels = g_levels),
    p = factor(p_levels[design$pi], levels = rev(p_levels))
  )
  mu <- exp(0.2 + 0.3 * dat$x + b_g[as.character(dat$g)] +
              b_p[as.character(dat$p)])
  dat$y <- stats::rgamma(nrow(dat), shape = shape, scale = mu / shape)
  list(data = dat, K = K, tree = km$tree, coords = km$coords)
}

spf_b_terms <- list(
  animal = "animal(1 | p, A = A)",
  phylo = "phylo(1 | p, tree = tree)",
  spatial = "spatial(1 | p, coords = coords)"
)

spf_b_fit <- function(fx, kind, sd_g = FALSE) {
  A <- fx$K
  tree <- fx$tree
  coords <- fx$coords
  parts <- c(paste("y ~ x + (1 | g) +", spf_b_terms[[kind]]), "sigma ~ 1")
  if (sd_g) parts <- c(parts, "sd(g) ~ 1")
  drmTMB(eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", ")))),
         family = Gamma(link = "log"), data = fx$data,
         control = drm_control(se = FALSE))
}

spf_b_oracle <- function(fit, fx, K = fx$K, tau_g = NULL, s_p = NULL) {
  dat <- fx$data
  beta <- unname(coef(fit, "mu"))
  sds <- unname(fit$sdpars$mu)
  if (is.null(tau_g)) tau_g <- sds[[1L]]
  if (is.null(s_p)) s_p <- sds[[2L]]
  shape <- exp(-2 * unname(coef(fit, "sigma"))[[1L]])
  Zg <- stats::model.matrix(~ 0 + g, dat)
  Zp <- stats::model.matrix(~ 0 + p, dat)
  Kp <- K[levels(dat$p), levels(dat$p)]
  ig <- seq_len(ncol(Zg))
  ip <- ncol(Zg) + seq_len(ncol(Zp))
  Sigma <- matrix(0, ncol(Zg) + ncol(Zp), ncol(Zg) + ncol(Zp))
  Sigma[ig, ig] <- diag(tau_g^2, length(ig))
  Sigma[ip, ip] <- s_p^2 * Kp
  spf_gamma_laplace(dat$y, beta[[1L]] + beta[[2L]] * dat$x, cbind(Zg, Zp),
                    Sigma, shape)
}

spf_b_check <- function(kind, seed) {
  fx <- spf_b_fixture(kind, seed)
  expect_false(identical(levels(fx$data$p), rownames(fx$K)))
  fit <- spf_b_fit(fx, kind)
  expect_equal(fit$opt$convergence, 0L, info = kind)
  expect_length(fit$sdpars$mu, 2L)
  oracle <- spf_b_oracle(fit, fx)
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - oracle), 1e-5)
  # Emulated bugs: positional (mislabelled) K, mis-scaled K, swapped SDs.
  expect_gt(abs(spf_b_oracle(fit, fx, K = spf_mislabel(fx$K)) - oracle), 0.05)
  expect_gt(abs(spf_b_oracle(fit, fx, K = 3 * fx$K) - oracle), 0.05)
  sds <- unname(fit$sdpars$mu)
  expect_gt(
    abs(spf_b_oracle(fit, fx, tau_g = sds[[2L]], s_p = sds[[1L]]) - oracle),
    0.05
  )
  # Constant-SD equivalence with sd(g) ~ 1.
  const_fit <- spf_b_fit(fx, kind, sd_g = TRUE)
  expect_equal(const_fit$opt$convergence, 0L, info = kind)
  expect_lt(abs(as.numeric(logLik(const_fit)) - ll), 1e-4)
  expect_equal(coef(const_fit, "mu"), coef(fit, "mu"), tolerance = 1e-3)
  invisible(fit)
}

test_that("plain Gamma (1 | g) + animal intercept matches the dense oracle", {
  skip_on_cran()
  spf_b_check("animal", 2026110701L)
})

test_that("plain Gamma (1 | g) + phylo intercept matches the dense oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  spf_b_check("phylo", 2026110702L)
})

test_that("plain Gamma (1 | g) + spatial intercept matches the dense oracle", {
  skip_on_cran()
  spf_b_check("spatial", 2026110703L)
})

# ------------------------------------------- (C) Gamma structured slope-only
spf_c_fixture <- function(K, seed, n_each = 12L, sigma = 0.35, sd = 0.5) {
  set.seed(seed)
  ids <- rownames(K)
  n_id <- length(ids)
  slope <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd
  names(slope) <- ids
  id <- factor(rep(ids, each = n_each), levels = ids)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
  mu <- exp(0.3 + 0.2 * x + slope[as.character(id)] * x)
  data <- data.frame(
    y = stats::rgamma(length(mu), shape = 1 / sigma^2, scale = mu * sigma^2),
    id = id, x = x
  )
  data <- data[sample(nrow(data)), , drop = FALSE]
  rownames(data) <- NULL
  list(data = data, K = K)
}

spf_c_laplace <- function(y, x, idx, beta, sigma, sd_by_level, K) {
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

spf_c_kernel <- function(n_id, scale = 1.7, rho = 0.45, prefix = "id") {
  ids <- paste0(prefix, seq_len(n_id))
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  K_base <- scale * rho^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K_base) <- list(ids, ids)
  K_base[order, order]
}

# Plain fit (no sd formula) versus sd(...) ~ 1 fit, oracle and bug checks.
spf_c_check <- function(fx, plain_formula, const_formula, label) {
  K <- fx$K
  dat <- fx$data
  fit <- drmTMB(plain_formula, family = Gamma(link = "log"), data = dat,
                control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L, info = label)
  sd_hat <- unname(fit$sdpars$mu)
  expect_length(sd_hat, 1L)
  oracle_at <- function(sd = sd_hat, K = fx$K) {
    spf_c_laplace(
      y = dat$y, x = dat$x, idx = match(as.character(dat$id), rownames(K)),
      beta = fit$coefficients$mu[c("(Intercept)", "x")],
      sigma = exp(fit$coefficients$sigma[[1L]]),
      sd_by_level = rep(sd, nrow(K)), K = K
    )
  }
  ll <- as.numeric(logLik(fit))
  oracle <- oracle_at()
  expect_lt(abs(ll - oracle), 1e-4)
  # Emulated bugs: halved SD, mis-scaled K, mislabelled K (non-spatial/tree).
  expect_gt(abs(oracle_at(sd = 0.5 * sd_hat) - oracle), 0.05)
  expect_gt(abs(oracle_at(K = 3 * K) - oracle), 0.05)
  expect_gt(abs(oracle_at(K = spf_mislabel(K)) - oracle), 0.05)
  # Constant-SD equivalence.
  const_fit <- drmTMB(const_formula, family = Gamma(link = "log"), data = dat,
                      control = drm_control(se = FALSE))
  expect_equal(const_fit$opt$convergence, 0L, info = label)
  expect_lt(abs(as.numeric(logLik(const_fit)) - ll), 1e-4)
  expect_equal(coef(const_fit, "mu"), coef(fit, "mu"), tolerance = 1e-3)
  invisible(fit)
}

test_that("plain Gamma relmat slope-only (K and Q) matches the dense oracle", {
  skip_on_cran()
  set.seed(20261201L)
  K <- spf_c_kernel(60L)
  expect_gt(max(diag(K)), 1.5)
  Q <- solve(K)
  dimnames(Q) <- dimnames(K)
  fx <- spf_c_fixture(K, 20261202L)
  fit_K <- spf_c_check(
    fx, bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1),
    bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1,
       sd(id, level = "relmat") ~ 1),
    "relmat K"
  )
  fit_Q <- spf_c_check(
    fx, bf(y ~ x + relmat(0 + x | id, Q = Q), sigma ~ 1),
    bf(y ~ x + relmat(0 + x | id, Q = Q), sigma ~ 1,
       sd(id, level = "relmat") ~ 1),
    "relmat Q"
  )
  expect_lt(abs(as.numeric(logLik(fit_Q)) - as.numeric(logLik(fit_K))), 1e-4)
})

test_that("plain Gamma animal slope-only (Ainv) matches the dense oracle", {
  skip_on_cran()
  A <- spf_c_kernel(50L, scale = 1.4, rho = 0.4, prefix = "a")
  Ainv <- solve(A)
  dimnames(Ainv) <- dimnames(A)
  fx <- spf_c_fixture(A, 20261203L)
  spf_c_check(
    fx, bf(y ~ x + animal(0 + x | id, Ainv = Ainv), sigma ~ 1),
    bf(y ~ x + animal(0 + x | id, Ainv = Ainv), sigma ~ 1,
       sd(id, level = "animal") ~ 1),
    "animal Ainv"
  )
})

test_that("plain Gamma phylo slope-only matches the dense oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(20261204L)
  n_species <- 40L
  tree <- ape::rcoal(n_species)
  tree$tip.label <- sample(paste0("species_", seq_len(n_species)))
  K <- ape::vcv(tree)
  K <- K / max(diag(K))
  K <- K[sample(n_species), ]
  K <- K[, rownames(K)]
  fx <- spf_c_fixture(K, 20261205L)
  fx$data$species <- fx$data$id
  dat <- fx$data
  fit <- spf_c_check(
    fx, bf(y ~ x + phylo(0 + x | id, tree = tree), sigma ~ 1),
    bf(y ~ x + phylo(0 + x | id, tree = tree), sigma ~ 1,
       sd(id, level = "phylogenetic") ~ 1),
    "phylo"
  )
})

test_that("plain Gamma spatial slope-only matches the dense oracle", {
  skip_on_cran()
  set.seed(20261206L)
  n_site <- 48L
  ids <- sprintf("site%03d", sample(n_site))
  coords <- as.matrix(expand.grid(easting = 0:7, northing = 0:5))
  rownames(coords) <- ids
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance) & distance > 0])
  K <- exp(-distance / range)
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(ids, ids)
  fx <- spf_c_fixture(K, 20261207L, n_each = 20L)
  spf_c_check(
    fx, bf(y ~ x + spatial(0 + x | id, coords = coords), sigma ~ 1),
    bf(y ~ x + spatial(0 + x | id, coords = coords), sigma ~ 1,
       sd(id, level = "spatial") ~ 1),
    "spatial"
  )
})

# ------------------------------------- (A) NB2 phylo_interaction slope-only
spf_a_tree <- function(n_tip, prefix) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }
  build(seq_len(n_tip))
  structure(
    list(edge = edges, edge.length = edge_lengths,
         tip.label = sample(paste0(prefix, seq_len(n_tip))),
         Nnode = n_tip - 1L),
    class = "phylo"
  )
}

spf_a_laplace <- function(y, x, value, pair_idx, beta, sd, K, sigma) {
  n_pair <- nrow(K)
  n_obs <- length(y)
  size <- 1 / sigma^2
  J <- matrix(0, n_obs, n_pair)
  J[cbind(seq_len(n_obs), pair_idx)] <- sd * value
  Kinv <- solve(K)
  eta0 <- beta[[1L]] + beta[[2L]] * x
  logjoint <- function(f) {
    eta <- eta0 + as.vector(J %*% f)
    sum(stats::dnbinom(y, size = size, mu = exp(eta), log = TRUE)) -
      0.5 * sum(f * (Kinv %*% f))
  }
  f <- rep(0, n_pair)
  for (iter in seq_len(200L)) {
    mu <- exp(eta0 + as.vector(J %*% f))
    score <- (y - mu) * size / (size + mu)
    info <- (y + size) * size * mu / (size + mu)^2
    grad <- as.vector(crossprod(J, score)) - as.vector(Kinv %*% f)
    H <- crossprod(J, info * J) + Kinv
    step <- as.vector(solve(H, grad))
    scale <- 1
    f0 <- logjoint(f)
    while (logjoint(f + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    f <- f + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  mu <- exp(eta0 + as.vector(J %*% f))
  info <- (y + size) * size * mu / (size + mu)^2
  logjoint(f) -
    0.5 * as.numeric(determinant(diag(n_pair) + K %*% crossprod(J, info * J))$modulus)
}

test_that("plain NB2 phylo_interaction slope-only matches the dense oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  set.seed(20261208L)
  tree1 <- spf_a_tree(8L, "plant_")
  tree2 <- spf_a_tree(4L, "poll_")
  A1 <- drmTMB:::drm_phylo_tip_covariance(tree1)
  A2 <- drmTMB:::drm_phylo_tip_covariance(tree2)
  grid <- expand.grid(plant = rownames(A1), pollinator = rownames(A2),
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  grid$pair <- paste(grid$plant, grid$pollinator, sep = ":")
  K <- kronecker(A2[rownames(A2), rownames(A2)], A1[rownames(A1), rownames(A1)])
  dimnames(K) <- list(grid$pair, grid$pair)
  n_pair <- nrow(grid)
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_pair)) * 0.5
  names(field) <- grid$pair
  row <- sample(rep(seq_len(n_pair), each = 12L))
  dat <- grid[row, , drop = FALSE]
  rownames(dat) <- NULL
  dat$x <- stats::rnorm(nrow(dat))
  eta <- 0.9 + 0.3 * dat$x + dat$x * unname(field[dat$pair])
  dat$y <- stats::rnbinom(nrow(dat), mu = exp(eta), size = 1 / 0.3^2)

  fit_of <- function(with_sd) {
    f <- if (with_sd) {
      bf(y ~ x + phylo_interaction(0 + x | plant:pollinator, tree1 = tree1,
                                   tree2 = tree2),
         sigma ~ 1, sd(pair, level = "phylogenetic_interaction") ~ 1)
    } else {
      bf(y ~ x + phylo_interaction(0 + x | plant:pollinator, tree1 = tree1,
                                   tree2 = tree2),
         sigma ~ 1)
    }
    drmTMB(f, family = nbinom2(), data = dat,
           control = drm_control(se = FALSE))
  }
  fit <- fit_of(FALSE)
  expect_equal(fit$opt$convergence, 0L)
  sd_hat <- unname(fit$sdpars$mu)
  expect_length(sd_hat, 1L)
  pair_idx <- match(dat$pair, rownames(K))
  oracle_at <- function(value = dat$x, sd = sd_hat, K = K0) {
    spf_a_laplace(dat$y, dat$x, value, pair_idx,
                  fit$coefficients$mu[c("(Intercept)", "x")], sd, K,
                  exp(fit$coefficients$sigma[[1L]]))
  }
  K0 <- K
  ll <- as.numeric(logLik(fit))
  oracle <- oracle_at()
  expect_lt(abs(ll - oracle), 1e-4)
  # Emulated bugs: intercept loading instead of slope, swapped Kronecker
  # order, mis-scaled K, halved SD.
  expect_gt(abs(oracle_at(value = rep(1, nrow(dat))) - oracle), 0.05)
  K_swapped <- kronecker(A1, A2)
  dimnames(K_swapped) <- dimnames(K)
  expect_gt(abs(oracle_at(K = K_swapped) - oracle), 0.05)
  expect_gt(abs(oracle_at(K = 2 * K) - oracle), 0.05)
  expect_gt(abs(oracle_at(sd = 0.5 * sd_hat) - oracle), 0.05)
  # Constant-SD equivalence with sd(pair, ...) ~ 1.
  const_fit <- fit_of(TRUE)
  expect_equal(const_fit$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(const_fit)) - ll), 1e-4)
  expect_equal(const_fit$coefficients$mu, fit$coefficients$mu, tolerance = 1e-3)
})
