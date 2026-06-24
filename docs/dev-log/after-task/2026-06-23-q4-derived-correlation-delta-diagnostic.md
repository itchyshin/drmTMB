# Q4 Derived-Correlation Delta Diagnostic

## 1. Goal

Add a private finite-difference delta diagnostic for q4 derived correlations so
the mission-control dashboard can show that finite diagnostic endpoints are
mechanically available on the stabilized fixture without promoting interval
reliability or coverage.

## 2. Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-delta-diagnostic.R`.
- The runner permits only `--n-rep=1`, uses stabilized seed `202606902` at
  scale `0.50`, fits the q4 Gaussian phylo fixture, and writes six
  derived-correlation diagnostic rows.
- Added raw artifact
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-diagnostic-results.tsv`.
- Added validator-owned dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-diagnostic.tsv`.
- Updated the mission-control validator, focused dashboard contract test,
  dashboard README, status JSON, sweep JSON, widget table list, and check-log.

## 3. Mathematical Contract

The diagnostic perturbs the full TMB parameter vector, not only the optimizer
parameter vector, at the six `theta_phylo` positions. For each perturbation it
reads the reported `phylo_q4_corr` matrix and extracts the six off-diagonal
derived correlations in the same order used by `corpairs()`. The row-level
standard errors use a finite-difference gradient and the `theta_phylo` block of
`fit$sdr$cov.fixed`.

The artifact records finite one-replicate Wald delta diagnostic intervals. The
intervals are clamped to `[-1, 1]` only if needed; this run did not require
clamping. These intervals are diagnostic mechanics evidence, not calibrated
interval reliability or coverage evidence.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-delta-diagnostic.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-diagnostic-results.tsv`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-diagnostic.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-diagnostic.md`

## 5. Checks Run

- `air format docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-delta-diagnostic.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-delta-diagnostic.R --n-rep=1`
  passed and wrote
  `q4-derived-correlation-delta-diagnostic-results.tsv`.
- `python3 tools/validate-mission-control.py` passed with six q4
  derived-correlation delta-diagnostic rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 783 assertions.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`,
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`, and
  `sh -n tools/start-mission-control.sh` passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed; the dashboard was already listening on `http://127.0.0.1:8765/`.
- Live fetches passed: `version.txt = r49`,
  `structured-re-q4-derived-correlation-delta-diagnostic.tsv` served seven
  lines, the raw delta artifact served seven lines, and served `status.json`
  plus `sweep.json` parsed as JSON.
- `git diff --check` passed in both active worktrees:
  `/Users/z3437171/Dropbox/Github Local/drmTMB` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## 6. Tests Of The Tests

The validator and focused R test require exactly six q4 derived-correlation
targets, the expected `theta_phylo` parameter count, finite covariance status,
finite positive delta standard errors, finite ordered endpoints inside
`[-1, 1]`, no boundary clamping in this seed, and report-vs-`corpairs()`
agreement below `1e-8`. They also require `coverage_indicator =
not_evaluated`, single-replicate MCSE placeholders, and explicit
no-coverage/no-REML/no-broad-bridge boundary wording.

These assertions would fail if the diagnostic silently used the wrong parameter
vector, lost a target, returned non-finite endpoints, diverged from
`corpairs()`, dropped denominator/MCSE fields, or overclaimed q4 interval
reliability.

## 7. Consistency Audit

The scoped audit checked the runner, raw artifact, sidecar, widget table list,
validator, focused R test, dashboard README, status/sweep feeds, and check-log.
The r49 language stays below q4 interval reliability, interval coverage, q4
REML, AI-REML, broad bridge support, public optimizer control, commit, PR, and
Ayumi-facing reply claims.

Stale-wording searches run:

- `rg -n "derived-correlation delta|q4-derived-correlation-delta|run-derived-correlation-delta|finite_delta_diagnostic|wald_delta_finite_difference" docs/dev-log/dashboard docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-derived-correlation-delta-diagnostic.R`
- `rg -n "q4 interval reliability|interval coverage|q4 REML|AI-REML|broad bridge support" docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-diagnostic.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-diagnostic-results.tsv docs/dev-log/dashboard/README.md docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The new-surface hits were the r49 source, raw artifact, sidecar, validator,
test, README, status/sweep, and check-log rows. The boundary hits retained
rejection wording rather than promoting interval reliability or coverage.

## 8. GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on in this slice. The work is
local mission-control evidence for SR150, and the current hard boundary keeps
Ayumi-facing replies and public promotion out of scope until explicit approval.

## 9. What Did Not Go Smoothly

The first implementation detail that mattered was parameter-vector length:
`fit$obj$report()` needs the full internal parameter vector, while `fit$opt$par`
is too short for this report path. The diagnostic now uses
`fit$obj$env$last.par.best` and only perturbs the named `theta_phylo` positions.

## 10. Team Learning

Gauss and Noether should keep q4 derived-correlation diagnostics tied to the
actual TMB report transform, not a hand-rolled transform. Fisher should treat
finite one-replicate delta endpoints as mechanics evidence only until a
replicated ADEMP grid supplies failed-fit denominators and MCSE.

## 11. Known Limitations

This slice does not calibrate coverage, compare profile/bootstrap
reconstruction, evaluate multiple seeds or scale levels, or promote any q4 REML
or AI-REML wording. SR150 remains blocked for interval reliability and coverage
until a replicated calibrated grid passes with denominator accounting and MCSE.

## 12. Next Actions

Scale the delta diagnostic into the calibrated q4 grid runner, retaining
failed-fit rows, warning context, finite-interval accounting, and MCSE before
any coverage wording changes.
