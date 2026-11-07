# After Task: Native Binomial ordinary plus phylogenetic logit SDs

## 1. Goal

Bind the existing native Binomial logit ordinary iid plus phylogenetic SD test to its exact required capability row.

## 2. Implemented

The fixed-seed test covers two SD slopes, marginal simulation, save/reload prediction, and constant-SD equivalence. No model code changed in this slice.

## 3a. Decisions and Rejected Alternatives

The receipt covers one ordinary iid intercept plus one phylogenetic tree intercept under logit. It does not infer other providers or links.

## 3. Mathematical Contract

The model adds an independent group intercept and tree-correlated tip intercept to the Binomial linear predictor. Each log SD has its own fixed-predictor design. The constant-SD model should match the model without an explicit SD formula.

## 4. Files Touched

- `tests/testthat/test-binomial-ordinary-phylo-sd.R` (read and executed; unchanged)
- `docs/dev-log/general-sd-regression/evidence/native-binomial-ordinary-phylo-logit-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-ordinary-phylo-logit-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-phylo-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 18 expectations. The test includes recovery, simulation, save/reload, and constant-SD equivalence.

Evidence reconciliation passed with 19,678 candidate rows, 114 linked rows, 19,564 unlinked rows, and 136 evidence records. Interval coverage was not run.

## 6. Tests of the Tests

The existing test checks the intended combined targets and an adjacent constant-SD identity. Both SD formula outputs are checked separately.

## 7a. Issue Ledger

No matching open issue was identified or changed. Remaining family and provider obligations stay in the general SD ledger.

## 8. Consistency Audit

The exact logit `iid + phylo` candidate row is now linked to this executed test. Documentation and Julia lanes have been notified. No public support claim is added here.

## 9. What Did Not Go Smoothly

The run completed within the estimated one-to-two-minute range without failures or warnings.

## 10. Known Residuals

This is one-seed recovery and workflow evidence. It does not establish interval coverage, Julia parity, or other providers and response families.

## 11. Team Learning

An existing high-value test should be linked to its precise capability row when it directly checks recovery and neighboring workflows.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial logit `mu`, q1 ordinary iid plus phylogenetic tree intercepts. This does NOT cover Julia fitting or bridge parity, interval calibration, or other response families.

## 13. Next Actions

Continue with remaining Bernoulli provider-input gaps and preserve the broader response-family and Julia scope.
