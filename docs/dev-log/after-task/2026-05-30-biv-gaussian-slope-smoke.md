# After Task: Bivariate Gaussian Slope Smoke Helper

## Goal

Add the local smoke helper named by the random-slope wrapper target:
`phase18_run_bivariate_gaussian_mu_slope_smoke()`.

## Implemented

Added a Phase 18 bivariate Gaussian `mu1`/`mu2` slope-only smoke surface:

- `inst/sim/dgp/sim_dgp_biv_gaussian_mu_slope.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_mu_slope.R`
- `inst/sim/run/sim_run_biv_gaussian_mu_slope_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_mu_slope_smoke.R`

The fitted model is:

```r
bf(
  mu1 = y1 ~ x + (0 + x | p | id),
  mu2 = y2 ~ x + (0 + x | p | id),
  sigma1 = ~1,
  sigma2 = ~1,
  rho12 = ~1
)
```

The summariser records fixed `mu1`/`mu2` coefficients, response-scale
`sigma1`/`sigma2`, residual `rho12`, the two slope-only random-effect SDs, and
the slope-slope correlation `cor(mu1:x,mu2:x | p | id)`.

## Mathematical Contract

This slice does not change the likelihood, parser, formula grammar, or public
API. It adds a simulation helper for an already fitted and source-tested
bivariate Gaussian route. The wrapper target remains local-only and is not yet
an Actions-dispatchable grid.

## Files Changed

- `inst/sim/dgp/sim_dgp_biv_gaussian_mu_slope.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_mu_slope.R`
- `inst/sim/run/sim_run_biv_gaussian_mu_slope_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_mu_slope_smoke.R`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-biv-gaussian-mu-slope.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `inst/sim/README.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-biv-gaussian-slope-smoke.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_biv_gaussian_mu_slope.R inst/sim/fit/sim_summarise_biv_gaussian_mu_slope.R inst/sim/run/sim_run_biv_gaussian_mu_slope_smoke.R inst/sim/run/sim_summary_biv_gaussian_mu_slope_smoke.R tests/testthat/test-phase18-biv-gaussian-mu-slope.R inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R inst/sim/README.md docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-biv-gaussian-slope-smoke.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-biv-gaussian-mu-slope', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e "files <- c('inst/sim/dgp/sim_dgp_biv_gaussian_mu_slope.R','inst/sim/fit/sim_summarise_biv_gaussian_mu_slope.R','inst/sim/run/sim_run_biv_gaussian_mu_slope_smoke.R','inst/sim/run/sim_summary_biv_gaussian_mu_slope_smoke.R','tests/testthat/test-phase18-biv-gaussian-mu-slope.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
Rscript --vanilla -e 'e<-new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local=e); p<-e$phase18_random_slope_wrapper_target_plan(e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv")); print(p[, c("lane_id", "target_status", "required_helper", "dispatch_mode")], row.names=FALSE)'
rg -n "bivariate Gaussian slope smoke|phase18_run_biv_gaussian_mu_slope_smoke|phase18_run_bivariate_gaussian_mu_slope_smoke|smoke_helper_available|local_helper_not_actions|Slice 1823" inst/sim tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-biv-gaussian-slope-smoke.md
git diff --check
```

The focused bivariate smoke tests passed, the focused workflow-registry tests
passed, the parse check passed, the target-row print showed the local helper
available but not Actions-wired, and `git diff --check` passed.

## Tests Of The Tests

The new test file checks seeded DGP reproducibility, truth metadata,
replicate/aggregate/manifest/failure outputs from a one-replicate smoke run,
finite estimates and errors, fit convergence, and malformed-input rejection.

## Consistency Audit

The wrapper-target plan now reports `smoke_helper_available` and
`local_helper_not_actions`, matching the new helper while preserving the
boundary that no GitHub Actions task or formal grid exists yet.

## What Did Not Go Smoothly

The first test helper sourced files into its own local function frame, so the
tests could not see the Phase 18 helpers. The test source helper now sources
into the caller frame.

## Team Learning

Ada gets the first random-slope wrapper target converted from source-test
evidence into a local smoke helper. Curie gets a deterministic recovery smoke
surface. Grace still gets a clean stop before Actions wiring or grid
promotion.

## Known Limitations

This is a local smoke helper only. It does not add a grid writer, artifact
writer, manual Actions task, profile intervals, bootstrap intervals, or broad
coverage claim.

## Next Actions

1. Add `phase18_write_biv_gaussian_mu_slope_grid_outputs()`.
2. Wire a manual-only Actions task after the artifact writer exists.
3. Audit the first artifact output before converting the random-slope wrapper
   target to dispatchable.
