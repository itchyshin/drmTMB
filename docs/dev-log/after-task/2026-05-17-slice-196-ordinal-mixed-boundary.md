# Slice 196 Ordinal Mixed-Model Boundary

Date: 2026-05-17

Goal: separate the fixed-effect cumulative-logit ordinal path from future
ordinal mixed models before the Phase 18 simulation gate.

## Standing Roles

- Ada kept the slice to an explicit unsupported boundary rather than a partial
  ordinal mixed likelihood.
- Boole checked that ordinary formula syntax such as `(1 | id)` is recognized
  as a planned ordinal mixed-model request, not a generic malformed formula.
- Gauss and Noether kept the fixed-effect cumulative-logit likelihood
  unchanged.
- Fisher required the future path to include cutpoint stability, weak-SD
  recovery, profile targets, and `ordinal::clmm` comparator checks.
- Pat checked that users see the first future target, `(1 | id)`, before the
  more ambitious random-slope path.
- Grace watched formatting, tests, pkgdown, and the open PR/CI queue.
- Rose checked that the roadmap, validation-debt register, known limitations,
  and formula grammar do not imply fitted ordinal random effects.

## What Changed

- Added an ordinal-specific error for cumulative-logit `mu` formulas that
  contain random-effect bar terms.
- Recorded `(1 | id)` as the first future ordinal mixed-model target, with
  random slopes staged later.
- Updated the roadmap, family registry, validation-debt register, known
  limitations, and family/formula vignettes to keep ordinal random effects
  separate from Gaussian random slopes.

## Validation

- `air format R/drmTMB.R ROADMAP.md docs/design/02-family-registry.md docs/design/34-validation-debt-register.md docs/dev-log/known-limitations.md vignettes/distribution-families.Rmd vignettes/formula-grammar.Rmd tests/testthat/test-cumulative-logit.R`
- `Rscript -e "devtools::test(filter = 'cumulative-logit', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `git diff --check`: passed.

## Remaining Risks

- This slice does not implement ordinal random effects, ordinal scale or
  discrimination formulas, known covariance, phylogenetic or spatial ordinal
  effects, bivariate ordinal models, or mixed-response ordinal models.
- Existing ordinal cutpoint profile targets are internal cutpoint targets; they
  are not evidence for ordinal random-effect intervals.
