# Arc 4 -- bound two-provider structured-mu fixture for mc-0417.
#
# WHY THIS FILE EXISTS
# ---------------------
# mc-0417 (docs/dev-log/dashboard/capability-ledger/cells.tsv, family nbinom2,
# estimator ML, structured mu) is a count-family AGGREGATE cell: its notes
# describe "exactly two intercept-only providers drawn from {phylo, spatial,
# animal, relmat} ... may co-occur as primary+secondary q1 fields", which has
# C(4,2) = 6 possible pairs and therefore no unique direct target. Boole's
# BIND decision (not split) pins mc-0417 to ONE pair -- spatial+relmat, the
# only pair with recovery evidence on record
# (docs/dev-log/after-task/2026-07-05-count-multiprovider-structured-mu.md,
# section 8, "crossed site x id ladder"; and its own row-105 admission test
# tests/testthat/test-count-multiprovider-structured-mu.R) -- rather than
# adding five more cells with zero evidence. Primary target:
# `sd:mu:spatial(1 | site)`. Companion (reported but not gated):
# `sd:mu:relmat(1 | id)`.
#
# THE WORKING FORMULA SHAPE
# ---------------------------
# tests/testthat/test-count-multiprovider-structured-mu.R:65-69 is the only
# place in the tree that builds a simultaneous two-provider structured NB2
# mean; the shape below is copied from there:
#
#   bf(
#     y ~ x + spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q),
#     sigma ~ 1
#   )
#
# Both `coords` (spatial()'s coordinate matrix/data.frame) and `Q` (relmat()'s
# precision matrix) must be BARE LOCAL SYMBOLS in the formula's evaluation
# environment -- the same requirement phylo()'s `tree` and phylo_interaction()
# 's `tree1`/`tree2` impose (R/parse-formula.R; tools/arc3-nbinom2-sigma-
# provider-fixtures.R; tools/arc3-phylo-interaction-fixtures.R). Field order
# is fixed by the canonical provider list (phylo, phylo_interaction, spatial,
# animal, relmat): spatial enters first (`log_sd_phylo` internally, surfaced
# as `spatial(1 | site)`), relmat enters second (`log_sd_phylo2`, surfaced as
# `relmat(1 | id)`) -- see the after-task report section 3a.
#
# FIXTURE DESIGN AND JUSTIFICATION
# -----------------------------------
# Crossed site x id x rep design (every (site, id) pair observed n_rep times)
# so the two structured fields are jointly identifiable, per the after-task
# report's mathematical contract (section 3b): `eta_mu = o + X beta + Z1 a1 +
# Z2 a2`, a1 a spatial coordinate GMRF, a2 an AR(1)-relatedness GMRF, each with
# its own SD on the log-SD internal scale.
#
# Both true SDs are GENUINE, non-zero, and inside the requested 0.4-0.8 band:
# `sd_spatial = 0.6`, `sd_relmat = 0.5` (distinct from the row-105 admission
# test's 0.45/0.40 so recovery here is not an artefact of a specific numeric
# coincidence). NB2 dispersion `sigma_nb2 = 0.35` is a nuisance parameter
# (neither target), matched to the after-task report's own recovery smoke.
#
# `spatial()`'s coordinates are a `1.75*pi`-arc layout (the same shape the
# row-105 admission test and mc-0421/0422's Grafen-tree precedent both use --
# see the exponential-decay kernel in `drm_spatial_coords_precision()`,
# R/drmTMB.R:13125). `relmat()`'s K is an AR(1)-style Toeplitz matrix
# (`0.35^|i-j|`, diagonal-inflated by 0.15), the same shape
# tests/testthat/test-count-multiprovider-structured-mu.R and
# tools/arc3-nbinom2-sigma-provider-fixtures.R's relmat builder both use.
#
# CONDITION NUMBERS (ill-conditioning was the root cause of two Arc 3 sigma-
# side failures -- mc-0421's coalescent phylo tree at kappa = 98563, and a
# separate finite-sample intercept/slope confound for mc-0424 -- so both
# matrices are checked here before any fit is trusted):
#   spatial coordinate covariance (n_site = 20, 1.75*pi arc): kappa = 66.2
#   relmat K (n_id = 24, AR(1) Toeplitz):                     kappa = 3.5
# Both are far below mc-0421's 98563-level pathology; this DGP has no
# structured intercept+slope pair on either provider (both are intercept-only
# per the row-105 grammar), so mc-0424's finite-sample cor(v0, v1) confound
# does not apply here either.
#
# DESIGN ITERATION NOTES (both tried, neither hidden)
# -------------------------------------------------------
# First design tried: n_site = 12, n_id = 15, n_rep = 8 (1440 obs; matches the
# 8x10x4=320-obs row-105 admission test's shape but scaled toward the after-
# task report's own n=960 recovery smoke). Point-fit gate (seeds 2026080501-
# 05, current source): PRIMARY (spatial) relative errors 0.069, 0.200, 0.119,
# 0.177, 0.609 -- seed 2026080505 FAILS (60.9% > 0.35). Diagnosed with a
# spatial-ONLY control fit (same data, relmat term dropped): identical 0.965
# estimate against true 0.6 -- the failure is a plain small-group-count
# recovery problem for the spatial provider alone, NOT a two-provider
# confound. Rejected: n_site = 12 gives the GMRF too few independent site
# levels for a stable SD estimate at this replication.
#
# Second design (FINAL, this file): n_site = 20, n_id = 24, n_rep = 5 (2400
# obs). Point-fit gate on the SAME 5 seeds: PRIMARY (spatial) relative errors
# 0.099, 0.197, 0.012, 0.270, 0.147 -- all 5 PASS (max 0.270 < 0.35). See
# POINT-FIT GATE RESULTS below for the full record including bracketing.
#
# Companion (relmat) note, NOT gating: at n_id = 24, seed 2026080503 gives
# sd_relmat_hat = 0.713 against true 0.5 (43% relative error). Diagnosed by
# regenerating the realized latent draw directly (same RNG stream, before the
# NB2 y/x calls): the REALIZED empirical SD of that one seed's 24-unit relmat
# draw is 0.714 -- the fit recovers the realized draw almost exactly (0.713
# vs 0.714). This is genuine finite-sample sampling variability in a 24-unit
# AR(1)-correlated draw, not an estimation defect: a check at n_id = 40 (same
# seed, same RNG position) still gives an elevated realized draw (0.627),
# consistent with slow ~1/sqrt(n) shrinkage of this kind of finite-sample
# noise (the same mechanism mc-0424's after-task record diagnosed for a
# structured intercept/slope pair, here arising from AR(1) draw variance
# alone since there is no slope term). The companion target is not part of
# the mc-0417 promotion contract (only `sd:mu:spatial(1 | site)` is), so this
# is reported, not chased.
#
# POINT-FIT GATE RESULTS (5 seeds, 2026080501-05, ML, current source; FINAL
# design n_site=20/n_id=24/n_rep=5; one retained stats::profile() per seed on
# the primary target, no separate profile()/confint() pair)
#   seed 2026080501: rel.err.spatial 0.099, brackets TRUE, conv 0, pdHess TRUE
#   seed 2026080502: rel.err.spatial 0.197, brackets TRUE, conv 0, pdHess TRUE
#   seed 2026080503: rel.err.spatial 0.012, brackets TRUE, conv 0, pdHess TRUE
#   seed 2026080504: rel.err.spatial 0.270, brackets TRUE, conv 0, pdHess TRUE
#   seed 2026080505: rel.err.spatial 0.147, brackets TRUE, conv 0, pdHess TRUE
# All 5: conf.status = "profile", profile.boundary FALSE, lower < estimate <
# upper. 5/5 PASS on both the relative-error and bracketing checks -- ready
# for tools/run-arc2-profile-feasibility.R --cell=mc-0417 registration and a
# Totoro multi-seed interval-feasibility campaign.

#' NB2 mu-side bound spatial+relmat fixture (mc-0417)
#'
#' @param n_site Number of spatial groups (coordinate GMRF levels).
#' @param n_id Number of relmat groups (AR(1) relatedness levels).
#' @param n_rep Observations per (site, id) crossed cell.
#' @param sd_spatial True SD of the spatial() random-intercept field on mu
#'   (log link) -- the PRIMARY profile target `sd:mu:spatial(1 | site)`.
#' @param sd_relmat True SD of the relmat() random-intercept field on mu
#'   (log link) -- the COMPANION target `sd:mu:relmat(1 | id)`.
#' @param sigma_nb2 NB2 dispersion (nuisance, not a profile target here).
#' @param seed RNG seed.
#' @return list(data, coords, Q, truth) -- `coords`/`Q` are returned bare so
#'   the caller can bind them as local symbols for `spatial()`/`relmat()`.
arc4_nbinom2_mu_spatial_relmat_fixture <- function(n_site = 20L, n_id = 24L,
                                                    n_rep = 5L, sd_spatial = 0.6,
                                                    sd_relmat = 0.5, sigma_nb2 = 0.35,
                                                    seed = 2026080501L) {
  set.seed(seed)
  sites <- paste0("s", seq_len(n_site))
  ids <- paste0("g", seq_len(n_id))

  # Spatial covariance from a coordinate GMRF precision over sites (kappa =
  # 66.2 at n_site = 20; see CONDITION NUMBERS above).
  theta <- seq(0, 1.75 * pi, length.out = n_site)
  coords <- data.frame(x = cos(theta), y = sin(theta))
  rownames(coords) <- sites
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = sites, group = "site"
  )
  spatial_cov <- solve(as.matrix(precision$precision))
  spatial_effect <- as.vector(
    t(chol(spatial_cov)) %*% stats::rnorm(n_site, sd = sd_spatial)
  )
  names(spatial_effect) <- sites

  # Relatedness covariance K over ids (AR(1)-style; kappa = 3.5 at n_id = 24);
  # relmat() takes Q = K^{-1}.
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  diag(K) <- diag(K) + 0.15
  dimnames(K) <- list(ids, ids)
  Q <- solve(K)
  relmat_effect <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_id, sd = sd_relmat)
  )
  names(relmat_effect) <- ids

  # Crossed design: every (site, id) pair, n_rep times -> fields separable.
  grid <- expand.grid(
    site = sites, id = ids, rep = seq_len(n_rep),
    stringsAsFactors = FALSE
  )
  x <- stats::rnorm(nrow(grid))
  eta <- 0.65 - 0.20 * x + spatial_effect[grid$site] + relmat_effect[grid$id]
  data <- data.frame(
    y = stats::rnbinom(nrow(grid), size = 1 / sigma_nb2^2, mu = exp(eta)),
    x = x, site = grid$site, id = grid$id
  )
  list(
    data = data, coords = coords, Q = Q,
    truth = c(
      sd_spatial = sd_spatial, sd_relmat = sd_relmat, sigma_nb2 = sigma_nb2
    )
  )
}
