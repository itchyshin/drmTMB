# drmTMB 0.0.0.9000

* `bf()` now stores parsed formula entries for distributional parameters, including bivariate `rho12`, meta-analysis `meta_known_V(V = V)`, and future random-effect scale syntax.
* `biv_gaussian()` now fits fixed-effect bivariate Gaussian location-scale-coscale models with separate `mu1`, `mu2`, `sigma1`, `sigma2`, and predictor-dependent `rho12` formulas.
* `drmTMB()` now fits the Phase 1 fixed-effect Gaussian location-scale model `bf(y ~ x, sigma ~ z)` with TMB.
* `meta_known_V(V = vi)` now fits diagonal known-variance Gaussian meta-analysis using `family = gaussian()`.
* `residuals()` now returns whitened Pearson residuals for bivariate Gaussian fits, and `vcov()` now uses coefficient-level row and column names.
* Initial project scaffold.
