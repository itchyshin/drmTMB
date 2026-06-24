# After-Task Report: Q4 Location One-Slope Interval Smoke Status

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Purpose

Run the first bounded direct-SD interval smoke for the exact bivariate Gaussian
structured q4 location cells with one shared labelled slope in `mu1` and `mu2`.
This follows the q4 location fixture-parity and interval-plan sidecars without
promoting interval reliability or coverage.

## Implementation

- Added `tools/run-structured-re-q4-location-slope-interval-smoke.R`.
- Added
  `docs/dev-log/dashboard/structured-re-q4-location-slope-interval-diagnostic-status.tsv`
  with 16 direct-SD status rows.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-24-q4-location-slope-interval-smoke/structured-re-q4-location-slope-interval-smoke-results.tsv`
  with 48 method-level rows.
- Added a dashboard contract test for the status sidecar and artifact.
- Wired the status sidecar into `tools/validate-mission-control.py`.
- Updated the q-series completion map, dashboard README, and check-log.

## Evidence

The runner completed on the strong deterministic fixture for `phylo()`,
fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix `relmat()`.
All four fits converged with `pdHess=TRUE`. All 16 direct-SD targets had finite
Wald and profile intervals. Bootstrap is recorded as `not_run_smoke_budget`
because a complete bootstrap pass was too slow for this local dashboard smoke.

Focused checks for the slice:

```sh
Rscript --vanilla tools/run-structured-re-q4-location-slope-interval-smoke.R
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"
python3 -m py_compile tools/validate-mission-control.py
python3 tools/validate-mission-control.py
git diff --check
```

Results: `structured-re-conversion-contracts` passed with 3,176 assertions.
`python3 -m py_compile tools/validate-mission-control.py`,
`python3 tools/validate-mission-control.py`, and `git diff --check` passed.
Mission-control validation reported 16 structured RE q4 location slope
interval-diagnostic status rows.

## Claim Boundary

This slice is diagnostic interval-smoke evidence only. It records finite
Wald/profile intervals for direct SD targets and does not claim bootstrap
success, derived-correlation interval support, interval reliability, interval
coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML,
non-Gaussian REML, broad bridge support, public optimizer controls, public
support, partial location-scale support, broader q8 support, DRAC execution,
SR150 coverage readiness, PR undrafting/merging, or an Ayumi-facing reply.

The `relmat()` rows remain K-matrix q4 location targets. Q precision
marshalling remains separate, and this smoke does not claim K/Q same-target
parity for the partial q4 location cell.

## Next Gate

Run a bounded bootstrap denominator smoke before any coverage-grid design.
Derived-correlation interval reconstruction, calibrated denominators, partial
location-scale runtime support, and coverage acceptance remain separate gates.
