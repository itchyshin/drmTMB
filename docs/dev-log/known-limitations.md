# Known Limitations

- Fixed-effect Gaussian location-scale and diagonal known-variance Gaussian
  meta-analysis are implemented.
- Fixed-effect bivariate Gaussian location-scale-coscale models are
  implemented with `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` formulas.
- The TMB template currently supports fixed effects only.
- `DESCRIPTION` maintainer metadata is a placeholder.
- Random effects and all non-Gaussian families are planned but not yet
  implemented.
- Full or block-diagonal known sampling covariance for meta-analysis is planned
  but not yet implemented.
