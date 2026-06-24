# After Task: Phylo Sigma One-Slope Native Cell

## Goal

Open the first structured residual-scale one-slope cell while keeping the
q-series boundary narrow.

The target cell is:

`phylo(1 + x | species, tree = tree)` in Gaussian `sigma`, ML,
sigma-only, native TMB route, point-fit and extractor evidence.

## Implemented

- Relaxed the univariate sigma-only structured-term gate for the first
  phylogenetic one-slope residual-scale cell.
- Kept non-phylo residual-scale structured slopes blocked by the existing
  intercept-only guard.
- Kept matched `mu+sigma` structured slope cells blocked by the
  location-scale intercept-only validator.
- Added a sigma-only phylogenetic intercept+slope DGP helper in
  `tests/testthat/test-phylo-gaussian.R`.
- Added a positive runtime test for
  `sigma ~ phylo(1 + x | species, tree = tree)`.
- Added rejection checks for sigma multi-slope phylo terms and matched
  `mu+sigma` phylo slope terms.
- Renamed the phylo sigma one-slope q-series support cell out of its planned
  id and into `qseries_phylo_q1_sigma_one_slope`.
- Updated the q-series conversion contract, mission-control validator, and
  structural-slope design prose.

## Evidence

The focused runtime test verifies:

- optimizer convergence;
- `phylo_mu_dpars()` reports the endpoint as `sigma`;
- q is 2 with coefficient names `(Intercept)` and `x`;
- `sdpars$sigma` has both `phylo(1 | species)` and
  `phylo(0 + x | species)`;
- no structured correlation is reported;
- `ranef()` returns the two coefficient-specific phylogenetic fields through
  the existing provider block key;
- conditional log-sigma predictions decompose into fixed effects plus
  structured phylogenetic contribution;
- both direct SD profile targets are registered.

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'phylo-gaussian')"` passed
  with 289 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1488 assertions.

## Claim Boundary

This slice is native point-fit and extractor evidence for one exact cell. It
does not add spatial, animal, or relmat residual-scale structured slopes. It
does not add matched `mu+sigma` slope cells, labelled structured slope
covariance, structured q4/q6/q8 slope cells, bridge support, interval
reliability, coverage, q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian
REML, DRAC execution, or SR150 evidence.

## Next Actions

1. Repeat the sigma-only one-slope runtime check for fixed-covariance
   `spatial()`.
2. Then add animal and relmat sigma-only one-slope cells, keeping K/Q and
   A/Ainv boundaries visible.
3. Only after provider runtime cells are banked, add same-target bridge
   fixture rows and then consider matched `mu+sigma` slope diagnostics.
