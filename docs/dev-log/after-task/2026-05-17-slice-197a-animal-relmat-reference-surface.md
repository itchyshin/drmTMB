# Slice 197a Animal and Relmat Reference Surface

Date: 2026-05-17

Goal: make the planned animal-model and user-supplied relatedness grammar
visible in the public reference index before fitted `animal()` or `relmat()`
likelihoods are implemented.

## Standing Roles

- Ada kept this as a reference-surface slice stacked after Slice 197, not a
  fitted likelihood change.
- Boole added parser support for the planned marker grammar and kept `gr()` as
  a legacy reserved marker rather than the main public route.
- Darwin centered the reader path on animal models first, then phylogeny,
  spatial dependence, combined structural layers, and lower-level `relmat()`.
- Pat required examples that name real eco-evo questions such as additive
  genetic variance, residual predictability, genomic relatedness, and growth.
- Jason aligned the syntax with animal-model and known-relatedness package
  conventions while preserving `drmTMB`'s univariate/bivariate scope.
- Grace watched roxygen2, `NAMESPACE`, pkgdown reference ordering, targeted
  tests, and CI order after PR #149.
- Rose checked that no documentation claims fitted `animal()` or `relmat()`
  support before likelihood, diagnostics, profile targets, and recovery tests
  exist.

## What Changed

- Added exported no-op formula markers `animal()` and `relmat()` with reference
  documentation and eco-evo examples.
- Extended `drm_formula()` parser metadata so planned `animal()` and `relmat()`
  terms are recorded as structured-effect markers with one required object
  source: `pedigree`, `A`, or `Ainv` for `animal()`; `K` or `Q` for `relmat()`.
- Updated the pkgdown reference index so the structured-effect section leads
  with `animal()`, `phylo()`, `spatial()`, and `relmat()`, while `gr()` moves to
  a reserved-marker section.
- Updated roadmap and design wording so structural dependence is taught as
  animal, phylogenetic, spatial, combined phylogenetic-spatial, then advanced
  `relmat()` or other known-dependence matrices.

## Validation

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/formula-markers.R R/parse-formula.R R/drmTMB.R ROADMAP.md docs/design/01-formula-grammar.md docs/design/16-phylo-spatial-common-math.md tests/testthat/test-package-skeleton.R tests/testthat/test-gaussian-location-scale.R _pkgdown.yml NEWS.md`
- `Rscript -e "devtools::document()"`: passed on the second run after the new
  topics existed.
- `Rscript -e "devtools::test(filter = 'package-skeleton|gaussian-location-scale|nongaussian-structured-boundary', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `git diff --check`: passed.

## Remaining Risks

- `animal()` and `relmat()` are planned markers only. They do not fit models
  yet.
- The fitted implementation still needs likelihood code, dense and sparse
  known-relatedness validation, extractor labels, profile targets, simulations,
  ASReml or other optional comparator checks, and a worked animal-model article.
