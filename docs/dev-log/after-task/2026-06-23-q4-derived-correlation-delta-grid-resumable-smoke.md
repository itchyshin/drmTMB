# Q4 Derived-Correlation Delta Grid Resumable Smoke

## 1. Goal

Implement the next r54 step after the ADEMP dry-run contract: a resumable
per-cell q4 derived-correlation delta-grid runner, verified with a tiny local
compute-then-resume smoke rather than a full calibrated campaign.

## 2. Implemented

- Added optional `--output-dir` and `--output-file` arguments to
  `run-calibrated-grid-delta-smoke.R` while preserving its default r51 output.
- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R`.
- The r54 runner builds seed-scale cell IDs, writes one TSV per cell, skips an
  existing cell unless `--force=true`, records a run log, and writes a manifest.
- Ran the runner twice:
  - first with `--force=true --reset-output=true --reset-log=true`, producing
    one computed cell;
  - then with `--force=false`, recording a skipped-existing resume action.
- Added generated artifacts:
  - `q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv`;
  - `q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv`;
  - `q4-derived-correlation-delta-grid-resumable-smoke/q4_delta_resumable_sd035_seed202607500/q4_delta_resumable_sd035_seed202607500.tsv`.
- Added validator-owned dashboard sidecar
  `structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv`.
- Updated the mission-control validator, focused dashboard contract test,
  dashboard table, dashboard README, status JSON, sweep JSON, version marker,
  executable-evidence ledger, and check-log.

## 3. Mathematical Contract

The r54 smoke inherits the r53 ADEMP target set but only executes one
seed-scale cell: seed 202607500 at scale 0.35. The delegated finite-difference
delta smoke fits the stabilized q4 Gaussian phylo model and writes the six
derived-correlation targets: `cor_mu1_mu2`, `cor_mu1_sigma1`,
`cor_mu1_sigma2`, `cor_mu2_sigma1`, `cor_mu2_sigma2`, and
`cor_sigma1_sigma2`.

The runner does not estimate calibrated coverage. It verifies that a completed
cell can be retained and skipped on a later invocation, while preserving
denominator fields for finite rows, failed fits, `pdHess = FALSE`, warnings,
unavailable intervals, and boundary-clamped rows.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-smoke.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke/q4_delta_resumable_sd035_seed202607500/q4_delta_resumable_sd035_seed202607500.tsv`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-resumable-smoke.md`

## 5. Checks Run

- `air format docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-smoke.R docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R`
  passed.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R --n-rep=1 --sd-scales=0.35 --cell-limit=1 --run-label=compute --force=true --reset-output=true --reset-log=true`
  passed and wrote one per-cell TSV.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R --n-rep=1 --sd-scales=0.35 --cell-limit=1 --run-label=resume --force=false`
  passed and recorded `skipped_existing`.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`,
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`, and
  `sh -n tools/start-mission-control.sh` passed.
- `python3 - <<'PY' ... compile(...) ... PY` passed for
  `tools/validate-mission-control.py` without writing `__pycache__`.
- `python3 tools/validate-mission-control.py` passed with 8 q4
  derived-correlation delta-grid resumable-smoke rows and 55
  executable-evidence rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1044 assertions.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed and served build `r54`; direct fetches passed for `version.txt`,
  `status.json`, `sweep.json`,
  `structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv`, the
  resumable manifest, the resumable run log, and the per-cell TSV under
  `docs/dev-log/simulation-artifacts/`.
- Final `git diff --check` passed in both active worktrees:
  `/Users/z3437171/Dropbox/Github Local/drmTMB` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## 6. Tests Of The Tests

The focused R test and mission-control validator require the sidecar, manifest,
run log, and per-cell output to agree: one observed cell, one computed action,
one skipped-existing action, six retained target rows, six finite delta rows,
two boundary-clamped rows, and explicit insufficient-replicate MCSE status.

These tests would fail if the runner silently recomputed during the second
invocation, dropped the per-cell output path, lost a target, removed clamped
rows from the denominator, or turned the smoke into a coverage claim.

## 7. Consistency Audit

Scoped searches run:

- `rg -n "resumable|skipped_existing|resume_skip_verified|run-calibrated-grid-delta-resumable|q4-derived-correlation-delta-grid-resumable" docs/dev-log/dashboard docs/dev-log/check-log.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-resumable-smoke.md`
- `rg -n "q4 interval reliability|interval coverage|q4 REML|AI-REML|broad bridge support|coverage evidence|calibrated coverage" docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-resumable-smoke.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/dashboard/README.md tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The first search found the runner, sidecar, manifest, run log, cell output,
widget, status feeds, validator, focused test, check-log, and
executable-evidence ledger. The second search found only boundary or negative
claim language around coverage, q4 REML, AI-REML, and broad bridge support.

## 8. GitHub Issue Maintenance

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence under SR150, and Ayumi-facing text remains out of
scope until the exact issue text and final reply are approved.

## 9. What Did Not Go Smoothly

The first runner attempt failed because the delegated `Rscript` call did not
quote the local Dropbox path containing a space. Quoting the script path and
`--output-dir` argument fixed the runner and is now part of the script.

## 10. Team Learning

Grace should keep path-with-space checks in resumable runners. Curie should
prefer per-cell artifacts plus a run log before asking for large calibrated
campaigns.

## 11. Known Limitations

This slice runs one seed-scale cell only. It verifies resumability plumbing but
does not run the 500-replicate grid, does not estimate calibrated coverage, does
not move SR150, and does not promote q4 interval reliability, q4 REML,
AI-REML, broad bridge support, a commit, PR, or Ayumi reply.

## 12. Next Actions

Run the full r53 ADEMP grid through the resumable cell contract, then summarize
coverage, failure, warning, and boundary-clamp rates with MCSE before moving
SR150.
