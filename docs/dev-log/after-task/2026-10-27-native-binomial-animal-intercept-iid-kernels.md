# After Task: Native Binomial animal-intercept SD input evidence

## 1. Goal

Record exact native Binomial logit animal-intercept SD evidence for A covariance, A-inverse precision, and pedigree inputs.

## 2. Implemented

No model code changed. A captured focused run exercised the existing standalone A, A-inverse, and pedigree animal-intercept test files on synthetic data. Each checks predictor-dependent SD fitting, target naming, named predictions, and equivalence of a constant-SD formula to the base model; the A and pedigree tests also check simulation output.

## 3a. Decisions and Rejected Alternatives

The evidence is linked to each exact provider input and the logit `mu` endpoint. A broad filter also ran an adjacent Beta-binomial pedigree test and matched a Julia bridge test whose live checks were skipped; neither is counted for the three native Binomial rows.

Assumptions made without asking: the existing fixed-seed test fixtures are appropriate for these direct fit checks. Their one-seed recovery tolerances are not treated as comprehensive recovery evidence or interval validation.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-intercept-iid-kernels-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-animal-intercept-iid-kernels.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-(sd-regression|ainv-sd-regression|pedigree-sd-regression)", reporter = "summary", stop_on_failure = TRUE)'` exited 0. The three target Binomial files passed 33 expectations. One adjacent Beta-binomial test passed 21 expectations. Two live Julia bridge checks were skipped because the Julia engine paths were not configured. Evidence reconciliation passed with 19,678 candidate rows, 125 linked rows, 19,553 unlinked rows, and 147 records. The source manifest hashes matched after the run.

## 6. Tests of the Tests

The A and A-inverse fixtures verify that the precision input represents the inverse of the reordered covariance. The pedigree fixture compares the derived sparse precision with the relationship matrix inverse. All three fitted tests require optimizer convergence and check named public predictions. Constant-SD equivalence is checked against the base model.

## 7a. Issue Ledger

No issue was opened or changed. The remaining family, link, effect, and engine rows remain obligations in the candidate ledger.

## 8. Consistency Audit

Each receipt links one exact native Binomial logit animal-intercept row. The source manifest includes the R builder, TMB likelihood, and three test files. The skipped Julia checks are disclosed in the run receipt and are not used as Julia evidence. Coverage calibration remains deferred.

## 9. What Did Not Go Smoothly

The filter matched the adjacent Beta-binomial and Julia bridge test files. Their results are retained in the console log, but only the three specified native Binomial tests are linked here.

## 10. Known Residuals

This is focused one-seed fit, output, simulation, and constant-SD-equivalence evidence. It does not establish interval coverage, Julia parity, or broader family and provider support. Aggregate gate state remains UNKNOWN because the gate runner is unavailable.

## 11. Team Learning

Anchor test filters to exact test names when heterogeneous suites share similar names. If a broad filter is used, report neighboring passes and skips separately from the capability rows being registered.

## 12. Cross-Product Coverage

The evidence covers native R/TMB Binomial logit `mu` animal-intercept SD regression for A covariance, A-inverse precision, and pedigree inputs. It does NOT cover Julia live fitting, bridge parity, interval calibration, other links, or other response families and effect combinations. No Golden Set run was needed because no known-mistake class was changed.
