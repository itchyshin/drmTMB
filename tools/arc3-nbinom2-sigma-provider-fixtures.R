# Arc 3 -- signal-bearing nbinom2 SCALE-side provider fixtures.
#
# WHY THIS FILE EXISTS
# ---------------------
# mc-0421/mc-0422/mc-0423/mc-0424 (targets `sd:sigma:phylo(1 | species)`,
# `sd:sigma:spatial(1 | site)`, `sd:sigma:animal(1 | id)`,
# `sd:sigma:relmat(1 | id)`; family nbinom2, estimator ML) are stuck at
# `point_fit_recovery` because no fixture exists: the existing
# tools/arc2-phylo-sigma-fixtures.R fixture is Gaussian and covers only
# phylo, and no test file defines standalone, reusable nbinom2 x
# spatial/animal/relmat sigma-side builders (the closest precedent, the
# `nb_sigma_fits` block in tests/testthat/test-nongaussian-structured-
# boundary.R, is a `control = drm_control(se = FALSE)` convergence smoke test
# with an identity `K_nb_sigma <- diag(8)` -- no genuine relatedness
# structure and no recovery check). The four builders below supply that
# missing signal-bearing DGP for all four providers.
#
# FISHER'S CONFOUNDING WARNING, AND THE NB2 STRUCTURED-SIGMA GATE
# -----------------------------------------------------------------
# In NB2, the dispersion parameter (`sigma`, internal `size = 1/sigma^2`) and
# a provider random-effect SD on log(sigma) are both second-moment count
# quantities -- a classic confounding risk. This file's mandatory point-fit
# gate (mean relative error <= 0.35 across >= 3 seeds) exists to catch that
# BEFORE any cell is registered for profiling; it caught two real DGP
# defects below (see DESIGN ITERATION NOTES).
#
# Separately, `validate_*_sigma_random_terms()` (R/drmTMB.R) gates count
# (nbinom2/poisson/etc.) structured `sigma` terms to unlabelled
# intercept-PLUS-one-slope only (`provider(1 + x | group, ...)`) --
# the OPPOSITE of beta()'s intercept-only scale gate that
# tools/arc2-beta-animal-fixtures.R's mc-0015 relies on. So every DGP here
# draws an independent structured INTERCEPT effect (the profiled target,
# `true_sd_intercept`) and a distinct structured SLOPE effect (nuisance,
# `true_sd_slope`) sharing the same provider correlation structure, fits
# `sigma ~ provider(1 + x | group, ...)`, and only the intercept component
# (`sd:sigma:provider(1 | group)`) is registered as a profile target --
# mirroring how tools/arc2-beta-animal-fixtures.R's mc-0013 targets only the
# slope component of an intercept+slope `animal()` block on mu.
#
# WITHIN-GROUP REPLICATION (standing drmTMB caveat)
# ---------------------------------------------------
# Scale-side variance components need within-group replication to be
# identified. NB2 count dispersion is noisier to estimate per group than
# Gaussian/beta scale, so this cohort uses MORE replication than Arc 1's
# 30-48-group / n_each ~= 12 rule of thumb for continuous scale targets:
#
#   phylo:   80 tips  x 30 obs/tip  = 2400 obs
#   spatial: 81 sites (9x9 grid) x 25 obs/site = 2025 obs
#   animal:  40 individuals (3-gen pedigree) x 25 obs/id = 1000 obs
#   relmat:  40 individuals (AR1 relatedness) x 25 obs/id = 1000 obs
#
# animal/relmat converged at the same 40-individual/n_each = 25-40 scale
# that Arc 2's beta() sigma-side cells (mc-0015) already validated; phylo and
# spatial needed substantially more (see DESIGN ITERATION NOTES) because
# their group-level correlation structure is smooth/dense (a coalescent tree
# correlation matrix, or an exponential spatial covariance), which reduces
# the effective number of independent groups relative to their raw group
# count.
#
# POINT-FIT GATE RESULTS (predeclared: mean relative error <= 0.35 across
# seeds 421/521/621 for mc-0421, 422/522/622 for mc-0422, 423/523/623 for
# mc-0423, 424/524/624 for mc-0424; ML, ONE seed each, no REML)
#   mc-0421 phylo:   0.418, 0.106, 0.298 -> mean 0.274  PASS
#   mc-0422 spatial: 0.335, 0.460, 0.093 -> mean 0.296  PASS
#   mc-0423 animal:  0.115, 0.212, 0.353 -> mean 0.227  PASS
#   mc-0424 relmat:  0.083, 0.194, 0.191 -> mean 0.156  PASS
# All twelve fits: convergence 0, pdHess TRUE, zero_cluster_rate 0.000 (no
# group had every observation land on a zero count for any of these DGPs).
#
# DESIGN ITERATION NOTES (do not shrink these without re-deriving)
# --------------------------------------------------------------
# - spatial: an early spiral coordinate layout (borrowed from
#   test-nongaussian-structured-boundary.R's `coords_poisson_slope`) has
#   off-diagonal spatial correlations of 0.23-0.91 -- too smooth to separate
#   the structured intercept and slope SDs. Across 3 seeds the intercept SD
#   collapsed to 0.0001-0.49 (mean relative error 0.44, boundary-adjacent).
#   A regular 9x9 grid (off-diagonal correlation 0.10-0.76) fixed this.
# - phylo: a fresh per-seed random `ape::rcoal()` topology is unstable --
#   one specific 45-tip tree drove the intercept SD to ~0.00008 (>99%
#   relative error, a hard boundary collapse) while other topologies
#   recovered fine. Freezing the tree topology at `tree_seed = 909` and
#   varying only the sampling draws by `seed` (mirroring how the pedigree/K
#   below are fixed structures) removed the hard collapses, but residual
#   sampling noise at n_tip = 60/n_each = 25 still put the mean relative
#   error over seeds 421/521/621 at 0.369, just above the 0.35 gate;
#   n_tip = 80/n_each = 30 brought it to 0.274.
#
# NB2 dispersion/mean scale: `log(mu) = eta_mu`, `log(sigma) = eta_sigma`,
# `size = 1 / sigma^2` (R/family.R's `nbinom2()`; `Var(y) = mu + sigma^2 *
# mu^2`). Mean structure is a plain intercept + one covariate
# (`mu = exp(1.0 + 0.30 * x)`) on all four DGPs, kept deliberately simple so
# sigma-side provider signal is not confounded with mu-side structure.

#' nbinom2 fixture: phylo(1 + x | species) on sigma, target the intercept SD
#'
#' @param n_tip Number of species tips. Default 80.
#' @param n_each Observations per tip. Default 30.
#' @param seed RNG seed for the sampling draws (group effects, x, y).
#' @param tree_seed RNG seed for the (frozen) tree topology. Default 909.
#' @param true_sd_intercept True SD of the structured intercept effect on
#'   log(sigma) -- the profiled target.
#' @param true_sd_slope True SD of the structured slope effect on
#'   log(sigma) -- required by the NB2 structured-sigma grammar
#'   (intercept-plus-one-slope only) but not itself profiled.
#' @param log_sigma0 Baseline log dispersion.
#' @param beta0,beta_x Mean-model (mu) intercept and slope, on the log link.
#' @return list(data, tree, true_sd_intercept, true_sd_slope, zero_cluster_rate)
arc3_nbinom2_sigma_phylo_fixture <- function(n_tip = 80L,
                                              n_each = 30L,
                                              seed = 421L,
                                              tree_seed = 909L,
                                              true_sd_intercept = 0.55,
                                              true_sd_slope = 0.20,
                                              log_sigma0 = log(0.40),
                                              beta0 = 1.0,
                                              beta_x = 0.30) {
  set.seed(tree_seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  chol_A <- chol(A)
  set.seed(seed)
  v0 <- as.vector(t(chol_A) %*% stats::rnorm(n_tip, sd = true_sd_intercept))
  v1 <- as.vector(t(chol_A) %*% stats::rnorm(n_tip, sd = true_sd_slope))
  tip <- rep(seq_len(n_tip), each = n_each)
  n <- n_tip * n_each
  x <- stats::rnorm(n)
  mu <- exp(beta0 + beta_x * x)
  sigma <- exp(log_sigma0 + v0[tip] + v1[tip] * x)
  size <- 1 / sigma^2
  y <- stats::rnbinom(n, mu = mu, size = size)
  dat <- data.frame(
    y = y, x = x,
    species = factor(tree$tip.label[tip], levels = tree$tip.label)
  )
  zero_rate <- mean(tapply(dat$y, dat$species, function(z) all(z == 0)))
  list(
    data = dat, tree = tree,
    true_sd_intercept = true_sd_intercept, true_sd_slope = true_sd_slope,
    zero_cluster_rate = zero_rate
  )
}

#' nbinom2 fixture: spatial(1 + x | site) on sigma, target the intercept SD
#'
#' @param n_side Grid side length (`n_side^2` sites). Default 9 (81 sites).
#' @param n_each Observations per site. Default 25.
#' @param seed RNG seed.
#' @param true_sd_intercept,true_sd_slope See
#'   `arc3_nbinom2_sigma_phylo_fixture()`.
#' @param log_sigma0,beta0,beta_x See `arc3_nbinom2_sigma_phylo_fixture()`.
#' @return list(data, coords, true_sd_intercept, true_sd_slope, zero_cluster_rate)
arc3_nbinom2_sigma_spatial_fixture <- function(n_side = 9L,
                                                n_each = 25L,
                                                seed = 422L,
                                                true_sd_intercept = 0.55,
                                                true_sd_slope = 0.20,
                                                log_sigma0 = log(0.40),
                                                beta0 = 1.0,
                                                beta_x = 0.30) {
  set.seed(seed)
  n_site <- n_side^2
  site_levels <- paste0("site_", seq_len(n_site))
  # A regular n_side x n_side grid (not the tighter spiral layout used by
  # tests/testthat/test-nongaussian-structured-boundary.R's smoke-only
  # fixtures) is required here -- see DESIGN ITERATION NOTES above.
  coords <- data.frame(
    x = rep(seq_len(n_side), each = n_side),
    y = rep(seq_len(n_side), times = n_side),
    row.names = site_levels
  )
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = site_levels, group = "site")
  cov <- solve(as.matrix(precision$precision))
  chol_cov <- chol(cov)
  v0 <- as.vector(t(chol_cov) %*% stats::rnorm(n_site, sd = true_sd_intercept))
  v1 <- as.vector(t(chol_cov) %*% stats::rnorm(n_site, sd = true_sd_slope))
  names(v0) <- site_levels
  names(v1) <- site_levels
  site <- rep(site_levels, each = n_each)
  n <- n_site * n_each
  x <- stats::rnorm(n)
  mu <- exp(beta0 + beta_x * x)
  sigma <- exp(log_sigma0 + v0[site] + v1[site] * x)
  size <- 1 / sigma^2
  y <- stats::rnbinom(n, mu = mu, size = size)
  dat <- data.frame(y = y, x = x, site = factor(site, levels = site_levels))
  zero_rate <- mean(tapply(dat$y, dat$site, function(z) all(z == 0)))
  list(
    data = dat, coords = coords,
    true_sd_intercept = true_sd_intercept, true_sd_slope = true_sd_slope,
    zero_cluster_rate = zero_rate
  )
}

#' nbinom2 fixture: animal(1 + x | id) on sigma, target the intercept SD
#'
#' @param seed RNG seed.
#' @param n_each Observations per individual. Default 25 (1000 obs across
#'   the 40-individual pedigree).
#' @param true_sd_intercept,true_sd_slope See
#'   `arc3_nbinom2_sigma_phylo_fixture()`.
#' @param log_sigma0,beta0,beta_x See `arc3_nbinom2_sigma_phylo_fixture()`.
#' @return list(data, pedigree, A, true_sd_intercept, true_sd_slope, zero_cluster_rate)
arc3_nbinom2_sigma_animal_fixture <- function(seed = 423L,
                                               n_each = 25L,
                                               true_sd_intercept = 0.55,
                                               true_sd_slope = 0.25,
                                               log_sigma0 = log(0.40),
                                               beta0 = 1.0,
                                               beta_x = 0.30) {
  # 40-individual, 3-generation synthetic pedigree -- same construction as
  # tools/arc2-beta-animal-fixtures.R's `.build_animal_pedigree_40()`,
  # duplicated here (not shared) and NESTED inside this function body (not
  # top level) for the same reason documented there:
  # tools/run-arc2-profile-feasibility.R's `source_fixture_builder()` only
  # `eval()`s the ONE top-level `<-` assignment matching the requested
  # `fn_name`, so a separate top-level helper function is silently never
  # sourced -- confirmed live: an earlier top-level version of this helper
  # produced "could not find function .build_animal_pedigree_40" when the
  # runner requested `arc3_nbinom2_sigma_animal_fixture` alone.
  .build_animal_pedigree_40 <- function() {
    n_f0 <- 4L
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
    gen3 <- do.call(rbind, lapply(1:2, function(i) {
      j <- i + 2L
      data.frame(
        id = paste0("g3_", i, "_", 1:4),
        dam = gen2_f[i], sire = gen2_m[j],
        stringsAsFactors = FALSE
      )
    }))
    rbind(ped, gen3)
  }
  set.seed(seed)
  pedigree <- .build_animal_pedigree_40()
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  id_levels <- rownames(A)
  n_id <- length(id_levels)
  chol_A <- chol(A)
  v0 <- as.vector(t(chol_A) %*% stats::rnorm(n_id, sd = true_sd_intercept))
  v1 <- as.vector(t(chol_A) %*% stats::rnorm(n_id, sd = true_sd_slope))
  names(v0) <- id_levels
  names(v1) <- id_levels
  id <- rep(id_levels, each = n_each)
  n <- length(id)
  x <- stats::rnorm(n)
  mu <- exp(beta0 + beta_x * x)
  sigma <- exp(log_sigma0 + v0[id] + v1[id] * x)
  size <- 1 / sigma^2
  y <- stats::rnbinom(n, mu = mu, size = size)
  dat <- data.frame(y = y, x = x, id = factor(id, levels = id_levels))
  zero_rate <- mean(tapply(dat$y, dat$id, function(z) all(z == 0)))
  list(
    data = dat, pedigree = pedigree, A = A,
    true_sd_intercept = true_sd_intercept, true_sd_slope = true_sd_slope,
    zero_cluster_rate = zero_rate
  )
}

#' nbinom2 fixture: relmat(1 + x | id) on sigma, target the intercept SD
#'
#' @param seed RNG seed.
#' @param n_id Number of individuals. Default 40.
#' @param n_each Observations per individual. Default 25 (1000 obs).
#' @param true_sd_intercept,true_sd_slope See
#'   `arc3_nbinom2_sigma_phylo_fixture()`.
#' @param log_sigma0,beta0,beta_x See `arc3_nbinom2_sigma_phylo_fixture()`.
#' @return list(data, K, Q, true_sd_intercept, true_sd_slope, zero_cluster_rate)
arc3_nbinom2_sigma_relmat_fixture <- function(seed = 424L,
                                               n_id = 40L,
                                               n_each = 25L,
                                               true_sd_intercept = 0.55,
                                               true_sd_slope = 0.25,
                                               log_sigma0 = log(0.40),
                                               beta0 = 1.0,
                                               beta_x = 0.30) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  # AR1-Toeplitz relatedness (same construction as
  # test-animal-relmat-gaussian.R's `new_known_relatedness_gaussian_data()`,
  # scaled from 8 to 40 individuals) -- a genuine, well-conditioned
  # correlation structure, never an identity matrix dressed up as one.
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  chol_K <- chol(K)
  v0 <- as.vector(t(chol_K) %*% stats::rnorm(n_id, sd = true_sd_intercept))
  v1 <- as.vector(t(chol_K) %*% stats::rnorm(n_id, sd = true_sd_slope))
  names(v0) <- id_levels
  names(v1) <- id_levels
  id <- rep(id_levels, each = n_each)
  n <- length(id)
  x <- stats::rnorm(n)
  mu <- exp(beta0 + beta_x * x)
  sigma <- exp(log_sigma0 + v0[id] + v1[id] * x)
  size <- 1 / sigma^2
  y <- stats::rnbinom(n, mu = mu, size = size)
  dat <- data.frame(y = y, x = x, id = factor(id, levels = id_levels))
  zero_rate <- mean(tapply(dat$y, dat$id, function(z) all(z == 0)))
  list(
    data = dat, K = K, Q = Q,
    true_sd_intercept = true_sd_intercept, true_sd_slope = true_sd_slope,
    zero_cluster_rate = zero_rate
  )
}
