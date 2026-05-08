# Known Limitations

- Gaussian location-scale models are implemented with fixed effects and simple
  `mu` random effects: random intercepts and random slopes with one numeric
  predictor per random-slope term. Multiple separate independent slope terms
  are allowed, and one-slope correlated random intercept-slope blocks are
  implemented as `(1 + x | id)` or `(1 + x | p | id)`.
- Residual-scale random intercepts are implemented in the `sigma` formula as
  `sigma ~ x + (1 | id)`.
- Diagonal and dense full known-covariance Gaussian meta-analysis is
  implemented.
- Fixed-effect bivariate Gaussian location-scale-coscale models are
  implemented with `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` formulas.
- The TMB template currently supports fixed effects, univariate Gaussian `mu`
  random intercepts, numeric random-slope terms, ordinary correlated
  intercept-slope blocks with optional covariance-block labels, and univariate
  Gaussian residual-scale random intercepts in `sigma`.
- Cross-formula labelled covariance sharing, residual-scale random slopes,
  random-effect scale models such as `sd(id) ~ x`, and all non-Gaussian
  families are planned but not yet implemented.
- `sd(id) ~ x` is planned for modelling predictors of the standard deviation
  of a `mu` random effect. Users should not substitute
  `sigma ~ x + (1 | id)` unless their scientific question is residual
  variability rather than among-group variation in the mean model.
- Sparse known sampling covariance for large meta-analysis, phylogenetic, and
  spatial workloads is planned but not yet implemented.
