# After Task: Poisson Likelihood Weight Test

## Goal

Strengthen the `weights =` test coverage by proving that row likelihood
weights work for an independent-row count family, not only Gaussian models.

## Implemented

- Added a Poisson test where `weights = 2` leaves the fitted mean coefficients
  unchanged and doubles the log-likelihood.
- Added a Poisson test where integer weights, including zero weights, match an
  explicitly row-duplicated dataset.

## Mathematical Contract

For a Poisson mean model,

```text
y_i ~ Poisson(lambda_i)
log(lambda_i) = X_i beta
nll = sum_i w_i {-log p(y_i | lambda_i)}
```

The test checks two consequences:

```text
w_i = 2 for all i
```

should scale the objective but not move `beta`, and integer `w_i` should match
replicating row `i` exactly `w_i` times, up to optimizer tolerance.

## Files Changed

- `tests/testthat/test-poisson-mean.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-poisson-likelihood-weight-test.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = 'poisson-mean')"
rg -n "Poisson.*weights|weights.*Poisson|weights.*planned|does not yet.*weights" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat/test-poisson-mean.R R man _pkgdown.yml
git diff --check
```

Results:

- targeted Poisson tests: 46 passed, 0 failed, 0 warnings, 0 skips;
- stale-wording search found no current documentation claiming that
  `weights =` is unimplemented;
- `git diff --check` is clean.

## Tests Of The Tests

The first targeted test run failed because the duplicated-data fit and weighted
fit differed by optimizer-scale jitter in the fifth decimal place of one
coefficient. The final tolerance is still tight enough to catch broken row
weighting while avoiding false failures from two separate optimizations.

## Consistency Audit

No likelihood equation, formula grammar, public documentation, pkgdown
navigation, roadmap item, or known-limitation changed. The implementation had
already routed `weights` through the Poisson TMB branch; this task only added a
direct test for that route.

## What Did Not Go Smoothly

The first coefficient tolerance was too strict for comparing two independently
optimized but mathematically equivalent Poisson likelihoods.

## Team Learning

- Curie should add cross-family tests when shared TMB machinery affects many
  likelihood branches.
- Ada should keep test-only phases narrow and avoid unnecessary documentation
  churn when user-facing behaviour is unchanged.

## Known Limitations

- Dense full `meta_known_V(V = V)` still rejects non-unit weights by design.
- Response-specific bivariate weights remain unimplemented.

## Next Actions

1. Add one analogous weight test for a distributional count model such as
   `nbinom2()` when the next count-family test pass happens.
2. Keep the tutorial distinction between `weights =` and `meta_known_V(V = V)`
   prominent as real meta-analysis examples are added.
