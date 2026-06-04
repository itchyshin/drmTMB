# After Task: NB2 mu Recovery Lane; Truncated NB2 Already Covered

## Goal

Per request, give NB2 and truncated-NB2 `mu` random-effect surfaces standalone
recovery artifact lanes, parallel to the Poisson lane.

## Findings

- **NB2 `mu` RE**: only rode the combined `first_wave_summary`, so it had no
  standalone artifact lane — a genuine gap. Its smoke summary
  (`phase18_summarise_nbinom2_mu_re_smoke()`) already computes the full recovery
  contract (aggregate bias/RMSE/MCSE, Wald intervals and coverage, profile
  intervals and coverage for the random-effect SD), so no new estimator was
  needed.
- **Truncated NB2 `mu` random-intercept**: already has a standalone,
  coverage-emitting artifact lane — its existing
  `truncated_nbinom2_mu_random_intercept` Actions task and
  `sim_write_truncated_nbinom2_mu_random_intercept_grid.R` writer already emit
  aggregate, Wald intervals/coverage, and profile intervals/coverage CSVs. A
  separate `_recovery` writer would be pure duplication, so none was added; the
  surface is documented as already covered.

## Implemented (NB2)

- `inst/sim/run/sim_write_nbinom2_mu_re_recovery_grid.R`: runs the existing
  recovery-capable summary at recovery-scale `n_rep` and emits isolated CSV
  artifacts.
- Opt-in `nbinom2_mu_re_recovery` Actions task (choices, dispatcher, task paths,
  workflow matrix `include_in_all: false`), registry row
  `nbinom2_mu_random_effects_recovery` (`ready_grid`, `random_slopes`), the test,
  and README/NEWS notes.

## Checks Run

The model-fitting test relies on GitHub Actions `R-CMD-check`. The registry plan
logic is pure base R and was executed against the updated CSV (this branch is
stacked on the Poisson recovery lane): registry 44, `ready_grid` 27, random-slope
plan 16, operating-characteristic 16 / 12-without-source-test, preflight rows 17,
bundle random_slopes 16, task lists setequal, new row dispatches cleanly. All R
files parse; CSV well-formed.

## Recovery-Lane Track Status

Standalone non-Gaussian recovery artifact lanes now exist for Poisson and NB2
`mu` random effects; truncated NB2 already had one. Together with the four
bivariate Gaussian lanes, the cloud-feasible recovery infrastructure is
complete. The remaining capability/release work needs local R and is tracked in
the handoff issue #491.
