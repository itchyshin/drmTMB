# After Task: Same-Response Mu/Sigma Slope Recovery Lane

## Goal

Move the fitted same-response bivariate Gaussian q2 `mu`/`sigma` slope
covariance slice from source-only evidence to a Phase 18 smoke/recovery artifact
lane, while keeping all-four p8/q8 endpoint covariance and power-grid claims
closed.

## Implemented

The implemented claim is narrow: `biv_gaussian()` already fits matching
same-response `(0 + x | p | id)` terms in `mu1`/`sigma1` or `mu2`/`sigma2`, and
Phase 18 now has local DGP, summariser, smoke, recovery, grid-writer, registry,
Actions-dispatch, and focused test coverage for the `mu1`/`sigma1` q2 route.

New simulation files:

- `inst/sim/dgp/sim_dgp_biv_gaussian_mu_sigma_slope.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_mu_sigma_slope.R`
- `inst/sim/run/sim_run_biv_gaussian_mu_sigma_slope_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_mu_sigma_slope_smoke.R`
- `inst/sim/run/sim_write_biv_gaussian_mu_sigma_slope_grid.R`
- `inst/sim/run/sim_summary_biv_gaussian_mu_sigma_slope_recovery.R`
- `inst/sim/run/sim_write_biv_gaussian_mu_sigma_slope_recovery_grid.R`

New tests:

- `tests/testthat/test-phase18-biv-gaussian-mu-sigma-slope.R`
- `tests/testthat/test-phase18-biv-gaussian-mu-sigma-slope-recovery.R`

The two new Actions tasks are `biv_gaussian_mu_sigma_slope` and
`biv_gaussian_mu_sigma_slope_recovery`.

## Mathematical Contract

The DGP uses one response-specific location-scale slope block:

```r
mu1 = y1 ~ x + (0 + x | p | id)
sigma1 = ~ x + (0 + x | p | id)
mu2 = y2 ~ x
sigma2 = ~ x
rho12 = ~ 1
```

The fitted group-level slope pair is
`cor(mu1:x,sigma1:x | p | id)`. This is a group-level random-effect correlation,
not residual `rho12`. The recovery tables report fixed `mu1`/`mu2` coefficients,
fixed log-`sigma1`/log-`sigma2` coefficients, the location-slope SD, the
scale-slope SD, the derived `mu_sigma` slope correlation, and residual `rho12`.
Wald intervals are reported only where the fitted summary carries a standard
error; the two SD rows and derived `mu_sigma` correlation stay
`derived_interval_unavailable`.

## Files Changed

The lane touched simulation harness files, Actions dispatch, registry rows,
focused tests, current status docs, README/NEWS/ROADMAP, vignettes, the check
log, and this after-task report. The previous source-level implementation files
remain part of the broader dirty worktree and were not reverted.

## Checks Run

- `air format ...` over the new simulation files, action/registry helpers, and
  focused tests completed without output.
- `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-mu-sigma-slope')"`
  returned 77 passes, no failures, warnings, or skips.
- `Rscript inst/sim/run/sim_run_actions_cell.R --task biv_gaussian_mu_sigma_slope --dry-run true --n-reps 1 --backend none --cores 1 --master-seed 20260629`
  printed the expected dry-run plan.
- `Rscript inst/sim/run/sim_run_actions_cell.R --task biv_gaussian_mu_sigma_slope_recovery --dry-run true --n-reps 1 --backend none --cores 1 --master-seed 20260630`
  printed the expected dry-run plan.
- A first action/registry focused test run failed only on stale registry counts
  after adding two `ready_grid` correlation-block rows; those expectations were
  updated.
- Final `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-mu-sigma-slope|phase18-actions-runner|phase18-structured-workflow-registry')"`
  returned 619 passes, no failures, warnings, or skips.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"` returned 1,389 passes,
  no failures, warnings, or skips.
- `Rscript -e "pkgdown::build_site()"` completed; the only warning was the known
  local `glmmTMB`/`TMB` version mismatch.
- `Rscript -e "pkgdown::check_pkgdown()"` returned "No problems found."
- Stale-current source and rendered-site scans found no old claim that
  same-response q2 `mu`/`sigma` slope covariance is source-only or planned.
- `git diff --check` passed.

Full `devtools::test()`, `devtools::check()`, and `devtools::document()` were
not run. No roxygen comments changed in this recovery-lane slice.

## Tests Of The Tests

The new tests check deterministic seeding, output schema, parameter ordering,
derived-correlation classification, manifest/failure tables, overwrite guards,
malformed DGP inputs, malformed cell inputs, recovery bias/MCSE columns, and
the intended lack of Wald interval endpoints for SD/correlation rows. The first
registry test run failed on row-count expectations, which confirmed that the
registry tests notice new admitted tasks rather than silently accepting drift.

## Consistency Audit

Current status docs now say the same-response q2 lane has smoke/recovery routing
and still needs larger-grid evidence before power use. They keep all-four p8/q8
endpoint covariance, random effects in `rho12`, cross-response/mismatched
coefficient slope pairs, and non-Gaussian correlated slopes closed.

Rendered-site checks confirmed that NEWS and ROADMAP expose the new lane, and
that stale same-response source-only wording is gone from the built pages.

## GitHub Issue Maintenance

I inspected open issue overlap for "same-response mu sigma slope",
"location-scale slope covariance", and "q8 endpoint". Matching open issues were
#491, #33, #59, and #5. I updated the active local-R work queue issue #491 with
the implementation and verification summary:

<https://github.com/itchyshin/drmTMB/issues/491#issuecomment-4637589854>

The issue remains open because a 500-replicate formal artifact audit and p8/q8
follow-up are still pending.

## What Did Not Go Smoothly

The estimand count was easy to miscount at first; the lane has 12 rows, not 11.
The registry tests also needed count updates after two `ready_grid` rows were
added. A first `gh issue comment` attempt failed because Markdown backticks were
interpreted by the shell; the successful comment used stdin so Markdown stayed
literal.

## Team Learning

For future Phase 18 lane additions, count the estimands before writing tests and
update the structured workflow registry tests in the same patch as the CSV row.
When posting Markdown issue comments from the shell, pass the body through stdin
or a file rather than inline double-quoted shell text.

## Known Limitations

This is local source and artifact-harness evidence, not a completed
500-replicate Actions audit. Same-response q2 power claims remain gated. The
lane currently exercises a response-1 `mu1`/`sigma1` DGP; the fitted likelihood
supports the symmetric response-2 `mu2`/`sigma2` route through the source-level
tests, but the artifact lane starts with one response-specific cell. All-four
p8/q8 endpoint covariance remains design-only.

## Next Actions

Run the new `biv_gaussian_mu_sigma_slope_recovery` task at formal replicate
count, audit convergence and Hessian diagnostics, then decide whether it is
strong enough to support the q8 endpoint design gate or only a diagnostic
neighbour row.
