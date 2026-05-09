# After Task: NB2 MASS Comparator

## Goal

Add an external comparator check for the plain negative-binomial 2
constant-dispersion overlap.

## Implemented

- Added `MASS` to `Suggests`.
- Added a comparator test against `MASS::glm.nb()`.
- Updated the testing strategy, testing-likelihoods vignette, and source map.

## Mathematical Contract

For the overlapping comparator case:

```text
Y_i ~ NB2(mu_i, size)
log(mu_i) = beta_0 + beta_1 x_i
Var(Y_i) = mu_i + mu_i^2 / size
```

`drmTMB` writes the same variance as:

```text
Var(Y_i) = mu_i + sigma^2 * mu_i^2
```

Therefore the comparator checks:

```text
sigma = 1 / sqrt(size) = 1 / sqrt(theta_MASS)
```

It also checks fixed-effect coefficients and `logLik()`.

## Files Changed

- `DESCRIPTION`
- `tests/testthat/test-comparators.R`
- `docs/design/05-testing-strategy.md`
- `vignettes/testing-likelihoods.Rmd`
- `vignettes/source-map.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

- `R -q -e 'packageVersion("MASS")'`
- ad hoc `drmTMB()` versus `MASS::glm.nb()` comparison
- `R -q -e 'devtools::test(filter = "comparators|nbinom2")'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `air format .` failed because `air` is not installed locally.
- `git diff --check`

Results:

- targeted comparator/NB2 tests: 139 passed, 0 failed, 0 warnings, 0 skips;
- full tests: 971 passed, 0 failed, 0 warnings, 0 skips;
- pkgdown check: no problems found;
- pkgdown site build: successful;
- R CMD check: 0 errors, 0 warnings, 0 notes;
- whitespace check: clean.

## Tests Of The Tests

- The test checks the exact scale translation from `MASS::glm.nb()`:
  `sigma = 1 / sqrt(theta)`.
- It checks `logLik()`, so a likelihood-constant or variance-function mismatch
  would be caught.
- It is intentionally restricted to `sigma ~ 1`, the only exact overlap with
  `MASS::glm.nb()`.

## Consistency Audit

Stale-wording search:

```sh
rg -n "MASS::glm.nb|glm.nb|MASS,|Negative-binomial 2 mean coefficients|test-comparators\.R" DESCRIPTION tests docs/design/05-testing-strategy.md vignettes/testing-likelihoods.Rmd vignettes/source-map.Rmd docs/dev-log/check-log.md docs/dev-log/after-task --glob '!docs/dev-log/after-task/2026-05-09-nb2-mass-comparator.md'
```

The active docs now record the comparator as implemented and state the scale
translation explicitly.

## What Did Not Go Smoothly

- Nothing substantive. The first ad hoc comparison matched on coefficients,
  transformed scale, and log-likelihood.
- The local formatter remains unavailable (`air: command not found`).

## Team Learning

- External comparators should be framed as checks for exact submodels, not as
  broad validation of every distributional extension.
- The NB2 scale translation is simple enough to teach in the testing vignette,
  which should help future contributors avoid reversing the direction of
  `sigma`.

## Known Limitations

- The comparator does not validate `sigma ~ predictors`.
- The comparator does not validate zero-inflated NB2.
- Those richer paths remain covered by simulation and independent likelihood
  tests.

## Next Actions

- Consider a small `glmmTMB` comparator only if dependency cost and TMB version
  mismatch warnings can be managed cleanly.
- Keep the next modelling feature small: hurdle/truncated counts or
  count-family diagnostics before COM-Poisson.
