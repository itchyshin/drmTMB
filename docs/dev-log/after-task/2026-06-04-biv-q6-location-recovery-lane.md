# After Task: Bivariate Gaussian q6 Location Recovery Lane

## Goal

Continue the Phase 18 evidence work (#59) by giving the bivariate Gaussian q6
`mu1`/`mu2` location covariance lane the same smoke-to-recovery promotion as the
q2 scale-intercept (PR #484) and q4 location (PR #488) lanes.

## Implemented

- Recovery summary and grid writer
  (`sim_summary_biv_gaussian_q6_location_recovery.R`,
  `sim_write_biv_gaussian_q6_location_recovery_grid.R`) that reuse the smoke
  DGP, fit summariser, and runner, run at recovery-scale `n_rep`, and add Wald
  intervals plus an interval-coverage table.
- Opt-in `biv_gaussian_q6_location_recovery` Actions task (choices, dispatcher,
  task paths, workflow matrix with `include_in_all: false`), registry row
  `bivariate_gaussian_q6_location_recovery` (`ready_grid`, `random_slopes`), the
  recovery test, and README/NEWS notes.

## Honest Interval Scoping

The q6 location lane has 30 estimands: 6 fixed `mu` coefficients (intercept plus
two slopes per response), 2 residual scales, 6 location random-effect SDs, 15
location-location correlations, and residual `rho12`. Wald intervals are
computed only for the fixed `mu` coefficients (which carry standard errors); the
six SDs and fifteen correlations have no Wald standard error, so they stay
`derived_interval_unavailable`. Bias and MCSE are still reported for those rows
as point estimates.

## Checks Run

Local R has no package dependencies in this environment, so the model-fitting
recovery test relies on GitHub Actions `R-CMD-check`. The registry plan logic is
pure base R and was executed directly with Rscript against the updated CSV to set
every count assertion empirically (registry 41, `ready_grid` 24, random-slope
plan 13, operating-characteristic 13 / 9-without-source-test, preflight rows 14,
bundle random_slopes 13, task lists setequal, new row dispatches cleanly). All
new/edited R files parse.

## Known Limitations

Recovery for the q6 location block; the continuous-integration test makes no
coverage claim. A formal coverage statement needs a deliberately sized run plus
an artifact audit. SD and location-correlation interval coverage need
profile/derived/bootstrap methods and are deferred. The same-response
location-scale block remains the next recovery candidate.
