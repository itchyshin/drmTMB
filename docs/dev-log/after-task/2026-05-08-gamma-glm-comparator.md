# After Task: Gamma GLM Comparator

## Goal

Add an external overlap check for the new Gamma mean-CV path without pretending
that base GLM and `drmTMB` share the same full dispersion model.

## Implemented

- Added a comparator test in `tests/testthat/test-comparators.R` for
  `drmTMB(bf(biomass ~ x), family = Gamma(link = "log"))` against
  `stats::glm(biomass ~ x, family = Gamma(link = "log"))`.
- Updated `docs/design/05-testing-strategy.md` to record the comparator and
  its limit.

## Mathematical Contract

The comparator covers the shared mean equation:

```text
log(mu_i) = beta_0 + beta_1 x_i
```

It does not compare the scale parameter. In `drmTMB`, `sigma` is an ML-fitted
coefficient of variation. In base GLM summaries, the reported dispersion is
estimated through the GLM dispersion machinery, so it is not the same fitted
object.

## Files Changed

- `tests/testthat/test-comparators.R`
- `docs/design/05-testing-strategy.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'comparators|gamma-location-scale')"`:
  94 passed.
- `Rscript -e "devtools::test()"`: 764 passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- `Rscript -e "devtools::check()"`: 0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

The comparator would fail if `drmTMB` built the Gamma `mu` model matrix
incorrectly, applied the wrong inverse link, or extracted the wrong `mu`
coefficients. It also checks optimizer convergence and `pdHess`.

## Consistency Audit

The testing strategy now lists the Gamma base-GLM comparator separately from
the independent `stats::dgamma()` likelihood check. No user-facing formula
grammar or likelihood parameterization changed.

## What Did Not Go Smoothly

The tempting comparison was `sigma` or `logLik()`, but that would be a fuzzy
test because base GLM's dispersion path differs from the `drmTMB` mean-CV
likelihood. The comparator is intentionally narrower.

## Team Learning

Fisher's two-tier checking principle works best when each external comparator
states the exact overlap. External package agreement is useful, but only for
the part of the model both packages estimate in the same way.

## Known Limitations

This comparator checks the mean model only. Gamma `sigma ~ predictors` is still
validated by simulation recovery and the independent likelihood calculation.

## Next Actions

- Add optional longer Gamma checks against GAMLSS only after the exact
  parameterization and likelihood constants are written down.
- Keep adding comparators only where the overlap is mathematically explicit.
