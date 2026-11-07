# After Task: Clean-Current Worker Receipt

## 1. Goal

Make each clean-current Bernoulli look-two batch receipt pass the frozen production worker contract before any model fit starts.

## 2. Implemented

Added a shared receipt builder for the clean-current look-two contract and wired stage-two preparation to use it. It records the 95% profile level, calibration flag, seed stream, frozen manifest digest, and batch identity required by the worker. One no-fit test now runs the positive Python preparation CLI, dispatches the prepared batches through `run_batches()`, and passes that exact root to the full R combiner CLI. The 12,000-attempt output preserves all clean-current source indices and marks second-look-only provenance as missing for first-look rows. This end-to-end test exposed and fixed a column mismatch when first- and second-look attempts were combined. The legacy preparation branch remains unchanged.

## 3a. Decisions and Rejected Alternatives

I used the production runner's `validate_design()` as the oracle, so the test exercises the worker contract instead of checking for expected strings alone. Assumption: the frozen worker fields and manifest hash remain the source of truth for all three batches. If the contract changes, update the shared builder and its tests with the worker.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/prepare-stage-two.py`
- `tools/general-sd-regression/native-calibration-stage-two/combine-stage-two.R`
- `tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R`
- `docs/dev-log/after-task/2026-10-20-clean-current-worker-receipt.md`
- `docs/dev-log/check-log.d/2026-10-20-clean-current-worker-receipt.md`

## 5. Checks Run

- Focused Python stage-two suite: PASS, 43 tests, including preparation CLI, no-fit runner dispatch, and full R combination of that exact prepared root.
- R stage-two rules: PASS, `STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12`.
- R combiner test: PASS, including the expected legacy replay rejection and `STAGE_TWO_CLEAN_CURRENT_FULL_COMBINE_PASS no_fits=TRUE attempts=12000`.
- Python byte compilation: PASS for `stage_two.py`, `prepare-stage-two.py`, and `test_stage_two.py`.
- `git diff --check`: PASS.
- After-task prose check: PASS, 0 findings; structural check: PASS. The acceptance-ledger checker returns nonzero because the programme's 12 gates remain open.
- No model fits, calibration campaign, Totoro job, or DRAC job ran.

## 6. Tests of the Tests

The receipt-construction test passes all three frozen batch manifests through the production runner's `validate_design()` function and confirms that batch 4 and an incorrect frozen manifest digest are rejected. The end-to-end test prepares a synthetic sealed first look, runs Python preparation and the real `run_batches()` validations with a terminal-error supervisor, and then invokes the full R combiner CLI against those exact outputs. External authorization and replay checks are stubbed, but both Python and R verify the generated manifests and receipts. The R output contains 12,000 attempts with source indices 1:9000 for the second look and missing second-look-only metadata for the first look. The first full CLI attempt exposed the real row-bind mismatch; typed column alignment fixed it.

## 7a. Issue Ledger

No GitHub issue was changed. I searched open issues for `Bernoulli calibration` and `random-effect SD regression`; the matches concern broader programme work and do not track this receipt defect. This fix does not close the Bernoulli calibration gate.

## 8. Consistency Audit

Checked the prepared receipt fields against `native-calibration/run-095.py` and `native-calibration/worker-095.R`. One test now covers the exact Python preparation → runner → R combiner path and checks complete decision-file generation. The separate R fixture still covers legacy replay rejection and positive clean-current output. The end-to-end runner records errors for every second-look case, so it verifies only identity, receipt, and combination plumbing, not likelihood fits or calibration.

## 9. What Did Not Go Smoothly

The first direct invocation of the R rules script omitted its required adapter-directory argument and stopped before testing. Re-running it with the directory passed completed successfully. The initial direct Python test selection lacked the shared fixture setup. The first positive R full-combiner run exposed a genuine schema mismatch at `rbind(first_attempts, second)`; after aligning the two frames with typed missing values, the 12,000-row combine completed. The first exact-root run then caught a test assertion that treated serialized `NA` values as empty CSV cells; the assertion now checks R's actual `NA` representation.

## 10. Known Residuals

These checks verify preparation receipt construction, no-fit runner dispatch, and the full R combination of the exact Python-generated root. External GO, binary, and replay verification are stubbed, and every synthetic second-look worker case ends in error by design. They prove cross-language file, receipt, row-binding, and identity plumbing only. They do not prove model recovery, interval calibration, or readiness to launch a production second look. Programme gates G0 through G8 remain open.

## 11. Team Learning

Prepared simulation receipts should be tested through the production worker's validator. A syntactically complete receipt can still fail the worker's frozen design gate.

Memory receipt: the supplied drmTMB `AGENTS.md` and project after-task protocol guided this slice. `route.py` returned no LOAD-FIRST manifest for the worktree. Golden Set: not run because this task concerned adapter receipt metadata.

## 12. Cross-Product Coverage

Covered: native TMB Bernoulli ordinary-intercept look-two worker admission for the three frozen batches, including one Python preparation-to-run-to-full-R-combiner CLI path on synthetic no-fit records. This slice does NOT cover Julia, other response families, other random-effect types, interval calibration, or production campaign readiness.
