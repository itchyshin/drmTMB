# M1 high-q recovery: shared helpers (DGP, truth extraction, metrics).
# Curie / simulation_tester. Evidence-only; no engine edits.
#
# These helpers build a balanced ultrametric tree, a KNOWN among-endpoint
# covariance Sigma over the q phylo effects, simulate a bivariate Gaussian
# location-scale dataset, and provide alignment + error metrics so a fitted
# drmTMB q4 / q8 block can be compared to the simulated truth.

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
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

# --- q4 all-four (intercept-only) DGP ---------------------------------------
# Endpoints in canonical drmTMB order: mu1, mu2, sigma1, sigma2.
# corr is the 4x4 among-endpoint phylo correlation; sd_phylo the 4 SDs.
q4_truth_corr <- function() {
  sd_phylo <- c(mu1 = 0.60, mu2 = 0.50, sigma1 = 0.35, sigma2 = 0.30)
  corr <- matrix(
    c(
      1.00, 0.50, 0.30, 0.10,
      0.50, 1.00, 0.10, 0.30,
      0.30, 0.10, 1.00, 0.40,
      0.10, 0.30, 0.40, 1.00
    ),
    nrow = 4L, byrow = TRUE,
    dimnames = list(names(sd_phylo), names(sd_phylo))
  )
  list(sd_phylo = sd_phylo, corr = corr)
}

simulate_q4_all_four <- function(seed, n_tip, n_each,
                                 truth = q4_truth_corr(),
                                 rho12 = 0.15) {
  set.seed(seed)
  sd_phylo <- truth$sd_phylo
  corr <- truth$corr
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  covariance <- diag(sd_phylo) %*% corr %*% diag(sd_phylo)
  z_phylo <- matrix(stats::rnorm(n_tip * 4L), n_tip, 4L)
  phylo_effect <- t(chol(A)) %*% z_phylo %*% chol(covariance)
  dimnames(phylo_effect) <- list(tree$tip.label, names(sd_phylo))

  species <- rep(tree$tip.label, each = n_each)
  n <- length(species)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  bm1 <- c(0.35, 0.30)
  bm2 <- c(-0.20, -0.25)
  bs1 <- c(-1.00, 0.20)
  bs2 <- c(-0.95, -0.15)
  eta_mu1 <- bm1[1] + bm1[2] * x + phylo_effect[species, "mu1"]
  eta_mu2 <- bm2[1] + bm2[2] * x + phylo_effect[species, "mu2"]
  log_s1 <- bs1[1] + bs1[2] * z + phylo_effect[species, "sigma1"]
  log_s2 <- bs2[1] + bs2[2] * z + phylo_effect[species, "sigma2"]
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat <- data.frame(
    y1 = eta_mu1 + exp(log_s1) * e1,
    y2 = eta_mu2 + exp(log_s2) * e2,
    x = x, z = z, species = species
  )
  list(data = dat, tree = tree, truth = truth, rho12 = rho12,
       sd_phylo = sd_phylo, corr = corr)
}

# --- q8 all-four one-slope DGP ----------------------------------------------
# Each endpoint = intercept + slope; 8 SD targets, 28 correlations.
# Endpoint order: mu1:int, mu1:x, mu2:int, mu2:x, sigma1:int, sigma1:x,
# sigma2:int, sigma2:x  (matches structured$dpars/coef_names ordering used by
# the accepted q8 test: rep(c("mu1","mu2","sigma1","sigma2"), each=2)).
q8_labels <- function() {
  dpars <- rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L)
  coef <- rep(c("(Intercept)", "x"), times = 4L)
  paste0(dpars, ":", coef)
}

q8_truth_corr <- function() {
  labs <- q8_labels()
  sd_phylo <- c(0.55, 0.30, 0.48, 0.26, 0.34, 0.20, 0.30, 0.18)
  names(sd_phylo) <- labs
  # Build a non-trivial PD 8x8 correlation from a low-rank + diagonal design,
  # then round for readability. Two latent factors give rich off-diagonals.
  set.seed(999)
  L <- matrix(stats::rnorm(8L * 2L, sd = 0.6), 8L, 2L)
  Sig <- L %*% t(L) + diag(0.5, 8L)
  d <- sqrt(diag(Sig))
  corr <- Sig / (d %o% d)
  dimnames(corr) <- list(labs, labs)
  list(sd_phylo = sd_phylo, corr = corr)
}

simulate_q8_all_four_one_slope <- function(seed, n_tip, n_each,
                                           truth = q8_truth_corr(),
                                           rho12 = 0.15) {
  set.seed(seed)
  sd_phylo <- truth$sd_phylo
  corr <- truth$corr
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  covariance <- diag(sd_phylo) %*% corr %*% diag(sd_phylo)
  z_phylo <- matrix(stats::rnorm(n_tip * 8L), n_tip, 8L)
  phylo_effect <- t(chol(A)) %*% z_phylo %*% chol(covariance)
  dimnames(phylo_effect) <- list(tree$tip.label, colnames(corr))

  species <- rep(tree$tip.label, each = n_each)
  n <- length(species)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  # Fixed effects.
  bm1 <- c(0.35, 0.30)
  bm2 <- c(-0.20, -0.25)
  bs1 <- c(-1.00, 0.20)
  bs2 <- c(-0.95, -0.15)
  # phylo columns: use intercept effect + slope*x for each endpoint.
  pe <- phylo_effect[species, ]
  eta_mu1 <- bm1[1] + bm1[2] * x + pe[, "mu1:(Intercept)"] + pe[, "mu1:x"] * x
  eta_mu2 <- bm2[1] + bm2[2] * x + pe[, "mu2:(Intercept)"] + pe[, "mu2:x"] * x
  log_s1 <- bs1[1] + bs1[2] * z + pe[, "sigma1:(Intercept)"] + pe[, "sigma1:x"] * x
  log_s2 <- bs2[1] + bs2[2] * z + pe[, "sigma2:(Intercept)"] + pe[, "sigma2:x"] * x
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat <- data.frame(
    y1 = eta_mu1 + exp(log_s1) * e1,
    y2 = eta_mu2 + exp(log_s2) * e2,
    x = x, z = z, species = species
  )
  list(data = dat, tree = tree, truth = truth, rho12 = rho12,
       sd_phylo = sd_phylo, corr = corr)
}

# --- truth vector in corpars$phylo order ------------------------------------
# corpars$phylo is the row-major upper triangle (i<j) of the qxq correlation in
# endpoint order. This returns the aligned true correlation vector.
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

# --- error metrics -----------------------------------------------------------
# Given a fitted correlation vector (in corpars$phylo order) and truth vector
# (same order), report per-pair bias/RMSE inputs plus Frobenius distance of the
# full correlation matrices.
recovery_metrics <- function(rho_hat, rho_true) {
  stopifnot(length(rho_hat) == length(rho_true))
  err <- rho_hat - rho_true
  list(
    max_abs_rho_hat = max(abs(rho_hat)),
    cap_saturated = any(abs(rho_hat) > 0.99),
    mean_bias = mean(err),
    rmse = sqrt(mean(err^2)),
    max_abs_err = max(abs(err)),
    per_pair_err = err
  )
}

frobenius_corr <- function(corr_hat, corr_true) {
  sqrt(sum((corr_hat - corr_true)^2))
}

# Rebuild the fitted qxq correlation matrix from corpars$phylo (upper-tri
# order) so we can compute Frobenius vs truth.
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
