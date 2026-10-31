# After-task report: homogeneous Toeplitz S2 native provider

## 1. Goal

Enable the approved direct Gaussian `homtoep` temporal provider and prove its
native likelihood against an independent dense covariance oracle.

## 2. Implemented

The provider spans `src/drmTMB.cpp`, `R/temporal.R`, and `R/drmTMB.R`. It
constructs a positive-definite Toeplitz covariance from inverse-Levinson
partial-autocorrelation coordinates and evaluates a full normalized MVN density
for every independent series. It reports `cor_lag*` correlations and reports its
single start vector as partial autocorrelations.

## 3a. Decisions and Rejected Alternatives

The provider uses the S0 inverse-Levinson map rather than direct lagwise
squashing, which can produce an indefinite matrix, or a generic Cholesky map,
which need not be Toeplitz. The first route remains direct only: it rejects an
ordinary intercept and does not claim intervals, prediction, or calibration.

## 4. Files Touched

New independent reference and native tests are
`tests/testthat/helper-temporal-homtoep-reference.R` and
`tests/testthat/test-temporal-homtoep-native.R`. The gate runner, parser test,
formula grammar, likelihood design note, Unlazy ledger, and check log were
updated to record the enabled provider and its limits.

## 5. Checks Run

- `Rscript --vanilla tools/temporal-homtoep-gates.R T3-3` emitted
  `TEMPORAL_HOMTOEP_T3_3_PASS`.
- T3-1 and T3-2 were reverified and emitted their expected pass receipts.
- The focused regression harness loaded the package once, explicitly converted
  testthat failures into a nonzero status, and emitted
  `TEMPORAL_HOMTOEP_S2_REGRESSION_PASS` for temporal parser, Gaussian smoke,
  identities, OU, OU dense oracle, Toeplitz map, Toeplitz parser, and Toeplitz
  native tests.
- `git diff --check` passed.

## 6. Tests of the Tests

The first dense oracle used `backsolve(chol(V), residual)`, which is incorrect
for R's upper Cholesky factor. The mismatch was investigated before any
tolerance changed. Replacing it with
`forwardsolve(t(chol(V)), residual)` reconciled the dense covariance, direct
marginal likelihood, and analytic Laplace calculation. The retained oracle
independently rebuilds correlations, covariance, score, both finite-difference
Hessians, and conditional modes without calling the package transform.

## 7a. Issue Ledger

`gh issue list --limit 100 --search "Toeplitz OR temporal"` found only open
issue #1302, the phylogenetic-temporal OU feature. It does not cover this direct
Toeplitz slice; no external issue was opened or changed.

## 8. Consistency Audit

`rg -n "homtoep|homogeneous Toeplitz|native covariance provider is not yet enabled" README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd _pkgdown.yml R tests` found the current implementation and design descriptions, with no stale pre-provider error wording.

## 9. What Did Not Go Smoothly

An aggregate test command initially ran historical test files before loading
the package and did not convert testthat failures to a process failure. The
replacement harness calls `pkgload::load_all()` first and exits nonzero on an
expectation error. No package defect was indicated by that failed harness.

## 10. Known Residuals

T3-3 is complete. T3-4 must verify row reconstruction, labelled extraction,
fitted values, residuals, and simulation; T3-5 must test AR1/diagonal reductions
and mutations. Recovery, profile intervals, calibration, ordinary-intercept
composition, `newdata`, and forecasts remain unavailable.

## 11. Team Learning

The gate runner executes each gated test file in an isolated R process;
aggregation must similarly load the package and inspect testthat result objects.
This prevents a reporting-only testthat invocation from becoming apparent proof
of success.

## 12. Cross-Product Coverage

The direct homogeneous Toeplitz provider was cross-checked with the existing
Gaussian ML AR1 and OU temporal suites, under constant `sigma`, complete rows,
and the native TMB engine. This work does NOT cover REML, penalized estimators,
the Julia engine, missing-response or missing-predictor models, aggregation,
ordinary-intercept composition, phylogenetic or spatial providers, non-Gaussian
families, `newdata`, forecasts, intervals, or calibration. #1302 remains a
separate additive phylogenetic-stable plus OU route.
