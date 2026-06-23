# Q4 Derived-Correlation Local Four-Shard Rehearsal

## 1. Goal

Bank r60 as a larger local shard rehearsal for the q4 derived-correlation
delta-grid runner, using the r59 hardened aggregate gate before any DRAC
dispatch.

## 2. Implemented

- Ran four private local shards over twelve seed-scale cells:
  six seeds crossed with scale levels `0.35` and `0.50`.
- Ran a forced compute pass for each shard, then a no-force resume pass for
  each shard.
- Aggregated the four private shard manifests and run logs with
  `aggregate-calibrated-grid-delta-shards.R`.
- Added dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-local-four-shard-rehearsal.tsv`.
- Updated the mission-control widget, validator, focused R contract test,
  dashboard README, status JSON, sweep JSON, executable-evidence ledger, and
  build marker `r60`.

## 3a. Decisions and Rejected Alternatives

This slice did not use DRAC. The purpose was to test whether the runner,
resume path, private-output contract, aggregate gate, and denominator ledgers
survive a slightly larger local shard rehearsal with warning and failure rows.
DRAC would have added scheduling and login overhead without improving this
specific gate.

The aggregate summary still records MCSE placeholders rather than coverage or
failure-rate MCSE estimates. Twelve seed-scale cells are enough to exercise the
plumbing and denominator accounting; they are not enough to make interval
reliability or coverage statements.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-local-four-shard-rehearsal/`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-local-four-shard-rehearsal.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-local-four-shard-rehearsal.md`
- `docs/dev-log/recovery-checkpoints/2026-06-23-084957-codex-checkpoint.md`

## 5. Checks Run

- Four shard compute commands passed with `--force=true`, private output roots,
  private manifests, private run logs, and `--allow-large=true`.
- Four shard resume commands passed with `--force=false` and recorded
  skipped-existing actions.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R --shard-root=docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-local-four-shard-rehearsal --n-shards=4 --expected-cells=12 --expected-target-rows=72 --aggregate-label=local_four_shard_rehearsal`
  passed.
- `Rscript tools/codex-checkpoint.R --goal "r60 q4 derived-correlation local four-shard rehearsal" --next "Run a medium local or totoro shard rehearsal with the r60 aggregate gate; keep DRAC gated until local/totoro runtime is insufficient and keep SR150 blocked until calibrated denominator and coverage MCSE evidence exists."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-084957-codex-checkpoint.md`.

Full validator, focused R test, JSON checks, widget fetches, diff checks, and
checkpoint evidence are recorded in the current check-log entry.

## 6. Tests of the Tests

The validator and focused R contract test now require:

- eight r60 dashboard sidecar rows;
- one local four-shard aggregate manifest row;
- six local four-shard aggregate summary rows, one per derived-correlation
  target;
- twelve unique seed-scale cells;
- twelve computed actions and twelve skipped-existing actions;
- 72 retained denominator rows;
- 71 finite delta diagnostic rows;
- 24 warning rows;
- 18 failure-class denominator rows;
- 17 boundary-clamped rows;
- zero coverage-evaluable rows;
- `aggregate_status = "aggregate_verified"`;
- explicit rejection of q4 interval reliability, interval coverage, q4 REML,
  AI-REML, HSquared transfer, and broad bridge support.

## 7. Issue Ledger

No new GitHub issue, pull request, Ayumi reply, or public claim was created.

## 8. Consistency Audit

The r60 wording stays within smoke and rehearsal evidence. It does not promote
q4 interval reliability, interval coverage, q4 REML, native-TMB q4 REML,
HSquared AI-REML, non-Gaussian AI-REML, broad bridge support, DRAC readiness,
or SR150 acceptance.

## 9. Residual Work

Use `totoro` for the next medium rehearsal unless local runtime is already
enough for the gate. Keep DRAC behind a real need for wall-clock throughput,
and keep SR150 blocked until calibrated denominator and MCSE evidence exists.
