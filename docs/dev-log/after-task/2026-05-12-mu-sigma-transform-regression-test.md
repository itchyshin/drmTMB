# After Task: Mu/Sigma Transform Regression Test

## Goal

Harden the first univariate `mu`/`sigma` covariance slice by checking the
conditional random-effect transform directly, not only through fitted summaries
and profile targets.

## Implemented

Added one focused test to `tests/testthat/test-gaussian-random-intercepts.R`.
The test builds a model specification with:

```r
bf(y ~ x + (1 | p | id), sigma ~ z + (1 | site) + (1 | p | id))
```

It then supplies deterministic latent `u_mu` and `u_sigma` values and checks
that:

- labelled `sigma` rows matched to the `mu` block use
  `rho * u_mu + sqrt(1 - rho^2) * u_sigma`;
- unlabelled `sigma` rows for the independent `site` block remain
  `sd_sigma * u_sigma`;
- the number of matched and unmatched rows agrees with the `id` and `site`
  group counts.

## Files Changed

- `tests/testthat/test-gaussian-random-intercepts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-mu-sigma-transform-regression-test.md`

## Checks Run

- `air format tests/testthat/test-gaussian-random-intercepts.R`: passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 210 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 625 expectations, 0 failures, 0 warnings, and 0 skips.

## Consistency Audit

This is test-only hardening. It does not change package code, formula grammar,
likelihood parameterization, roxygen topics, NEWS, or pkgdown navigation.

## Tests Of The Tests

The test uses deterministic latent values rather than a fitted model so the
expected transform is explicit. It includes an independent `sigma` block in the
same spec to make sure the matched-label logic does not leak across all
`sigma` random effects.

## What Did Not Go Smoothly

Nothing blocking. The first version checked unmatched rows with negative
indexing; the final test names `matched` and `unmatched` rows explicitly and
checks both group counts before comparing values.

## Team Learning

- Curie added a direct regression guard for the sign and index mapping.
- Noether kept this at the transform identity, separate from profile and
  summary-surface tests.
- Ada kept the slice test-only so the committed checkpoint remains a stable
  base for any later implementation work.

## Known Limitations

- This test checks the R-side transform used for fitted random-effect
  reporting and prediction contributions.
- It does not add an independent marginal likelihood comparator for the full
  Laplace objective.

## Next Actions

1. If the branch needs another hardening slice, add a small comparator for the
   Laplace objective or a cross-package overlap, not another duplicate surface
   assertion.
