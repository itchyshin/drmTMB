# After Task: Mu/Sigma Prediction Contribution Test

## Goal

Add a fitted-data prediction guard for the first univariate Gaussian
`mu`/`sigma` covariance slice, so the branch checks the user-facing `sigma`
prediction path as well as the internal transform and joint objective.

## Implemented

Added a deterministic test in
`tests/testthat/test-gaussian-random-intercepts.R` for:

```r
bf(y ~ x + (1 | p | id), sigma ~ z + (1 | site) + (1 | p | id))
```

The model combines a matched labelled `mu`/`sigma` random-intercept covariance
block with an independent unlabelled `sigma` block. The test verifies that
`sigma_random_effect_contribution()` equals the manual row-wise sum of fitted
`sigma` random effects times their design values, then checks that
`predict(fit, dpar = "sigma", type = "link")` is the fixed sigma linear
predictor plus that contribution. It also checks that `stats::sigma(fit)` is
`exp()` of the fitted sigma-link prediction.

## Mathematical Contract

For fitted data,

```text
eta_sigma_i = X_sigma[i, ] beta_sigma + Z_sigma[i, ] b_sigma
sigma_i = exp(eta_sigma_i)
```

The matched labelled `id` component in `b_sigma` has already been transformed
by the `mu`/`sigma` covariance machinery. The independent `site` component must
enter the row-wise prediction contribution without being treated as a matched
cross-parameter covariance row.

## Files Changed

- `tests/testthat/test-gaussian-random-intercepts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-mu-sigma-prediction-contribution-test.md`

## Checks Run

- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 216 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 631 expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'sigma_random_effect_contribution|predict\([^\n]*dpar = "sigma"|mu/sigma covariance|mu/sigma' R tests README.md ROADMAP.md NEWS.md docs vignettes`:
  reviewed prediction and covariance wording touched by the claim; no
  source-doc changes needed for this test-only guard.
- `rg -n 'rho12|sigma1|sigma2|sd\(' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-gaussian-random-intercepts.R`:
  reviewed correlation terminology around `rho12` and group-level covariance;
  no stale wording introduced.

## Tests Of The Tests

The new test combines the implemented labelled `mu`/`sigma` covariance block
with an already-supported neighbouring feature, an independent unlabelled
`sigma` random intercept. It compares the exported fitted-data prediction
surface to an explicit reconstruction from the fitted fixed effects,
random-effect values, random-effect indices, and random-effect design values.

## Consistency Audit

This is test-only hardening. It does not change formula grammar, likelihood
parameterization, user-facing documentation, examples, NEWS, README, roadmap,
known-limitations text, or pkgdown navigation.

## What Did Not Go Smoothly

No implementation problem this time. The main guardrail was keeping the test
small enough to avoid turning the prediction check into another likelihood
comparator.

## Team Learning

- Pat gets evidence that fitted `sigma` predictions include the conditional
  group-level scale contribution a user would see.
- Noether gets a direct equality between the symbolic fitted-data equation and
  the implementation path.
- Curie kept the new fixture deterministic and adjacent to the earlier
  transform and objective tests.
- Rose confirmed this did not change the `rho12` versus group-level covariance
  naming boundary.

## Known Limitations

- The test covers fitted-data predictions only. It does not add support for
  conditional random-effect prediction on new grouping levels in `newdata`.
- It covers the first intercept-only `mu`/`sigma` covariance slice, not random
  slopes, bivariate `sigma1`/`sigma2` random effects, or multiple labelled
  covariance blocks.

## Next Actions

1. Refresh the recovery checkpoint after this commit.
2. If the branch stays clean, prepare the accumulated covariance/profile slice
   for PR review rather than broadening the feature in this thread.
