# Slice 195 Inflation, Hurdle, and One-Inflation Boundary

Date: 2026-05-17

Goal: close the zero-inflation, hurdle, and one-inflation random-effect gate
before Phase 18 by making unsupported requests explicit and by keeping
bounded-response one-inflation fixed-effect-first.

## Standing Roles

- Ada kept the slice narrow: boundary messages, tests, docs, and roadmap
  status, not a new likelihood.
- Boole checked the grammar boundary for `zi`, `hu`, planned `zoi`, and
  planned `coi`.
- Gauss and Noether kept the likelihood claim honest: no inflation,
  hurdle, one-inflation, or cross-parameter random-effect likelihood was
  introduced.
- Fisher required the future path to name extractor, interval, profile-target,
  and simulation-recovery evidence before fitting random effects.
- Pat and Darwin kept the user-facing interpretation clear for count and
  bounded-response examples.
- Grace watched formatting, targeted tests, pkgdown, and the open CI lane.
- Rose checked that the roadmap, validation-debt register, known limitations,
  and vignettes do not imply fitted support where only a boundary exists.

## What Changed

- Added component-specific errors for random-effect bar terms in `zi` and `hu`
  formulas.
- Added zero-inflated NB2 and hurdle NB2 count-side random-effect boundaries
  when `mu` contains a bar term while `zi` or `hu` is present.
- Added fixed-effect-first errors for planned bounded-response `zoi` and `coi`
  formulas in beta and beta-binomial routes, with a separate message when those
  planned formulas contain random effects.
- Recorded that future covariance among `mu`, `sigma`, shape, inflation,
  hurdle, and one-inflation random effects should use constant block
  correlations only after each component random-effect path is stable.
- Updated the roadmap, family registry, validation-debt register, known
  limitations, and family/count/proportion vignettes to reflect the Slice 195
  boundary.

## Validation

- `air format R/drmTMB.R ROADMAP.md docs/design/02-family-registry.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md vignettes/distribution-families.Rmd vignettes/count-nbinom2.Rmd vignettes/proportion-beta-binomial.Rmd tests/testthat/test-zi-poisson.R tests/testthat/test-zi-nbinom2.R tests/testthat/test-hurdle-nbinom2.R tests/testthat/test-beta-location-scale.R tests/testthat/test-beta-binomial.R`
- `Rscript -e "devtools::test(filter = 'zi-poisson|zi-nbinom2|hurdle-nbinom2|beta-location-scale|beta-binomial', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `git diff --check`: passed.

## Remaining Risks

- This slice does not implement fixed-effect zero-one-inflated beta or
  beta-binomial likelihoods.
- This slice does not implement random effects in `zi`, `hu`, `zoi`, `coi`, or
  the count-side `mu` path of zero-inflated and hurdle routes.
- Cross-parameter covariance involving inflation, hurdle, or shape random
  effects remains design-only until the separate component random-effect paths
  exist and have recovery evidence.
