# After Task: Native Binomial phylogenetic and relatedness SD pair

## 1. Goal

Add one native Bernoulli q1 intercept pair: a tree-backed phylogenetic field and a relatedness field using K covariance or equivalent Q precision, each with its own predictor-dependent SD formula.

## 2. Implemented

The native Binomial builder now admits the phylo plus relmat q1 intercept pair. The existing generic second-field likelihood assembles the two independent fields; no C++ likelihood change was required. The error message lists this exact pair among the fitted Binomial routes.

## 3a. Decisions and Rejected Alternatives

The pair is limited to independent q1 intercept fields and a supplied relatedness covariance matrix `K` or its equivalent precision `Q = solve(K)`. The test crosses tips and populations so that the two latent fields have distinct group mappings. It does not add arbitrary provider combinations.

## 3. Mathematical Contract

The linear predictor is `eta = X beta + tau_tree[g] u_tree[g] + tau_relmat[h] u_relmat[h]`, with independent fields using their supplied covariance kernels. Each log SD has its own fixed-predictor design. The population SD predictor is constant within each population. Matrix labels are reversed relative to factor levels to exercise name alignment.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-binomial-phylo-relmat-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-relmat-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-phylo-relmat-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 12 expectations. It checks optimizer convergence, both SD-slope recovery bounds, coefficient target names, group-named predictions, structured-effect labels, and K/Q equivalence in likelihood, SD coefficients, and name-aligned predictions. The source manifest and console log are retained with the receipt.

The red run first reached the current builder refusal for multiple providers. After admitting this pair, the focused test passed. The evidence reconciler passed with 19,678 candidate rows, 97 linked rows, 19,581 unlinked rows, and 119 records. `git diff --check` passed for the edited implementation and test.

## 6. Tests of the Tests

The red test failed at the intended pair-admission guard before fitting. After the builder update, all twelve expectations passed without warnings.

## 7a. Issue Ledger

No issue was opened or changed. The broader family and provider obligations remain on the active general SD ledger.

## 8. Consistency Audit

The formula has two distinct q1 provider targets and two matching SD formulas. The native route retains the tree and relatedness kernel scaling, with K/Q equivalence checked. Prediction returns the tree and population SDs under their own group labels. No Julia fitting, bridge, public help, or coverage claim is made.

## 9. What Did Not Go Smoothly

No unexpected failures occurred. The first run confirmed the pre-existing refusal; the admitted route passed the fixed-seed recovery checks.

## 10. Known Residuals

This evidence covers one native Binomial logit q1 tree plus K-covariance pair. Probit/cloglog, other structured pairs, slopes, missing responses, Julia parity, and interval calibration remain open.

## 11. Team Learning

Crossing both group dimensions and reversing the covariance-matrix labels makes a single synthetic test check whether each provider's SD predictor and output remain attached to the intended groups.

## 12. Cross-Product Coverage

The covered engine is native R/TMB for Binomial logit `mu`, q1 intercepts,
with a phylo tree and relmat K covariance or equivalent Q precision as separate providers. This does NOT cover
Julia fitting, the R-to-Julia bridge, other links, slopes, other
provider pairs, missing-response routes, or interval calibration.

## 13. Next Actions

Continue with the next unresolved Bernoulli provider pair. Keep Julia parity and uncertainty calibration as separate evidence tasks.
