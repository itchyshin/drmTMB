# Arc 2 (group g12) -- signal-bearing Gaussian matched-q2 fixtures for
# spatial(), animal(), relmat() on BOTH mu and sigma simultaneously.
#
# WHY THIS FILE EXISTS
# ---------------------
# mc-0291/mc-0303/mc-0315 (targets `sd:mu:spatial(1 | p | site)`,
# `sd:mu:animal(1 | p | id)`, `sd:mu:relmat(1 | p | id)`; family gaussian,
# estimator ML) are parked at `point_fit_recovery`. cells.tsv's
# legacy_evidence_source for all three points to
# "qseries_{spatial,animal,relmat}_q1_mu_sigma_intercept", which resolves to
# docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-sigma-
# intercept-n5-local/structured-re-gaussian-lowq-mu-sigma-intercept-local-
# smoke.tsv -- an artifact whose own claim_boundary column states verbatim
# it "promotes exactly no Q-Series row" and is "not coverage evidence". That
# artifact cannot justify a park; the underlying fixture
# (tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R,
# n_group=10/n_each=10/n_rep=5, spiral spatial layout, generic
# `make_dense_covariance()` for animal/relmat) has also already been shown
# defective by a LATER, unrelated campaign: the spiral layout was
# independently found "too smooth to separate the structured intercept and
# slope SDs" and replaced by a regular 9x9 grid in
# tools/arc3-nbinom2-sigma-provider-fixtures.R (see that file's DESIGN
# ITERATION NOTES). This file supplies a real, adequately-scaled DGP.
#
# R/drmTMB.R:2300-2309 forbids the matched-mean-scale shape
# (`provider(1 | p | group)` in BOTH mu and sigma) under REML=TRUE for
# spatial/animal/relmat (only `phylo()` is admitted there); the fixtures and
# runner cell here are therefore ML (REML=FALSE) throughout, unlike
# mc-0282/mc-0283's REML phylo siblings.
#
# DESIGN: reuses the exact provider-structure builders already validated in
# tools/arc3-nbinom2-sigma-provider-fixtures.R (regular 9x9 spatial grid via
# `drmTMB:::drm_spatial_coords_precision()`; n_founders=8 (80-individual)
# synthetic pedigree via `drmTMB:::drm_pedigree_additive_relationship()`;
# n_id=80 AR1-Toeplitz relatedness K) -- starting at the scale that work
# already found necessary rather than re-discovering it -- but swaps the NB2
# sigma-only-intercept DGP for a Gaussian DGP with INDEPENDENT genuine
# signal on BOTH mu (identity link, true SD 0.6) and log(sigma) (log link,
# true log-SD 0.7), matching mc-0282/mc-0283's phylo q2 fixture
# (tools/arc2-phylo-sigma-fixtures.R) for direct comparability. The two
# draws share the SAME provider correlation structure but are drawn from
# independent `rnorm()` calls, so (as with mc-0282/mc-0283) any promotion
# here supports a marginal-SD claim only, never a mu/sigma cross-block
# correlation claim.
#
# The fitted formula shape --
#   mu ~ x + provider(1 | p | group, ...); sigma ~ provider(1 | p | group, ...)
# -- is copied verbatim from the `matched_mean_scale` list element in
# tests/testthat/test-reml-structured-location.R (used there only to prove
# REML rejects it for these three providers); it is reused here unmodified
# as the ML-fit skeleton.
#
# Each builder reports base::kappa() of the underlying provider covariance
# matrix so seed-level receipts can carry the conditioning diagnostic this
# campaign requires.

#' Gaussian ML fixture: spatial(1 | p | site) on BOTH mu and log(sigma)
#'
#' @param n_side Grid side length (`n_side^2` sites). Default 9 (81 sites),
#'   matching the well-conditioned grid validated in
#'   tools/arc3-nbinom2-sigma-provider-fixtures.R (the spiral layout it
#'   replaced was independently shown too smooth to separate structured
#'   intercept/slope SDs).
#' @param n_each Observations per site. Default 25.
#' @param seed RNG seed.
#' @param true_sd_mu True SD of the spatial effect on mu (identity link).
#' @param true_log_sd_sigma True SD of the spatial effect on log(sigma).
#' @param mu0,beta_x,log_sigma0 See `arc2_phylo_sigma_q2_fixture()`.
#' @return list(data, coords, true_sd_mu, true_log_sd_sigma, cov_condition_number)
arc2_spatial_mu_sigma_q2_fixture <- function(n_side = 9L,
                                             n_each = 25L,
                                             seed = 101L,
                                             true_sd_mu = 0.6,
                                             true_log_sd_sigma = 0.7,
                                             mu0 = 0.4,
                                             beta_x = 0.7,
                                             log_sigma0 = log(0.5)) {
  set.seed(seed)
  n_site <- n_side^2
  site_levels <- paste0("site_", seq_len(n_site))
  coords <- data.frame(
    x = rep(seq_len(n_side), each = n_side),
    y = rep(seq_len(n_side), times = n_side),
    row.names = site_levels
  )
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = site_levels, group = "site")
  cov <- solve(as.matrix(precision$precision))
  cov_condition_number <- base::kappa(cov, exact = TRUE)
  chol_cov <- chol(cov)
  u_mu <- as.vector(t(chol_cov) %*% stats::rnorm(n_site)) * true_sd_mu
  u_sigma <- as.vector(t(chol_cov) %*% stats::rnorm(n_site)) * true_log_sd_sigma
  names(u_mu) <- site_levels
  names(u_sigma) <- site_levels
  site <- rep(site_levels, each = n_each)
  n <- n_site * n_each
  x <- stats::rnorm(n)
  sigma_site <- exp(log_sigma0 + u_sigma[site])
  y <- mu0 + beta_x * x + u_mu[site] + stats::rnorm(n, 0, sigma_site)
  list(
    data = data.frame(y = y, x = x, site = factor(site, levels = site_levels)),
    coords = coords,
    true_sd_mu = true_sd_mu,
    true_log_sd_sigma = true_log_sd_sigma,
    cov_condition_number = cov_condition_number
  )
}

#' Gaussian ML fixture: animal(1 | p | id) on BOTH mu and log(sigma)
#'
#' @param seed RNG seed.
#' @param n_each Observations per individual. Default 25.
#' @param n_founders Number of founder pairs seeding the synthetic
#'   3-generation pedigree. Default 8 (80 individuals total) -- the scale
#'   tools/arc3-nbinom2-sigma-provider-fixtures.R's mc-0423 diagnosis found
#'   necessary after n_founders=4 (40 individuals) showed sampling fragility
#'   even for a single structured NB2 sigma-only target.
#' @param true_sd_mu True SD of the animal effect on mu (identity link).
#' @param true_log_sd_sigma True SD of the animal effect on log(sigma).
#' @param mu0,beta_x,log_sigma0 See `arc2_phylo_sigma_q2_fixture()`.
#' @return list(data, pedigree, A, true_sd_mu, true_log_sd_sigma, A_condition_number)
arc2_animal_mu_sigma_q2_fixture <- function(seed = 101L,
                                            n_each = 25L,
                                            n_founders = 8L,
                                            true_sd_mu = 0.6,
                                            true_log_sd_sigma = 0.7,
                                            mu0 = 0.4,
                                            beta_x = 0.7,
                                            log_sigma0 = log(0.5)) {
  # Nested (not top-level) helper -- tools/run-arc2-profile-feasibility.R's
  # `source_fixture_builder()` only `eval()`s the ONE top-level `<-`
  # assignment matching the requested `fn_name`; a separate top-level helper
  # would silently never be sourced (documented failure mode recorded in
  # tools/arc3-nbinom2-sigma-provider-fixtures.R's matching helper).
  .build_animal_pedigree <- function() {
    n_f0 <- n_founders
    founders_f <- paste0("f0_", seq_len(n_f0))
    founders_m <- paste0("m0_", seq_len(n_f0))
    ped <- data.frame(
      id = c(founders_f, founders_m), dam = NA_character_, sire = NA_character_,
      stringsAsFactors = FALSE
    )
    gen1 <- do.call(rbind, lapply(seq_len(n_f0), function(i) {
      data.frame(
        id = paste0("g1_", i, "_", 1:2),
        dam = founders_f[i], sire = founders_m[i],
        stringsAsFactors = FALSE
      )
    }))
    ped <- rbind(ped, gen1)
    gen1_f <- gen1$id[seq(1, nrow(gen1), by = 2)]
    gen1_m <- gen1$id[seq(2, nrow(gen1), by = 2)]
    gen2 <- do.call(rbind, lapply(seq_len(n_f0), function(i) {
      j <- (i %% n_f0) + 1L
      data.frame(
        id = paste0("g2_", i, "_", 1:4),
        dam = gen1_f[i], sire = gen1_m[j],
        stringsAsFactors = FALSE
      )
    }))
    ped <- rbind(ped, gen2)
    gen2_f <- gen2$id[seq(1, nrow(gen2), by = 4)]
    gen2_m <- gen2$id[seq(2, nrow(gen2), by = 4)]
    half_f0 <- n_f0 %/% 2L
    gen3 <- do.call(rbind, lapply(seq_len(half_f0), function(i) {
      j <- i + half_f0
      data.frame(
        id = paste0("g3_", i, "_", 1:4),
        dam = gen2_f[i], sire = gen2_m[j],
        stringsAsFactors = FALSE
      )
    }))
    rbind(ped, gen3)
  }
  set.seed(seed)
  pedigree <- .build_animal_pedigree()
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  A_condition_number <- base::kappa(A, exact = TRUE)
  id_levels <- rownames(A)
  n_id <- length(id_levels)
  chol_A <- chol(A)
  u_mu <- as.vector(t(chol_A) %*% stats::rnorm(n_id)) * true_sd_mu
  u_sigma <- as.vector(t(chol_A) %*% stats::rnorm(n_id)) * true_log_sd_sigma
  names(u_mu) <- id_levels
  names(u_sigma) <- id_levels
  id <- rep(id_levels, each = n_each)
  n <- length(id)
  x <- stats::rnorm(n)
  sigma_id <- exp(log_sigma0 + u_sigma[id])
  y <- mu0 + beta_x * x + u_mu[id] + stats::rnorm(n, 0, sigma_id)
  list(
    data = data.frame(y = y, x = x, id = factor(id, levels = id_levels)),
    pedigree = pedigree, A = A,
    true_sd_mu = true_sd_mu,
    true_log_sd_sigma = true_log_sd_sigma,
    A_condition_number = A_condition_number
  )
}

#' Gaussian ML fixture: relmat(1 | p | id) on BOTH mu and log(sigma)
#'
#' @param seed RNG seed.
#' @param n_id Number of individuals. Default 80 -- the scale
#'   tools/arc3-nbinom2-sigma-provider-fixtures.R found necessary to shrink
#'   finite-sample intercept/slope correlation (|cor| <= 0.135 at n_id=80
#'   vs up to 0.457 at n_id=40 for one NB2 sigma-only draw pair; re-checked
#'   directly below for this fixture's two independent Gaussian draw pairs).
#' @param n_each Observations per individual. Default 25.
#' @param true_sd_mu True SD of the relmat effect on mu (identity link).
#' @param true_log_sd_sigma True SD of the relmat effect on log(sigma).
#' @param mu0,beta_x,log_sigma0 See `arc2_phylo_sigma_q2_fixture()`.
#' @return list(data, K, Q, true_sd_mu, true_log_sd_sigma, K_condition_number, cor_v0_v1)
arc2_relmat_mu_sigma_q2_fixture <- function(seed = 101L,
                                            n_id = 80L,
                                            n_each = 25L,
                                            true_sd_mu = 0.6,
                                            true_log_sd_sigma = 0.7,
                                            mu0 = 0.4,
                                            beta_x = 0.7,
                                            log_sigma0 = log(0.5)) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  K_condition_number <- base::kappa(K, exact = TRUE)
  chol_K <- chol(K)
  u_mu <- as.vector(t(chol_K) %*% stats::rnorm(n_id)) * true_sd_mu
  u_sigma <- as.vector(t(chol_K) %*% stats::rnorm(n_id)) * true_log_sd_sigma
  names(u_mu) <- id_levels
  names(u_sigma) <- id_levels
  id <- rep(id_levels, each = n_each)
  n <- length(id)
  x <- stats::rnorm(n)
  sigma_id <- exp(log_sigma0 + u_sigma[id])
  y <- mu0 + beta_x * x + u_mu[id] + stats::rnorm(n, 0, sigma_id)
  list(
    data = data.frame(y = y, x = x, id = factor(id, levels = id_levels)),
    K = K, Q = Q,
    true_sd_mu = true_sd_mu,
    true_log_sd_sigma = true_log_sd_sigma,
    K_condition_number = K_condition_number,
    cor_v0_v1 = stats::cor(u_mu, u_sigma)
  )
}
