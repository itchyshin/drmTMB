# drmTMB 0.0.0.9000

* `bf()` now stores parsed formula entries for distributional parameters, including bivariate `rho12`, meta-analysis `meta_known_V(V = V)`, and random-effect scale syntax.
* `biv_gaussian()` now fits fixed-effect bivariate Gaussian location-scale-coscale models with separate `mu1`, `mu2`, `sigma1`, `sigma2`, and predictor-dependent `rho12` formulas.
* `check_drm()` now provides a first-pass diagnostic table for optimizer convergence, fixed gradients, Hessian status, dropped rows, scale positivity, `rho12` boundaries, known sampling covariance summaries, random-effect replication, and weak random-slope design checks.
* `drm_formula()` is now the primary formula constructor; `bf()` remains a short alias.
* `drm_formula(mvbind(y1, y2) ~ x)` is now implemented as shorthand for identical bivariate Gaussian location formulas, expanding internally to `mu1 = y1 ~ x` and `mu2 = y2 ~ x`.
* `drmTMB()` now fits Gaussian location-scale models with fixed effects, random intercepts, labelled random intercepts such as `(1 | p | id)`, independent numeric random slopes, and ordinary labelled or unlabelled correlated random intercept-slope blocks in the `mu` formula, such as `bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1)`, `bf(y ~ x1 + (1 + x1 | id), sigma ~ x1)`, and `bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x1)`.
* `drmTMB()` now accepts `family = c(gaussian(), gaussian())` and `family = list(gaussian(), gaussian())`, routing both to the implemented bivariate Gaussian location-coscale likelihood. Mixed composed families such as `c(gaussian(), poisson())` remain planned and currently error clearly.
* Gaussian residual-scale random intercepts are implemented in the `sigma` formula, for example `bf(y ~ x1 + (1 | id), sigma ~ x1 + (1 | id))`. These model residual-scale heterogeneity and are distinct from random-effect scale formulae such as `sd(id) ~ x_group`.
* Gaussian random-effect scale formulae are implemented for one or more distinct unlabelled `mu` random intercepts, for example `bf(y ~ x1 + (1 | id) + (1 | site), sigma ~ x2, sd(id) ~ x_group, sd(site) ~ site_type)`. Each `sd(group)` predictor must be constant within the named group after missing-row filtering.
* Gaussian `mu` random-effect correlations from correlated blocks are exposed as `corpars$mu`, keeping group-level labels such as `p` separate from residual bivariate `rho12`.
* `deviance()`, `df.residual()`, and `nobs()` now work for `drmTMB` fits, making base-R model summaries and comparison helpers more complete.
* `fitted()` now returns fitted location values: a numeric `mu` vector for univariate Gaussian models and a two-column `mu1`/`mu2` matrix for bivariate Gaussian models.
* `fixef()` now returns distributional fixed-effect coefficients and acts as a mixed-model-friendly alias for `coef()`.
* `meta_known_V(V = V)` now fits Gaussian meta-analysis with diagonal or dense full known sampling covariance using `family = gaussian()`.
* `meta_vcov_bivariate()` now builds row-paired dense sampling covariance matrices for bivariate Gaussian meta-analysis with known within-study covariance, and `meta_known_V(V = V)` now fits complete-row bivariate Gaussian known-`V` models by adding that sampling covariance to the fitted residual covariance from `sigma1`, `sigma2`, and `rho12`.
* `ranef()` now returns fitted conditional random-effect blocks, including ordinary `mu`, residual-scale `sigma`, and current `phylo_mu` blocks when present.
* `rho12()` now returns response-scale residual correlations from bivariate Gaussian location-coscale fits, with `type = "link"` available for atanh-scale linear predictors.
* `drmTMB()` now fits intercept-only phylogenetic random effects in the univariate Gaussian location formula with `phylo(1 | species, tree = tree)`, using an ultrametric branch-length tree and the sparse augmented A-inverse path.
* Planned structured-effect markers outside that first phylogenetic path, such as `phylo(1 + x | species, tree = tree)`, phylogenetic terms in `sigma`, and `spatial(1 | site, coords = coords)`, are parsed by `drm_formula()` and rejected by `drmTMB()` with planned-feature errors until their TMB likelihoods and recovery tests are implemented.
* Public documentation now pairs symbolic model equations with matching R syntax for the first Gaussian location-scale, random-effect scale, bivariate `rho12`, meta-analysis, and phylogenetic examples, and clarifies planned spatial `coords` versus `mesh` inputs.
* `residuals()` now returns whitened Pearson residuals for bivariate Gaussian fits, and `vcov()` now uses coefficient-level row and column names.
* Initial project scaffold.
