# Q4 Derived-Correlation Delta Grid Contract

## 1. Goal

Define the next validated gate for scaling the r49 finite-difference
derived-correlation diagnostic into a calibrated q4 grid, without changing the
existing r46 smoke artifact or promoting interval reliability.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-contract.tsv`.
- The sidecar records eight contract rows: grid entrypoint, seed/scale
  identity, `theta_phylo` report reconstruction, interval fields, six-target
  set, denominator policy, MCSE policy, and claim-boundary policy.
- Updated `tools/validate-mission-control.py` so the sidecar is schema-owned,
  evidence-linked, and checked for denominator, MCSE, failure-reason, and
  no-coverage boundary requirements.
- Updated `tests/testthat/test-structured-re-conversion-contracts.R` so the
  focused R contract test reads and checks the r50 rows.
- Updated the dashboard widget to build `r50`, render the new table, and load
  the new TSV.
- Updated dashboard README, status JSON, sweep JSON, and check-log.

## 3. Mathematical Contract

The r50 sidecar does not add new numerical estimates. It turns the r49
finite-difference mechanics into requirements for the future calibrated-grid
runner:

- each replicate must retain seed, scale, fit, Hessian, gradient, and warning
  context;
- each derived-correlation row must use the full TMB parameter vector, named
  `theta_phylo` positions, the reported `phylo_q4_corr` matrix, and the
  `theta_phylo` covariance block;
- each target must emit finite delta endpoints only when `delta_se` is finite
  and positive;
- unavailable intervals, fit failures, Hessian failures, nonfinite-theta rows,
  and warning rows remain in denominators;
- `coverage_mcse` and `failure_rate_mcse` are required before any coverage
  wording.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-contract.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-contract.md`

## 5. Checks Run

- `air format tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`,
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`, and
  `sh -n tools/start-mission-control.sh` passed.
- `python3 - <<'PY' ... compile(...) ... PY` passed for
  `tools/validate-mission-control.py` without writing `__pycache__`.
- `python3 tools/validate-mission-control.py` passed with eight q4
  derived-correlation delta-grid contract rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 799 assertions.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed; the dashboard was already listening on `http://127.0.0.1:8765/`.
- Live fetches passed: `version.txt = r50`,
  `structured-re-q4-derived-correlation-delta-grid-contract.tsv` served nine
  lines, and served `status.json` plus `sweep.json` parsed as JSON.
- `git diff --check` passed in both active worktrees:
  `/Users/z3437171/Dropbox/Github Local/drmTMB` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## 6. Tests Of The Tests

The validator requires exactly eight contract IDs and checks each row's
component, required output fields, denominator policy, MCSE policy, failure
policy, evidence URL, status, and boundary wording. The focused R test checks
the same table shape and requires the denominator row to retain
`coverage_indicator`. These tests would fail if a future edit drops failed-fit
denominators, omits MCSE fields, or turns the contract into a coverage claim.

## 7. Consistency Audit

Scoped searches run:

- `rg -n "delta-grid|delta grid|q4-derived-correlation-delta-grid|delta_grid|grid-extension contract" docs/dev-log/dashboard docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`
- `rg -n "q4 interval reliability|interval coverage|q4 REML|AI-REML|broad bridge support" docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-contract.tsv docs/dev-log/dashboard/README.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The first search finds the new sidecar, widget, validator, focused test,
status/sweep rows, and README text. The second search finds boundary wording
and validator/test assertions that reject overclaims.

## 8. GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on. This is local
mission-control contract work under SR150, and Ayumi-facing text remains out of
scope until the exact issue text and final reply are approved.

## 9. What Did Not Go Smoothly

The first validator draft redundantly required the literal word `denominator`
inside a policy value that was already exact-checked. The fix removed the
redundant substring check and kept the stricter exact policy assertion.

## 10. Team Learning

Curie should introduce grid-scale numerical changes through a contract sidecar
before changing executable grid artifacts. That gives Fisher and Rose a place
to lock denominator and MCSE requirements before finite endpoints appear in a
larger run.

## 11. Known Limitations

This slice does not implement the calibrated-grid delta runner, does not run a
replicated grid, and does not estimate coverage. SR150 remains blocked for q4
interval reliability and interval coverage.

## 12. Next Actions

Implement a separate calibrated-grid delta runner or mode that writes the
r50-required fields while leaving the existing r46 smoke artifact stable.
