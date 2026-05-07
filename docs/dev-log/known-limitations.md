# Known Limitations

- Gaussian location-scale models are implemented with fixed effects and `mu`
  random intercepts.
- Diagonal and dense full known-covariance Gaussian meta-analysis is
  implemented.
- Fixed-effect bivariate Gaussian location-scale-coscale models are
  implemented with `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` formulas.
- The TMB template currently supports fixed effects and univariate Gaussian
  `mu` random intercepts.
- Random slopes, random effects in scale formulae, random-effect scale models,
  and all non-Gaussian families are planned but not yet implemented.
- Sparse known sampling covariance for large meta-analysis, phylogenetic, and
  spatial workloads is planned but not yet implemented.
