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
#   relmat:  80 individuals (AR1 relatedness) x 25 obs/id = 2000 obs
#     (raised from 40/1000 -- see the 2026-08-02 DESIGN ITERATION note below)
#
# animal converged at the same 40-individual/n_each = 25-40 scale that
# Arc 2's beta() sigma-side cells (mc-0015) already validated; phylo and
# spatial needed substantially more replication (see DESIGN ITERATION NOTES)
# because their group-level correlation structure is smooth/dense (a
# phylogenetic correlation matrix, or an exponential spatial covariance),
# which reduces the effective number of independent groups relative to
# their raw group count; relmat needed a larger group count for a
# different reason (finite-sample intercept/slope confounding, not
# structure smoothness -- see the 2026-08-02 DESIGN ITERATION note below).
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
# 2026-08-02 TOTORO 3-SEED CONTRACT FAILURE AND RE-GATE (mc-0421, mc-0424)
# -------------------------------------------------------------------------
# mc-0421 and mc-0424 both passed the point-fit gate above and mc-0422/
# mc-0423's own 3-seed Totoro interval-feasibility contract (seeds
# 2026080301/02/03), but mc-0421 and mc-0424 each failed 1/3 seeds on
# seed 2026080303: mc-0421 gave a boundary-limited profile (estimate 0.278,
# lower NA, upper 0.675, profile_boundary TRUE); mc-0424 gave
# conf_status = profile_interval_unavailable (estimate 0.517, lower NA,
# upper NA, "profile may not cross the likelihood-ratio threshold on both
# sides"). DIAGNOSIS (see docs/dev-log/interval-feasibility/ for the Curie
# session that ran it) found two DIFFERENT mechanisms, not one shared cause:
#
# - mc-0421 (phylo): `ape::rcoal()` coalescent trees at n_tip = 80 are
#   intrinsically ill-conditioned -- the frozen tree_seed = 909 topology's
#   correlation matrix A had condition number 98563 (min eigenvalue
#   0.00055, max off-diagonal 0.9995), a property of the coalescent
#   process itself (near-tip coalescent events pile up, producing
#   near-duplicate tip pairs), NOT a fixable property of that one
#   tree_seed draw: a scan of 61 alternative tree_seeds at n_tip = 80 found
#   condition numbers of 33000-540000 for ALL of them, and increasing
#   n_tip to 100/120/140/160 (holding the coalescent family fixed) did not
#   reduce the seed-to-seed variance of the realized structured-intercept
#   draw either (sd-of-realized-sd stayed 0.07-0.14 across n_tip). This
#   ill-conditioning inflates the SAMPLING variance of the fitted
#   intercept SD across seeds -- the three original Totoro seeds
#   (2026080301/02/03) gave point estimates 0.79/0.72/0.28 against a true
#   0.55 (mean relative error 0.41, ABOVE the 0.35 gate; only the
#   different point-fit-gate seeds 421/521/621 happened to average under
#   the threshold). Seed 03's specific draw put the realized species
#   effects in the flat, near-zero-SD region of an already-flat
#   likelihood surface (profile trace: delta-deviance stays ~0.07,
#   nowhere near the ~3.84 crossing threshold, as profile_value shrinks
#   from 0.55 down to 1e-93, before nlminb hits NA/NaN evaluation at the
#   numerical floor) -- a real, seed-dependent low-information failure
#   caused by the tree's structural near-singularity, not a data-size
#   problem answerable by more n_tip/n_each.
#
# - mc-0424 (relmat): the AR1-Toeplitz K (n_id = 40) is well-conditioned
#   (condition number 3.5) and seed 03's realized structured-intercept
#   draw (empirical SD 0.548) was close to the true 0.55 -- an information
#   problem is ruled out here. The actual defect: with only 40 individuals,
#   the FINITE-SAMPLE correlation between the independently-drawn
#   intercept and slope structured effects (v0, v1; population correlation
#   0 by construction) can be large by chance -- seed 03 realized
#   cor(v0, v1) = -0.457, versus 0.196/-0.470/... for other seeds (a
#   10-seed scan at n_id = 40 gave max|cor| = 0.457). The seed-03 profile
#   trace shows a clean lower-side LR crossing near profile_value ~= 0.37
#   (delta-deviance 5.7, above the 3.84 threshold) but an anomalous
#   DISCONTINUOUS drop in the objective at the last upper-side profile
#   point (profile_value = 0.768: objective drops by ~5.2 units, an
#   alternate local optimum found mid-sweep) -- `stats::profile()`'s
#   interpolation then fails with "need at least two non-NA values to
#   interpolate" because the upper side never cleanly brackets the
#   threshold. This is intercept/slope confounding amplified by small n,
#   not a conditioning defect in K itself. A 10-seed scan showed
#   max|cor(v0, v1)| shrinks from 0.457 (n_id = 40) to 0.356 (n_id = 60) to
#   0.135 (n_id = 80), consistent with the expected ~1/sqrt(n) shrinkage of
#   a finite-sample correlation between two independent draws.
#
# REDESIGN (both keep true_sd_intercept = 0.55 for comparability with the
# passing mc-0422/mc-0423 siblings; true_sd_slope unchanged in both cells):
# - mc-0421: replaced the `ape::rcoal()` coalescent tree with a random
#   topology (`ape::rtree(n_tip, br = NULL, rooted = TRUE)`, same
#   tree_seed = 909) plus `ape::compute.brlen(topology, method = "Grafen",
#   power = 0.5)` branch lengths. Grafen's method is a standard
#   deterministic (topology-shape-driven) ultrametric branch-length
#   assignment in `ape`; power = 0.5 spaces node heights more evenly than
#   the coalescent's tip-clustered event times, cutting the correlation
#   matrix's condition number from 98563 to 183 (min eigenvalue 0.11) while
#   keeping a genuine, non-identity, non-trivial random topology (mean
#   off-diagonal correlation 0.22, comparable to before). Confirmed
#   `ape::is.ultrametric()` TRUE (drmTMB's `phylo()` requires an
#   ultrametric tree for the correlation-scale prior).
# - mc-0424: increased n_id from 40 to 80 (n_each unchanged at 25, so
#   2000 obs instead of 1000) specifically to shrink the finite-sample
#   intercept/slope confounding diagnosed above, not as an undirected
#   information boost.
#
# DESIGNS TRIED AND REJECTED FOR mc-0421 (phylo):
# - Flooring only the terminal branch lengths of the existing rcoal tree at
#   5%/10% of tree depth (condition number 1083/542, both much better) --
#   REJECTED: breaks `ape::is.ultrametric()` (root-to-tip distances differ
#   by construction once only terminal edges are lengthened), which
#   `drm_phylo_augmented_precision()`'s `validate_phylo_tree()` rejects
#   outright for a correlation-scale phylo() term.
# - Scanning 61 alternative rcoal() tree_seeds at n_tip = 80 -- REJECTED:
#   best condition number found was still 32893 (tree_seed = 46), no
#   material improvement; the near-duplicate-tip pathology is intrinsic to
#   the coalescent process at this n_tip, not a per-seed accident.
# - Increasing n_tip to 100/120/140/160 holding the rcoal() family fixed --
#   REJECTED: condition number gets WORSE (up to 540883 at n_tip = 160) and
#   seed-to-seed variance of the realized structured effect did not shrink.
#
# RE-GATE RESULTS (5 seeds, 2026080301-05; ML; local only, current source;
# both cells at true_sd_intercept = 0.55):
#   mc-0421 phylo (Grafen tree):  rel. err. 0.019, 0.111, 0.314, 0.175,
#     0.064 -> mean 0.137  PASS. Local interval smoke (same 5 seeds, one
#     retained stats::profile() each): all 5 conf.status = "profile",
#     lower < estimate < upper, convergence 0, pdHess TRUE, profile.boundary
#     FALSE -- including seed 2026080303 (lower 0.228, upper 0.585), the
#     seed that failed on Totoro under the old rcoal() tree.
#   mc-0424 relmat (n_id = 80): rel. err. 0.325, 0.109, 0.280, 0.364, 0.177
#     -> mean 0.251  PASS. Local interval smoke (same 5 seeds): all 5
#     conf.status = "profile", lower < estimate < upper, convergence 0,
#     pdHess TRUE, profile.boundary FALSE -- including seed 2026080303
#     (lower 0.271, upper 0.553), the seed that failed on Totoro at
#     n_id = 40.
# Both cells are RE-GATED and ready for a Totoro re-run of the 3+ seed
# interval-feasibility contract; no forced pass, no cell dropped.
#
# 2026-08-02 mc-0423 (animal) SEED-2026080302 WITHHOLD: DIAGNOSED, RETAINED
# STOP (Curie session; NOT re-gated)
# -----------------------------------------------------------------------
# mc-0423 passed its own point-fit gate and mc-0423's Totoro 3-seed
# interval-feasibility contract (seeds 2026080301/02/03), but seed
# 2026080302 gave estimate 0.283 against true 0.55 (49% relative error)
# with a 95% profile interval [0.137, 0.479] EXCLUDING the true value.
# Fisher's withhold flagged that, unlike mc-0424, the finite-sample
# cor(v0, v1) diagnostic had never been run for the animal provider.
# Running it (10+ seeds, `arc3_nbinom2_sigma_animal_fixture()`'s A matrix at
# the default `n_founders = 4`): max|cor(v0, v1)| = 0.51 (seed 423), but
# seed 2026080302 itself is -0.14 -- NOT an outlier. The A matrix condition
# number is 66.7 (well-conditioned; nowhere near mc-0421 (phylo)'s
# 98563-level ill-conditioning). The relmat mechanism is therefore RULED
# OUT for this cell -- tested directly, not assumed.
# `n_founders` was added to `arc3_nbinom2_sigma_animal_fixture()` so the
# pedigree can be doubled (4 -> 8 founder pairs, 40 -> 80 individuals,
# n_each unchanged at 25) as a direct information-count fix on the axis
# that remained open (more independent pedigree units). Re-gating the
# shared 2026080301-05 seed family at `n_founders = 8`:
#   seed 2026080301: estimate 0.434, rel.err. 0.211, CI [0.300, 0.609] brackets 0.55
#   seed 2026080302: estimate 0.420, rel.err. 0.236, CI [0.264, 0.605] brackets 0.55
#   seed 2026080303: estimate 0.419, rel.err. 0.238, CI [0.297, 0.581] brackets 0.55
#   seed 2026080304: estimate 0.329, rel.err. 0.402, CI [0.207, 0.488] EXCLUDES 0.55
#   seed 2026080305: estimate 0.584, rel.err. 0.062, CI [0.426, 0.792] brackets 0.55
# The originally-failing seed (2026080302) is fixed, but a DIFFERENT seed
# (2026080304) now fails both the 0.35 relative-error gate and the
# bracketing check. 4/5, not 5/5. `n_founders = 8` is kept as this file's
# default for mc-0423 because it is a genuine, diagnosis-driven improvement
# (worst-case relative error over the family: 49% at n_founders = 4 -> 40%
# at n_founders = 8), but the cell is NOT promoted: it stays at
# `point_fit_recovery`. This is a well-diagnosed, non-forced STOP -- the
# animal-provider NB2 structured-sigma intercept SD shows real
# seed-to-seed sampling fragility at this scale that is not explained by
# the relmat cor(v0, v1) mechanism and is not eliminated by one round of
# n_id doubling. No Totoro campaign is recommended for mc-0423 without
# either a further diagnosed fix or an explicit decision to accept the STOP.
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
#' @param grafen_power Power parameter for `ape::compute.brlen(method =
#'   "Grafen")`. Default 0.5 -- see the 2026-08-02 DESIGN ITERATION note
#'   above: a plain `ape::rcoal()` coalescent tree at this n_tip is too
#'   ill-conditioned (near-duplicate tip pairs) for this cell's structured
#'   sigma target to be seed-stable, so the tree topology is still random
#'   (`ape::rtree()`) but its branch lengths come from Grafen's method
#'   instead of coalescent event times.
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
                                              grafen_power = 0.5,
                                              true_sd_intercept = 0.55,
                                              true_sd_slope = 0.20,
                                              log_sigma0 = log(0.40),
                                              beta0 = 1.0,
                                              beta_x = 0.30) {
  set.seed(tree_seed)
  topology <- ape::rtree(n_tip, br = NULL, rooted = TRUE)
  topology$tip.label <- paste0("sp_", seq_len(n_tip))
  tree <- ape::compute.brlen(topology, method = "Grafen", power = grafen_power)
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
#'   the 40-individual pedigree at the default `n_founders = 4`).
#' @param n_founders Number of founder pairs (f0/m0) seeding the synthetic
#'   3-generation pedigree. Default 4 (40 individuals total: 8 founders + 8
#'   gen1 + 16 gen2 + 8 gen3). `n_founders = 8` doubles every generation
#'   (16 founders + 16 gen1 + 32 gen2 + 16 gen3 = 80 individuals) -- see the
#'   2026-08-02 DESIGN ITERATION note below (mc-0423 seed-2026080302
#'   diagnosis): unlike mc-0424 (relmat), the failing seed's cor(v0, v1) was
#'   NOT an outlier, but n_founders = 8 still shrinks the family's max|cor|
#'   and, more importantly, its point-fit sampling variance, by giving the
#'   between-individual variance component more independent pedigree units
#'   to be estimated from.
#' @param true_sd_intercept,true_sd_slope See
#'   `arc3_nbinom2_sigma_phylo_fixture()`.
#' @param log_sigma0,beta0,beta_x See `arc3_nbinom2_sigma_phylo_fixture()`.
#' @return list(data, pedigree, A, true_sd_intercept, true_sd_slope, zero_cluster_rate)
arc3_nbinom2_sigma_animal_fixture <- function(seed = 423L,
                                               n_each = 25L,
                                               n_founders = 4L,
                                               true_sd_intercept = 0.55,
                                               true_sd_slope = 0.25,
                                               log_sigma0 = log(0.40),
                                               beta0 = 1.0,
                                               beta_x = 0.30) {
  # `n_founders`-founder-pair, 3-generation synthetic pedigree -- same
  # construction as tools/arc2-beta-animal-fixtures.R's
  # `.build_animal_pedigree_40()` at the default `n_founders = 4`,
  # duplicated here (not shared) and NESTED inside this function body (not
  # top level) for the same reason documented there:
  # tools/run-arc2-profile-feasibility.R's `source_fixture_builder()` only
  # `eval()`s the ONE top-level `<-` assignment matching the requested
  # `fn_name`, so a separate top-level helper function is silently never
  # sourced -- confirmed live: an earlier top-level version of this helper
  # produced "could not find function .build_animal_pedigree_40" when the
  # runner requested `arc3_nbinom2_sigma_animal_fixture` alone.
  .build_animal_pedigree_40 <- function() {
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
    # Generalizes the original n_f0 = 4 case's `lapply(1:2, ...)` /
    # `j <- i + 2L`: half of the n_f0 gen2 founder-pairs continue to gen3,
    # each mated with the "other half"'s sire (n_f0 = 4 -> 1:2, j = i + 2;
    # n_f0 = 8 -> 1:4, j = i + 4).
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
#' @param n_id Number of individuals. Default 80 (raised from 40 -- see the
#'   2026-08-02 DESIGN ITERATION note above: at n_id = 40 the finite-sample
#'   correlation between the independently-drawn intercept and slope
#'   structured effects can reach |cor| = 0.457 by chance, which destabilizes
#'   the profile sweep; n_id = 80 shrinks that to |cor| <= 0.135 over a
#'   10-seed scan).
#' @param n_each Observations per individual. Default 25 (2000 obs at the
#'   default n_id = 80).
#' @param true_sd_intercept,true_sd_slope See
#'   `arc3_nbinom2_sigma_phylo_fixture()`.
#' @param log_sigma0,beta0,beta_x See `arc3_nbinom2_sigma_phylo_fixture()`.
#' @return list(data, K, Q, true_sd_intercept, true_sd_slope, zero_cluster_rate)
arc3_nbinom2_sigma_relmat_fixture <- function(seed = 424L,
                                               n_id = 80L,
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
