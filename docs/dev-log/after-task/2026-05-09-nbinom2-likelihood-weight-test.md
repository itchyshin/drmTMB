# After Task: NB2 Likelihood Weight Test

## Goal

Extend row likelihood-weight coverage to a distributional count model where
both the mean and overdispersion scale are formula-driven.

## Implemented

- Added an `nbinom2()` test where `weights = 2` leaves the fitted `mu` and
  `sigma` coefficients unchanged and doubles the log-likelihood.
- Added an `nbinom2()` test where integer weights, including zero weights,
  match an explicitly row-duplicated dataset.

## Mathematical Contract

For an NB2 mean-dispersion model,

```text
y_i ~ NegativeBinomial(mu_i, sigma_i)
log(mu_i) = X_mu,i beta_mu
log(sigma_i) = X_sigma,i beta_sigma
Var(y_i) = mu_i + sigma_i^2 mu_i^2
nll = sum_i w_i {-log p(y_i | mu_i, sigma_i)}
```

The test checks that constant row weights scale the objective without moving
`beta_mu` or `beta_sigma`, and that integer row weights are equivalent to row
duplication up to optimizer tolerance.

## Files Changed

- `tests/testthat/test-nbinom2-location-scale.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-nbinom2-likelihood-weight-test.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = 'nbinom2-location-scale')"
rg -n "nbinom2.*weights|weights.*nbinom2|weights.*planned|does not yet.*weights" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat/test-nbinom2-location-scale.R R man _pkgdown.yml
git diff --check
```

Results:

- targeted NB2-family tests: 108 passed, 0 failed, 0 warnings, 0 skips;
- stale-wording search found no current documentation claiming that
  `weights =` is unimplemented;
- `git diff --check` is clean.

## Tests Of The Tests

The new test protects a different likelihood class from the Poisson check:
`nbinom2()` estimates both `mu` and `sigma`, and the row-duplication comparison
checks both coefficient blocks plus the log-likelihood.

## Consistency Audit

No formula grammar, likelihood equation, public documentation, pkgdown
navigation, roadmap item, or known-limitation changed. The implemented TMB
branch already multiplied NB2 row contributions by `weights(i)`; this task
only added direct coverage for that route.

## What Did Not Go Smoothly

Nothing substantial. The targeted test filter also ran the neighbouring
truncated NB2 file because of the shared name, but that was useful extra
coverage and remained green.

## Team Learning

- Curie should add representative cross-family tests for shared likelihood
  machinery before adding exhaustive tests for every family.
- Ada should keep coverage commits small enough that CI failures identify the
  affected likelihood class immediately.

## Known Limitations

- Zero-inflated, hurdle, and truncated count-family weights do not yet have
  equally direct row-duplication tests.
- Dense full `meta_known_V(V = V)` still rejects non-unit weights by design.

## Next Actions

1. Add one representative zero-inflated or hurdle weight test later, after the
   core count-family coverage remains stable.
2. Continue using row-duplication tests for independent-row likelihood
   weighting where the interpretation is clear.
