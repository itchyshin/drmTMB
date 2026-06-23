# Q4 Derived-Correlation Local Eight-Shard Medium Rehearsal

## 1. Goal

Bank r61 as a medium local shard rehearsal for the q4 derived-correlation
delta-grid runner, using the r60 aggregate gate and keeping DRAC behind an
explicit throughput need.

## 2. Implemented

- Ran eight private local shards over 48 seed-scale cells: 24 seeds crossed
  with scale levels `0.35` and `0.50`.
- Ran a forced compute pass for each shard, then a no-force resume pass for
  each shard.
- Aggregated the eight private shard manifests and run logs with
  `aggregate-calibrated-grid-delta-shards.R`.
- Added dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal.tsv`.
- Updated the mission-control widget, validator, focused R contract test,
  dashboard README, status JSON, sweep JSON, executable-evidence ledger, and
  build marker `r61`.

## 3a. Decisions and Rejected Alternatives

`totoro` was tested first, but non-interactive SSH failed with
`Permission denied (publickey,password)` under `BatchMode=yes`. Rather than
pause the slice, the medium rehearsal ran locally. DRAC was not used because
the current gate was still about resumability, private outputs, and aggregate
denominator accounting, not wall-clock throughput.

The medium rehearsal still records MCSE placeholders. Forty-eight seed-scale
cells are enough to stress the ledger and expose warning, failure, and
boundary-clamp behavior; they are not enough for interval reliability or
coverage wording.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal/`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-local-eight-shard-medium-rehearsal.md`
- `docs/dev-log/recovery-checkpoints/2026-06-23-090312-codex-checkpoint.md`

## 5. Checks Run

- Eight shard compute commands passed with `--force=true`, private output
  roots, private manifests, private run logs, and `--allow-large=true`.
- Eight shard resume commands passed with `--force=false` and recorded
  skipped-existing actions.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R --shard-root=docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-local-eight-shard-medium-rehearsal --n-shards=8 --expected-cells=48 --expected-target-rows=288 --aggregate-label=local_eight_shard_medium_rehearsal`
  passed.
- `air format tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R`
  passed.
- `python3 tools/validate-mission-control.py` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1324 assertions.
- `Rscript tools/codex-checkpoint.R --goal "r61 q4 derived-correlation local eight-shard medium rehearsal" --next "Restore non-interactive totoro access or continue local shards for a calibrated-denominator pre-grid; keep DRAC gated until local/totoro runtime is insufficient and keep SR150 blocked until calibrated denominator and coverage MCSE evidence exists."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-090312-codex-checkpoint.md`.

Full validator, focused R test, JSON checks, widget fetches, diff checks, and
checkpoint evidence are recorded in the current check-log entry.

## 6. Tests of the Tests

The validator and focused R contract test now require:

- eight r61 dashboard sidecar rows;
- one local eight-shard medium aggregate manifest row;
- six local eight-shard medium aggregate summary rows, one per
  derived-correlation target;
- 48 unique seed-scale cells;
- 48 computed actions and 48 skipped-existing actions;
- 288 retained denominator rows;
- 276 finite delta diagnostic rows;
- 156 warning rows;
- 108 failure-class denominator rows;
- 61 boundary-clamped rows;
- zero coverage-evaluable rows;
- `aggregate_status = "aggregate_verified"`;
- explicit rejection of q4 interval reliability, interval coverage, q4 REML,
  AI-REML, HSquared transfer, and broad bridge support.

## 7. Issue Ledger

No new GitHub issue, pull request, Ayumi reply, or public claim was created.

## 8. Consistency Audit

The r61 wording stays within medium local rehearsal evidence. It does not
promote q4 interval reliability, interval coverage, q4 REML, native-TMB q4
REML, HSquared AI-REML, non-Gaussian AI-REML, broad bridge support, DRAC
readiness, or SR150 acceptance.

## 9. Residual Work

Before a calibrated grid, either restore non-interactive `totoro` SSH or keep
using local shards only while runtime is acceptable. DRAC should wait until the
wall-clock cost justifies the login and scheduling overhead.
