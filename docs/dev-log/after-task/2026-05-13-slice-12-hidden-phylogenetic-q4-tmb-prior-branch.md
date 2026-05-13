# After Task: Slice 12 Hidden Phylogenetic q4 TMB Prior Branch

## Goal

Mirror the Slice 11 R algebra scaffold in TMB without opening public bivariate
`phylo()` syntax. The target is a hidden prior-only branch for a q=4
phylogenetic state across `mu1`, `mu2`, `sigma1`, and `sigma2`.

## Implemented

`src/drmTMB.cpp` now has hidden `model_type == 94`. It reads the existing
augmented sparse phylogenetic precision, a q by q state covariance matrix, and
the `u_re_cov_probe` vector. The branch reshapes that vector into a node by
state matrix, evaluates the matrix-normal precision-form density, and reports
the quadratic matrix for test inspection.

The TMB data contract now includes `re_cov_probe_covariance`, with dummy values
provided by `empty_labelled_covariance_block_tmb_data()` so ordinary models are
unchanged. `tests/testthat/test-phylo-utils.R` compares the hidden TMB branch
against `drm_phylo_correlated_precision_nll()` for the q=4 state.

## Team Roles

Ada kept the branch hidden. Gauss checked the precision-form TMB density.
Noether checked the vector-to-matrix ordering against the R Kronecker
comparator. Curie added the branch parity test. Rose guarded the public
boundary: bivariate `phylo()` remains planned.

## Scope Boundary

This slice does not change accepted formulas, ordinary fitted models,
`corpairs()`, `summary()`, `profile_targets()`, examples, or user-facing docs.
It is a hidden C++ parity check for the next phylogenetic bridge.

## Files Changed

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `tests/testthat/test-phylo-utils.R`
- `ROADMAP.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-12-hidden-phylogenetic-q4-tmb-prior-branch.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-phylo-utils.R ROADMAP.md
  docs/design/09-phylogenetic-and-spatial-speed.md
  docs/design/15-location-coscale-phylogenetic-extension.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-12-hidden-phylogenetic-q4-tmb-prior-branch.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-utils")'`: passed with 52
  expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Next Actions

1. Run focused phylogenetic utility tests.
2. Commit and push this hidden TMB branch.
3. Next slice: add extractor/status scaffolding for future phylogenetic q4 pair
   names, still without public fitted support.
