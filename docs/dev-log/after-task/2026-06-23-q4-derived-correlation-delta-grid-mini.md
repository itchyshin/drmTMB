# Q4 Derived-Correlation Delta Grid Mini

## 1. Goal

Scale the r51 one-replicate q4 derived-correlation delta smoke into a small
replicated mini-grid while keeping all seed-scale target rows in the denominator
and preserving the no-coverage boundary.

## 2. Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-mini.R`.
- The runner defaults to two seeds and scale levels 0.35 and 0.50, fitting four
  seed-scale cells and writing six q4 derived-correlation target rows for each
  cell.
- Added raw artifact
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-mini-results.tsv`.
- Added validator-owned dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-mini-status.tsv`.
- Updated the mission-control validator, focused dashboard contract test,
  dashboard table, dashboard README, status JSON, sweep JSON, version marker,
  executable-evidence ledger, and check-log.

## 3. Mathematical Contract

The mini-grid uses the same stabilized q4 Gaussian phylo fixture family as r51.
For each seed-scale cell, it fits `mu1`, `mu2`, `sigma1`, and `sigma2` phylo
effects, reconstructs the six derived correlations from the full TMB parameter
vector and `theta_phylo` positions, checks the `phylo_q4_corr` report against
`corpairs(level = "phylogenetic")`, and computes finite-difference Wald delta
endpoints from the `theta_phylo` covariance block.

The output keeps every seed-scale-target row in the denominator. In this mini
run all 24 rows have `fit_status = fit_ok`, `pdHess = TRUE`,
`interval_status = finite_delta_diagnostic`, and
`coverage_indicator = delta_diagnostic_covers_true`; five rows are boundary
clamped at the correlation limits. Coverage and failure-rate MCSE columns are
computed for the mini-grid but labelled
`computed_mini_grid_diagnostic_not_calibrated`.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-mini.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-mini-results.tsv`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-mini-status.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-mini.md`

## 5. Checks Run

- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-mini.R --n-rep=2 --sd-scales=0.35,0.50`
  passed and wrote `q4-derived-correlation-delta-grid-mini-results.tsv`.
- `air format docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-mini.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`,
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`, and
  `sh -n tools/start-mission-control.sh` passed.
- `python3 - <<'PY' ... compile(...) ... PY` passed for
  `tools/validate-mission-control.py` without writing `__pycache__`.
- `python3 tools/validate-mission-control.py` passed with eight q4
  derived-correlation delta-grid mini rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 908 assertions.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed; the live widget served `version.txt = r52`, nine sidecar lines, 25
  raw artifact lines, and parseable `status.json` plus `sweep.json`.
- Final `git diff --check` passed in both active worktrees:
  `/Users/z3437171/Dropbox/Github Local/drmTMB` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## 6. Tests Of The Tests

The validator and focused R test require the sidecar schema, eight sidecar
contract rows, 24 raw target rows, two seeds, two scale levels, four
seed-scale cells, the exact six q4 derived-correlation targets, finite
theta-covariance reconstruction, finite diagnostic endpoints, retained
denominator rows, five boundary-clamped rows, computed mini-grid MCSE fields,
and explicit no-coverage/no-REML/no-broad-bridge wording.

These tests would fail if the runner silently dropped a seed-scale cell, lost a
target, erased denominator rows, changed the report/corpairs reconstruction,
removed boundary-clamp accounting, or presented the mini-grid as calibrated
coverage evidence.

## 7. Consistency Audit

Scoped searches run:

- `rg -n "delta-grid mini|delta grid mini|q4-derived-correlation-delta-grid-mini|run-calibrated-grid-delta-mini|delta_grid_mini" docs/dev-log/dashboard docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-mini.R`
- `rg -n "q4 interval reliability|interval coverage|q4 REML|AI-REML|broad bridge support" docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-mini-status.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-mini-results.tsv docs/dev-log/dashboard/README.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The first search found the new runner, raw artifact, sidecar, widget, status
feeds, validator, focused test, check-log, and executable-evidence ledger. The
second search found boundary wording and validator/test assertions that reject
overclaims.

## 8. GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence under SR150, and Ayumi-facing text remains out of
scope until the exact issue text and final reply are approved.

## 9. What Did Not Go Smoothly

The first status-feed update used a combined member name, which the validator
correctly rejected as non-canonical. The feed now uses Curie as lead and keeps
the Fisher/Rose review context in the text.

## 10. Team Learning

Curie can now scale from smoke to mini-grid without changing the raw target
schema. Fisher and Rose should treat the five boundary-clamped rows as useful
edge evidence for the ADEMP-sized grid rather than as reliability evidence.

## 11. Known Limitations

This slice runs only four seed-scale cells. It computes diagnostic MCSE fields
but does not estimate calibrated coverage, does not set MCSE thresholds, and
does not promote q4 interval reliability, q4 REML, AI-REML, or broad bridge
support.

## 12. Next Actions

Scale r52 to an ADEMP-sized calibrated grid with failed-fit denominator rows,
boundary-clamp accounting, predeclared MCSE thresholds, and explicit stop/go
criteria before SR150 can move from blocked to banked.
