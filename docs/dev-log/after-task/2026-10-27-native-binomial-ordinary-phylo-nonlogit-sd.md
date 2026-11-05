# After Task: Native Binomial ordinary and phylogenetic non-logit SDs

## 1. Goal

Add recovery and output checks for the native Binomial ordinary iid plus phylogenetic q1 intercept route under probit and complementary-log-log links.

## 2. Implemented

A fixed-seed test fits both links with separate SD regressions for ordinary groups and phylogenetic tips. No model-builder or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

The test covers one ordinary iid intercept plus one phylogenetic tree intercept. It does not expand to multiple ordinary terms, slopes, or other structured providers.

## 3. Mathematical Contract

The linear predictor includes an ordinary group effect and a tree-correlated tip effect. Each log SD depends on a predictor constant within its own group. Responses use the probit or cloglog inverse link, and each fit estimates both SD slopes.

## 4. Files Touched

- `tests/testthat/test-binomial-ordinary-phylo-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-ordinary-phylo-nonlogit-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-ordinary-phylo-nonlogit-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-phylo-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 20 expectations. Both links checked convergence, positive recovery of both SD slopes within fixed bounds, coefficient names, predicted SD counts, and structured-effect labels.

Evidence reconciliation passed with 19,678 candidate rows, 111 linked rows, 19,567 unlinked rows, and 133 evidence records. Interval coverage was not run.

## 6. Tests of the Tests

The test generates independent binary responses from probit and cloglog inverse links on the same latent-effect design. It checks each latent SD target separately and returns predictions at the matching group and tip grain.

## 7a. Issue Ledger

No matching open issue was identified or changed. The wider family and provider obligations remain in the active general SD ledger.

## 8. Consistency Audit

The formula and data use ordinary group and phylogenetic tip SD targets. Evidence is limited to native Binomial probit and cloglog `iid + phylo` intercepts. Documentation and Julia lanes have been notified. No public support claim is added here.

## 9. What Did Not Go Smoothly

The first run stopped because an assertion helper rejected its `info` argument. I replaced those comparisons with `expect_true()`; the full focused test passed on retry.

## 10. Known Residuals

This is one-seed point-recovery evidence. It does not establish interval coverage, Julia parity, or other response families and random-effect combinations.

## 11. Team Learning

Separating assertion-helper errors from model-fit failures keeps recovery evidence interpretable.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial probit and cloglog `mu`, q1 ordinary iid plus phylogenetic tree intercepts with separate SD predictors. This does NOT cover Julia fitting or bridge parity, interval calibration, or other families.

## 13. Next Actions

Continue with the next unlinked Bernoulli family and provider rows while retaining fixed-seed recovery checks.
