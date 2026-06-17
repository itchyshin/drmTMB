# After Task: Bivariate Gaussian q4 Location Recovery Lane

## Goal

Continue the Phase 18 evidence work (#59) by promoting the bivariate Gaussian
q4 `mu1`/`mu2` location covariance lane from a single-replicate smoke check to a
multi-replicate recovery lane, reusing the recovery pattern established for the
q2 scale-intercept lane (PR #484).

## Implemented

- Recovery summary and grid writer
  (`sim_summary_biv_gaussian_q4_location_recovery.R`,
  `sim_write_biv_gaussian_q4_location_recovery_grid.R`) that reuse the smoke
  DGP, fit summariser, and runner, run at recovery-scale `n_rep`, and add Wald
  intervals plus an interval-coverage table.
- Opt-in `biv_gaussian_q4_location_recovery` Actions task: choices (runner and
  registry generator), dispatcher branch, `phase18_actions_task_paths`, and a
  workflow matrix entry with `include_in_all: false`.
- Registry row `bivariate_gaussian_q4_location_recovery` (`ready_grid`,
  `random_slopes`), the recovery test
  (`test-phase18-biv-gaussian-q4-location-recovery.R`), and README/NEWS notes.

## Honest Interval Scoping

The q4 location lane has 17 estimands: 4 fixed `mu` coefficients, 2 residual
scales, 4 location random-effect SDs, 6 location-location correlations, and
residual `rho12`. Wald intervals are computed only for endpoints that carry a
standard error in `summary(fit)$coefficients` (the fixed `mu1`/`mu2`
coefficients); the four SDs and six correlations have no Wald standard error, so
their interval endpoints stay `NA` and remain `derived_interval_unavailable`,
consistent with the q4 interval policy. Bias and MCSE are still reported for
those rows as point estimates.

## Checks Run

Local R has no package dependencies in this environment (network policy blocks
the R repositories), so the model-fitting recovery test relies on GitHub Actions
`R-CMD-check`. The registry plan logic is pure base R and was executed directly
with Rscript against the updated CSV to set every count assertion empirically
(registry 39, `ready_grid` 22, random-slope plan 12, operating-characteristic
12 / 8-without-source-test, preflight rows 13, bundle counts 12, task lists
setequal, new row dispatches cleanly with non-empty operating-characteristic
fields). All new/edited R files parse.

## Known Limitations

Recovery for the q4 location-intercept-plus-slope block; the continuous
-integration test makes no coverage claim. A formal coverage statement needs a
deliberately sized run plus an artifact audit. SD and location-correlation
interval coverage need profile/derived/bootstrap methods and are deferred.
q6 location and the same-response location-scale block remain candidates for the
same recovery treatment next.
