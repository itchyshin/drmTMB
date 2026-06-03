# After Task: Bivariate Q4 Location Smoke Artifact Lane

## Goal

Add the Phase 18 smoke/artifact lane for the matching q4 bivariate Gaussian
location block `(1 + x | p | id)` in both `mu1` and `mu2`, while keeping
recovery, coverage, power, q6 artifact routing, residual-scale slopes, random
`rho12`, and p8/q8 endpoint claims outside this task.

## Implemented

The new `biv_gaussian_q4_location` lane has a seeded DGP, fit summariser, smoke
runner, aggregate writer, manual Actions task, workflow registry row, and
focused tests. The smoke summary records fixed `mu1`/`mu2` coefficients,
residual `sigma1`/`sigma2`, four direct q4 location SDs, six derived q4
location correlations, residual `rho12`, convergence, Hessian status, warning
counts, runtime, manifest rows, and failure rows.

## Mathematical Contract

For each grouping level, the latent location vector is

```text
(b_mu1_intercept, b_mu1_x, b_mu2_intercept, b_mu2_x)
```

with four positive SDs and a 4 by 4 correlation matrix. The SDs are direct
`log_sd_re_cov` profile targets. The six q4 correlations are
`theta_re_cov`-based derived random-correlation rows, so they remain
point/status rows for this smoke lane rather than direct interval targets.
Residual `rho12` is fitted and summarised separately as the residual coscale
correlation.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/dgp/sim_dgp_biv_gaussian_q4_location.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_q4_location.R`
- `inst/sim/run/sim_run_biv_gaussian_q4_location_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_q4_location_smoke.R`
- `inst/sim/run/sim_write_biv_gaussian_q4_location_grid.R`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `tests/testthat/test-phase18-biv-gaussian-q4-location.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/63-implementation-map-slices-311-325.md`
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/148-phase6c-random-slope-simulation-plan.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-02-bivariate-q4-location-smoke-artifact-lane.md`

## Checks Run

```sh
air format R/drmTMB.R R/profile.R tests/testthat/test-biv-gaussian.R tests/testthat/test-phase18-biv-gaussian-q4-location.R tests/testthat/test-phase18-actions-runner.R tests/testthat/test-phase18-structured-workflow-registry.R inst/sim/dgp/sim_dgp_biv_gaussian_q4_location.R inst/sim/fit/sim_summarise_biv_gaussian_q4_location.R inst/sim/run/sim_run_biv_gaussian_q4_location_smoke.R inst/sim/run/sim_summary_biv_gaussian_q4_location_smoke.R inst/sim/run/sim_write_biv_gaussian_q4_location_grid.R inst/sim/run/sim_phase18_structured_workflow_registry.R inst/sim/run/sim_run_actions_cell.R
Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-q4-location')"
Rscript -e "devtools::test(filter = 'phase18-actions-runner|phase18-structured-workflow-registry')"
Rscript -e "devtools::test(filter = 'biv-gaussian')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::check()"
Rscript -e "pkgdown::build_site()"
rg -n 'q4 location.*no Phase 18 artifact lane|q4.*would need.*wrapper|nine rows with non-none Actions|five grid/admitted rows|include_source_test = FALSE.*five|q4 location.*source-tested but.*no artifact|intercept-plus-slope q4.*Planned|q4 location.*planned|artifact lane planned' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes inst/sim tests/testthat .github/workflows/phase18-simulation-grid.yaml
git diff --check
```

Results:

- Formatter completed without errors.
- The q4 smoke-lane test returned 45 passes, no failures, warnings, or skips.
- The Actions and structured-workflow registry tests returned 453 passes, no
  failures, warnings, or skips.
- The broader bivariate Gaussian regression run returned 911 passes, no
  failures, warnings, or skips.
- The final full package test run returned 9,316 passes, no failures, warnings,
  or skips.
- `pkgdown::check_pkgdown()` reported no problems.
- `devtools::check()` completed with 0 errors, 0 warnings, and 1 NOTE:
  "unable to verify current time".
- `pkgdown::build_site()` completed and wrote the rendered site to
  `pkgdown-site`; it emitted one local-library warning that `glmmTMB` was built
  with TMB 1.9.17 while the current TMB was 1.9.21.
- The stale scan returned only intentional historical or boundary hits: Slice
  1825 had nine Actions-routed random-slope rows before q4 routing, while q6
  artifact routing, residual-scale slope covariance, same-response
  location-scale slope covariance, and p8/q8 endpoint covariance remain
  planned.
- `git diff --check` passed.

Not run: `devtools::document()`, because no roxygen comments changed.

## Tests Of The Tests

The new tests check seeded DGP reproducibility, truth metadata, fit summary
shape, parameter classes, manifest and failure-table output, overwrite guards,
and malformed DGP input. The Phase 18 Actions tests check dry-run acceptance,
dependency sourcing, dispatch to the writer, and workflow YAML exposure. The
structured registry tests check the new row count, random-slope plan routing,
operating-characteristic plan counts, and q4 minimum-estimand wording.

## Consistency Audit

The registry now lists `bivariate_gaussian_q4_location` as `ready_grid` with
Actions task `biv_gaussian_q4_location`. The random-slope workflow has ten
admitted rows: six with grid/smoke artifact routes and four source-test rows.
The Phase 18 programme, implementation-map slices, and p8/q8 planning note now
say q4 location has smoke artifact routing. They still hold q6 location at
source-tested status and keep residual-scale, same-response location-scale,
random `rho12`, and p8/q8 endpoint support outside this task.

## GitHub Issue Maintenance

Live issue audit from this recovery pass showed #33 and #59 still open, and
draft PR #445 still on `codex/phase6c-twin-exchange`. No GitHub comment was
added because this smoke-lane work is local and the branch is ahead of origin.
Update #33 or the draft PR after the branch is pushed or the local changes are
committed.

## What Did Not Go Smoothly

The source-gate closeout correctly said q4 had no artifact lane yet, but the
next smoke-lane edits initially left two older design-map rows saying q4 was
still planned. The stale-wording scan caught those rows in
`docs/design/63-implementation-map-slices-311-325.md` and
`docs/design/67-sdstar-p8-poisson-q1.md`.

## Team Learning

When a source-tested covariance route receives an artifact lane, update both
the workflow registry counts and the older endpoint taxonomy notes in the same
pass. The current-state matrix can be correct while older design maps still
carry stale "planned" labels.

## Known Limitations

This task adds a smoke/artifact lane only. It does not estimate recovery,
coverage, power, Monte Carlo error, q6 artifact routing, residual-scale
bivariate slopes, same-response location-scale slope covariance, random effects
in `rho12`, p8/q8 endpoint covariance, derived intervals for q4 correlations,
predictor-dependent slope-correlation regression, or non-Gaussian bivariate
random-slope covariance.

## Next Actions

Run the manual `biv_gaussian_q4_location` Phase 18 Actions task after the local
branch is pushed, then audit the produced aggregate, replicate, manifest, and
failure CSVs before any recovery or coverage pilot is opened.
