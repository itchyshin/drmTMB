# q4 Location One-Slope Bootstrap Budget Probe

## Purpose

This slice checks whether the q4 location one-slope direct-SD bootstrap route is
cheap enough to move from deterministic Wald/profile smoke evidence into an
all-target bootstrap denominator runner.

## What Changed

- Added `tools/run-structured-re-q4-location-slope-bootstrap-budget-probe.R`.
- Added
  `docs/dev-log/dashboard/structured-re-q4-location-slope-bootstrap-budget-probe.tsv`.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-bootstrap-budget-probe/structured-re-q4-location-slope-bootstrap-budget-probe-results.tsv`.
- Wired the new sidecar into `tools/validate-mission-control.py` and
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Updated the q-series completion map, dashboard README, and check log.

## Result

The representative `phylo()` `mu1:(Intercept)` direct-SD target returned a
finite two-refit bootstrap interval. Fixed-covariance `spatial()`, A-matrix
`animal()`, and K-matrix `relmat()` are explicit
`not_run_after_phylo_budget_probe` rows because a full local provider pass is
too expensive for this dashboard smoke. A prior spatial precursor attempt
exceeded the local turn budget before writing a complete artifact, so it is
recorded as planning evidence rather than a usable denominator.

## Evidence

- `Rscript --vanilla tools/run-structured-re-q4-location-slope-bootstrap-budget-probe.R`
  completed and wrote the dashboard sidecar and method-level artifact.
- The phylo row retained bootstrap refit accounting in `method_message`.
- `python3 -m py_compile tools/validate-mission-control.py` passed as the
  syntax gate for the updated validator.
- `python3 tools/validate-mission-control.py` passed and reported 4 structured
  RE q4 location slope bootstrap-budget probe rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 3,254 assertions.

## Boundary

This is diagnostic bootstrap budget evidence only. It does not admit all-target
bootstrap denominators, derived-correlation intervals, interval reliability,
interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML,
non-Gaussian REML, broad bridge support, public optimizer controls, DRAC
execution, SR150 coverage readiness, partial location-scale support, Q
precision marshalling, K/Q same-target parity, public support, PR
undrafting/merging, or an Ayumi-facing reply.

## Next Gate

Run provider-rotating bootstrap probes, or an all-16 direct-SD bootstrap
denominator runner, on Totoro or through a reviewed DRAC/totoro dispatch plan.
The next artifact must retain every provider/target outcome, including
nonconvergence and nonfinite interval rows, before any coverage-grid design.
