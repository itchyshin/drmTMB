# After Task: NB2 animal supplied-covariance SD regression

## 1. Goal

Check whether predictor-dependent SD for an NB2 animal intercept preserves labels and gives equivalent fitted results when the same covariance is supplied directly as `A` or through its pedigree representation.

## 2. Implemented

No production code changed. The focused test now binds the pedigree as a formula-visible object and compares it with the direct covariance-matrix route.

## 3a. Decisions and Rejected Alternatives

Keep this as one narrow provider-equivalence receipt. Do not promote other animal structures, NB2 endpoints, or engine parity from this test.

## 4. Files Touched

- `tests/testthat/test-nbinom2-animal-sd-regression.R` adds the supplied-`A` versus pedigree comparison and uses a named `pedigree` object in the structured formula.
- `docs/dev-log/general-sd-regression/inventory.md` records the exact evidence boundary.
- `docs/dev-log/check-log.d/2026-10-22-nbinom2-animal-A-direct-sd.md` records the command, result and source binding.
- This report records the slice and limits.

## 5. Checks Run

- `NOT_CRAN=true Rscript -e 'devtools::load_all(".", quiet = TRUE); testthat::test_file("tests/testthat/test-nbinom2-animal-sd-regression.R")'`: passed, 16 assertions, no failures, warnings or skips.
- The first direct `test_file()` invocation did not load the package and failed before model evaluation. Loading the package before the second invocation allowed the test to run.
- Candidate HEADs and relevant source hashes are recorded in the check log. Both candidate worktrees are dirty.

## 6. Tests of the Tests

The comparison would fail if either fit failed to converge, SD coefficient vectors differed, log likelihoods differed, or returned SD predictions lost/misassigned the animal labels. The shared fixture intentionally uses a nontrivial label ordering for the supplied covariance.

## 7a. Issue Ledger

No GitHub issue was changed. No issue lookup was performed for this bounded local test slice.

## 8. Consistency Audit

The inventory now distinguishes this supplied-matrix provider comparison from the existing pedigree recovery evidence. The row remains narrow and does not claim Julia parity or calibrated uncertainty.

## 9. What Did Not Go Smoothly

The first focused test command used an unsupported `filter` argument, then a direct test-file run omitted package loading. Both were corrected before the passing run; neither is counted as a model failure.

## 10. Known Residuals

This test does not establish NB2 animal slope or correlated-block support, Julia parity, interval calibration, or behavior for unrelated covariance providers. No production likelihood or formula parser code was changed.

## 11. Team Learning

For structured formulas, provider objects must be bound to named symbols in the evaluation environment; fixture member access inside the formula is not accepted by the parser. Focused test-file runs also need package loading when invoked outside `devtools::test()`.

## 12. Cross-Product Coverage

The exercised cell is native TMB, NB2 `mu`, q1 animal intercept, predictor-dependent SD, supplied covariance `A` compared with its equivalent pedigree input, one independent synthetic fixture. This test does NOT cover Julia, interval calibration, animal slopes, correlated blocks, other NB2 endpoints, or other covariance providers. No broader cross-product row is closed.
