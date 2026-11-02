# After Task: Current-Source Tweedie Related-Matrix Bridge Recheck

## 1. Goal

Recheck one existing Julia and native TMB Tweedie related-matrix SD comparison after the Julia family source changed since the previous receipt.

## 2. Implemented

No model code changed. The current-source bridge test passed 24 expectations with one live Julia bridge fit. A new source manifest covers 199 files in both candidate worktrees. The previous receipt remains historical because its Julia Tweedie source digest did not match the current file.

## 3a. Decisions and Rejected Alternatives

I reran the existing bridge test instead of changing the likelihood or adding a duplicate test. The run note records streamed output and the exact process exit; it does not pretend to be a raw redirected console log.

## 3b. Mathematical Contract

The SD formula estimates the coefficient-SD multiplier in `D K D`. The reported marginal SD includes the supplied kernel diagonal. The test uses one q1 mean intercept and a non-unit, label-permuted relatedness matrix.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-current-v3/receipt.json`
- `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-current-v3/source-manifest.json`
- `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-current-v3/run-note.txt`
- `docs/dev-log/check-log.d/2026-10-23-tweedie-relmat-bridge-source-recheck.md`
- This report.

## 5. Checks Run

- Julia-only `test/test_tweedie_relmat_sd_regression.jl`: 55/55 assertions passed across the regression testsets.
- Julia-only `test/test_tweedie_relmat_sd_validation.jl`: 14/14 assertions passed.
- R bridge `devtools::test(filter = "julia-tweedie-relmat-sd", reporter = "summary", stop_on_failure = TRUE)`: exit 0; 24 expectations passed, one configured live-Julia setup check skipped, and one live bridge test ran.
- `git diff --check` on the Julia Tweedie source and focused test files passed.
- Source manifest SHA-256: `650bdd7437f6cb397f3b6492b9f5d3095a50fc1dfe332615bef6a934dc069617`. It records native head `425bee81572c625a634b2b083050c5c57c1dc1f1` and Julia head `70dbf564eb670144c63c08f61ea099084d95add2`.
- The `lane_preflight.sh` check for shared `docs/dev-log/check-log.md` did not complete after 26 seconds and was stopped. The central index was left unchanged; the per-check receipt and this report are new files.

## 6. Tests of the Tests

The existing bridge test exercises the public R-to-Julia path, the same synthetic response and kernel in both engines, fitted SD coefficients, group predictions, public parameter output, and log likelihood. This recheck did not add a new assertion or repeat the test's original red phase.

## 7a. Issue Ledger

A read-only search for open issues matching “Tweedie related-matrix SD” returned no matching feature issue. No issue was created, edited, or closed because this task refreshed evidence for an existing route.

## 8. Consistency Audit

The route and tests still describe a Tweedie related-matrix mean-intercept SD fit. The earlier independent Julia regression and native TMB test remain separate evidence. The new manifest pins current Julia `src/tweedie.jl` at `8f83de17f26784928197593f5c6a602e075e5dc3640f4679ee7d4da55d33462a`. No model behavior, public docs, or support claims changed. The central check-log index was not edited because its ownership preflight did not return a file verdict.

## 9. What Did Not Go Smoothly

The first direct Julia command could not find Julia on `PATH`; the rerun used the installed Juliaup path. The live R bridge fit took about ten minutes. The ownership preflight for the shared central check log hung before producing a file verdict, so that shared file was not edited.

## 10. Known Residuals

This evidence covers one complete-response Tweedie q1 related-matrix location-intercept comparison. It does not establish broad family or effect parity, all public output and refit surfaces, independent likelihood accuracy, or calibrated uncertainty. The wider programme remains active.

## 11. Team Learning

For dirty candidate worktrees, branch heads alone do not pin the tested code. Compare the exact source manifest with the prior receipt and rerun affected behavior when a digest changes.

## 12. Cross-Product Coverage

The tested cross-product cell is Tweedie location, q1 related-matrix intercept, supplied label-permuted non-unit-diagonal K, one group-level SD predictor, and native R/TMB plus Julia fits on identical synthetic data. It does not cover other families, providers, random-effect types, endpoints, block structures, all public output/refit workflows, or calibrated uncertainty. Continue closing the remaining required cells; keep the calibration gate open until the agreed validation phase passes.
