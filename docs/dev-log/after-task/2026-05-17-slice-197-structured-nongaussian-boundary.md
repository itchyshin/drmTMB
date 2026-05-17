# Slice 197 Structured Non-Gaussian Boundary

Date: 2026-05-17

Goal: decide whether structured non-Gaussian effects enter Phase 18 now or stay
deferred with explicit diagnostics.

## Standing Roles

- Ada kept the slice as a boundary decision: no structured non-Gaussian
  likelihood was introduced.
- Boole checked that `phylo()`, `spatial()`, planned `animal()`, and planned
  `relmat()` markers receive a clear route-level message.
- Gauss and Noether kept the fitted structured-effect claim Gaussian-only.
- Fisher required ordinary family-specific random-effect recovery and interval
  evidence before structured non-Gaussian paths enter simulation.
- Darwin and Jason kept the animal-model route aligned with the same
  relatedness-matrix layer as phylogeny and spatial dependence, while
  preserving the need for eco-evo examples.
- Pat checked that count and bounded-response tutorials do not teach
  structured non-Gaussian examples as fitted.
- Grace watched formatting, targeted tests, pkgdown, and PR CI order.
- Rose checked roadmap, validation-debt, known-limitations, and tutorial
  wording for accidental fitted claims.

## What Changed

- The generic structured-effect boundary now recognizes `phylo`, `spatial`,
  planned `animal`, and planned `relmat` markers.
- The unsupported message now states that current fitted structured paths are
  Gaussian-only and that structured count, bounded, ordinal, shape, inflation,
  hurdle, and one-inflation paths remain deferred.
- Added a focused structured non-Gaussian boundary test across count, bounded,
  positive-continuous, ordinal, phylogenetic, spatial, animal, and `relmat`
  marker requests, including location, scale, shape, inflation, and hurdle
  subformulas.
- Updated the roadmap, family registry, validation-debt register, known
  limitations, and count/proportion tutorials.

## Validation

- `air format R/drmTMB.R ROADMAP.md docs/design/02-family-registry.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md vignettes/count-nbinom2.Rmd vignettes/proportion-beta-binomial.Rmd tests/testthat/test-nongaussian-structured-boundary.R`
- `Rscript -e "devtools::test(filter = 'nongaussian-structured-boundary|cumulative-logit', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `git diff --check`: passed.

## Remaining Risks

- This slice does not implement non-Gaussian `phylo()`, `spatial()`,
  `animal()`, or `relmat()` effects.
- The likely future path is still ordinary family-specific random effects
  first, then one intercept-only structured `mu` path for a single
  non-Gaussian family with recovery, profile targets, extractors, and
  diagnostics.
