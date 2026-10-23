# N5b full pilot receipt -- P2 inference-parity, run LOCALLY on the Mac

drmtmb_ref: a1a63613b41deb4308e2be1d011fe39415bdbe51
drmjl_ref: 77513aa0663209b96e53a649d232558515f687fa
decision (from the local pre-run receipt): RUN
wall_seconds: 69

Grid: 4 partial rows (`base_gaussian_location_scale`, `biv_gaussian_residual`,
`plain_binomial_nonphylo`, `gaussian_response_mask`) x {wald, profile} x 2
engines x **5 seeds**, plus `bootstrap` (`R = 20`) for the 3 rows whose
response is a single stored column (`plain_binomial_nonphylo` excluded,
drmTMB#1123 -- its `cbind(successes, failures)` response cannot be
reconstructed by `bootstrap_response_data()`). Each seed re-simulates a fresh
response from that row's own TMB fit via `simulate.drmTMB()`, refits both
engines on the new draw, then calls `confint()` per method per coefficient.
Command:

```sh
DRM_JL_PATH=<drmjl-objat clone @ 77513aa0> \
DRMTMB_P2_OUT=<tsv path> \
DRMTMB_WORKTREE=<wt-n5> \
JULIA_HOME=$(dirname $(readlink -f ~/.juliaup/bin/julia)) \
OPENBLAS_NUM_THREADS=1 DRMTMB_P2_CORES=4 DRMTMB_P2_SEEDS=5 \
Rscript tools/parity-p2-pilot.R --full-pilot
```

Ran in **69 seconds** on 4 `parallel::makeCluster(type = "PSOCK")` workers
(script deviation from the requested `mclapply`: `mclapply()` forks the
process, and on macOS starting a fresh JuliaCall/`libjulia` session inside a
fork is unsafe and segfaulted every worker on the first attempt -- "The
process has forked and you cannot use this CoreFoundation functionality
safely" -- so the script uses `parallel::makeCluster(..., type = "PSOCK")` +
`parLapply()` instead: independent freshly-spawned R processes, not forks,
matching what worked in the pre-run's own timing probes. Still the `parallel`
package, still <= 6 cores -- `DRMTMB_P2_CORES=4`, `OPENBLAS_NUM_THREADS=1`
propagated to every worker via `clusterEvalQ()`).

One script bug found and fixed before this run produced real numbers: the
first attempt returned an all-`NA` row for every one of `gaussian_response_
mask`'s 5 seeds, because `row_gaussian_response_mask_data()` (the row's
synthetic-data generator) was not in the `clusterExport()` list, so PSOCK
workers -- which start from an empty global environment -- could not find it.
Fixed by adding it to `clusterExport()`; the second run produced no error
rows.

## Convergence counts (2 coefficients x 5 seeds = 10 checks per row per engine)

| row | tmb converged | julia converged |
|---|---|---|
| base_gaussian_location_scale | 10 / 10 | 10 / 10 |
| biv_gaussian_residual | 10 / 10 | 10 / 10 |
| plain_binomial_nonphylo | 10 / 10 | 10 / 10 |
| gaussian_response_mask | 10 / 10 | 10 / 10 |

All 20 row x seed cells converged on both engines across all 5 seeds -- no
non-convergence anywhere in this pilot.

## Per row x method endpoint deltas (2 coefficients x 5 seeds x 2 endpoints = 20 comparable endpoints per cell, where Julia returns a value)

| row | method | julia CI available | n deltas | max abs delta | mean abs delta |
|---|---|---|---|---|---|
| base_gaussian_location_scale | wald | yes | 20 | 4.177e-06 | 1.301e-06 |
| base_gaussian_location_scale | profile | yes | 20 | 9.519e-06 | 4.365e-06 |
| base_gaussian_location_scale | bootstrap | yes | 20 | 1.040e-01 | 3.503e-02 |
| biv_gaussian_residual | wald | yes | 20 | 5.719e-08 | 1.885e-08 |
| biv_gaussian_residual | profile | **NO** (Julia target not profile/bootstrap-ready) | 0 | NA | NA |
| biv_gaussian_residual | bootstrap | **NO** (same reason) | 0 | NA | NA |
| plain_binomial_nonphylo | wald | yes | 20 | 6.773e-09 | 4.650e-09 |
| plain_binomial_nonphylo | profile | yes | 20 | 3.333e-06 | 2.124e-06 |
| plain_binomial_nonphylo | bootstrap | excluded (drmTMB#1123) | -- | -- | -- |
| gaussian_response_mask | wald | yes | 20 | 9.644e-06 | 1.673e-06 |
| gaussian_response_mask | profile | yes | 20 | 1.624e-05 | 5.695e-06 |
| gaussian_response_mask | bootstrap | yes | 20 | 1.847e-01 | 5.895e-02 |

Largest delta anywhere: **1.847e-01** (`gaussian_response_mask`, bootstrap).
Largest delta among `wald`/`profile` (deterministic-ish endpoint
computations on both engines): **1.624e-05** (`gaussian_response_mask`,
profile).

`biv_gaussian_residual`'s fixed-effect targets (`fixef:mu1:x`, `fixef:mu2:x`)
are **not profile/bootstrap-ready on the Julia engine** for every one of the
5 seeds -- `drm_julia_validate_inference_targets()` aborts before any Julia
round-trip (`drm_julia_wald_targets()` sets `fixef_profile_ready <- !is_biv
&& ...`, and this is a bivariate model) -- so only `wald` is cross-engine
comparable for this row; this is a pre-existing, documented bridge
limitation, not something this pilot changes or works around.

## Boundary-honesty notes

None of the 8 fixed-effect coefficients probed across the 4 rows
(`mu:(Intercept)`, `mu:x`, `mu1:x`, `mu2:x` per applicable row) is a
variance, correlation, or other boundary-prone shape parameter -- all are
ordinary location coefficients on the real line, so drmTMB's bootstrap
boundary detector (`bootstrap_at_boundary`, `R/profile.R`) had nothing to
flag, and the run log confirms zero `drmTMB_bootstrap_boundary_warning`
messages across all 60 bootstrap calls (3 bootstrap-eligible rows x 2
coefficients x 5 seeds). This pilot therefore carries no boundary-interval
evidence one way or the other; it says nothing about how bootstrap or
profile intervals behave near an sd/rho boundary, which is a separate
question from what this row set probes.

## What the bootstrap deltas are (and are not) evidence of

The `wald`/`profile` deltas (1e-06 to 1e-08 scale) track the tight parity
already measured elsewhere in this repo for these same fixtures (Workflow G,
A5, the local pre-run above). The `bootstrap` deltas are two orders of
magnitude larger (1e-01 to 1e-02 scale) because TMB's and Julia's percentile
bootstraps draw from **independent RNG streams** even when both are called
with the same nominal `seed` argument (they do not share a common random
number generator across the R/Julia boundary), and `R = 20` replicates alone
carries substantial percentile-interval sampling noise (~1/sqrt(20)) on
either engine on its own. The bootstrap deltas measured here are therefore
dominated by that independent-resampling noise floor, not by a
cross-engine bootstrap-algorithm disagreement -- distinguishing the two
would need matched RNG streams or many more seeds, which this pilot does not
attempt.

This is a PIPELINE proof only: it fits both engines on 5 independently
simulated draws per row and calls `confint()` on both; it makes no
interval-property claim, and touches no capability-ledger row or dashboard
TSV.
