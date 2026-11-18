# After Task: Julia Bernoulli Phylogenetic SD Parameter Predictions

## 1. Goal

Check that the Julia fit object exposes predictor-dependent phylogenetic SDs through the public `predict_parameters()` interface, including reordered new data.

## 2. Implemented

Extended the mock-backed Bernoulli phylogenetic SD bridge test to assert the public dpar label, training-data estimates, and estimates and species labels for reordered new data. No production code changed.

### Mathematical Contract

For the fitted SD design row (w_g), the public prediction is `exp(w_g %*% alpha)`. This test checks the reported value and its row-to-species alignment; it does not establish interval calibration or live Julia fitting.

## 3a. Decisions and Rejected Alternatives

The public prediction path already returned the expected values, so this slice adds regression coverage without changing production code. The test keeps target-label and row-alignment assertions separate from numeric equality.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-phylo-sd.R`
- `docs/dev-log/after-task/2026-10-19-julia-binomial-phylo-predict-parameters.md`

## 5. Checks Run

- Focused `testthat::test_file("tests/testthat/test-julia-binomial-phylo-sd.R")`: passed, 10 expectations; the live Julia test was skipped because neither `DRMODELS_JL_PATH` nor `DRM_JL_PATH` was set.
- `git diff --check` on tracked files: passed. The new test file is untracked in this candidate worktree, so that command did not inspect it.
- The exact test file was reviewed and the assertions compare numeric values without requiring names that the public table does not promise.

## 6. Tests of the Tests

The original run failed only because the expected vector retained names absent from the public result. The assertion was corrected to compare unnamed numeric values, and the full focused file then passed. The test checks both training output and an explicitly reordered new-data case, including factor-label alignment.

## 7a. Issue Ledger

No issue was opened, updated, or closed. This test-only slice does not change a support claim or resolve an issue; issue reconciliation remains part of programme closeout.

## 8. Consistency Audit

The assertions follow the existing public dpar label `sd_phylo(species)` and do not change the formula grammar or fitted model. The existing live Julia bridge report remains separate evidence for fitting and direct prediction; it does not prove this new `predict_parameters()` path on a live Julia fit. No broader status-inventory wording or navigation changed.

## 9. What Did Not Go Smoothly

The first equality assertion incorrectly required vector names that the returned table does not preserve. The values and order were otherwise correct.

## 10. Known Residuals

The test uses a mock `drmTMB_julia` object because live Julia was unavailable in this run. The shared check log was not edited: preflight found extensive divergent edits on other refs, and the incoming diff contains independent additions at the end of that append-only file. The report records this bounded test result but does not close any programme gate.

## 11. Team Learning

For table-returning public prediction methods, assert target labels and row alignment separately from numeric values. Avoid inheriting incidental names from the internal design vector.

## 12. Cross-Product Coverage

This test covers the Bernoulli phylogenetic random-intercept SD target through a mocked Julia fit object and the R public prediction method. It does NOT cover a live Julia fit, another family, effect type, parameter endpoint, or uncertainty method.

## Next Actions

Run this assertion against a live Julia Bernoulli phylogenetic fit when the paired engine path is available, then continue the cross-family and cross-effect capability ledger.
