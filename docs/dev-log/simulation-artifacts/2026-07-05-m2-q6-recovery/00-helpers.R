# M2 q6 recovery: shared helpers (DGP, provider covariance, truth, metrics).
# Curie / simulation_tester. Evidence-only; extends the M1 high-q helpers to the
# q6 two-slope location-only bivariate Gaussian block.
#
# q6 = `(1 + x + z | p | id)` in mu1 and mu2. Six endpoints in canonical order:
#   mu1:(Intercept), mu1:x, mu1:z, mu2:(Intercept), mu2:x, mu2:z
# -> 6 SDs + 15 among-endpoint correlations (upper triangle of a 6x6). The four
# providers (phylo/spatial/animal/relmat) share ONE truth Sigma over these six
# endpoints; each provider imposes its own among-GROUP covariance A. The fit's
# `corpars[[provider]]` is the row-major upper triangle in the same endpoint
# order, so recovery compares it to the simulated truth.

balanced_ultrametric_tree <- function(n_tip = 16L) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
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
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("g_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

# --- q6 truth ---------------------------------------------------------------
q6_labels <- function() {
  dpars <- rep(c("mu1", "mu2"), each = 3L)
  coef <- rep(c("(Intercept)", "x", "z"), times = 2L)
  paste0(dpars, ":", coef)
}

# A non-trivial PD 6x6 correlation from a fixed 2-factor low-rank + diagonal
# design: rich off-diagonals, guaranteed recoverable. Built from a DETERMINISTIC
# loading matrix (no RNG) so it never touches the global stream -- otherwise, as
# a default argument, it would reset the per-replicate seed and collapse every
# seed to the same dataset.
q6_truth_corr <- function() {
  labs <- q6_labels()
  sd_phylo <- c(0.55, 0.32, 0.28, 0.48, 0.30, 0.24)
  names(sd_phylo) <- labs
  # Rows = endpoints [mu1:int, mu1:x, mu1:z, mu2:int, mu2:x, mu2:z]. Factor 1
  # couples intercepts across responses; factor 2 couples the x/z slopes.
  L <- matrix(
    c(
      0.90, 0.10,
      0.20, 0.80,
      0.50, 0.40,
      0.80, 0.20,
      0.30, 0.70,
      0.40, 0.55
    ),
    nrow = 6L, byrow = TRUE
  )
  Sig <- L %*% t(L) + diag(0.4, 6L)
  d <- sqrt(diag(Sig))
  corr <- Sig / (d %o% d)
  dimnames(corr) <- list(labs, labs)
  list(sd_phylo = sd_phylo, corr = corr)
}

# --- provider group covariances ---------------------------------------------
# Each returns a list(A = <ng x ng covariance>, levels = <group labels>, plus
# the object the fit consumes: tree / coords / A / K).
provider_group_cov <- function(provider, n_group) {
  if (provider == "phylo") {
    tree <- balanced_ultrametric_tree(n_group)
    A <- drmTMB:::drm_phylo_tip_covariance(tree)
    return(list(A = A, levels = tree$tip.label, tree = tree))
  }
  if (provider == "spatial") {
    levels <- paste0("g_", seq_len(n_group))
    theta <- seq(0, 6 * pi, length.out = n_group)
    coords <- data.frame(
      x = cos(theta) + seq_len(n_group) / (3 * n_group),
      y = sin(theta) + seq_len(n_group) / (5 * n_group)
    )
    rownames(coords) <- levels
    precision <- drmTMB:::drm_spatial_coords_precision(
      coords,
      site = levels,
      group = "site"
    )
    A <- solve(as.matrix(precision$precision))
    dimnames(A) <- list(levels, levels)
    return(list(A = A, levels = levels, coords = coords))
  }
  # animal / relmat: an AR(1)-style relatedness covariance, passed as A / K.
  levels <- paste0("g_", seq_len(n_group))
  K <- outer(seq_len(n_group), seq_len(n_group), function(i, j) 0.4^abs(i - j))
  diag(K) <- diag(K) + 0.10
  dimnames(K) <- list(levels, levels)
  if (provider == "animal") {
    return(list(A = K, levels = levels, animal_A = K))
  }
  list(A = K, levels = levels, relmat_K = K)
}

# --- q6 DGP -----------------------------------------------------------------
simulate_q6_location <- function(seed, provider, n_group, n_each,
                                 truth = q6_truth_corr(), rho12 = 0.15) {
  set.seed(seed)
  sd_phylo <- truth$sd_phylo
  corr <- truth$corr
  gc <- provider_group_cov(provider, n_group)
  A <- gc$A
  levels <- gc$levels
  covariance <- diag(sd_phylo) %*% corr %*% diag(sd_phylo)
  z_eff <- matrix(stats::rnorm(n_group * 6L), n_group, 6L)
  effect <- t(chol(A)) %*% z_eff %*% chol(covariance)
  dimnames(effect) <- list(levels, colnames(corr))

  grp <- rep(levels, each = n_each)
  n <- length(grp)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  bm1 <- c(0.30, 0.25, -0.15)
  bm2 <- c(-0.20, -0.20, 0.10)
  ls1 <- -1.00
  ls2 <- -0.95
  e_re <- effect[grp, ]
  eta_mu1 <- bm1[1] + bm1[2] * x + bm1[3] * z +
    e_re[, "mu1:(Intercept)"] + x * e_re[, "mu1:x"] + z * e_re[, "mu1:z"]
  eta_mu2 <- bm2[1] + bm2[2] * x + bm2[3] * z +
    e_re[, "mu2:(Intercept)"] + x * e_re[, "mu2:x"] + z * e_re[, "mu2:z"]
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat <- data.frame(
    y1 = eta_mu1 + exp(ls1) * e1,
    y2 = eta_mu2 + exp(ls2) * e2,
    x = x, z = z, id = grp
  )
  c(list(data = dat, truth = truth, rho12 = rho12), gc)
}

# --- fit one provider q6 ----------------------------------------------------
# Marker objects (tree/coords/animal_A/relmat_K) resolve from this frame.
fit_q6 <- function(sim, provider, control) {
  tree <- sim$tree
  coords <- sim$coords
  animal_A <- sim$animal_A
  relmat_K <- sim$relmat_K
  form <- switch(
    provider,
    phylo = bf(
      mu1 = y1 ~ x + z + phylo(1 + x + z | p | id, tree = tree),
      mu2 = y2 ~ x + z + phylo(1 + x + z | p | id, tree = tree),
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    ),
    spatial = bf(
      mu1 = y1 ~ x + z + spatial(1 + x + z | p | id, coords = coords),
      mu2 = y2 ~ x + z + spatial(1 + x + z | p | id, coords = coords),
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    ),
    animal = bf(
      mu1 = y1 ~ x + z + animal(1 + x + z | p | id, A = animal_A),
      mu2 = y2 ~ x + z + animal(1 + x + z | p | id, A = animal_A),
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    ),
    relmat = bf(
      mu1 = y1 ~ x + z + relmat(1 + x + z | p | id, K = relmat_K),
      mu2 = y2 ~ x + z + relmat(1 + x + z | p | id, K = relmat_K),
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1
    )
  )
  suppressWarnings(drmTMB(
    form, family = biv_gaussian(), data = sim$data, control = control
  ))
}

# --- truth / metrics (upper-tri of a q x q correlation) ---------------------
upper_tri_vec <- function(corr) {
  q <- nrow(corr)
  out <- numeric(0)
  nm <- character(0)
  for (i in seq_len(q - 1L)) {
    for (j in seq.int(i + 1L, q)) {
      out <- c(out, corr[i, j])
      nm <- c(nm, paste0(rownames(corr)[i], "~", colnames(corr)[j]))
    }
  }
  stats::setNames(out, nm)
}

recovery_metrics <- function(rho_hat, rho_true) {
  stopifnot(length(rho_hat) == length(rho_true))
  err <- rho_hat - rho_true
  list(
    max_abs_rho_hat = max(abs(rho_hat)),
    cap_saturated = any(abs(rho_hat) > 0.99),
    mean_bias = mean(err),
    rmse = sqrt(mean(err^2)),
    max_abs_err = max(abs(err))
  )
}

corr_from_upper <- function(rho_hat, q) {
  M <- diag(q)
  pos <- 1L
  for (i in seq_len(q - 1L)) {
    for (j in seq.int(i + 1L, q)) {
      M[i, j] <- rho_hat[pos]
      M[j, i] <- rho_hat[pos]
      pos <- pos + 1L
    }
  }
  M
}

frobenius_corr <- function(corr_hat, corr_true) {
  sqrt(sum((corr_hat - corr_true)^2))
}
