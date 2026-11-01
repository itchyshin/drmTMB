# After task: predict/marginal validator tests

## 1. Goal

Refresh the local PR #1606 candidate onto current `main`, verify its fit-free validator tests, and record the exact tested source without changing product code.

## 2. Implemented

Created worktree `/private/tmp/drmtmb-pr1606-current-main-20261022` on `codex/pr1606-current-main-20261022` from PR head `0e1a847ec3f89b105d1622791b2bc1b24ad806a9`, then merged `review/main` at `2fb93b768977330fc9939d86375c37329a539277`. The merge had no conflicts. Updated the check log and this report to identify local test results and remaining limits.

## 3a. Decisions and Rejected Alternatives

Kept the PR test-only. No production, API, or capability claim changed. This task did not authorize a push, review-state change, or merge on GitHub, so the candidate remains local and the PR remains draft.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-20-predict-marginal-validator-tests.md`
- `docs/dev-log/check-log.d/2026-10-22-predict-marginal-validator-tests.md`

The PR's added test file was unchanged by this refresh.

## 5. Checks Run

On merged source `a40b66c7905d92972ee7365fc63dcdaf1f0a29c9`, `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 R_PROFILE_USER=/dev/null Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-predict-marginal-parameter-validators.R")'` passed: 114 pass, 0 fail, 0 warnings, 0 skips. Debug compilation emitted 12 compiler warnings. `capability_ledger.py --check` passed with 31 generated outputs; C14 receipt equivalence passed with 3 eligible and 7 retained source-different receipts; `tools.tests.test_capability_ledger` passed all 81 tests; `git diff --check` passed. The report-only refresh changes no R or C++ source.

## 6. Tests of the Tests

The test file checks validator return values and errors, reserved output names, averaging scales, clamp-band flags, row-wise link standard errors, and unavailable-interval output. `predict_parameters_clamp_bent()` uses a minimal stand-in object; no model fit is constructed.

## 7a. Issue Ledger

PR #1606 has no linked issue. No issue state changed.

## 8. Consistency Audit

Spot-checked the assertions against the helper definitions in `R/predict-parameters.R` and `R/marginal-parameters.R`. The test-only change does not alter model or API design, so no design-doc or pkgdown update is needed.

## 9. What Did Not Go Smoothly

The debug build emitted 12 compiler warnings from existing sources and dependencies. They did not appear as testthat warnings. The local merge itself was conflict-free.

## 10. Known Residuals

The full package suite, `R CMD check`, and fit-dependent helper paths were not run. The earlier PR-head workflow run `39854055897` had four successful checks and two cancelled Ubuntu shards; it does not validate merged source `a40b66c`. No fresh exact-head CI exists because this candidate was not pushed.

## 11. Team Learning

Fit-free tests can check pure helper contracts without model fitting. Keep their report explicit about stand-ins and untested fit-dependent paths.

## 12. Cross-Product Coverage

This task does NOT cover model fitting, fit-dependent prediction helpers, the full package suite, `R CMD check`, GitHub CI for the merged candidate, or interval calibration. It makes no model-recovery or coverage claim.
