# After Task: Bivariate Phylogenetic Location Syntax Guard

## Goal

Create a clean parser/spec contract for the next fitted bivariate phylogenetic
location slice without claiming that the likelihood is wired yet.

## Implemented

Bivariate Gaussian models now detect `phylo()` terms in `mu1` and `mu2` before
ordinary random-effect extraction. A single-sided phylogenetic term errors with
a matched-term message. Matched terms that use different grouping variables or
tree objects error with a shared-group/shared-tree message. Matched
`phylo(1 | group, tree = tree)` terms in both location formulas are recognized,
then deliberately rejected with a message saying they are the next fitted slice.

The guard keeps `sigma1`, `sigma2`, and residual `rho12` as ordinary
fixed-effect distributional parameters for this next bivariate phylogenetic
location path.

## Team Roles

Ada kept the slice at the parser/spec boundary. Boole checked that the syntax
contract is explicit. Gauss and Noether get a cleaner handoff for the next TMB
likelihood slice. Rose checked that this does not claim fitted bivariate
`phylo()` support.

## Scope Boundary

This slice adds errors and tests only. It does not add a bivariate
phylogenetic likelihood, latent random-effect parameters, `corpairs()` rows,
simulation recovery, or user-facing documentation that calls the model fitted.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-bivariate-phylogenetic-location-syntax-guard.md`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian")'`: passed with 501
  expectations, 0 failures, 0 warnings, and 0 skips.

## Next Actions

1. Commit and push this syntax guard.
2. Start the fitted bivariate phylogenetic location likelihood slice:
   correlated phylogenetic random intercepts in `mu1`/`mu2`.
