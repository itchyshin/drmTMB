# After Task: Portable clean-current stage-two combine test

## 1. Goal

Make the stage-two combiner regression test reproducible without files in a temporary directory that may have been deleted.

## 2. Implemented

The negative legacy-replay test now writes its own 3,000 metadata-only result rows. They intentionally omit `profile_level`, so the combiner must reject them before producing a combined result. These test rows are not fitted attempts or calibration evidence. The full clean-current combiner test still exercises three sealed batches of terminal errors without fitting.

## 3a. Decisions and Rejected Alternatives

Keep the test focused on the missing-profile-metadata rejection and clean-current identity mapping. Do not skip the test when historical files are absent, and do not fabricate fitted calibration evidence.

## 4. Files Touched

- `tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.d/2026-10-22-stage-two-combine-fixture.md`
- `docs/dev-log/after-task/2026-10-22-stage-two-combine-fixture.md`

## 5. Checks Run

- Before the repair, the focused R test failed because its 3,000 result-file symlinks pointed to missing `/private/tmp/drmtmb-first-look-complete-20261017/production-prepared` files.
- `python3 tools/general-sd-regression/native-calibration/self-test.py`: passed (`NATIVE_CALIBRATION_SELF_TEST_PASS`, integrity and DGP checks passed).
- `python3 tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`: 57 tests passed in 38.671 seconds.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-stage-two-rules.R tools/general-sd-regression/native-calibration-stage-two`: passed, including three clean-current mapping offsets.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-verify-first-look-registry.R`: passed, including copied-manifest tamper rejection.
- `Rscript tools/general-sd-regression/native-calibration-stage-two/test-combine-stage-two.R`: passed both the legacy metadata rejection and the 12,000-attempt clean-current combine test; the output states `no_fits=TRUE`.
- After-task report structure check passed using `check_after_task()`.
- `git diff --check -- .unlazy/general-sd-regression/GATES.md`: passed. Direct trailing-whitespace scan passed for the untracked test and documentation files.

## 6. Tests of the Tests

The added assertion first reproduced the broken fixture by requiring all result paths to exist as regular files. The repair generated local metadata-only CSVs; the test then reached and passed the intended `profile_level` rejection. It also passed the positive sealed clean-current mapping path.

## 7a. Issue Ledger

No GitHub issue was changed. This repairs an internal test fixture and does not change public model behavior. No calibration campaign was launched.

## 8. Consistency Audit

The test description now distinguishes synthetic metadata stubs from fitted attempts. The programme ledger records this harness evidence under G5, which remains open; the test establishes no interval calibration.

## 9. What Did Not Go Smoothly

The fixture had retained symlinks whose targets lived outside the repository in a temporary directory. The first local run stopped at the missing result file before it could test the intended rejection. The reported under-one-minute self-test estimate also ran for about 62 seconds, then passed.

## 10. Known Residuals

This repair does not authenticate a production run, authorize look two, establish interval coverage, or fix the existing inference evidence gaps. The full acceptance-ledger reverify was not run in this slice, so no programme-gate change is claimed.

## 11. Team Learning

Regression tests should generate small deterministic fixtures inside their temporary directory. They should not depend on large external attempt directories or ephemeral `/private/tmp` symlinks.

## 12. Cross-Product Coverage

This is a pure R/Python calibration-harness test repair. It does NOT cover fitted-model recovery, TMB or Julia calibration, other families, structured-effect calibration, model output parity, documentation rendering, or full programme gates.
