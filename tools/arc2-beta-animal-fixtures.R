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
# change to that generic sourcing logic is needed). That mechanism only
# `eval()`s the ONE top-level `<-` assignment matching the requested
# `fn_name` -- a separate top-level `build_animal_pedigree_40 <- function()`
# helper would silently never be sourced when the runner asks for
# `beta_animal_mu_slope_fixture` alone. So the pedigree builder below is
# nested INSIDE each fixture function (duplicated, not shared) rather than
# hoisted to top level.
#
# REBUILD (2026-08-02): the first version of this file reused the 8-individual
# pedigree from tests/testthat/test-animal-relmat-gaussian.R's
# `new_animal_pedigree_gaussian_data()` (four founders, four descendants).
# That pedigree is too thin to identify a variance component -- mc-0013's
# random-slope SD recovered at ~0.28 against a true 0.55 (a ~49% relative
# error) across the mandatory point-fit gate, and Rose's closeout explicitly
# ruled the design NOT promotable, citing Arc 1's own "n_id >= 30-48" bar for
# SD targets. The nested `.build_animal_pedigree_40()` below replaces it with
# a 40-individual, 3-generation synthetic pedigree built specifically for
# this file (no existing test fixture in the suite has an animal() pedigree
# this large). It is a genuine multi-generation relatedness structure, not an
# identity matrix dressed up as one: 8 unrelated founders (4 dam-line x
# 4 sire-line) produce 8 gen-1 offspring (2 per founder pair); gen-1
# individuals are cross-mated (each dam paired with a sire from a
# *different* founder pair, so gen-2 individuals are half- not full-sibs
# across families) to produce 16 gen-2 offspring (4 per pair); two
# non-adjacent gen-2 pairs produce a final 8 gen-3 offspring (4 per pair),
# for 8 + 8 + 16 + 8 = 40 individuals total. The resulting additive
# relationship matrix `A` is well-conditioned and positive definite (min
# eigenvalue ~0.114, max ~7.58) with off-diagonal relatedness spanning 0
# (unrelated founders) to 0.5 (full sibs) and a non-trivial mean of ~0.16 --
# real pedigree structure, never collapsing to `diag(40)`.

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
# True SD values (0.50 intercept, 0.55 slope) stay well away from zero per
# the task's shape-parameter guidance. `n_each = 20` (800 observations across
# the 40-individual pedigree) was chosen from a single-seed pilot fit (~3.7s,
# convergence 0, pdHess TRUE, slope estimate 0.52 against a true 0.55) before
# committing to the mandatory 5-seed point-fit gate; that gate's actual
# numbers are reported in this task's after-task record, not restated here.
beta_animal_mu_slope_fixture <- function(
  seed = 20260013L,
  n_each = 20L,
  beta0 = -0.2,
  beta_x = 0.45,
  sd_intercept = 0.50,
  sd_slope = 0.55,
  phi = 10
) {
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
# component can be separated from residual (beta sampling) noise. `n_each =
# 40` (1600 observations across the 40-individual pedigree) was chosen from a
# single-seed pilot fit (~4.8s, convergence 0, pdHess TRUE, SD estimate 0.53
# against a true 0.55) before the mandatory 5-seed point-fit gate.
beta_animal_sigma_intercept_fixture <- function(
  seed = 20260015L,
  n_each = 40L,
  beta0 = 0.10,
  beta_x = 0.35,
  sigma0 = 0.30,
  sd_animal_sigma = 0.55
) {
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
