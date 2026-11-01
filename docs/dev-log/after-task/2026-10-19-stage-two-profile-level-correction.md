# After Task: Restore the Approved 95% Profile Interval Contract

## 1. Goal

Align the Bernoulli calibration worker, stage-two adapters, tests, and current contract with the approved distinction between 95% fitted profile intervals and 97.5% Monte Carlo intervals across two looks.

## 2. Implemented

Added a separately versioned first-look chain: `prepare-095.R`, `worker-095.R`, `summarize-095.R`, `summarize-timing-095.R`, and `run-095.py`. It requests 95% profile intervals, records the returned confidence level in every result row, and rejects any returned level other than 0.95. Updated stage-two and adapter-qualification paths to pin and invoke that worker. Their result validators now require `profile_level = 0.95`. Updated the current calibration contract and stage-two notes to classify the earlier 97.5%-profile experiment as historical exploratory evidence that cannot authorize another look.

## 3a. Decisions and Rejected Alternatives

The approved design uses 95% fitted profile intervals. The repeated-look analyzer uses two-sided 97.5% Monte Carlo confidence intervals to spend alpha across its two planned looks. These are separate uncertainty layers. The previous interpretation conflated them. The earlier 97.5% worker and its result artifacts remain unchanged for traceability.

## 4. Files Touched

- Added `tools/general-sd-regression/native-calibration/prepare-095.R`, `worker-095.R`, `summarize-095.R`, `summarize-timing-095.R`, `test-summarize-timing-095.R`, and `run-095.py` as a distinct, source-pinned 95% first-look path.
- Updated `tools/general-sd-regression/native-calibration-stage-two/stage-two-rules.R`, `stage_two.py`, `run-adapter-qualification.py`, and their R/Python tests to require 95% profile intervals and use the new worker.
- Updated `docs/dev-log/general-sd-regression/staged-calibration-contract.md`, `docs/dev-log/general-sd-regression/stage-two-execution-design.md`, and the stage-two README to clarify the confidence-level distinction and invalidate the earlier look-two trigger.
- Updated `tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R` to describe the retained fixture as a legacy 97.5% fitted-interval fixture.
- Appended check evidence to `docs/dev-log/check-log.md`.

## 5. Checks Run

- Before the implementation change, the revised R rule test failed because the production validator still required 97.5%. This confirmed the test caught the contract mismatch.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two` passed with `STAGE_TWO_R_RULES_PASS`.
- `Rscript tools/general-sd-regression/native-calibration/test-summarize-timing-095.R` passed its synthetic 45-attempt timing and tamper checks.
- `python3 -m unittest tools.general-sd-regression.native-calibration-stage-two.test_stage_two` passed all 31 tests.
- `git diff --check` passed for the worker, stage-two adapters, and contract documents.
- The no-fit combiner regression test was started twice but did not finish within the observed local wait; both runs were stopped. It is recorded as unverified, not passing.
- No fitted calibration campaign or remote compute ran. Totoro remains occupied by the paired DRM.jl lane.

## 6. Tests of the Tests

The tests were first changed to accept 0.95 and reject 0.975. The R test failed against the old validator, then passed after the implementation update. Python tests check both accepted worker identity and rejection of a result row with the wrong profile level. The combiner regression remains pending because its full 3,000-row fixture did not complete in the available local run.

## 7a. Issue Ledger

No GitHub issue was changed. This task corrects the internal calibration contract and source-pinned adapter inside the active implementation programme; no linked public issue was identified during this bounded change.

## 8. Consistency Audit

The worker, first-look runner and summarizer, stage-two validators, source registries, and current calibration contract now agree on a 0.95 fitted interval. The staged Monte Carlo interval calculations remain at 97.5%. The prior 0.975 worker and result evidence remain intact and are explicitly described as historical. The first look still requires a fresh 95% run and complete replay before a later look is eligible. Existing multi-lane files outside this slice were preserved.

## 9. What Did Not Go Smoothly

The no-fit combiner test did not complete within the interactive wait. Its fixture includes 3,000 retained result files and a subprocess replay, so the runtime may be dominated by filesystem hashing or subprocess startup. The test needs a bounded timing diagnosis before it can serve as a routine local check.

## 10. Known Residuals

No new 95% first-look fits have run, and there is no corrected calibration result. The new 95% first-look chain has received syntax and timing-summary contract checks, but no production capsule or fit has run; no prepared capsule or fit has run. The first-look replay fixture and the large combiner regression need verification against it. The broader programme still has open Julia live parity, other family/type coverage, uncertainty calibration, and NotebookLM methods review.

## 11. Team Learning

Keep the fitted-interval confidence level explicit in the source contract and validate the returned interval metadata, while separately recording the confidence level used by repeated-look Monte Carlo calculations. A historical decision receipt cannot carry forward after the statistical contract changes.

## 12. Cross-Product Coverage

This slice does NOT cover completion of the Bernoulli calibration gate or the wider random-effect SD programme. It corrects the profile-level implementation and stage-two validation contract. A fresh 95% first look, verified replay, completed combiner test, calibrated uncertainty results, live Julia fitting, and remaining family/type rows are outstanding.
