# After Task: Nonqualifying Stage-Two Decisions Cannot Report Completion

## 1. Goal

Make the second-look combiner distinguish a finished analysis from a nonqualifying staged decision. This is a calibration-harness integrity fix; it does not qualify the Bernoulli uncertainty procedure.

## 2. Implemented

The combiner now reports successful completion only for `accept`, `fail`, or `inconclusive`. It retains the decision receipt for other states, prints a nonqualifying marker, and exits nonzero.

## 3. Mathematical Contract

The frozen look-two analyzer has three terminal analytical outcomes: `accept`, `fail`, and `inconclusive`. Operational or evidence-integrity states such as `incomplete` and `integrity_failure` must not be represented as a completed analysis. This change does not alter the analyzer, thresholds, or statistical decision rules.

## 3a. Decisions and Rejected Alternatives

Keep the analyzer unchanged and enforce its existing three-outcome contract at the combiner boundary. Retain the receipt for a nonqualifying result, but return a nonzero process status. Do not treat a failed statistical decision (`fail`) as an execution failure; it is a completed analysis.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R`
- `tools/general-sd-regression/native-calibration-stage-two/combine-stage-two.R`
- `tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R`
- `tools/general-sd-regression/native-calibration-stage-two/README.md`
- `docs/dev-log/check-log.md`
- This report

## 5. Checks Run

- Red test: `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two` failed because the completion-status helper was absent.
- Green test: the same R rules command passed and printed `STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12`.
- `python3 tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`: 29 tests passed in 9.123 seconds.
- `git diff --check -- tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two/combine-stage-two.R tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R`: passed.
- The after-task structure checker passed. The prose checker reported zero findings (633 words; no em dashes).
- No fits, remote compute, or calibration campaign was run.

## 6. Tests of the Tests

The assertions exercise the production marker-emission helper for a valid and nonqualifying outcome, check its printed marker and exit status, and cover the full three-outcome allowlist plus `incomplete`, `integrity_failure`, and an unknown value. The test failed before implementation because the helper was absent, then caught the marker's trailing-space defect before passing. A later no-fit subprocess test invokes the actual combiner with sealed synthetic inputs and a test-only analyzer stub that injects an impossible `integrity_failure`; it verifies a nonzero child exit and retained receipt. This validates defensive process-boundary behavior only, not analyzer behavior or statistical calibration.

## 8. Consistency Audit

Updated the adapter README to define the marker and exit-status behavior. No model formula, likelihood, family claim, public API, or package vignette changed. The exact inventory scan `rg "STAGE_TWO_COMBINE_COMPLETE|STAGE_TWO_COMBINE_NONQUALIFYING|integrity_failure|incomplete" tools/general-sd-regression/native-calibration-stage-two` was reviewed; the protocol description and implementation now agree. No navigation update is needed.

## 7a. Issue Ledger

No issue was changed. The open-issue search surfaced #59, a broad simulation-framework issue, and #1007, a separate calibration reconciler defect. Neither tracks this stage-two combiner status contract, so no issue update was warranted.

## 9. What Did Not Go Smoothly

The first lane-preflight path named a `.py` file, while the actual combiner is `combine-stage-two.R`. The corrected path preflight confirmed the file is absent from other refs. The test first failed because the helper was missing, then caught an extra trailing space in the marker. Both failures were fixed before the passing run.

## 11. Team Learning

Campaign completion markers should be driven by an explicit allowlist of terminal analytical outcomes, not printed unconditionally after receipt creation. A receipt can preserve a failed decision without treating the run as successful.

## Follow-up verification (2026-10-18)

`Rscript tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R` passed against the final test file, printing `STAGE_TWO_COMBINE_SUBPROCESS_PASS no_fits=TRUE injected_analyzer=TRUE status=1`; the wrapper exited 0 and the child status 1 was expected. The R rules test passed, as did all 29 Python stage-two tests. No model fits, remote compute, or calibration campaign ran. The injected analyzer result is deliberately impossible under the real analyzer and must not be counted as statistical evidence.

## 10. Known Residuals

The subprocess test exercises the full command-line combiner with sealed, real-shaped no-fit inputs, but injects an impossible analyzer result; it does not validate the analyzer's statistical behavior. Missing adversarial tests for forged replay artifacts, batch-supervisor failure ordering, owned-child cleanup, and external-seal mutation remain open. Fresh source-bound qualification and runtime evidence remain required before any calibration launch. The prior v8 partial run remains nonqualifying.

## 12. Cross-Product Coverage

This change is limited to the internal R calibration harness and its R rules test. It does NOT cover model fitting, package APIs, likelihoods, Julia, other response families, random-effect types, or uncertainty calibration. No fits or calibration runs were performed.

## Next Actions

Add no-fit integration tests for the real replay and batch-runner gates, then obtain an independent source review. Do not launch the calibration campaign until qualification, timing, and the existing approval gate are satisfied.
