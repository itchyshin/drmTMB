# M3 q12 recovery: helpers for the q12 two-slope all-four block (12 endpoints,
# 66 correlations). Reuses the M2 provider infrastructure and adds the q12 DGP +
# fit. q12 = `(1 + x + z | p | id)` on mu1/mu2/sigma1/sigma2.
# Endpoint order: mu1:{int,x,z}, mu2:{int,x,z}, sigma1:{int,x,z}, sigma2:{int,x,z}.
# pdHess is expected FALSE (66 correlations); inference routes through
# profile/bootstrap (ELR excluded), per the arc doctrine.

m2 <- "docs/dev-log/simulation-artifacts/2026-07-05-m2-q6-recovery/00-helpers.R"
source(m2)  # provider_group_cov, balanced_ultrametric_tree, upper_tri_vec,
            # recovery_metrics, corr_from_upper, frobenius_corr

q12_labels <- function() {
  dpars <- rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 3L)
  coef <- rep(c("(Intercept)", "x", "z"), times = 4L)
  paste0(dpars, ":", coef)
}

# Deterministic PD 12x12 correlation (fixed 3-factor low-rank + diagonal; no RNG).
q12_truth_corr <- function() {
  labs <- q12_labels()
  sd_re <- c(0.55, 0.32, 0.28, 0.48, 0.30, 0.24,
             0.34, 0.22, 0.20, 0.30, 0.20, 0.18)
  names(sd_re) <- labs
  L <- matrix(
    c(
      0.90, 0.10, 0.05,
      0.20, 0.80, 0.10,
      0.15, 0.25, 0.75,
      0.80, 0.15, 0.10,
      0.25, 0.75, 0.15,
      0.10, 0.20, 0.70,
      0.55, 0.35, 0.20,
      0.30, 0.60, 0.25,
      0.20, 0.30, 0.55,
      0.50, 0.40, 0.25,
      0.35, 0.55, 0.20,
      0.25, 0.30, 0.50
    ),
    nrow = 12L, byrow = TRUE
  )
  Sig <- L %*% t(L) + diag(0.4, 12L)
  d <- sqrt(diag(Sig))
  corr <- Sig / (d %o% d)
  dimnames(corr) <- list(labs, labs)
  list(sd_re = sd_re, corr = corr)
}

simulate_q12_all_four <- function(seed, provider, n_group, n_each,
                                  truth = q12_truth_corr(), rho12 = 0.15) {
  set.seed(seed)
  sd_re <- truth$sd_re
  corr <- truth$corr
  gc <- provider_group_cov(provider, n_group)
  A <- gc$A
  levels <- gc$levels
  covariance <- diag(sd_re) %*% corr %*% diag(sd_re)
  z_eff <- matrix(stats::rnorm(n_group * 12L), n_group, 12L)
  effect <- t(chol(A)) %*% z_eff %*% chol(covariance)
  dimnames(effect) <- list(levels, colnames(corr))

  grp <- rep(levels, each = n_each)
  n <- length(grp)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  bm1 <- c(0.35, 0.30, -0.15); bm2 <- c(-0.20, -0.25, 0.10)
  bs1 <- c(-1.00, 0.15); bs2 <- c(-0.95, -0.10)
  e <- effect[grp, ]
  re <- function(k) e[, k]
  eta_mu1 <- bm1[1] + bm1[2] * x + bm1[3] * z +
    re("mu1:(Intercept)") + x * re("mu1:x") + z * re("mu1:z")
  eta_mu2 <- bm2[1] + bm2[2] * x + bm2[3] * z +
    re("mu2:(Intercept)") + x * re("mu2:x") + z * re("mu2:z")
  log_s1 <- bs1[1] + bs1[2] * z +
    re("sigma1:(Intercept)") + x * re("sigma1:x") + z * re("sigma1:z")
  log_s2 <- bs2[1] + bs2[2] * z +
    re("sigma2:(Intercept)") + x * re("sigma2:x") + z * re("sigma2:z")
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
  dat <- data.frame(
    y1 = eta_mu1 + exp(log_s1) * e1,
    y2 = eta_mu2 + exp(log_s2) * e2,
    x = x, z = z, id = grp
  )
  c(list(data = dat, truth = truth, rho12 = rho12), gc)
}

fit_q12 <- function(sim, provider, control) {
  tree <- sim$tree
  coords <- sim$coords
  animal_A <- sim$animal_A
  relmat_K <- sim$relmat_K
  form <- switch(
    provider,
    phylo = bf(
      mu1 = y1 ~ x + z + phylo(1 + x + z | p | id, tree = tree),
      mu2 = y2 ~ x + z + phylo(1 + x + z | p | id, tree = tree),
      sigma1 = ~ z + phylo(1 + x + z | p | id, tree = tree),
      sigma2 = ~ z + phylo(1 + x + z | p | id, tree = tree),
      rho12 = ~1
    ),
    spatial = bf(
      mu1 = y1 ~ x + z + spatial(1 + x + z | p | id, coords = coords),
      mu2 = y2 ~ x + z + spatial(1 + x + z | p | id, coords = coords),
      sigma1 = ~ z + spatial(1 + x + z | p | id, coords = coords),
      sigma2 = ~ z + spatial(1 + x + z | p | id, coords = coords),
      rho12 = ~1
    ),
    animal = bf(
      mu1 = y1 ~ x + z + animal(1 + x + z | p | id, A = animal_A),
      mu2 = y2 ~ x + z + animal(1 + x + z | p | id, A = animal_A),
      sigma1 = ~ z + animal(1 + x + z | p | id, A = animal_A),
      sigma2 = ~ z + animal(1 + x + z | p | id, A = animal_A),
      rho12 = ~1
    ),
    relmat = bf(
      mu1 = y1 ~ x + z + relmat(1 + x + z | p | id, K = relmat_K),
      mu2 = y2 ~ x + z + relmat(1 + x + z | p | id, K = relmat_K),
      sigma1 = ~ z + relmat(1 + x + z | p | id, K = relmat_K),
      sigma2 = ~ z + relmat(1 + x + z | p | id, K = relmat_K),
      rho12 = ~1
    )
  )
  suppressWarnings(drmTMB(
    form, family = biv_gaussian(), data = sim$data, control = control
  ))
}
