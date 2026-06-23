# Q4 Derived-Correlation Delta Grid Resumable Pilot

## 1. Goal

Bank r55 as a small multi-cell resumability pilot for the q4
derived-correlation delta grid: two seeds crossed with two scale levels, with
one compute pass and one resume pass, while keeping SR150 blocked until
calibrated-grid MCSE evidence exists.

## 2. Implemented

- Ran the resumable q4 derived-correlation delta-grid runner with
  `--n-rep=2`, scale levels `0.35,0.50`, and `--cell-limit=4`.
- Ran a second pass without force and confirmed all four per-cell TSV outputs
  were skipped rather than recomputed.
- Refreshed the manifest, run log, and four per-cell outputs under
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/`.
- Updated the mission-control sidecar, validator, focused R dashboard contract
  test, dashboard README, widget build marker, JSON feeds, and executable
  evidence ledger for r55.
- Replanned the compute ladder around CPU resources: laptop/local checks for
  tiny contracts, `totoro` for larger CPU-only resumability pilots, and DRAC
  job arrays for calibrated ADEMP campaigns. GPU work remains out of scope.

## 3a. Decisions and Rejected Alternatives

The slice deliberately stayed at four seed-scale cells rather than starting the
500-replicate calibrated grid. The r55 aim is to prove multi-cell resumability,
retained denominator accounting, and dashboard/test/validator agreement before
spending totoro or DRAC time on calibrated coverage evidence.

The dashboard continues to describe this as pilot evidence only. No q4 interval
reliability, interval coverage, q4 REML, HSquared AI-REML, broad bridge support,
public optimizer control, Ayumi reply, commit, or PR is promoted.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke/q4_delta_resumable_sd035_seed202607500/q4_delta_resumable_sd035_seed202607500.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke/q4_delta_resumable_sd035_seed202607501/q4_delta_resumable_sd035_seed202607501.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke/q4_delta_resumable_sd050_seed202607500/q4_delta_resumable_sd050_seed202607500.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke/q4_delta_resumable_sd050_seed202607501/q4_delta_resumable_sd050_seed202607501.tsv`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-resumable-pilot.md`
- `docs/dev-log/recovery-checkpoints/2026-06-23-071733-codex-checkpoint.md`

## 5. Checks Run

- `git status --short --branch` and `git diff --check` passed in both active
  worktrees before editing.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R --n-rep=2 --sd-scales=0.35,0.50 --cell-limit=4 --run-label=r55_compute --force=true --reset-output=true --reset-log=true`
  passed and wrote four per-cell TSV outputs.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-delta-resumable-smoke.R --n-rep=2 --sd-scales=0.35,0.50 --cell-limit=4 --run-label=r55_resume --force=false`
  passed and recorded four `skipped_existing` actions.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` passed.
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `air format tests/testthat/test-structured-re-conversion-contracts.R` passed.
- `python3 tools/validate-mission-control.py` passed with eight r55 q4
  derived-correlation delta-grid resumable-smoke sidecar rows and 55
  executable-evidence rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1045 assertions.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`
  passed and served build `r55`; direct Python `urllib` fetches passed for
  `version.txt`, `status.json`, `sweep.json`, the resumable-smoke sidecar, the
  manifest, the run log, and one per-cell TSV.
- `Rscript tools/codex-checkpoint.R --goal "r55 q4 derived-correlation delta-grid resumable pilot" --next "Prime a shared totoro SSH ControlMaster for this process, then run a larger CPU-only resumability pilot before any DRAC calibrated ADEMP grid."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-071733-codex-checkpoint.md`.
- Final `git diff --check` passed in both active worktrees:
  `/Users/z3437171/Dropbox/Github Local/drmTMB` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot`.

## 6. Tests of the Tests

The validator and focused R contract test now require four explicit seed-scale
cell IDs, four computed actions, four skipped actions, 24 retained target rows,
24 retained denominator rows, six boundary-clamped rows, and the r55 compute /
resume run-label sequence. The checks would fail if a completed cell were
silently recomputed, if a cell output disappeared, if the denominator dropped
boundary-clamped rows, or if the pilot were relabelled as calibrated coverage
evidence.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence under SR150. Ayumi-facing work remains explicitly out
of scope until the exact reply text and posting decision are approved.

## 8. Consistency Audit

Scoped scans run for this slice:

```sh
rg -n "r54|1 observed cell|six retained q4 derived-correlation|one computed action|one seed-scale cell|2 boundary-clamped" docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json docs/dev-log/dashboard/README.md docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv docs/dev-log/dashboard/structured-re-executable-evidence.tsv tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py
rg -n "q4 interval reliability|interval coverage|q4 REML|HSquared AI-REML|AI-REML|broad bridge support|Ayumi reply" docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-resumable-smoke.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-manifest.tsv docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-resumable-smoke-run-log.tsv docs/dev-log/after-task/2026-06-23-q4-derived-correlation-delta-grid-resumable-pilot.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json
```

The first stale-r54 scan returned no live stale-count references after the r55
edits. The second claim-boundary scan found expected negative boundary wording
only, not promoted q4 interval reliability, interval coverage, q4 REML,
HSquared AI-REML, broad bridge support, or Ayumi-facing text.

## 9. What Did Not Go Smoothly

The first sidecar update script tried to read `cell_output_root` from the
manifest, while the manifest column is `output_root`; the failed attempt wrote
nothing, and the mapping was fixed before updating the sidecar.

The first executable-evidence ledger update accidentally appended non-contract
columns. The mission-control validator caught the schema drift immediately, and
the file was repaired back to the 10-column ledger contract before continuing.

The first dashboard fetch loop used `curl`, which is not available in this
shell, and the loop did not stop on the missing command. The check was repeated
with Python `urllib` and explicit status/body checks, which passed and reported
`version=r55`.

## 10. Known Residuals

This is still a four-cell pilot. It proves multi-cell resumability and dashboard
accounting, not interval reliability or calibrated coverage. SR150 remains
blocked until a calibrated grid is run and summarized with MCSE. `totoro` is
connected in the user's terminal but is not yet available to this process
through a reusable SSH ControlMaster socket.

## 11. Team Learning

Curie should scale this lane in three rungs: r55 local four-cell pilot, a larger
CPU-only `totoro` pilot once the shared SSH socket is usable, then DRAC array
jobs for ADEMP-calibrated evidence. Grace should keep the dashboard ledger
schema under validator control before any generated or scripted update touches
wide TSV files.
