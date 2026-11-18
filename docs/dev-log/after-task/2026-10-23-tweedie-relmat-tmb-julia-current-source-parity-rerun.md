# After Task: Current-Source Tweedie Related-Matrix Bridge Rerun

## 1. Goal

Verify the existing synthetic Tweedie related-matrix random-effect SD bridge against the current native TMB and paired Julia candidate sources.

## 2. Implemented

No model code changed. The public R bridge test passed 24 assertions for one q1 Tweedie location-intercept SD model using the same synthetic data and a permuted, non-unit-diagonal relatedness matrix. A 199-file source manifest, console log, and evidence receipt now bind this run to the native and Julia candidates. The receipt adds a second record for an already-linked required row, so the number of distinct linked rows remains 25.

## 3a. Decisions and Rejected Alternatives

I reran the existing live bridge test instead of changing the likelihood or adding a duplicate test. The current-source run adds a source-bound parity receipt to the existing Tweedie related-matrix row.

## 3b. Mathematical Contract

Both fits use the supplied kernel scale. The SD formula models the multiplier in \(D K D\); the marginal SD also includes the corresponding diagonal of \(K\). The test compares fitted coefficients, group-level SD predictions, and log likelihood after aligning the permuted matrix labels.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-current-v2/receipt.json`
- `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-current-v2/source-manifest.json`
- `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-recheck-v2.log`
- `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-recheck.log` and `docs/dev-log/general-sd-regression/evidence/tweedie-relmat-parity-20261023-recheck-with-path.log` (failed and interrupted attempts retained).
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- This report and `docs/dev-log/check-log.d/2026-10-23-tweedie-relmat-bridge-rerun.md`.

## 5. Checks Run

- `devtools::test(filter = "julia-tweedie-relmat-sd", reporter = "summary", stop_on_failure = TRUE)`: exit 0; 24 assertions passed; one live Julia bridge test ran. JuliaCall reported a non-fatal `LogExpFunctionsInverseFunctionsExt` precompile warning (`loglogistic` undefined).
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 19,118 candidate rows, 25 distinct linked rows, and 31 evidence records.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 11/11 passed.
- `git diff --check` on the evidence table, receipt directory, and console log: passed.
- Source manifest SHA-256: `5c09e5cb6793998a4ed12fcf7d3bce5eb79ec70dce879bb97bad99a3be42d876`. The manifest covers 199 native and Julia source, project, helper, and test files. Both candidate HEADs are recorded in the receipt.

## 6. Tests of the Tests

The live test combines both engines on identical synthetic data, checks label-permuted kernel alignment, and compares three fitted outputs. The evidence reconciler independently verifies the required row, test hash, receipt hash, and manifest hash. The first invocation failed before Julia started because Julia was absent from `PATH`. A second invocation was interrupted before assertions completed after I miscounted elapsed time; both attempt logs are retained. The final run used Julia 1.10.0 on the corrected `PATH` and completed successfully.

## 8. Consistency Audit

No likelihood, formula grammar, documentation claim, or support boundary changed. The prior Julia-only simulation and recovery receipt remains separate from this paired fit comparison. The console retains the dependency warning; no warning-free setup claim is made.

## 7a. Issue Ledger

No issue was changed. This task refreshed evidence for an existing route and did not introduce or alter user-facing behavior.

## 9. What Did Not Go Smoothly

The first command omitted the Julia launcher path. In the following attempt, I incorrectly treated roughly 6–7 minutes of runtime as longer than the previous 8.7-minute measurement and stopped it early. I corrected the elapsed-time estimate, allowed a 12-minute window, and obtained the passing run.

## 11. Team Learning

For a repeated cross-engine fit, record a fresh elapsed-time bound and check the actual process duration before applying an overrun stop. Keep launcher failures, interrupted runs, and completed model evidence distinct.

## 10. Known Residuals

This is one synthetic Tweedie q1 related-matrix location-intercept fit using the R/TMB and Julia engines, with fitted coefficients, named group SD output, and log likelihood compared. It does NOT cover other families, providers, block shapes, distributional parameters, bivariate models, simulation or refit parity, or calibrated intervals. The JuliaCall extension warning remains unresolved. The overall capability and calibration gates remain open.

## 12. Cross-Product Coverage

The tested cross-product cell is Tweedie location, q1 related-matrix intercept, supplied label-permuted non-unit-diagonal K, one group-level SD predictor, and native R/TMB plus Julia fits on identical synthetic data. It does NOT cover other families, providers, random-effect types, endpoints, block structures, public workflow surfaces beyond the compared fit outputs, or uncertainty calibration. Continue closing the remaining required capability rows and keep the calibration gate open until its prespecified campaign passes.
