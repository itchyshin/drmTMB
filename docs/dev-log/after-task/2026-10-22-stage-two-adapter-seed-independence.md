# After Task: Reject Reused Look-Two Adapter Seeds

## 1. Goal

Prevent operational qualification fits from selecting observations that are later counted in Bernoulli look-two calibration.

## 2. Implemented

The clean-current adapter resolver and qualification receipt validator now reject the existing fitted-probe route. Its probes use look-two rows 1, 4001, and 8001, and the qualification runner accepts them only when fit-health checks pass. Those seeds are also part of the 9,000-attempt calibration denominator. The look-two manifest remains unchanged.

## 3a. Decisions and Rejected Alternatives

Operational checks that condition on fit health must use seeds independent of the calibration denominator. Calibration attempts retain the frozen planned denominator and are not screened by a prior qualification result on the same observations. Keep the frozen look-two manifest unchanged. Reject its three-row reuse path until a source-bound qualification uses a disjoint stream.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`
- `tools/general-sd-regression/native-calibration-stage-two/README.md`
- `docs/dev-log/general-sd-regression/staged-calibration-contract.md`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- The new resolver regression test failed before the guard because no `ValueError` was raised.
- `python3 tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`: 58 tests passed in 112.561 seconds.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: `STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12`.
- The slow no-fit 12,000-row combine test passed alone in 71.355 seconds. An earlier full-suite attempt hit its embedded deadline; the later full suite passed.
- No model fits, calibration jobs, or remote runs were launched.

## 6. Tests of the Tests

The added test was observed failing before implementation and passing afterward. The runner test verifies that a prepared clean-current qualification is rejected before it can write a qualification receipt. Receipt validation separately rejects a stale clean-current PASS.

## 7a. Issue Ledger

`gh issue list --state open --search "Bernoulli SD calibration adapter seeds" --limit 10` returned no matching issues. No issue was opened or changed.

## 8. Consistency Audit

The adapter README and staged-calibration contract now describe the shared-seed problem and the fail-closed behavior. The programme ledger keeps G5 open. The former row-mapping test is labeled as identity mapping only, not evidence of independent qualification. The separate `timing.csv` stream is recorded as a candidate source, not as a qualified replacement.

## 9. What Did Not Go Smoothly

The first full test run had one embedded combine-deadline failure. The same case passed by itself and the complete suite passed on rerun, so this did not require a source change.

## 10. Known Residuals

The clean-current adapter qualification path is intentionally unavailable until an independent seed stream and matching source-bound runner are implemented. The existing 45-row timing stream has not been requalified against the exact worker and installed library. Look two remains unauthorized, and no coverage claim is supported.

## 11. Team Learning

Source identity and disjointness checks must cover operational qualification data as well as the main calibration manifest. A fit-free mapping test cannot qualify a fit-bearing route.

## 12. Cross-Product Coverage

This task covers a calibration-harness safety correction. It does NOT cover independent adapter qualification, look-two calibration, interval-coverage acceptance, other response families, structured-effect calibration, Julia calibration, or programme-wide implementation and documentation gates. Next, design a separately hashed, seed-disjoint qualification manifest and runner, then verify its exact-source fit and runtime receipts before reconsidering look two.
