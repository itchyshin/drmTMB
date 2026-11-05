# After Task: Tweedie Related-Matrix SD TMB/Julia Parity

## Goal

Check the structured Tweedie SD route against native TMB using the same synthetic data and labelled covariance matrix.

## Implemented

Extended the live Julia bridge test to fit both engines on a 32-group, 8-repeat synthetic fixture with a non-unit-diagonal, label-permuted relatedness matrix. The test compares convergence, SD coefficients, group-level SD multipliers, and log likelihood.

## Mathematical Contract

Both fits use the supplied kernel scale. The fitted SD formula describes the multiplier in \(D K D\); the marginal SD also depends on the supplied kernel diagonal.

## Files Changed

- `tests/testthat/test-julia-tweedie-relmat-sd.R`
- `docs/dev-log/check-log.md`
- This report.

## Checks Run

- `git diff --check -- tests/testthat/test-julia-tweedie-relmat-sd.R`: passed before the focused run.
- `DRMTMB_JULIA_TESTS=true NOT_CRAN=true DRM_JL_PATH=... JULIA_DEPOT_PATH=... JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-tweedie-relmat-sd")'`: final run **24 passed, 0 failed, 0 skipped**, in 522.6 seconds.
- JuliaCall printed a dependency-extension precompile warning (`LogExpFunctionsInverseFunctionsExt`, `loglogistic` undefined) while setting up; the live Julia fit ran and the test completed successfully.

## Tests Of The Tests

The first same-data attempt used 16 groups and 4 observations per group. Native TMB did not converge, and the likelihoods differed by about 15.7, so those parity expectations were not retained. The revised fixture follows the information-rich design already used by the native Tweedie related-matrix recovery test and checks permuted matrix labels and non-unit diagonal scaling. A first public-table assertion also failed because the engines ordered groups differently. The final test matches by `row_label`, then confirms equal target, component, group set, and estimates; all 24 assertions pass.

## Consistency Audit

No model likelihood, formula grammar, or public support claim changed. Existing tests already check the native structured Tweedie implementation and the Julia structured fit separately. This test adds one paired candidate point-comparison row. README, NEWS, roadmap, known-limitations, formula-grammar docs, and pkgdown navigation were not changed because this is test evidence for an existing route.

## GitHub Issue Maintenance

No issue search or tracker change was made for this focused parity test; no new support claim is being proposed.

## What Did Not Go Smoothly

The small initial fixture was not informative enough for stable native convergence. The larger fixture took about nine minutes and exposed a JuliaCall setup warning that did not block fitting.

## Team Learning

Use the established information-rich fixture shape for cross-engine Tweedie checks; tiny smoke fixtures can pass route admission while failing to support meaningful optimizer comparisons.

## Known Limitations

This is one complete-response Tweedie related-matrix mean-intercept SD comparison. For `predict()`, Julia prefixes names with `sd_relmat(group):` while native TMB returns group names; the tested `predict_parameters()` table provides a group `row_label` that aligns estimates across engines. Other structured effects, endpoints, multiple targets, all public output/refit surfaces, independent likelihood accuracy, and interval calibration remain unvalidated. It does not close any programme gate.

## Next Actions

Continue the required-family/effect/backend inventory and output audit. Keep uncertainty calibration explicitly open until its deferred validation phase.
