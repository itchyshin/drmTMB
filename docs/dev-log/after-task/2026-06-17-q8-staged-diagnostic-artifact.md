# Q8 Staged Diagnostic Artifact

Date: 2026-06-17

## Goal

Make the private q8 cold-versus-staged diagnostic runner usable from the
Phase 18 evidence system without turning it into a public warm-start API or a
q8 recovery claim.

## What Changed

- Added
  `phase18_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid_outputs()`.
- The writer runs the q8 endpoint DGP, fits a q4 source route, builds the q8
  target specification, and calls the private staged-fit diagnostic runner.
- It writes split CSV artifacts for:
  - cold/staged fit metrics;
  - objective, log-likelihood, and elapsed-time deltas;
  - staged-start provenance;
  - scope and unsupported claims;
  - manifest and failures.
- Added the manual opt-in
  `biv_gaussian_q8_endpoint_staged_diagnostic` Phase 18 Actions task.
- Added the corresponding structured-workflow registry row and updated q8
  capability/status ledgers.
- Added CRAN-safe tests with injected fake source-fit and diagnostic functions
  so unit tests verify artifact plumbing without forcing a hard q8 optimizer
  comparison.

## Checks

```sh
air format inst/sim/run/sim_write_biv_gaussian_q8_endpoint_staged_diagnostic_grid.R inst/sim/run/sim_run_actions_cell.R inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-biv-gaussian-q8-staged-diagnostic.R tests/testthat/test-phase18-actions-runner.R tests/testthat/test-phase18-structured-workflow-registry.R
Rscript --vanilla -e 'devtools::test(filter = "phase18-biv-gaussian-q8-staged-diagnostic|phase18-actions-runner|phase18-structured-workflow-registry", reporter = "summary")'
Rscript --vanilla -e 'devtools::document()'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
Rscript --vanilla -e 'devtools::check(error_on = "never")'
git diff --check
conflict-marker scan outside check-log/after-task history
forbidden-framing scan over added diff lines
```

The focused test subset passed after formatting. `devtools::document()`
completed; unrelated generated Rd/RoxygenNote drift was reverted because this
slice does not change exported documentation. `pkgdown::check_pkgdown()` failed
on the pre-existing `drm_phylo_penalty` topic missing from `_pkgdown.yml`,
which belongs to the Claude penalty/Ayumi lane and was not changed here.
`devtools::check(error_on = "never")` passed in 10m 51.7s with 0 errors, 0
warnings, and 1 environment note: future-file timestamp checking could not
verify the current time. Static diff, conflict-marker, and added-line
forbidden-framing scans passed.

## Boundary

This is an opt-in diagnostic artifact only. It does not add a public `start`,
`start_from`, `warm_start`, prepared-spec, or `map` API. It does not change
likelihoods, `src/drmTMB.cpp`, TMB density code, Gaussian clamps, penalties,
MAP/GMRF terms, Julia bridge code, DRM.jl, Ayumi/Model A work, q8 recovery,
q8 coverage, q8 power, interval calibration, speed claims, or release
readiness.

The scope CSV explicitly records that numerical guards need their own
sensitivity simulations before inferential claims. That points to the existing
guard-sensitivity contract in
`docs/design/176-numerical-guard-simulation-audit.md`; it does not try to
settle guard impacts inside this q8 start-diagnostic slice.
