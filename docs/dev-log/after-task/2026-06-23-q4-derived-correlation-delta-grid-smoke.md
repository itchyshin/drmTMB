# Q4 Derived-Correlation Delta Grid Smoke

## 1. Goal

Add an executable one-replicate smoke runner that writes grid-shaped
finite-difference delta rows for q4 derived correlations, while keeping earlier
r46 and r49 artifacts stable.

## 2. Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-smoke.R`.
- The runner permits only `--n-rep=1`, uses stabilized seed `202606902` at
  scale `0.50`, fits the q4 Gaussian phylo fixture, and writes six
  derived-correlation rows.
- Added raw artifact
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-smoke-results.tsv`.
- Added validator-owned dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv`.
- Updated the mission-control validator, focused dashboard contract test,
  dashboard README, status JSON, sweep JSON, widget table list, and check-log.

## 3. Mathematical Contract

The runner uses the stabilized q4 Gaussian phylo fixture and the same six
derived-correlation targets as `corpairs(fit, level = "phylogenetic")`. It
perturbs the full TMB parameter vector at the named `theta_phylo` positions,
reads the reported `phylo_q4_corr` matrix, and computes finite-difference delta
standard errors from the `theta_phylo` covariance block.

The output is grid-shaped: every row carries seed/scale identity, fit status,
Hessian status, warning context, failure reason, target identity, finite or
unavailable interval fields, coverage placeholders, failure-rate placeholders,
and explicit claim-boundary text. In this one-replicate smoke all six rows have
finite diagnostic delta endpoints and `mcse_status = insufficient_replicates`.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-smoke.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-smoke-results.tsv`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-smoke.md`

## 5. Checks Run

- `air format docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-smoke.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`,
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`, and
  `sh -n tools/start-mission-control.sh` passed.
- `python3 - <<'PY' ... compile(...) ... PY` passed for
  `tools/validate-mission-control.py` without writing `__pycache__`.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-smoke.R --n-rep=1`
  passed and wrote `q4-derived-correlation-delta-grid-smoke-results.tsv`.
- `python3 tools/validate-mission-control.py` passed with eight q4
  derived-correlation delta-grid smoke rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 852 assertions.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed; the dashboard was already listening on `http://127.0.0.1:8765/`.
- Live fetches passed: `version.txt = r51`,
  `structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv` served
  nine lines, the raw smoke artifact served seven lines, and served
  `status.json` plus `sweep.json` parsed as JSON.
- Final `git diff --check` passed in both active worktrees:
  `/Users/z3437171/Dropbox/Github Local/drmTMB` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## 6. Tests Of The Tests

The validator and focused R test require exactly eight sidecar rows and six raw
target rows. They check the expected replicate ID, seed, six target names,
finite `theta_phylo` covariance status, positive delta standard errors, ordered
endpoints inside `[-1, 1]`, no boundary clamping in this seed, retained
denominator row count, single-replicate MCSE placeholders, and explicit
no-coverage/no-REML/no-broad-bridge boundary wording.

These tests would fail if the runner silently dropped a target, used the wrong
parameter vector, lost failure-reason or MCSE fields, erased unavailable rows
from denominator accounting, or presented finite diagnostic endpoints as
coverage evidence.

## 7. Consistency Audit

Scoped searches run:

- `rg -n "delta-grid smoke|delta grid smoke|q4-derived-correlation-delta-grid-smoke|run-calibrated-grid-delta-smoke|delta_grid_smoke" docs/dev-log/dashboard docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-smoke.R`
- `rg -n "q4 interval reliability|interval coverage|q4 REML|AI-REML|broad bridge support" docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-smoke-status.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-smoke-results.tsv docs/dev-log/dashboard/README.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The first search found the new runner, raw artifact, sidecar, widget, status
feeds, validator, and focused test. The second search found boundary wording
and validator/test assertions that reject overclaims.

## 8. GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence under SR150, and Ayumi-facing text remains out of
scope until the exact issue text and final reply are approved.

## 9. What Did Not Go Smoothly

The sidecar uses eight status rows to mirror the r50 contract components even
though the raw artifact has six target rows. That duplication is intentional:
it gives the dashboard a compact contract-level view while the raw artifact
retains target-level evidence.

## 10. Team Learning

Curie can now scale the q4 delta path from one replicate to many without
changing the target schema. Fisher and Rose should keep the next grid work
focused on denominators, failed fits, warning contexts, and MCSE before any
coverage interpretation.

## 11. Known Limitations

This slice runs one stabilized replicate only. It does not estimate calibrated
coverage, does not compare profile or bootstrap reconstruction, and does not
promote q4 interval reliability, q4 REML, AI-REML, or broad bridge support.

## 12. Next Actions

Turn the one-replicate smoke into a multi-replicate calibrated delta grid that
keeps failed-fit denominator rows and computes coverage and failure-rate MCSE.
