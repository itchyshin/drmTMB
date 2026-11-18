# After Task: Native Binomial crossed intercept SD regression

## 1. Goal

Verify predictor-dependent SDs for two crossed independent Binomial intercepts under probit and complementary log-log links.

## 2. Implemented

Added a fixed-seed synthetic test with separate SD formulas for each grouping factor. The two link fits check convergence, signed broad recovery bounds for both SD slopes, named group SD predictions, and binary marginal simulation. No model-builder or likelihood change was required for this evidence slice.

## 3a. Decisions and Rejected Alternatives

Kept each intercept as an independent q1 field, matching the existing crossed random-effects structure. This test does not turn the two terms into a correlated block. Interval-coverage validation remains deferred under the approved implementation-first scope.

## 4. Files Touched

- `tests/testthat/test-binomial-crossed-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-crossed-nonlogit-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- This after-task report and paired check log.

## 5. Checks Run

- Focused test: 18 expectations passed for probit and cloglog, with no failures or warnings.
- Evidence reconciliation passed: 19,678 candidate rows, 149 linked rows, 19,529 unlinked rows, and 169 records.
- The source manifest pins the R builder, TMB objective, and test source; the test transcript is retained.
- No full R suite, full pkgdown build, live Julia run, or interval-coverage campaign was run.

## 6. Tests of the Tests

Each link uses a different response generated from two independently sampled crossed group intercepts. The assertions would detect fitting failure, wrong sign or broad recovery for either SD slope, misnamed predictions, and invalid binary simulation output.

## 7a. Issue Ledger

No GitHub issue was changed. The crossed intercept candidate rows for probit and cloglog now have hash-verified recovery records; both remain unreviewed.

## 8. Consistency Audit

The DGP and formula use two additive independent intercept fields, each with its own group-constant SD predictor. This evidence applies to the exact crossed q1 layout and the two tested links.

## 9. What Did Not Go Smoothly

No fit or harness error occurred in the focused run. The shared lane census remains busy, so the new test and evidence paths were isolated and leased before writing.

## 10. Known Residuals

This is one seed per link, not a recovery grid or uncertainty-calibration result. It does not cover nested terms, correlated blocks, Julia parity, or other response families. The broader goal remains active.

## 11. Team Learning

For additive q1 effects, simulate each crossed field independently and keep each SD predictor constant within its own grouping factor. Test all public target names and simulation output along with coefficient recovery.

## 12. Cross-Product Coverage

- Family: Bernoulli/Binomial.
- Engine: native R/TMB.
- Endpoint: `mu`.
- Links: probit and complementary log-log.
- Effects: two crossed independent iid intercepts, each with predictor-dependent SD.
- Data: synthetic with fixed seeds.
- This slice does NOT cover nested layouts, correlated blocks, Julia, interval coverage, or other families.
