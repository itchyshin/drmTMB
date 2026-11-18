# After Task: Julia Bernoulli phylogenetic SD prediction order

## 1. Goal

Strengthen the live R-to-Julia Bernoulli phylogenetic SD check so predictions
are verified after the requested species rows are reordered.

## 2. Implemented

Added a permuted-`newdata` assertion to the existing probit phylogenetic
cross-engine test. This checks that predicted `sd_phylo(species)` values follow
the input rows and their species-specific SD predictors.

## 3a. Decisions and Rejected Alternatives

Kept the existing model and formula. Added a focused assertion to test the
public prediction result without changing the predictor design or kernel
scaling.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-phylo-sd.R`
- `docs/dev-log/check-log.d/2026-10-26-julia-binomial-phylo-prediction-order.md`
- `docs/dev-log/after-task/2026-10-26-julia-binomial-phylo-prediction-order.md`

## 5. Checks Run

The focused `julia-binomial-phylo-sd` test passed 49 expectations in 38.6
seconds. Two live Julia fits ran, for logit and probit, with corresponding
native TMB comparisons. JuliaCall used Julia 1.10.0. `git diff --check`
reported a pre-existing blank line at end of
`tests/testthat/test-binomial-sd-integration.R`; this task did not change that
file. The first focused run failed before fitting because JuliaCall could not
find Julia in the login-shell `PATH`; the rerun set `JULIA_HOME` and `PATH`
explicitly and passed.

## 6. Tests of the Tests

The live probit and logit test paths exercised the bridge and TMB fits. The
probit fixture recovered a slope of 0.326 for a true value of 0.5 in a separate
fit, and the test now requires a positive estimate within 0.3 of truth. The
new prediction assertion computes expected scales from the permuted
fixed-effect design matrix and checks the returned row order.

## 7a. Issue Ledger

The issue tracker was left unchanged because this check covers an existing
predictor-dependent SD route.

## 8. Consistency Audit

The model formula is `tau_g = exp(W_g alpha)` multiplying the existing
phylogenetic covariance kernel. The assertion uses the established
`sd_phylo(species)` target and `predict()` interface. The evidence covers output
ordering for this focused route. Broader structured-effect parity remains
unverified.

## 9. What Did Not Go Smoothly

JuliaCall starts Julia through a login shell that did not inherit the Juliaup
path in the initial run. Supplying `JULIA_HOME` and adding Juliaup to `PATH`
resolved the setup problem.

## 10. Known Residuals

The recovery bound applies to one fixed-seed synthetic probit fixture; recovery
across seeds and conditions remains unverified. Confidence-interval coverage
remains uncalibrated. Other structured families and R/TMB and Julia parity
beyond this Bernoulli phylogenetic route remain unverified.

## 11. Team Learning

Cross-engine prediction tests should permute grouped `newdata` rows. Matching
the formula on rows in their original order alone can miss a target-to-row
mapping error.

## 12. Cross-Product Coverage

This task covers R-to-Julia Bernoulli phylogenetic SD prediction ordering for
one probit synthetic fixture and preserves the existing logit checks. This task
does NOT cover confidence-interval calibration, other Bernoulli effect types,
other response families, or all structured covariance providers.
