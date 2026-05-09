# After Phase: Count-Family Seed Surface

## Goal

Record the current count-family state after the Poisson, ZIP, NB2, ZINB2, and
NB2 comparator tasks, so older task notes with earlier limitations do not
mislead the next contributor.

## Implemented

The current fixed-effect univariate count surface is:

- `family = poisson(link = "log")` with `y ~ predictors`;
- `family = poisson(link = "log")` plus `zi ~ predictors` for zero-inflated
  Poisson models;
- `family = nbinom2()` with `y ~ predictors` and optional `sigma ~ predictors`;
- `family = nbinom2()` plus `zi ~ predictors` for zero-inflated NB2 models.

There is no public `zi_poisson()`, `zi_nbinom2()`, or `meta_gaussian()`
constructor. Zero inflation is a distributional parameter formula, not a
separate response family.

## Mathematical Contract

Poisson:

```text
Y_i ~ Poisson(mu_i)
log(mu_i) = X_mu[i, ] beta_mu
E[Y_i] = Var[Y_i] = mu_i
```

Zero-inflated Poisson:

```text
Pr(Y_i = 0) = zi_i + (1 - zi_i) exp(-mu_i)
Pr(Y_i = y > 0) = (1 - zi_i) Poisson(y | mu_i)
logit(zi_i) = X_zi[i, ] beta_zi
E[Y_i] = (1 - zi_i) mu_i
```

NB2:

```text
Y_i ~ NB2(mu_i, sigma_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
size_i = 1 / sigma_i^2
Var[Y_i] = mu_i + sigma_i^2 mu_i^2
```

Zero-inflated NB2:

```text
Pr(Y_i = 0) = zi_i + (1 - zi_i) NB2(0 | mu_i, sigma_i)
Pr(Y_i = y > 0) = (1 - zi_i) NB2(y | mu_i, sigma_i)
logit(zi_i) = X_zi[i, ] beta_zi
E[Y_i] = (1 - zi_i) mu_i
```

## Files Changed

This is a roll-up note. The implementation lives in:

- `R/drmTMB.R`
- `R/methods.R`
- `R/family.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-poisson-mean.R`
- `tests/testthat/test-zi-poisson.R`
- `tests/testthat/test-nbinom2-location-scale.R`
- `tests/testthat/test-zi-nbinom2.R`
- `tests/testthat/test-comparators.R`

## Checks Run

The phase-level evidence is distributed across the individual after-task
reports. The latest full package checks after the roll-up context were:

- full tests: 981 passed, 0 failed, 0 warnings, 0 skips;
- pkgdown check: no problems found;
- pkgdown build: successful;
- R CMD check: 0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

The count-family tests include:

- simulation recovery for Poisson, ZIP, NB2, and ZINB2;
- independent density checks against `stats::dpois()` and `stats::dnbinom()`;
- mixture-boundary checks for `zi -> 0` and `zi -> 1`;
- Poisson-limit checks for NB2 as `sigma -> 0`;
- a `MASS::glm.nb()` comparator for the constant-dispersion NB2 overlap;
- complete-case and malformed-input checks for invalid count responses,
  unsupported random effects, offsets, `meta_known_V()`, and bivariate
  shorthand.

## Consistency Audit

Current active docs should say that count zero-inflation is implemented for
fixed-effect Poisson and NB2. Future work should be restricted to random-effect,
structured, hurdle, truncated, multivariate, and mixed-response count paths.

Older after-task reports for Poisson and NB2 still mention zero inflation as a
next action. Those reports are historical records and are superseded by this
phase roll-up plus the ZIP and ZINB2 after-task reports.

## What Did Not Go Smoothly

- The count-family surface expanded quickly, which made DESCRIPTION and
  overview-vignette wording stale.
- Comparator coverage is uneven by necessity: base GLM checks Poisson exactly,
  `MASS::glm.nb()` checks only constant NB2 dispersion, and ZIP/ZINB2 currently
  rely on simulation and independent likelihood tests.

## Team Learning

- Treat zero inflation as a distributional parameter formula (`zi ~ ...`), not
  a separate family name.
- Keep `mu` as the conditional count mean when `zi` is present and use
  `fitted()` for the unconditional response mean.
- Every mixture family needs a fitted-response rule, Pearson variance rule, and
  boundary test.

## Known Limitations

- No count random effects yet.
- No count offsets yet.
- No hurdle or truncated count models yet.
- No phylogenetic or spatial structured count models yet.
- No bivariate or mixed-response count models yet.

## Next Actions

- Decide beta/proportion parameterization before coding `beta()`.
- For counts, design truncated NB2 before hurdle NB2 so the positive-count
  conditional likelihood is tested first.
- Keep COM-Poisson planned, but do not implement it before simpler bounded and
  truncated-response grammar is stable.
