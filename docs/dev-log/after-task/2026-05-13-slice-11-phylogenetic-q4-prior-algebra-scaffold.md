# After Task: Slice 11 Phylogenetic q4 Prior Algebra Scaffold

## Goal

Start the phylogenetic endpoint without opening public bivariate `phylo()`
syntax too early. The immediate target is the covariance algebra for a q=4
state across `mu1`, `mu2`, `sigma1`, and `sigma2` on the augmented
phylogenetic precision already used by the univariate path.

## Implemented

`R/phylo-utils.R` now has an internal
`drm_phylo_correlated_precision_nll()` helper. It evaluates a matrix-normal
Gaussian prior for a node-by-state effect matrix, using the sparse augmented
tree precision for rows and a positive-definite covariance matrix for state
columns.

`tests/testthat/test-phylo-utils.R` now checks a q=4 state against a dense
Kronecker covariance calculation. The test also checks that a diagonal
two-state covariance matches the sum of two existing independent
`drm_phylo_precision_nll()` evaluations, plus malformed covariance guards.

## Team Roles

Ada kept this as an internal scaffold. Gauss checked the matrix-normal density
form. Noether checked the q=4 state names against the endpoint vocabulary.
Curie added the dense-comparator test. Rose guarded the public-support boundary:
this is not bivariate `phylo()` support.

## Scope Boundary

This slice does not change formula grammar, accepted bivariate syntax, TMB
data, TMB likelihood code, `corpairs()`, `summary()`, or user documentation
examples. It is a tested algebra contract for the next phylogenetic bridge.

## Files Changed

- `R/phylo-utils.R`
- `tests/testthat/test-phylo-utils.R`
- `ROADMAP.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/15-location-coscale-phylogenetic-extension.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-11-phylogenetic-q4-prior-algebra-scaffold.md`

## Checks Run

- `air format R/phylo-utils.R tests/testthat/test-phylo-utils.R ROADMAP.md
  docs/design/09-phylogenetic-and-spatial-speed.md
  docs/design/15-location-coscale-phylogenetic-extension.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-11-phylogenetic-q4-prior-algebra-scaffold.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-utils")'`: passed with 49
  expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Next Actions

1. Run focused phylogenetic utility tests.
2. Commit and push this internal algebra scaffold.
3. Next phylogenetic slice: add a hidden TMB prior branch for the same
   correlated q=4 state, still without public bivariate `phylo()` syntax.
