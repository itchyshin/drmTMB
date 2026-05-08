# drmTMB 0.0.0.9000

* `bf()` now stores parsed formula entries for distributional parameters, including bivariate `rho12`, meta-analysis `meta_known_V(V = V)`, and random-effect scale syntax.
* `biv_gaussian()` now fits fixed-effect bivariate Gaussian location-scale-coscale models with separate `mu1`, `mu2`, `sigma1`, `sigma2`, and predictor-dependent `rho12` formulas.
* `drm_formula()` is now the primary formula constructor; `bf()` remains a short alias.
* `drmTMB()` now fits Gaussian location-scale models with fixed effects, random intercepts, labelled random intercepts such as `(1 | p | id)`, independent numeric random slopes, and ordinary labelled or unlabelled correlated random intercept-slope blocks in the `mu` formula, such as `bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1)`, `bf(y ~ x1 + (1 + x1 | id), sigma ~ x1)`, and `bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x1)`.
* `drmTMB()` now accepts `family = c(gaussian(), gaussian())` and `family = list(gaussian(), gaussian())`, routing both to the implemented bivariate Gaussian location-coscale likelihood. Mixed composed families such as `c(gaussian(), poisson())` remain planned and currently error clearly.
* Gaussian residual-scale random intercepts are implemented in the `sigma` formula, for example `bf(y ~ x1 + (1 | id), sigma ~ x1 + (1 | id))`. These model residual-scale heterogeneity and are distinct from random-effect scale formulae such as `sd(id) ~ x_group`.
* Gaussian random-effect scale formulae are implemented for exactly one unlabelled `mu` random intercept, for example `bf(y ~ x1 + (1 | id), sigma ~ x2, sd(id) ~ x_group)`. The `sd(id)` predictors must be constant within `id` after missing-row filtering.
* Gaussian `mu` random-effect correlations from correlated blocks are exposed as `corpars$mu`, keeping group-level labels such as `p` separate from residual bivariate `rho12`.
* `meta_known_V(V = V)` now fits Gaussian meta-analysis with diagonal or dense full known sampling covariance using `family = gaussian()`.
* `residuals()` now returns whitened Pearson residuals for bivariate Gaussian fits, and `vcov()` now uses coefficient-level row and column names.
* Initial project scaffold.
