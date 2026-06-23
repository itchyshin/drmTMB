# Q4 Derived-Correlation Two-Shard Rehearsal

## 1. Goal

Bank r58 as a local two-shard rehearsal for the q4 derived-correlation
delta-grid runner, proving private shard outputs and aggregation before any
DRAC use.

## 2. Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R`.
- Ran two private local shards with two seeds and scale levels `0.35` and
  `0.50`.
- Ran a forced compute pass for each shard, then a no-force resume pass.
- Aggregated the two private shard manifests and run logs.
- Added dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-two-shard-rehearsal.tsv`.
- Updated mission-control widget, validator, focused R contract test,
  dashboard README, status JSON, sweep JSON, executable-evidence ledger, and
  build marker `r58`.

## 3a. Decisions and Rejected Alternatives

The rehearsal ran locally rather than on DRAC. The purpose was to test the
write-isolation and aggregate gate, not to buy throughput. This follows the new
DRAC compute resource gate: use local or `totoro` first, then use DRAC only
when the evidence value justifies shared compute.

The aggregate script requires shard manifests and run logs to exist before it
runs. It does not watch live jobs or append to a shared file.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-two-shard-rehearsal/`
- `docs/dev-log/dashboard/structured-re-q4-derived-correlation-delta-grid-two-shard-rehearsal.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-two-shard-rehearsal.md`
- `docs/dev-log/recovery-checkpoints/2026-06-23-080746-codex-checkpoint.md`

## 5. Checks Run

- Two shard compute commands passed with `--force=true`, private output roots,
  private manifests, and private run logs.
- Two shard resume commands passed with `--force=false` and recorded
  skipped-existing actions.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R --n-shards=2 --expected-cells=4 --expected-target-rows=24 --aggregate-label=two_shard_rehearsal`
  passed after fixing a vectorized path-helper bug in the aggregate script.
- `Rscript tools/codex-checkpoint.R --goal "r58 q4 derived-correlation local two-shard rehearsal" --next "Use local or totoro for the next larger shard rehearsal unless runtime proves DRAC is needed; keep SR150 blocked until observed MCSE-calibrated evidence exists."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-080746-codex-checkpoint.md`.

Full validator, focused R test, and diff-check evidence is recorded in the
current check-log entry.

## 6. Tests of the Tests

The validator and focused R contract test now require:

- eight dashboard sidecar rows;
- one aggregate manifest row;
- six aggregate summary rows, one per derived-correlation target;
- four unique seed-scale cells;
- four computed actions and four skipped-existing actions;
- 24 retained denominator rows;
- 24 finite delta diagnostic rows;
- six boundary-clamped rows;
- zero coverage-evaluable rows;
- `aggregate_status = "aggregate_verified"`;
- explicit rejection of q4 interval reliability, interval coverage, q4 REML,
  AI-REML, HSquared transfer, and broad bridge support claims.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on.

## 8. Consistency Audit

This is local aggregation/resume evidence only. SR150 remains blocked. The
slice does not promote interval reliability, coverage, q4 REML, HSquared
AI-REML, non-Gaussian AI-REML, broad bridge support, a public optimizer,
DRAC readiness, a commit, a PR, or an Ayumi-facing reply.

## 9. What Did Not Go Smoothly

The first aggregate run failed because `rel_path()` assumed scalar input while
the aggregate manifest passes vectors of shard manifests and run logs. The
helper now handles vector input. This was exactly the sort of cheap local
failure the rehearsal was meant to catch before any shared compute dispatch.

## 10. Known Residuals

The next useful rung is a larger local or `totoro` shard rehearsal if runtime
remains acceptable. DRAC should wait until local or `totoro` runtime becomes the
bottleneck for the evidence gate.

## 11. Team Learning

Grace and Curie should rehearse aggregation locally before remote dispatch.
Ada should ask whether the next evidence gate needs more throughput or just
better accounting. Rose should block DRAC use when local or `totoro` is still
enough.
