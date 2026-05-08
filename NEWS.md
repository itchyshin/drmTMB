# drmTMB 0.0.0.9000

* `bf()` now stores parsed formula entries for distributional parameters, including bivariate `rho12`, meta-analysis `meta_known_V(V = V)`, and future random-effect scale syntax.
* `biv_gaussian()` now fits fixed-effect bivariate Gaussian location-scale-coscale models with separate `mu1`, `mu2`, `sigma1`, `sigma2`, and predictor-dependent `rho12` formulas.
* `drmTMB()` now fits Gaussian location-scale models with fixed effects, random intercepts, labelled random intercepts such as `(1 | p | id)`, independent numeric random slopes, and ordinary labelled or unlabelled correlated random intercept-slope blocks in the `mu` formula, such as `bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1)`, `bf(y ~ x1 + (1 + x1 | id), sigma ~ x1)`, and `bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x1)`.
* Gaussian residual-scale random intercepts are implemented in the `sigma` formula, for example `bf(y ~ x1 + (1 | id), sigma ~ x1 + (1 | id))`. These model residual-scale heterogeneity and are distinct from future random-effect scale formulae such as `sd(id) ~ x1`.
* Gaussian `mu` random-effect correlations from correlated blocks are exposed as `corpars$mu`, keeping group-level labels such as `p` separate from residual bivariate `rho12`.
* `meta_known_V(V = V)` now fits Gaussian meta-analysis with diagonal or dense full known sampling covariance using `family = gaussian()`.
* `residuals()` now returns whitened Pearson residuals for bivariate Gaussian fits, and `vcov()` now uses coefficient-level row and column names.
* Initial project scaffold.
