# After Task: Spatial Sigma One-Slope Native Cell

## Goal

Extend the structured residual-scale one-slope lane from `phylo()` to the next
provider-safe cell: fixed-covariance coordinate `spatial()`.

The target cell is:

`spatial(1 + x | site, coords = coords)` in Gaussian `sigma`, ML, sigma-only,
native TMB route, point-fit and extractor evidence.

## Implemented

- Relaxed the univariate sigma-only structured-term gate for fixed-covariance
  spatial one-slope residual-scale cells.
- Kept animal and relmat residual-scale structured slopes blocked by the
  existing intercept-only guard.
- Kept matched `mu+sigma` structured slope cells blocked by the
  location-scale intercept-only validator.
- Added a sigma-only coordinate-spatial intercept+slope DGP helper in
  `tests/testthat/test-spatial-gaussian.R`.
- Added a positive runtime test for
  `sigma ~ spatial(1 + x | site, coords = coords)`.
- Updated the existing spatial boundary test so multi-slope sigma terms,
  labelled slope covariance, matched `mu+sigma` slope terms, and bivariate
  slope terms remain rejected.
- Updated the q-series support cell from planned to native point-fit/extractor
  status.
- Updated the q-series conversion contract, mission-control validator,
  structural-slope design prose, q-series map, NEWS, and check log.

## Evidence

The focused runtime test verifies:

- optimizer convergence;
- `phylo_mu_dpars()` reports the endpoint as `sigma`;
- q is 2 with coefficient names `(Intercept)` and `x`;
- `sdpars$sigma` has both `spatial(1 | site)` and
  `spatial(0 + x | site)`;
- no structured correlation is reported;
- `ranef()` returns the two coefficient-specific spatial fields through the
  existing provider block key;
- conditional log-sigma predictions decompose into fixed effects plus the
  structured spatial contribution;
- both direct SD profile targets are registered.

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-spatial-gaussian.R tests/testthat/test-gaussian-location-scale.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'spatial-gaussian')"` passed
  with 168 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'gaussian-location-scale|structured-re-conversion-contracts')"`
  passed with 1570 assertions.

## Claim Boundary

This slice is native point-fit and extractor evidence for one exact
fixed-covariance spatial cell. It does not add range-estimating spatial
support, mesh/SPDE support, animal or relmat residual-scale structured slopes,
matched `mu+sigma` slope cells, labelled structured slope covariance,
structured q4/q6/q8 slope cells, bridge support, interval reliability,
coverage, q4 REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML, DRAC
execution, or SR150 evidence.

## Next Actions

1. Repeat the sigma-only one-slope runtime check for `animal()`.
2. Then add `relmat()` sigma-only one-slope coverage with K/Q boundary checks.
3. Keep bridge parity, matched `mu+sigma` slope diagnostics, intervals, and
   coverage in later evidence tiers.
