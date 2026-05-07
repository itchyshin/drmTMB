# Known Limitations

- Gaussian location-scale models are implemented with fixed effects and simple
  `mu` random effects: random intercepts and random slopes with one numeric
  predictor per random-slope term. Multiple separate independent slope terms
  are allowed, and one-slope correlated random intercept-slope blocks are
  implemented as `(1 + x | id)` or `(1 + x | p | id)`.
- Diagonal and dense full known-covariance Gaussian meta-analysis is
  implemented.
- Fixed-effect bivariate Gaussian location-scale-coscale models are
  implemented with `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` formulas.
- The TMB template currently supports fixed effects and univariate Gaussian
  `mu` random intercepts, numeric random-slope terms, and ordinary correlated
  intercept-slope blocks with optional covariance-block labels.
- Cross-formula labelled covariance sharing, random effects in scale formulae,
  random-effect scale models, and all non-Gaussian families are planned but not
  yet implemented.
- Sparse known sampling covariance for large meta-analysis, phylogenetic, and
  spatial workloads is planned but not yet implemented.
