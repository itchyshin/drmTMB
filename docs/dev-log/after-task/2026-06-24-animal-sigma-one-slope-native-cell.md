# After Task: Animal Sigma One-Slope Native Cell

## Goal

Extend the structured residual-scale one-slope lane to the next provider:
`animal()` with an explicit additive covariance matrix.

The target cell is:

`animal(1 + x | id, A = A)` in Gaussian `sigma`, ML, sigma-only, native TMB
route, point-fit and extractor evidence.

## Implemented

- Relaxed the univariate sigma-only structured-term gate for the animal
  A-matrix one-slope residual-scale cell.
- Kept relmat residual-scale structured slopes blocked by the existing
  intercept-only guard.
- Kept matched `mu+sigma` structured slope cells blocked by the
  location-scale intercept-only validator.
- Added a sigma-only animal intercept+slope DGP helper in
  `tests/testthat/test-animal-relmat-gaussian.R`.
- Added a positive runtime test for `sigma ~ animal(1 + x | id, A = A)`.
- Added a guard that matched `mu+sigma` animal slope terms remain rejected.
- Updated the q-series support cell from planned to native point-fit/extractor
  status.
- Updated the q-series conversion contract, mission-control validator,
  structural-slope design prose, q-series map, NEWS, and check log.

## Evidence

The focused runtime test verifies:

- optimizer convergence;
- `phylo_mu_dpars()` reports the endpoint as `sigma`;
- q is 2 with coefficient names `(Intercept)` and `x`;
- `sdpars$sigma` has both `animal(1 | id)` and `animal(0 + x | id)`;
- no structured correlation is reported;
- `ranef()` returns the two coefficient-specific animal fields through the
  existing provider block key;
- conditional log-sigma predictions decompose into fixed effects plus the
  structured animal contribution;
- both direct SD profile targets are registered.

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-animal-relmat-gaussian.R`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian')"`
  passed with 200 assertions.

## Claim Boundary

This slice is native point-fit and extractor evidence for one exact A-matrix
animal cell. It does not add pedigree/Ainv bridge marshalling, relmat
residual-scale structured slopes, matched `mu+sigma` slope cells, labelled
structured slope covariance, structured q4/q6/q8 slope cells, bridge support,
interval reliability, coverage, q4 REML, q4 AI-REML, HSquared AI-REML,
non-Gaussian REML, DRAC execution, or SR150 evidence.

## Next Actions

1. Add the relmat sigma-only one-slope cell with K/Q boundary checks.
2. Keep bridge parity, matched `mu+sigma` slope diagnostics, intervals, and
   coverage in later evidence tiers.
