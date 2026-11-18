# Bernoulli SD formula design parity

## 1. Goal

Check that R/TMB and Julia build the same group-level SD design for an independent synthetic Bernoulli example with a factor, a numeric predictor, and their interaction.

## 2. Implemented

Added test-only coverage in both repositories. The R builder is compared with `model.matrix(~ band * z, ...)`; the Julia builder is checked against the corresponding treatment-coded columns. Both tests verify `exp(Z %*% alpha)` and reject a factor that changes within a random-effect group.

## 3a. Decisions and Rejected Alternatives

This slice changes no likelihood or public API. Shared model assembly and Julia inference files have active owners, so the work stays in two new, narrowly leased test files. The fixture is generated independently and contains no collaborator data.

## 4. Files Touched

- `tests/testthat/test-binomial-sd-formula-design.R`
- `test/test_binomial_sd_formula_design.jl`
- Paired check-log and after-task records in drmTMB and DRModels.jl.
- Exact-draft assessment records for both reports.

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-sd-formula-design", reporter = "summary")'`: passed; four expectations.
- `JULIA_DEPOT_PATH="/private/tmp/drmTMB-julia-depot:/Users/z3437171/.julia" OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 OMP_NUM_THREADS=1 julia --project=. test/test_binomial_sd_formula_design.jl`: passed, 5/5 in 4.0 seconds.

## 6. Tests of the Tests

The assertions compare column names and values with an independently constructed treatment-coded design, check a nonzero interaction in the log-SD predictor, and make a one-row within-group factor change that must error. These tests exercise formula-design semantics only.

## 7a. Issue Ledger

Read-only searches of both repositories' open issues found no issue specific to factor contrasts and interaction coding in random-effect SD formulas. No issue was opened, changed, or closed. The full capability and inference ledger remains open.

## 8. Consistency Audit

The test syntax matches the existing `sd(group) ~ predictors` formula surface. No parser, likelihood, user-facing documentation, or package capability claim changed. Programme gates G0-G8 remain open.

The after-task structure check passed. Its overall acceptance-ledger check returned exit 1 because the programme still has open gates, including Bernoulli calibration and full capability coverage. This test slice does not close those programme gates.

## 9. What Did Not Go Smoothly

The first R assertion compared matrix results with different names; the test now removes names before comparing numeric values. Julia's default depot could not write its lock file in this environment, so the test used a task-specific writable depot. Both final reruns passed.

## 10. Known Residuals

This slice does NOT establish model fitting, parameter recovery, interval calibration, same-data estimate parity, or support for structured random effects. It does not close the Bernoulli delivery or the general programme.

## 11. Team Learning

Test the SD design matrix against ordinary fixed-effect coding directly. Matching the likelihood path alone would not reveal a factor-contrast or interaction-column mismatch between engines.

## 12. Cross-Product Coverage

R/TMB and Julia now have matching formula-design assertions for one synthetic Bernoulli case. This slice does NOT cover fitted-value parity, recovery, uncertainty, or any other family or random-effect type.
