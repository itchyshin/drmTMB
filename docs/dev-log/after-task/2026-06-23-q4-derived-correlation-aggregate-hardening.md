# Q4 Derived-Correlation Aggregate Hardening

## 1. Goal

Bank r59 as a hardening slice for the q4 derived-correlation two-shard
aggregate gate before any larger local, `totoro`, or DRAC sweep.

## 2. Implemented

- Added an explicit optional `--repo-root` argument to
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R`.
- Made the aggregate script reject missing cell output files and duplicate
  computed cell IDs.
- Fixed aggregate-status precedence so count and duplicate structural failures
  are not overwritten by resume-status failures.
- Expanded the aggregate summary to carry one row per derived-correlation
  target with denominator, warning, failure, boundary-clamp, rate, and
  MCSE-placeholder fields.
- Added focused testthat negative-path checks for missing shard manifests,
  missing cell outputs, count mismatches, and duplicate computed cell IDs using
  tempdir shard copies.
- Updated mission-control validation, dashboard README, status JSON, sweep
  JSON, executable-evidence ledger, and build marker `r59`.

## 3a. Decisions and Rejected Alternatives

This slice did not use DRAC. The useful work was local accounting hardening:
the aggregate gate needed to fail deterministically before we scale the
runner. A larger simulation sweep would have added runtime without improving
trust in the shard ledger.

The summary still uses `not_computed_two_shard_rehearsal` MCSE placeholders.
That is intentional. Four seed-scale cells are enough to test resumability and
aggregation, not interval reliability or coverage.

## 4. Files Touched

- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R`
- `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-derived-correlation-delta-grid-two-shard-rehearsal/aggregate/q4-derived-correlation-delta-grid-two_shard_rehearsal-aggregate-summary.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-executable-evidence.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-23-q4-derived-correlation-aggregate-hardening.md`
- `docs/dev-log/recovery-checkpoints/2026-06-23-082817-codex-checkpoint.md`

## 5. Checks Run

- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R --n-shards=2 --expected-cells=4 --expected-target-rows=24 --aggregate-label=two_shard_rehearsal`
  passed and regenerated the aggregate manifest and expanded summary.
- `air format tests/testthat/test-structured-re-conversion-contracts.R docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/aggregate-calibrated-grid-delta-shards.R`
  passed.
- `python3 tools/validate-mission-control.py` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1184 assertions.
- `Rscript tools/codex-checkpoint.R --goal "r59 q4 derived-correlation aggregate hardening" --next "Run a larger local or totoro shard rehearsal with the hardened aggregate gate; keep DRAC gated until local/totoro runtime is insufficient and keep SR150 blocked until calibrated denominator and coverage MCSE evidence exists."`
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-06-23-082817-codex-checkpoint.md`.

Full final validation, JSON checks, widget fetches, and diff checks are recorded
in the current check-log entry.

## 6. Tests of the Tests

The focused R contract test now executes the aggregate script against temporary
copies of the shard ledger and requires failure for:

- a missing shard manifest;
- a missing cell output file;
- an expected-cell count mismatch;
- a duplicate computed `cell_id`.

The dashboard validator now requires target-level denominator fields,
failure/warning/boundary-clamp rates, MCSE placeholders, and the expected
boundary-clamp counts in the aggregate summary.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on.

## 8. Consistency Audit

This is aggregate race-safety and denominator-accounting evidence only. It does
not promote q4 interval reliability, interval coverage, q4 REML, native-TMB q4
REML, HSquared AI-REML, non-Gaussian AI-REML, broad bridge support, DRAC
readiness, SR150 unblocking, a commit, a PR, or an Ayumi-facing reply.

## 9. What Did Not Go Smoothly

The negative-path test first failed because the subprocess helper did not quote
the script path under `Github Local`. The aggregate script now accepts
`--repo-root`, and the test helper derives that root from `DESCRIPTION` rather
than from `getwd()`, which can differ under `devtools::test()`.

The count-mismatch test also exposed status-precedence drift:
`aggregate_resume_not_verified` was overwriting structural count failures. The
aggregate script now lets count and duplicate failures take precedence.

## 10. Known Residuals

The next useful rung is a larger local or `totoro` rehearsal using the hardened
aggregate gate. DRAC should still wait until the local or `totoro` route is too
slow for the evidence gate.

## 11. Team Learning

Grace should treat aggregate scripts like parsers: every structural assumption
needs a negative-path test. Curie should keep MCSE placeholders explicit until
replicate counts are calibrated. Rose should keep SR150 blocked until the
calibrated denominator and coverage evidence exists.
