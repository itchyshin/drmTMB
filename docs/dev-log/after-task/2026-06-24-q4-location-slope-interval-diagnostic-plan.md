# After-Task Report: Q4 Location One-Slope Interval Diagnostic Plan

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Purpose

Create the target-level interval diagnostic plan for the exact bivariate
Gaussian structured `mu1+mu2` intercept-plus-one-slope q4 location cells. The
plan follows the fixture-parity evidence for `phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K-matrix `relmat()` and names the
interval targets before any interval smoke, denominator, or coverage work.

## Implementation

- Added `tools/run-structured-re-q4-location-slope-interval-plan.R`.
- Added
  `docs/dev-log/dashboard/structured-re-q4-location-slope-interval-diagnostic-plan.tsv`
  with 40 planned rows: 16 direct-SD targets and 24 derived-correlation targets.
- Added a dashboard contract test that keeps the plan target-level and linked to
  the exact q4 location support cells.
- Wired the sidecar into `tools/validate-mission-control.py`.
- Updated the q-series completion map and dashboard README.

## Evidence

Focused checks passed:

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"
python3 -m py_compile tools/validate-mission-control.py
python3 tools/validate-mission-control.py
git diff --check
```

Results: 3,104 `structured-re-conversion-contracts` assertions passed.
Mission-control validation passed and reported 40 structured RE q4 location
slope interval-diagnostic plan rows.

## Claim Boundary

This slice is a plan-only interval target map. It does not run Wald, profile,
bootstrap, delta-method, or coverage diagnostics. It does not promote interval
reliability, interval coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
HSquared AI-REML, non-Gaussian REML, broad bridge support, public optimizer
controls, public support, partial location-scale support, broader q8 support,
DRAC execution, SR150 coverage readiness, PR undrafting/merging, or an
Ayumi-facing reply.

The `relmat()` rows remain K-matrix q4 location targets. Q precision
marshalling remains separate, and the plan does not claim K/Q same-target
parity for the partial q4 location cell.

## Next Gate

Run deterministic direct-SD interval smoke for the 16 planned direct targets.
Keep derived-correlation interval reconstruction, calibrated denominators,
partial location-scale runtime support, and coverage acceptance separate.
