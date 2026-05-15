# After Task: Phase 5b Slice 42 Fixed-Effect Design Density

## Goal

Add a small diagnostic stepping stone toward sparse fixed-effect matrices
without changing the likelihood, formula grammar, or TMB data contract.
The implemented claim is: `check_drm()` now reports the density of the largest
retained fixed-effect design block, so users and developers can distinguish
wide mostly-zero designs from genuinely dense designs.

## Implemented

- Refactored `check_fixed_effect_design_size()` to use an internal
  `fixed_effect_design_summary()` helper.
- Recorded matrix class, row count, column count, nonzero count, density, and
  object size for each retained fixed-effect design matrix.
- Added `largest_density=...` to the `fixed_effect_design_size` diagnostic row.
- Updated the diagnostic message for wide mostly-zero designs to point toward
  the future sparse fixed-effect matrix path.
- Updated the sparse fixed-effect design note, large-data vignette, roadmap,
  NEWS, and `man/check_drm.Rd`.

## Mathematical Contract

No model equation changed. For every distributional parameter, the fitted
linear predictor is still the dense product `X beta`. This slice only measures
the retained design matrices after fitting and reports whether a wide matrix is
mostly zero.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `docs/design/26-sparse-fixed-effect-matrices.md`
- `vignettes/large-data.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- `man/check_drm.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "check-drm", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::document()'`: passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_article("large-data")'`:
  passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The existing wide-factor diagnostic test now checks both the new value field
and the changed message. It would fail if `largest_density` disappeared or if
wide mostly-zero dense matrices were not labelled as sparse fixed-effect
candidates.

## Consistency Audit

The large-data vignette and sparse fixed-effect design note now agree:
`fixed_effect_design_size` reports size, width, and density, but sparse
fixed-effect matrices are still planned. The rebuilt local large-data article
contains the new density wording.

## What Did Not Go Smoothly

This slice exposed a small robustness issue in the first helper draft:
unnamed design-matrix lists would have produced an empty summary. The helper
now falls back to generated names such as `X1`, which keeps the diagnostic
usable if a future builder forgets to name a block.

## Team Learning

- Ada should keep treating Phase 5b as a ladder: diagnostic signal first,
  sparse implementation later.
- Boole should avoid adding a public `sparse_fixed` control until the dense
  versus sparse contract is tested.
- Gauss should review the first TMB sparse branch before any optimizer-facing
  change lands.
- Noether should check that future sparse and dense products produce the same
  `eta` vectors before likelihood tests.
- Curie should make the first sparse test a parity test, not a large benchmark.
- Fisher should treat density as a diagnostic cue, not inference evidence.
- Pat should keep the article clear that a sparse candidate is not a failed
  model.
- Grace should keep `pkgdown::check_pkgdown()` in the gate whenever user-facing
  diagnostics change.
- Rose should keep scanning for overclaims that density reporting is the same
  as sparse-matrix support.

## Known Limitations

- `sparse_fixed` remains unimplemented.
- The diagnostic runs after dense model matrices have already been built.
- Sparse fixed-effect memory savings still need TMB-side support and parity
  tests.

## Next Actions

The next Phase 5b slice should design the actual dense-versus-sparse parity
test and choose the first safe implementation target, probably univariate
Gaussian `mu` fixed effects with no random effects and a high-cardinality
factor.
