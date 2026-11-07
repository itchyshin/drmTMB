# After Task: Bernoulli Stage-Two Current-Source Review

## 1. Goal

Bind the post-v8 stage-two adapter and its tests to an exact source snapshot, run no-fit integrity checks, and obtain independent review before considering more qualification work.

## 2. Implemented

Recorded a 17-file SHA-256 manifest for all current `.py`, `.R`, and `.md` files in the adapter directory. The independent reviewer rehashed all 17 files against the manifest, checked the manifest digest and JSON receipt, and confirmed the recorded HEAD. The source-snapshot review gate passes.

## 3a. Decisions and Rejected Alternatives

No statistical model, interval, threshold, or staged decision rule changed. The combiner status change preserves outputs for nonqualifying outcomes and returns a nonzero status unless the analyzer reports `accept`, `fail`, or `inconclusive`. No campaign was relaunched because the v8 throughput contradicts the prior runtime projection.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-current-source-audit-20261019/adapter-source-hashes.csv`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-current-source-audit-20261019/adapter-source-hashes.sha256`
- `docs/dev-log/general-sd-regression/evidence/calibration-20261017/stage-two-current-source-audit-20261019/source-audit.json`
- `docs/dev-log/check-log.d/2026-10-19-stage-two-current-source-review.md`
- This report

## 5. Checks Run

- `python3 -m unittest tools.general-sd-regression.native-calibration-stage-two.test_stage_two`: 29 tests passed.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: passed with `STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12`.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-prior-seeds.R tools/general-sd-regression/native-calibration-stage-two`: passed with `PRIOR_SEED_STREAM_NEGATIVES_PASS streams=3`.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-verify-first-look-registry.R tools/general-sd-regression/native-calibration-stage-two`: copied-manifest registry and tamper guard passed.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R tools/general-sd-regression/native-calibration-stage-two`: passed with `STAGE_TWO_COMBINE_SUBPROCESS_PASS no_fits=TRUE injected_analyzer=TRUE status=1`. The subprocess warning reflects the deliberately injected nonqualifying status.
- Independent snapshot readback: `ADAPTER_SOURCE_MANIFEST_READBACK_PASS rows=17 sha256=d9c1d9e7a071ab666c304d6aa46ac494d2ba710e7ab841f824b0f8d44d394e23`.
- Independent inference review: passed the exact current source snapshot review gate; all 17 source hashes, the manifest digest, JSON receipt, and HEAD matched.
- `git diff --check`: passed after the report and check-log additions.
- `python3 /Users/z3437171/shinichi-brain/tools/slop_check.py <absolute report path> <absolute check-log shard path>`: `FINDINGS: 0`.
- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R <absolute report path>`: report structure passed. The subsequent acceptance-ledger re-verification produced no output for more than one minute and was interrupted; it returned no ledger verdict, so no gate status is claimed from that step.

## 6. Tests of the Tests

The Python suite includes mapping, identity, and integrity-negative controls. The R suites check prior-stream and registry tampering. The combiner test launches no model fits, injects an impossible `integrity_failure`, and checks that outputs remain available while the subprocess exits nonzero with a nonqualifying marker. It does not test the statistical analyzer or interval calibration.

## 7a. Issue Ledger

No issue was changed. The recent read-only search found only broad phase or test-sweep issues (#59, #61, and #1463), with no specific adapter execution issue to update.

## 8. Consistency Audit

The source manifest includes all current adapter source and test documents, excludes generated Python bytecode, and binds the live worktree at HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`. The v7 qualification and v8 runtime records remain historical snapshots. This report and the check-log shard distinguish source review from operational qualification and calibration. No public API or package support statement changed.

## 9. What Did Not Go Smoothly

The synthetic combiner test took longer than expected because it replays 3,000 retained first-look records and validates three full manifests. It completed successfully and emitted a warning for the deliberately nonzero subprocess result.

## 10. Known Residuals

This closes source-snapshot review only. The current adapter still needs operational qualification and a fresh runtime assessment. The v8 run stopped incomplete after 531.969 seconds; its observed throughput contradicts the earlier 7,956-second projection. No Bernoulli interval-calibration result or current 9,000-fit authorization exists. Programme gates G0-G8 remain open.

## 11. Team Learning

Post-run evidence changes need a new source manifest even when they affect only decision-status handling. Hash source and tests together, keep generated Python bytecode out of the snapshot, and require independent readback before treating the seal as current.

## 12. Cross-Product Coverage

Covers: the current source and test snapshot for the Bernoulli stage-two adapter, plus its nonqualifying combiner process status.

Does NOT cover: any package fitting capability, Bernoulli recovery, calibrated interval coverage, the current adapter's three-fit operational qualification, a fresh runtime projection, or completion of the 9,000-attempt second look. It does not cover Julia parity, other response families, random-effect types, distributional endpoints, or any cross-engine capability row.

Next action: use this reviewed source snapshot for bounded qualification and fresh runtime measurement, then seek specific approval before any campaign whose projection exceeds three hours.

Use the source-reviewed adapter snapshot for a bounded current-source qualification only after confirming the exact prepared-library and registry bindings. Re-estimate campaign runtime from fresh evidence. If the new campaign projection exceeds three hours, present the pre-run design and results for approval before launch.
