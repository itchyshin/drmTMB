# Q4 Derived-Correlation Interval Smoke

## 1. Goal

Add an executable smoke path for q4 derived-correlation interval status so the
mission-control dashboard can distinguish mapped point targets from unavailable
derived-correlation intervals before any calibrated coverage grid is claimed.

## 2. Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-interval-smoke.R`.
- The runner permits only `--n-rep=1`, uses stabilized seed `202606902` at
  scale `0.50`, fits the q4 Gaussian phylo smoke fixture, and writes the six
  `corpairs(conf.int = TRUE)` derived-correlation rows.
- Added raw artifact
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-interval-smoke-results.tsv`.
- Added validator-owned dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-interval-smoke.tsv`.
- The sidecar records profile-target mapping, reconstructed point estimates,
  unavailable interval endpoints, denominator retention, and
  `insufficient_replicates` MCSE status.
- Updated the mission-control validator, focused dashboard contract test,
  dashboard README, status JSON, sweep JSON, widget table list, and check-log.

## 3a. Decisions and Rejected Alternatives

The smoke keeps derived-correlation endpoints unavailable instead of inventing a
delta-method or profile reconstruction in the runner. That is deliberate: the
current evidence proves the target mapping and denominator contract, not finite
interval reliability. A larger grid was also rejected for this slice because the
single-replicate smoke is the gate that verifies schema, warnings, unavailable
rows, and MCSE fields before scaling.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-interval-smoke.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-interval-smoke-results.tsv`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-interval-smoke.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-interval-smoke.md`

## 5. Checks Run

- `air format docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-interval-smoke.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-interval-smoke.R --n-rep=1`
  passed and wrote
  `q4-derived-correlation-interval-smoke-results.tsv`.
- `python3 tools/validate-mission-control.py` passed with six q4
  derived-correlation interval-smoke rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 730 assertions.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`,
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`, and
  `sh -n tools/start-mission-control.sh` passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed; the dashboard was already listening on `http://127.0.0.1:8765/`.
- Live fetches passed: `version.txt = r48`,
  `structured-re-q4-derived-correlation-interval-smoke.tsv` served seven lines,
  the raw smoke artifact served seven lines, and served `status.json` plus
  `sweep.json` parsed as JSON.
- Initial `git diff --check` passed in both active worktrees before editing.

## 6. Tests of the Tests

The validator and focused R test now require exactly six q4 derived-correlation
targets, the expected profile-target prefix, unavailable interval status,
missing endpoints, retained failure reason, retained denominator fields, and
explicit no-coverage/no-REML/no-broad-bridge boundary wording. The first focused
test run failed because the profile-target assertion used a regex anchor with a
fixed-string helper; after changing the assertion to the literal
`cor:phylo:` prefix, the focused test passed with 730 assertions. These
assertions would fail if a row silently gained finite endpoints, lost its
profile target, dropped the unavailable reason, or overclaimed interval
coverage.

## 7a. Issue Ledger

This slice advances the SR150/q4 interval blocker by adding executable
diagnostic evidence. It does not close SR150: calibrated finite-interval
coverage evidence remains blocked until a reconstruction method and replicated
grid pass. No GitHub issue was opened, closed, or commented on in this slice:
the work is local mission-control evidence, and the current hard boundary keeps
Ayumi-facing replies and public promotion out of scope until explicit approval.

## 8. Consistency Audit

The neighborhood audit checked the r46 smoke artifact, the r47 reconstruction
contract, the mission-control validator, the focused dashboard contract test,
the dashboard README, the widget sidecar list, and the status/sweep activity
surfaces. The r48 language stays below q4 interval reliability, interval
coverage, q4 REML, AI-REML, broad bridge support, public optimizer control,
commit, PR, and Ayumi-facing reply claims.

Stale-wording searches run:

- `rg -n "derived-correlation interval smoke|q4-derived-correlation-interval-smoke|run-derived-correlation-interval-smoke|derived_interval_unavailable" docs/dev-log/dashboard docs/dev-log/after-task/2026-06-23-q4-derived-correlation-interval-smoke.md docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`
- `rg -n "q4 interval reliability|interval coverage|q4 REML|AI-REML|broad bridge support" docs/dev-log/dashboard/structured-re-q4-derived-correlation-interval-smoke.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-interval-smoke-results.tsv docs/dev-log/dashboard/README.md docs/dev-log/after-task/2026-06-23-q4-derived-correlation-interval-smoke.md docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The scoped hits were the new r48 source, raw artifact, sidecar, validator,
test, README, status/sweep, and check-log rows. The boundary hits retained
rejection wording rather than promoting interval reliability or coverage.

## 9. What Did Not Go Smoothly

The dashboard README wording differed from the checkpoint summary, so the patch
had to anchor on the current source text. The test also needed explicit
`is.na()` vector checks for blank interval columns because `read.delim()`
imports all-blank columns as missing values.

## 10. Known Residuals

Derived q4 correlation intervals remain unavailable. MCSE fields are present
but marked `insufficient_replicates` because this is one smoke replicate. No
finite derived-correlation interval, q4 interval coverage, q4 REML, HSquared
AI-REML, broad bridge support, public optimizer control, commit, PR, or
Ayumi-facing claim is made.

## 11. Team Learning

For q4 interval work, bank the target map and denominator behavior before
writing a reconstruction method. The next method slice should make finite
derived-correlation intervals explicit and testable, but unavailable rows must
remain in the denominator until replicated MCSE evidence exists.
