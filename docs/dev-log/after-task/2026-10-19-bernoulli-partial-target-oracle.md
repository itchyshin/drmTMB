# After Task: Bernoulli Partial-Target Likelihood Oracle

## Goal

Check that the native correlated Bernoulli likelihood handles either coefficient having a predictor-dependent SD while the other coefficient keeps a constant SD.

## Implemented

The existing two partial-target fits now compare their fitted marginal log likelihoods with an independent two-dimensional Gauss-Hermite calculation. This checks the mixed predictor-dependent and constant-SD branches for the intercept and slope separately.

## Mathematical Contract

For each group, the oracle integrates the Bernoulli likelihood over a correlated Gaussian intercept-slope pair. The selected coefficient has its fitted log-SD regression; the other coefficient uses its fitted constant SD. The fitted correlation and fixed-effect estimates are held at their maximum-likelihood estimates for this numerical likelihood check.

## Files Changed

- `tests/testthat/test-binomial-correlated-sd.R`: added a separate oracle comparison to each partial-target fit.
- `docs/dev-log/check-log.md`: recorded the focused test result and its scope.
- This report records the validation boundary.

## Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-correlated-sd")'`: 60 passed, 0 failed, 0 warnings, 0 skips; 35.2 seconds.
- `git diff --check -- tests/testthat/test-binomial-correlated-sd.R`: passed before running the focused suite.

## Tests Of The Tests

The test uses the independent Gauss-Hermite likelihood calculation already used for the full two-target model. Each partial-target case has its own fitted parameters and oracle comparison, so the test does not infer native likelihood correctness from R-side covariance reconstruction alone.

## Consistency Audit

This change adds test coverage only. It does not change model behavior, formula syntax, documentation, or capability claims. The existing test still checks fitted covariance reconstruction and the full two-target likelihood oracle. No broader stale-wording scan was needed for this test-only change.

## GitHub Issue Maintenance

An open-issue search for `binomial random-effect SD` found no issue matching this specific partial-target likelihood test gap. The issue tracker is unchanged.

## What Did Not Go Smoothly

The independent review correctly identified that the partial-target fits existed but lacked direct likelihood-oracle comparisons. The tests now check both cases separately.

## Team Learning

When adding a mixed branch to a likelihood, test each one-sided target configuration against the independent numerical oracle, even when a full-target oracle already passes.

## Known Limitations

These are numerical likelihood checks, not interval-calibration evidence. The independent review also identified a Julia slope-only bootstrap-refit test gap; that remains open. Full Bernoulli calibration and the broader programme gates remain open.

## Next Actions

Add the missing Julia slope-only bootstrap-refit check, then resolve the source-freshness boundary before launching a calibration campaign for the current implementation.
