# After Task: Julia Binomial Related-Matrix Save and Reload

## 1. Goal

Close one public-output gap for the existing Binomial related-matrix random-effect SD route by checking the fitted Julia object after save and reload.

## 2. Implemented

Extended the live TMB/Julia bridge fixture with three assertions that compare the Julia fit's SD coefficients, group-level SD predictions, and `predict_parameters()` estimates before and after RDS serialization. The test still checks the same-data TMB/Julia fit and the independent seeded simulation oracle. All 35 assertions passed with one live Julia bridge fit. A source-bound receipt now links the Julia Binomial q1 `relmat()` intercept row, increasing distinct receipted rows from 25 to 26.

## 3a. Decisions and Rejected Alternatives

I extended the existing synthetic bridge fixture rather than adding another model fit or an unrelated serializer-only test. The first run caught an assertion mismatch: the original prediction vector had its standard `sd_relmat(id):` prefix removed for alignment, while the reloaded vector still had it. The corrected test normalizes both vectors before comparison. The first failure summary is retained in `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-rds-20261023/failed-attempt.md`.

## 3b. Mathematical Contract

For the tested intercept, the structured effect is \(b=Dz\), with \(z\sim N(0,K)\) and group-specific \(D\) from the log-SD regression. The workflow test checks output preservation across serialization; the existing independent oracle checks the seeded marginal draw against the labelled, non-unit-diagonal covariance and the fitted group SDs.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-relmat-sd-parity.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-rds-20261023/receipt.json`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-rds-20261023/source-manifest.json`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-rds-20261023/test-console.log`
- `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-rds-20261023/failed-attempt.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- This report and `docs/dev-log/check-log.d/2026-10-23-julia-binomial-relmat-save-reload.md`.

## 5. Checks Run

- `devtools::test(filter = "julia-binomial-relmat-sd-parity", reporter = "summary", stop_on_failure = TRUE)`: exit 0, 35 assertions passed, one live Julia bridge test. JuliaCall emitted the known non-fatal `LogExpFunctionsInverseFunctionsExt` warning (`loglogistic` undefined).
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 19,118 candidate rows, 26 distinct linked rows, and 32 evidence records.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 11/11 passed.
- The receipt binds the run to a 199-file native and Julia manifest, including the executed test, helper files, package sources, Julia project, and Julia sources. Its source-manifest SHA-256 is `0889784e9bea86386dd95faa4cce73d5cb10f8a567531063d8e85f14e9e95ce8`.

## 6. Tests of the Tests

The new assertions run on the fitted object returned by the public R bridge and compare values from both sides of serialization. The seeded simulator oracle remains independent of `simulate()` and verifies covariance ordering and group-to-row mapping. The first run demonstrated that the test detects inconsistent name normalization; the corrected test passes with the expected public group labels.

## 7a. Issue Ledger

No issue was changed. This test-only addition strengthens output evidence for an existing route and does not introduce new public behavior.

## 8. Consistency Audit

No likelihood or formula grammar changed, and public documentation remains accurate. The new receipt is scoped to one complete-response Binomial location intercept with a supplied labelled covariance matrix. It does not promote the row to general support or interval calibration.

## 9. What Did Not Go Smoothly

The first run wrote no console file because the evidence directory did not exist. I retained its failure details in a short attempt note, created the directory before retrying, and captured the successful run's complete console output.

## 10. Known Residuals

This is one q1 Binomial related-matrix intercept. Other structured effects, slopes, endpoints, families, output/refit combinations, and uncertainty calibration remain open. JuliaCall's extension warning is still unresolved. The program gates remain open beyond the bounded Bernoulli gate.

## 11. Team Learning

When a test normalizes output names for cross-engine alignment, apply the same normalization to a serialized object before comparing values. Pre-create evidence directories before starting commands whose output is being captured.

## 12. Cross-Product Coverage

This test covers the Julia Binomial logit location, q1 related-matrix intercept, supplied labelled non-unit-diagonal K, fixed group-level SD predictor, native TMB/Julia same-data point comparison, Julia RDS output preservation, and one independent seeded simulation draw. It does NOT cover other families, providers, effect structures, endpoints, refit workflows, or calibrated interval uncertainty.
