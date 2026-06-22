# Row-Specific Parity Smoke

Slice S039 records the first same-target parity smoke rows for native TMB
versus the R-to-Julia bridge. The purpose is deliberately narrow: a row can be
used as parity evidence only for the exact model cell and target named in the
table.

## Covered Rows

`tests/testthat/test-julia-tmb-parity.R` covers:

- Route C, univariate Gaussian location-scale with `sigma ~ x`: log-likelihood
  parity below `1e-6` and coefficient parity below `1e-5`.
- Route B, bivariate Gaussian residual `rho12`: log-likelihood parity below
  `1e-6`.

The same test file keeps Route A, Gaussian phylo-mean with `sigma ~ 1`,
explicitly skipped because the all-node route has a known log-likelihood bug.

## Boundary

These rows do not promote a release claim, q4 inference, non-Gaussian REML,
interval coverage, or native phylogenetic REML. They only show that two named
Gaussian bridge cells have same-target smoke evidence when a parity-capable
DRM.jl checkout and Julia home are supplied.
