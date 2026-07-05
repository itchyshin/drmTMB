# M3 q8 recovery: helpers for the q8 all-four one-slope block (8 endpoints,
# 28 correlations). Reuses the M2 provider infrastructure (provider_group_cov,
# tree builder, metrics) and adds the q8 DGP + fit for all four providers.
#
# q8 = `(1 + x | p | id)` on mu1, mu2, sigma1, sigma2. Eight endpoints in
# canonical order (matches structured$dpars/coef_names and corpars upper-tri):
#   mu1:int, mu1:x, mu2:int, mu2:x, sigma1:int, sigma1:x, sigma2:int, sigma2:x
# -> 8 SDs + 28 among-endpoint correlations. The four providers share ONE truth
# Sigma; each imposes its own among-group covariance A (A ⊗ Sigma).
#
# Key question (M1 found phylo q8 pdHess=FALSE persists even at 1024 groups):
# does the weak-identification hold for spatial/animal/relmat too, or does any
# provider reach pdHess=TRUE at Santi-scale?

m2 <- "docs/dev-log/simulation-artifacts/2026-07-05-m2-q6-recovery/00-helpers.R"
source(m2)  # provider_group_cov, balanced_ultrametric_tree, upper_tri_vec,
            # recovery_metrics, corr_from_upper, frobenius_corr

# --- q8 truth ---------------------------------------------------------------
q8_labels <- function() {
  dpars <- rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L)
  coef <- rep(c("(Intercept)", "x"), times = 4L)
  paste0(dpars, ":", coef)
}

# Deterministic PD 8x8 correlation from a fixed 2-factor low-rank + diagonal
# design (no RNG -- a default-arg RNG reset would clobber the per-replicate seed).
q8_truth_corr <- function() {
  labs <- q8_labels()
  sd_re <- c(0.55, 0.32, 0.48, 0.30, 0.34, 0.22, 0.30, 0.20)
  names(sd_re) <- labs
  # Rows = the 8 endpoints. Factor 1 couples intercepts, factor 2 couples slopes.
  L <- matrix(
    c(
      0.90, 0.10,
      0.20, 0.80,
      0.80, 0.15,
      0.25, 0.75,
      0.55, 0.35,
      0.30, 0.60,
      0.50, 0.40,
      0.35, 0.55
    ),
    nrow = 8L, byrow = TRUE
  )
  Sig <- L %*% t(L) + diag(0.4, 8L)
  d <- sqrt(diag(Sig))
  corr <- Sig / (d %o% d)
  dimnames(corr) <- list(labs, labs)
  list(sd_re = sd_re, corr = corr)
}

# --- q8 DGP (all-four one-slope) --------------------------------------------
simulate_q8_all_four <- function(seed, provider, n_group, n_each,
                                 truth = q8_truth_corr(), rho12 = 0.15) {
  set.seed(seed)
  sd_re <- truth$sd_re
  corr <- truth$corr
  gc <- provider_group_cov(provider, n_group)
  A <- gc$A
  levels <- gc$levels
  covariance <- diag(sd_re) %*% corr %*% diag(sd_re)
  z_eff <- matrix(stats::rnorm(n_group * 8L), n_group, 8L)
  effect <- t(chol(A)) %*% z_eff %*% chol(covariance)
  dimnames(effect) <- list(levels, colnames(corr))

  grp <- rep(levels, each = n_each)
  n <- length(grp)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  bm1 <- c(0.35, 0.30); bm2 <- c(-0.20, -0.25)
  bs1 <- c(-1.00, 0.20); bs2 <- c(-0.95, -0.15)
  e <- effect[grp, ]
  eta_mu1 <- bm1[1] + bm1[2] * x + e[, "mu1:(Intercept)"] + x * e[, "mu1:x"]
  eta_mu2 <- bm2[1] + bm2[2] * x + e[, "mu2:(Intercept)"] + x * e[, "mu2:x"]
  log_s1 <- bs1[1] + bs1[2] * z + e[, "sigma1:(Intercept)"] + x * e[, "sigma1:x"]
  log_s2 <- bs2[1] + bs2[2] * z + e[, "sigma2:(Intercept)"] + x * e[, "sigma2:x"]
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat <- data.frame(
    y1 = eta_mu1 + exp(log_s1) * e1,
    y2 = eta_mu2 + exp(log_s2) * e2,
    x = x, z = z, id = grp
  )
  c(list(data = dat, truth = truth, rho12 = rho12), gc)
}

# --- fit one provider q8 (all-four one-slope) -------------------------------
fit_q8 <- function(sim, provider, control) {
  tree <- sim$tree
  coords <- sim$coords
  animal_A <- sim$animal_A
  relmat_K <- sim$relmat_K
  form <- switch(
    provider,
    phylo = bf(
      mu1 = y1 ~ x + phylo(1 + x | p | id, tree = tree),
      mu2 = y2 ~ x + phylo(1 + x | p | id, tree = tree),
      sigma1 = ~ z + phylo(1 + x | p | id, tree = tree),
      sigma2 = ~ z + phylo(1 + x | p | id, tree = tree),
      rho12 = ~1
    ),
    spatial = bf(
      mu1 = y1 ~ x + spatial(1 + x | p | id, coords = coords),
      mu2 = y2 ~ x + spatial(1 + x | p | id, coords = coords),
      sigma1 = ~ z + spatial(1 + x | p | id, coords = coords),
      sigma2 = ~ z + spatial(1 + x | p | id, coords = coords),
      rho12 = ~1
    ),
    animal = bf(
      mu1 = y1 ~ x + animal(1 + x | p | id, A = animal_A),
      mu2 = y2 ~ x + animal(1 + x | p | id, A = animal_A),
      sigma1 = ~ z + animal(1 + x | p | id, A = animal_A),
      sigma2 = ~ z + animal(1 + x | p | id, A = animal_A),
      rho12 = ~1
    ),
    relmat = bf(
      mu1 = y1 ~ x + relmat(1 + x | p | id, K = relmat_K),
      mu2 = y2 ~ x + relmat(1 + x | p | id, K = relmat_K),
      sigma1 = ~ z + relmat(1 + x | p | id, K = relmat_K),
      sigma2 = ~ z + relmat(1 + x | p | id, K = relmat_K),
      rho12 = ~1
    )
  )
  suppressWarnings(drmTMB(
    form, family = biv_gaussian(), data = sim$data, control = control
  ))
}
