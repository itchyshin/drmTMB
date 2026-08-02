# Arc 2 fixture builders: beta family x animal() relationship-matrix random
# effects.
#
# Unlike the other Arc 2 profile-feasibility cells (mc-0186, mc-0263,
# mc-0274, mc-0277), no existing tests/testthat/ file defines a *named*,
# reusable fixture-builder function for a beta() + animal() model -- the
# closest precedents (tests/testthat/test-nongaussian-structured-mu-slope.R's
# "beta x animal(1 + x | id, pedigree)" block and
# tests/testthat/test-nongaussian-structured-boundary.R's
# "beta_sigma_animal" block) build their data inline inside a single
# `test_that()`, not as a standalone function. Per the mc-0013/mc-0015
# registration task, these two builders are therefore single-sourced here in
# tools/ instead -- via the SAME `source_fixture_builder()` mechanism
# `tools/run-arc2-profile-feasibility.R` already uses to pull fixtures out of
# tests/testthat/ (it parses this file's top-level `<-` assignments, so no
# change to that generic sourcing logic is needed).
#
# Both DGPs reuse the 8-individual pedigree from
# tests/testthat/test-animal-relmat-gaussian.R's
# `new_animal_pedigree_gaussian_data()` (four founders, four descendants with
# partial parentage), which is the only pedigree shape already proven
# (elsewhere in the suite) to produce a well-conditioned, positive-definite
# additive relationship matrix `A` for `drmTMB:::drm_pedigree_additive_relationship()`.

# --- mc-0013: beta() x animal(1 + x | id) on mu -----------------------------
#
# `animal()` on a non-Gaussian `mu` only admits "intercept-only or one-slope"
# structured terms (see the boundary check in
# tests/testthat/test-nongaussian-structured-boundary.R and the "beta x
# animal(1 + x | id, pedigree)" recovery block in
# tests/testthat/test-nongaussian-structured-mu-slope.R) -- there is no
# slope-only `animal(0 + x | id, ...)` grammar. So to expose the
# `sd:mu:animal(0 + x | id)` target (the independent random-SLOPE SD), the DGP
# must fit the full intercept+slope block `animal(1 + x | id, pedigree =
# pedigree)` and simply target the slope component of it, leaving the
# intercept component (`sd:mu:animal(1 | id)`) unregistered/unprofiled.
#
# True SD values (0.50 intercept, 0.55 slope) are set well away from zero per
# the task's shape-parameter guidance; `n_each = 30` (240 observations across
# 8 individuals) was chosen empirically after a smoke fit at
# `n_each = 20`/`sd = 0.30/0.20` (test-nongaussian-structured-mu-slope.R's own
# values) recovered acceptably but this task asked for SDs comfortably off
# the null, which needs more replication per individual to keep the fit
# well-behaved (pdHess = TRUE) at the larger true SD.
beta_animal_mu_slope_fixture <- function(
  seed = 20260013L,
  n_each = 30L,
  beta0 = -0.2,
  beta_x = 0.45,
  sd_intercept = 0.50,
  sd_slope = 0.55,
  phi = 10
) {
  set.seed(seed)
  pedigree <- data.frame(
    id = paste0("id", seq_len(8L)),
    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  id_levels <- rownames(A)
  n_id <- length(id_levels)
  id <- rep(id_levels, each = n_each)
  x <- stats::rnorm(length(id))
  intercept_effect <- as.vector(t(chol(A)) %*% stats::rnorm(n_id, sd = sd_intercept))
  slope_effect <- as.vector(t(chol(A)) %*% stats::rnorm(n_id, sd = sd_slope))
  names(intercept_effect) <- id_levels
  names(slope_effect) <- id_levels
  eta <- beta0 + beta_x * x + intercept_effect[id] + slope_effect[id] * x
  mu <- stats::plogis(eta)
  # beta()'s implemented contract is logit(mu) = eta_mu, log(sigma) =
  # eta_sigma, phi = 1 / sigma^2 (R/family.R); phi here is the fixed true
  # dispersion (sigma ~ 1 in the fitted formula), not itself a target.
  y <- stats::rbeta(length(id), mu * phi, (1 - mu) * phi)
  y <- pmin(pmax(y, 1e-4), 1 - 1e-4) # keep strictly inside (0, 1)
  list(
    data = data.frame(y = y, x = x, id = id),
    pedigree = pedigree,
    A = A,
    beta0 = beta0,
    beta_x = beta_x,
    sd_intercept = sd_intercept,
    sd_slope = sd_slope,
    phi = phi
  )
}

# --- mc-0015: beta() x animal(1 | id) on sigma ------------------------------
#
# The scale (sigma) side has no observation-level `mu` signal from the animal
# effect -- the group-level draw only shifts each individual's dispersion --
# so it is only identifiable with substantial WITHIN-INDIVIDUAL REPLICATION:
# each individual needs enough observations for its own beta-distributed
# scatter to inform a per-individual sigma before the animal-effect variance
# component can be separated from residual (beta sampling) noise. The
# precedent in test-nongaussian-structured-boundary.R uses `n_each = 16`
# across 8 individuals purely as a convergence smoke check (no true-SD
# recovery claim); here `n_each = 50` (400 observations across 8 individuals)
# was chosen to keep the fit well-behaved (pdHess = TRUE, profile-feasible)
# at the larger true SD (0.55) this task asks for.
beta_animal_sigma_intercept_fixture <- function(
  seed = 20260015L,
  n_each = 50L,
  beta0 = 0.10,
  beta_x = 0.35,
  sigma0 = 0.30,
  sd_animal_sigma = 0.55
) {
  set.seed(seed)
  pedigree <- data.frame(
    id = paste0("id", seq_len(8L)),
    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  id_levels <- rownames(A)
  n_id <- length(id_levels)
  id <- rep(id_levels, each = n_each)
  x <- stats::rnorm(length(id))
  animal_effect <- as.vector(t(chol(A)) %*% stats::rnorm(n_id, sd = sd_animal_sigma))
  names(animal_effect) <- id_levels
  mu <- stats::plogis(beta0 + beta_x * x)
  sigma <- exp(log(sigma0) + animal_effect[id])
  phi <- 1 / (sigma^2)
  y <- stats::rbeta(length(id), mu * phi, (1 - mu) * phi)
  y <- pmin(pmax(y, 1e-4), 1 - 1e-4) # keep strictly inside (0, 1)
  list(
    data = data.frame(y = y, x = x, id = id),
    pedigree = pedigree,
    A = A,
    beta0 = beta0,
    beta_x = beta_x,
    sigma0 = sigma0,
    sd_animal_sigma = sd_animal_sigma
  )
}
