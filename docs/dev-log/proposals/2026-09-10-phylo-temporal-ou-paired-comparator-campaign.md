# Proposed paired comparator campaign for the unqualified phylogenetic-OU intercept interval

## Aim

Determine whether the failed P1--P3 intercept-profile coverage in G13 is
specific to drmTMB's implementation or is reproduced by an independently
implemented, model-matched Gaussian mixed-model fit. This campaign is a
diagnosis of the existing failed interval claim. It neither replaces G13 nor
qualifies an interval method or permits a later temporal covariance structure.

## Frozen data-generating process

Use the first 3,000 rows of `phylo_temporal_ou_g11_manifest()`: P1, P2, and P3
with 1,000 attempts each. For each task, reproduce `run-phylo-temporal-ou-g12-task.R`'s
`simulate_fixture()` exactly: seed from the manifest, a newly generated
`ape::rcoal()` tree, explicit tip levels, original unequal schedules,
balanced between-species predictor, independently randomized within-species
predictor, phylogenetic stable SD, independent within-species OU deviation,
and Gaussian residual. The same generated data and tree feed both engines.

The truth is fixed at intercept/between/within = 0/0.5/0.5. This comparator
campaign profiles the intercept only; the existing G13 estimates all three
mean effects and remains the calibration result for drmTMB.

## Paired fits

For every generated data/tree pair, fit ML Gaussian models with independent
phylogenetic and temporal random effects:

```r
drmTMB::drmTMB(
  bf(y ~ between + within +
       phylo(1 | species, tree = tree) +
       temporal(1 | species, time = elapsed, structure = "ou"),
     sigma ~ 1),
  data = dat, family = gaussian(), REML = FALSE
)

glmmTMB::glmmTMB(
  y ~ between + within +
    propto(0 + species | dummy, A) +
    ou(time_factor + 0 | species),
  data = dat, family = gaussian(), REML = FALSE
)
```

Here `A = ape::vcv(tree, corr = TRUE)` with row/column names exactly matching
`species`, `dummy` has one level, and `time_factor = glmmTMB::numFactor(elapsed)`.
Both engines use one fixed-intercept 95% likelihood profile. The campaign
records selected estimate, lower/upper endpoint, availability, Hessian status,
error/warnings, elapsed time, engine/package/source fingerprints, and the
manifest row for every engine-task pair.

## Measured pre-run and estimate

At source `60165971414bf84d13b6b3ac232335a7ba0feddb`, five paired draws per
P1--P3 cell completed all 30 fits/profiles. Mean per-dataset paired times were
7.613 seconds (P1), 13.196 seconds (P2), and 8.853 seconds (P3), or 2.47 CPU
minutes for 15 pairs. The direct extrapolation for 3,000 pairs is 8.24
CPU-hours before scheduler/archive overhead. The pilot's complete evidence is
`simulation-artifacts/2026-09-10-phylo-temporal-ou-comparator-pilot-601659714-r5/`.

## Proposed execution envelope

Run on DRAC **Rorqual**, not a login node or Fir: 3,000 array tasks, one data
set per task, one CPU, 4 GiB, and a 30-minute wall-time limit. Cap simultaneous
tasks at 60, below the shared 250-core ceiling. Pin all R/TMB threads to one.
Store transient work in a fresh `/scratch` staging root; checksum-seal each
complete or failed task archive; mirror each immutable archive and sidecar to
a new Totoro campaign root. Check live Rorqual capacity immediately before
submission. A five-task smoke and checksum/mirror verification precede any
bounded array release.

## No-fit closure and interpretation

A source-pinned re-verifier must reject a missing archive, malformed sidecar,
mixed source/package fingerprints, incomplete 3,000-task denominator,
duplicate engine-task pair, or absent profile record. It reports, separately
by cell and engine: all-attempt availability and coverage, conditional
coverage, lower/upper tails, profile widths, runtime, paired cover-status
disagreements, and estimate/endpoint differences.

There is deliberately no new calibration threshold. The output adjudicates
attribution: close paired agreement with replicated undercoverage supports a
finite-sample/model-inference limitation; material disagreement requires a
new numerical diagnosis. Neither outcome qualifies the current interval
workflow without a later explicit decision.

## Required authorization

This is a new campaign, distinct from the completed G12 estimator campaign.
Implementation of the source-pinned worker and no-fit verifier may proceed
locally. Submission requires explicit authorization for the stated 3,000-task
Rorqual/60-core envelope after those tools and their smoke controls are
reviewable.
