# Arc 5 -- signal-bearing Gaussian one-slope structured fixtures for the four
# `legacy_02` q1 cells: mc-0286 (mu spatial), mc-0289 (sigma spatial),
# mc-0298 (mu animal), mc-0310 (mu relmat).
#
# WHY THIS FILE EXISTS
# ---------------------
# cells.tsv's `route_variant="legacy_02"` (one-slope ML) shape for these four
# provider/dpar combinations has never been attempted under the current
# stats::profile()-based interval-feasibility framework: it is absent from
# both tools/run-arc2-profile-feasibility.R's cell registry and
# tools/arc2_profile_reconcile.py's CELL_CONTRACTS. Their `primary_evidence_id`
# is imported `legacy_model_evidence` from the MR-T0 migration (commit
# 095409c0), not a measurement taken under this framework. This file supplies
# the missing signal-bearing DGPs so the four cells can run the same
# five-seed point-fit gate + local interval smoke used elsewhere in the
# capability ledger.
#
# REUSE, NOT INVENTION
# ---------------------
# `arc5_gaussian_mu_one_slope_fixture()` (mc-0286 spatial, mc-0310 relmat,
# mc-0298 animal) is ONE shared builder parameterised by `provider`, honestly
# reusing the spatial/relmat correlation-structure constructors from
# tools/run-arc1a-gaussian-reml-provider-campaign.R's `spatial_K()` /
# `relmat_K()` (same circular-arc coordinate grid / AR(1)-Toeplitz relatedness,
# same TRUTH constants beta0=0.4, beta_x=0.25, sigma=0.5, tau0=0.5, tau_x=0.38,
# n_each=20) at M=16 -- one rung above the M=8 that arc1a's own REML profile
# campaign (docs/dev-log/simulation-artifacts/2026-07-13-arc1a-gaussian-reml-
# providers/profile-summary.tsv) showed reaches 1000/1000 finite profiles for
# the identical shape/provider under REML; ML is expected to be no harder to
# profile than REML at the same design. Sharing the builder is honest here
# because spatial and relmat truly share one DGP skeleton (draw an
# independent structured intercept + slope from a provider correlation
# matrix, then a plain linear mean); animal needs its own pedigree branch
# because arc1a's `animal_K()` is hard-capped at M = 8 (a fixed, non-
# parameterized 8-row pedigree literal) and the legacy SR150 campaign
# (docs/dev-log/dashboard/structured-re-gaussian-mu-slope-review-decision.tsv)
# showed a genuine, unexplained 0.88-coverage defect for animal at n_each=7 --
# so the animal branch scales the pedigree via `n_founders` (following
# tools/arc3-nbinom2-sigma-provider-fixtures.R's
# `.build_animal_pedigree_40()` 3-generation construction, generalised from
# its fixed n_founders=4) rather than reusing the frozen M=8 pedigree as-is.
#
# `arc5_gaussian_sigma_spatial_one_slope_fixture()` (mc-0289) is a SEPARATE
# builder (different formula shape entirely -- the structured term sits on
# `sigma`, not `mu`) modelled on tools/arc3-nbinom2-sigma-provider-
# fixtures.R's `arc3_nbinom2_sigma_spatial_fixture()` grammar (draw an
# independent structured intercept AND slope on log(sigma) from the same
# provider correlation matrix, profile only the intercept), but for the
# Gaussian family and using a well-conditioned REGULAR GRID (via
# `drmTMB:::drm_spatial_coords_precision()` on a grid, not the legacy
# circular arc) at a smaller grid than arc3's 9x9=81 sites, since Gaussian ML
# is typically easier to profile than NB2 dispersion-confounded sigma.
#
# CONDITION NUMBERS (base::kappa(exact = TRUE) on the provider correlation/
# relationship matrix used to draw the structured effects; all four DGPs are
# well-conditioned -- none approaches mc-0421 (phylo)'s original 98563)
#   mc-0286 spatial mu M=16 (circular arc, arc1a geometry):    kappa = 66.97
#   mc-0310 relmat mu M=16 (AR(1)-Toeplitz, arc1a geometry):   kappa = 3.43
#   mc-0298 animal mu (pedigree A, n_founders = 4 or 8):       kappa = 66.70
#     (identical at n_founders = 4 and 8 -- the synthetic pedigree's
#     relative topology is self-similar under founder doubling)
#   mc-0289 sigma spatial 5x5 grid (drm_spatial_coords_precision):
#     kappa = 60.46
#
# FIVE-SEED POINT-FIT GATE + INTERVAL SMOKE RESULTS (tools/arc5-gaussian-q1-
# one-slope-point-fit-gate.R; predeclared design, ONE design per cell, no
# retuning after seeing results)
#
#   mc-0286 (spatial mu, M=16, n_each=20): mean rel.err. 0.0947 (seeds
#     0.098/0.220/0.069/0.083/0.002) -- GATE PASS. Interval smoke 5/5 clean:
#     conf.status="profile", lower<estimate<upper, convergence 0, pdHess
#     TRUE, interval brackets truth on every seed. PROMOTED: registered in
#     tools/run-arc2-profile-feasibility.R (mc-0286) and
#     tools/arc2_profile_reconcile.py (CELL_CONTRACTS); the OFFICIAL runner
#     + reconciler (not just this ad hoc gate script) reconciled 5/5 PASS.
#
#   mc-0298 (animal mu, n_founders=8 [80 individuals], n_each=20): mean
#     rel.err. 0.0569 (seeds 0.057/0.061/0.049/0.097/0.021) -- GATE PASS.
#     n_founders was raised from arc1a's fixed M=8 pedigree specifically
#     because a 10-seed cor(v0,v1) scan showed max|cor| shrinks from 0.52
#     (n_founders=4, 40 individuals) to 0.35 (n_founders=8, 80 individuals),
#     the same finite-sample intercept/slope confounding mechanism
#     tools/arc3-nbinom2-sigma-provider-fixtures.R diagnosed for relmat.
#     Interval smoke 5/5 clean, brackets truth on every seed. PROMOTED:
#     registered in both files; official runner + reconciler 5/5 PASS.
#
#   mc-0310 (relmat mu, M=16, n_each=20): mean rel.err. 0.1933 (seeds
#     0.015/0.038/0.020/0.504/0.389) -- GATE PASS by the mean-only
#     criterion, BUT seeds 3104 and 3105 individually exceed the 0.35
#     per-seed threshold, and the interval smoke on those same two seeds
#     produces a profile interval that EXCLUDES the true value (0.50):
#     seed 3104 estimate 0.248, CI [0.164, 0.388]; seed 3105 estimate 0.695,
#     CI [0.502, 1.036]. Per the binding contract ("ANY single seed with
#     >0.35 error OR an interval excluding truth BLOCKS promotion even if
#     the mean passes"), mc-0310 is NOT promoted. This is well-evidenced,
#     genuine finite-sample recovery/sampling variance at M=16 groups under
#     ML -- NOT a conditioning artifact (relmat's K has kappa=3.43, the
#     best-conditioned of all four provider matrices here) and NOT
#     something the REML precedent (mc-0287/mc-0311, 1000/1000 finite
#     profiles) predicted, since ML's sampling variance at the same M is
#     evidently larger than REML's for this shape/provider. STOP, not
#     retuned (M=16 was the single predeclared design; a next step would be
#     M=32, not pursued in this arc so the STOP stays honestly reported
#     rather than forced to pass).
#
#   mc-0289 (sigma spatial, 5x5=25 sites, n_each=24): mean rel.err. 0.2017
#     (seeds 0.101/0.300/0.015/0.178/0.415) -- GATE PASS by the mean-only
#     criterion, BUT seed 2895 individually exceeds the 0.35 per-seed
#     threshold (0.415) AND its profile interval [0.157, 0.416] EXCLUDES the
#     true value 0.45. Per the same binding contract, mc-0289 is NOT
#     promoted. This matches the plan's own risk assessment: spatial-on-
#     sigma is a genuine, measured, provider-specific small-group
#     profile/recovery fragility (the legacy Wald-channel campaign already
#     showed spatial sigma finite-rate below the 0.95 gate at g=8 while
#     phylo/animal/relmat cleared it at the same design). 4/5 seeds are
#     clean; 1/5 is a real recovery failure, not a fixture-shape defect.
#     STOP, not retuned (5x5=25 sites was the single predeclared design; a
#     larger grid, e.g. 6x6 or 7x7, would be the natural next step, not
#     pursued in this arc).

#' Gaussian one-slope structured-mu fixture, shared across spatial/relmat/animal
#'
#' Draws an independent structured intercept AND slope on the mean (mu) from
#' one provider's correlation matrix, matching the `provider(1 + x | group)`
#' "one-slope" grammar these four cells target. Only the intercept SD is a
#' profile target (`sd:mu:<provider>(1 | <group>)`); the slope SD is a
#' nuisance parameter required by the formula shape.
#'
#' @param provider One of "spatial", "relmat", "animal".
#' @param M Group count for spatial/relmat (default 16; arc1a's own REML
#'   profile campaign cleared 1000/1000 finite profiles at M in {8,16,32} for
#'   this exact provider/shape). Ignored for `provider = "animal"`.
#' @param n_founders Founder-pair count for the animal pedigree (default 4;
#'   8 founders + 8 gen1 + 16 gen2 + 8 gen3 = 40 individuals). `n_founders =
#'   8` doubles every generation to 80 individuals, following
#'   tools/arc3-nbinom2-sigma-provider-fixtures.R's diagnosed animal fix.
#'   Ignored for `provider != "animal"`.
#' @param n_each Observations per group (default 20, matching arc1a).
#' @param seed RNG seed for the sampling draws (group effects, x, y).
#' @param beta0,beta_x,sigma Fixed mean intercept/slope and residual SD
#'   (defaults match arc1a's TRUTH: 0.4, 0.25, 0.5).
#' @param tau0,tau_x True SD of the structured intercept (profiled) and slope
#'   (nuisance) effects (defaults match arc1a's TRUTH: 0.5, 0.38).
#' @return list(data, object = list(labels, coords|K|A, condition_number),
#'   provider, true_sd_intercept, true_sd_slope)
arc5_gaussian_mu_one_slope_fixture <- function(provider = c("spatial", "relmat", "animal"),
                                                M = 16L,
                                                n_founders = 4L,
                                                n_each = 20L,
                                                seed,
                                                beta0 = 0.4,
                                                beta_x = 0.25,
                                                sigma = 0.5,
                                                tau0 = 0.5,
                                                tau_x = 0.38) {
  provider <- match.arg(provider)
  group_name <- if (identical(provider, "spatial")) "site" else "id"

  if (identical(provider, "spatial")) {
    labels <- paste0("site_", seq_len(M))
    theta <- seq(0, 1.5 * pi, length.out = M)
    coords <- data.frame(
      x = cos(theta) + seq_len(M) / (3 * M),
      y = sin(theta)
    )
    row.names(coords) <- labels
    precision <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
    K <- solve(as.matrix(precision$precision))
    object <- list(labels = labels, coords = coords, K = K)
  } else if (identical(provider, "relmat")) {
    labels <- paste0("id", seq_len(M))
    K <- outer(seq_len(M), seq_len(M), function(i, j) 0.35^abs(i - j))
    diag(K) <- diag(K) + 0.15
    dimnames(K) <- list(labels, labels)
    object <- list(labels = labels, K = K)
  } else {
    # `n_founders`-founder-pair, 3-generation synthetic pedigree, the same
    # construction as tools/arc3-nbinom2-sigma-provider-fixtures.R's
    # `.build_animal_pedigree_40()`, generalised over `n_founders`. Kept
    # inline (not a separate top-level helper) so this stays a SINGLE
    # top-level `<-` assignment -- tools/run-arc2-profile-feasibility.R's
    # `source_fixture_builder()` only evaluates the one top-level assignment
    # matching the requested fixture name.
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
    half_f0 <- max(1L, n_f0 %/% 2L)
    gen3 <- do.call(rbind, lapply(seq_len(half_f0), function(i) {
      j <- ((i - 1L + half_f0) %% n_f0) + 1L
      data.frame(
        id = paste0("g3_", i, "_", 1:4),
        dam = gen2_f[i], sire = gen2_m[j],
        stringsAsFactors = FALSE
      )
    }))
    pedigree <- rbind(ped, gen3)
    A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
    labels <- rownames(A)
    object <- list(labels = labels, pedigree = pedigree, A = A)
  }

  provider_matrix <- switch(provider, spatial = object$K, relmat = object$K, animal = object$A)
  condition_number <- base::kappa(provider_matrix, exact = TRUE)

  set.seed(seed)
  chol_mat <- chol(provider_matrix)
  z <- replicate(2L, as.vector(t(chol_mat) %*% stats::rnorm(nrow(provider_matrix))))
  effects <- sweep(z, 2L, c(tau0, tau_x), `*`)
  colnames(effects) <- c("intercept", "slope_x")
  row.names(effects) <- object$labels

  group <- rep(object$labels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(object$labels))
  mu <- beta0 + beta_x * x + effects[group, "intercept"] + effects[group, "slope_x"] * x
  dat <- data.frame(y = stats::rnorm(length(mu), mu, sigma), x = x)
  dat[[group_name]] <- group

  list(
    data = dat,
    object = c(object, list(condition_number = condition_number)),
    provider = provider,
    true_sd_intercept = tau0,
    true_sd_slope = tau_x
  )
}

#' Gaussian one-slope structured-sigma fixture (spatial provider only)
#'
#' Draws an independent structured intercept AND slope on log(sigma) from a
#' well-conditioned regular-grid spatial correlation matrix (never the
#' legacy circular arc, per tools/arc3-nbinom2-sigma-provider-fixtures.R's
#' regular-grid design-iteration note), fits a plain linear mean (no
#' structured mu term, so mu-side signal cannot confound the sigma target),
#' and targets only the intercept SD (`sd:sigma:spatial(1 | site)`).
#'
#' @param n_side Grid side length (`n_side^2` sites). Default 5 (25 sites).
#' @param n_each Observations per site. Default 24 (600 obs).
#' @param seed RNG seed.
#' @param beta0,beta_x Fixed mean intercept/slope (no structured mu term).
#' @param tau0,tau_x True SD of the structured intercept (profiled) and slope
#'   (nuisance) effects on log(sigma).
#' @param log_sigma0 Baseline log residual SD.
#' @return list(data, object = list(labels, coords, K, condition_number),
#'   provider = "spatial", true_sd_intercept, true_sd_slope)
arc5_gaussian_sigma_spatial_one_slope_fixture <- function(n_side = 5L,
                                                           n_each = 24L,
                                                           seed,
                                                           beta0 = 0.4,
                                                           beta_x = 0.25,
                                                           tau0 = 0.45,
                                                           tau_x = 0.30,
                                                           log_sigma0 = log(0.5)) {
  n_site <- n_side^2
  labels <- paste0("site_", seq_len(n_site))
  coords <- data.frame(
    x = rep(seq_len(n_side), each = n_side),
    y = rep(seq_len(n_side), times = n_side),
    row.names = labels
  )
  precision <- drmTMB:::drm_spatial_coords_precision(coords, site = labels, group = "site")
  K <- solve(as.matrix(precision$precision))
  condition_number <- base::kappa(K, exact = TRUE)

  set.seed(seed)
  chol_K <- chol(K)
  z <- replicate(2L, as.vector(t(chol_K) %*% stats::rnorm(n_site)))
  effects <- sweep(z, 2L, c(tau0, tau_x), `*`)
  colnames(effects) <- c("intercept", "slope_x")
  row.names(effects) <- labels

  site <- rep(labels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_site)
  mu <- beta0 + beta_x * x
  log_sigma <- log_sigma0 + effects[site, "intercept"] + effects[site, "slope_x"] * x
  dat <- data.frame(y = stats::rnorm(length(mu), mu, exp(log_sigma)), x = x, site = site)

  list(
    data = dat,
    object = list(labels = labels, coords = coords, K = K, condition_number = condition_number),
    provider = "spatial",
    true_sd_intercept = tau0,
    true_sd_slope = tau_x
  )
}
