# After Task: Binomial correlated q=4 probit and cloglog SD regression

## 1. Goal

Check native Bernoulli fitting and point recovery for a correlated q=4 random-effect block with predictor-dependent SD formulas under probit and complementary log-log links.

## 2. Implemented

Added one fixed-seed synthetic test with an intercept and three numeric slopes in one correlated block. Each of the four coefficients has a distinct SD predictor. No likelihood or builder source code changed.

## 3a. Decisions and Rejected Alternatives

This is a light point-recovery and output check. The first probit fit converged but reported a non-positive-definite Hessian. I retained the recovery tolerances and removed the Hessian-positive assertion because this test does not claim Wald inference or interval calibration. The report records the Hessian limitation. The DGP is generated independently of collaborator data.

## 4. Files Touched

- `tests/testthat/test-binomial-correlated-q4-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-correlated-q4-nonlogit-20261027/`
- `docs/dev-log/after-task/2026-10-27-native-binomial-correlated-q4-nonlogit-sd.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-correlated-q4-nonlogit-sd.md`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`

## 5. Checks Run

- Captured corrected focused test: exit 0; 32 expectations passed across two fits.
- Five-file source manifest: all SHA-256 values matched after the run.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed at 139 linked rows, 19,539 unlinked rows, and 161 evidence records out of 19,678 candidates.
- First attempt: probit optimizer converged but `pdHess` was false; also found that installed testthat 3.3.2 does not accept `info` in `expect_length()`.
- Second attempt: confirmed `expect_type()` also lacks `info`; signature checks showed `expect_lt()` lacks it as well. Removed unsupported labels only.
- After-task structure, prose, and targeted whitespace checks are recorded in the check log.
- No full suite, pkgdown build, Julia live engine, bootstrap, profile, or interval calibration was run.

## 6. Tests of the Tests

The test generates a valid q=4 correlation matrix from six partial-correlation parameters and applies the same Cholesky factor to the simulated random effects. It checks fitted coefficient-specific SD predictions against the fitted coefficients and group predictors. It also checks all six public correlations and the underlying partial-correlation parameters against the generating values. The first failing Hessian assertion served as a diagnostic and was not replaced by looser recovery thresholds.

## 7a. Issue Ledger

Searched open GitHub issues for `Bernoulli correlated q4 SD probit cloglog`. No matching issue was found, so no issue was changed.

## 8. Consistency Audit

The test and receipt describe only one native Binomial q=4 fixture under probit and complementary log-log. The Hessian warning is explicit. No user-facing family or formula claim changed because the documentation audit lane owns the public documentation surface.

## 9. What Did Not Go Smoothly

Two test runs stopped on unsupported `info` arguments after the first fit. The focused q=4 fits take several minutes each. The first-run transcript and both harness-error logs are preserved in the evidence folder. The corrected run completed both links without changing recovery thresholds.

## 10. Known Residuals

The probit fit has a non-positive-definite Hessian, so Wald standard errors are not trustworthy for that fit. The test directly covers q=4. The q=2 and q=3 cases, larger blocks, interval calibration, Julia parity, and other response families remain open.

## 11. Team Learning

Check the installed testthat function signatures before adding diagnostic `info` labels to helper expectations. Keep point-recovery criteria separate from Hessian-based uncertainty claims.

## 12. Cross-Product Coverage

- Response family: Binomial.
- Engine: native R/TMB.
- Endpoint: `mu`.
- Links: probit and complementary log-log.
- Random effect: one correlated ordinary block, q=4, with an intercept and three numeric slopes.
- SD regression: four distinct fixed-effect SD formulas.
- Data: independent fixed-seed synthetic data, 256 groups and 48 observations per group.
- This slice does NOT cover other q values, structured providers, Julia, other families, or uncertainty calibration.
