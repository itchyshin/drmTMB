# After Task: Poisson mu Random-Effect Standalone Recovery Lane

## Goal

Extend the Phase 18 recovery evidence (#59) to a non-Gaussian family by giving
the ordinary Poisson `mu` random-effect surface its own dispatchable recovery
artifact lane.

## Finding That Shaped The Slice

Before building, an audit of the non-Gaussian `mu` random-effect smoke summaries
(Poisson, NB2, truncated NB2) showed they **already compute the full recovery
contract**: aggregate bias/RMSE/MCSE, Wald intervals and coverage, and profile
intervals and coverage for the random-effect SD. This is unlike the bivariate
Gaussian smoke summaries (aggregate-only), which is why those needed new
recovery wrappers. So no new estimator was warranted here — building one would
have been duplicative. The only genuine gap was that Poisson `mu` random effects
had no standalone, artifact-producing dispatch lane; they only rode the combined
`first_wave_summary`.

## Implemented

- `inst/sim/run/sim_write_poisson_mu_re_recovery_grid.R`: a writer that runs the
  existing `phase18_summarise_poisson_mu_re_smoke()` at recovery-scale `n_rep`
  and emits isolated CSV artifacts (aggregate, replicates, manifest, failures,
  Wald intervals/coverage, profile intervals/coverage), matching the per-lane
  failure-ledger convention used by the bivariate Gaussian recovery lanes.
- Opt-in `poisson_mu_re_recovery` Actions task (choices, dispatcher, task paths,
  workflow matrix `include_in_all: false`), registry row
  `poisson_mu_random_effects_recovery` (`ready_grid`, `random_slopes`), the test,
  and README/NEWS notes.

## Checks Run

The model-fitting test relies on GitHub Actions `R-CMD-check` (local R has no
package dependencies here). The registry plan logic is pure base R and was
executed against the updated CSV to set every count empirically: registry 43,
`ready_grid` 26, random-slope plan 15, operating-characteristic 15 /
11-without-source-test, preflight rows 16, bundle random_slopes 15, task lists
setequal, new row dispatches cleanly. All R files parse; CSV well-formed.

## Status

This is the first standalone non-Gaussian recovery artifact lane. The NB2 and
truncated-NB2 `mu` random-effect surfaces have the same coverage machinery and
could get the same standalone-writer treatment if desired, but the higher-value
remaining work is the local-R queue captured in #491 (TMB capabilities,
comparator fits, release prep), which is where "all capabilities before the
power simulation" actually gets unlocked.
