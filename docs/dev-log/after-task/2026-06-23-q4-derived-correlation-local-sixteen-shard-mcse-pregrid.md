# Q4 Derived-Correlation Local Sixteen-Shard MCSE Pre-Grid

## 1. Goal

Bank r62 as a local calibrated-denominator pre-grid for the q4
derived-correlation delta-grid runner, adding diagnostic MCSE fields for
failure, warning, and boundary-clamp rates while keeping coverage
non-evaluable and DRAC gated.

## 2. Implemented

- Added opt-in `--compute-rate-mcse=true` support to
  `aggregate-calibrated-grid-delta-shards.R`.
- Kept the aggregate default backward-compatible: prior r58-r61 aggregates
  still emit MCSE placeholders unless the new flag is enabled.
- Ran sixteen private local shards over 96 seed-scale cells: 48 seeds crossed
  with scale levels `0.35` and `0.50`.
- Ran a forced compute pass for each shard, then a no-force resume pass for
  each shard.
- Aggregated the sixteen private shard manifests and run logs with
  diagnostic MCSE enabled.
- Added dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid.tsv`.
- Updated the mission-control widget, validator, focused R contract test,
  dashboard README, status JSON, sweep JSON, executable-evidence ledger, and
  build marker `r62`.

## 3a. Decisions and Rejected Alternatives

DRAC was not used. The r62 question was still local race-safety,
denominator-retention, resumability, and diagnostic MCSE plumbing, not cluster
throughput. `totoro` was also not used because the prior non-interactive SSH
check failed under `BatchMode=yes`; local runtime remained acceptable for this
pre-grid.

Fisher reviewed the MCSE plan read-only and recommended keeping coverage
non-evaluable while computing failure, warning, and boundary-clamp diagnostic
rate MCSEs. Grace reviewed the runner read-only and confirmed the race-safety
condition: one process per private shard root, no concurrent same-shard writes,
aggregate only after compute and resume passes finish.

The manifest-level failure-rate MCSE uses cell-level failure fractions rather
than treating all six target rows in a cell as independent. The target-level
summary MCSEs are plug-in binomial diagnostics over retained target rows.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid/`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-local-sixteen-shard-mcse-pregrid.md`
- `docs/dev-log/recovery-checkpoints/2026-06-23-094312-codex-checkpoint.md`

## 5. Checks Run

- Sixteen shard compute commands passed with `--force=true`, private output
  roots, private manifests, private run logs, and `--allow-large=true`.
- Sixteen shard resume commands passed with `--force=false` and recorded
  skipped-existing actions.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R --shard-root=docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-local-sixteen-shard-mcse-pregrid --n-shards=16 --expected-cells=96 --expected-target-rows=576 --aggregate-label=local_sixteen_shard_mcse_pregrid --compute-rate-mcse=true`
  passed.
- `Rscript tools/codex-checkpoint.R --goal "r62 q4 derived-correlation local sixteen-shard MCSE pre-grid" --next "Choose the next calibrated-denominator slice: either a larger local/totoro pre-grid if runtime remains acceptable, or prepare a DRAC job-array only after carrying forward private shard roots, compute-then-resume logs, aggregate_status=aggregate_verified, diagnostic MCSE fields, and coverage not_evaluable boundaries. Keep SR150 blocked until coverage-evaluable denominator and calibrated coverage MCSE evidence exists."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-094312-codex-checkpoint.md`.

Final validator, focused R test, JSON checks, widget fetches, diff checks, and
checkpoint evidence are recorded in the current check-log entry.

## 6. Tests of the Tests

The validator and focused R contract test now require:

- eight r62 dashboard sidecar rows;
- one local sixteen-shard MCSE pre-grid aggregate manifest row;
- six local sixteen-shard MCSE pre-grid aggregate summary rows, one per
  derived-correlation target;
- 96 unique seed-scale cells;
- 96 computed actions and 96 skipped-existing actions;
- 576 retained denominator rows;
- 555 finite delta diagnostic rows;
- 306 warning rows;
- 192 failure-class denominator rows;
- 126 boundary-clamped rows;
- zero coverage-evaluable rows;
- `coverage_mcse = "not_evaluable_local_sixteen_shard_mcse_pregrid"`;
- numeric diagnostic MCSE fields for failure, warning, and boundary-clamp
  rates;
- `aggregate_status = "aggregate_verified"`;
- explicit rejection of q4 interval reliability, interval coverage, q4 REML,
  AI-REML, HSquared transfer, and broad bridge support.

## 7. Issue Ledger

No new GitHub issue, pull request, Ayumi reply, or public claim was created.

## 8. Consistency Audit

The r62 wording stays within local MCSE pre-grid evidence. It does not promote
q4 interval reliability, interval coverage, q4 REML, native-TMB q4 REML,
HSquared AI-REML, non-Gaussian AI-REML, broad bridge support, DRAC readiness,
or SR150 acceptance.

## 9. Residual Work

SR150 remains blocked until coverage-evaluable denominator rows and calibrated
coverage MCSE evidence exist. The next slice should either run a slightly
larger local or `totoro` calibrated-denominator pre-grid if runtime remains
acceptable, or prepare a DRAC job-array only after the same private-shard and
aggregate gates are carried forward.
