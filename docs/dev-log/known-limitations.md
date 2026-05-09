# Known Limitations

- Gaussian location-scale models are implemented with fixed effects and simple
  `mu` random effects: random intercepts and random slopes with one numeric
  predictor per random-slope term. Multiple separate independent slope terms
  are allowed, and one-slope correlated random intercept-slope blocks are
  implemented as `(1 + x | id)` or `(1 + x | p | id)`.
- Residual-scale random intercepts are implemented in the `sigma` formula as
  `sigma ~ x + (1 | id)`.
- Random-effect scale formulae are implemented for one or more distinct
  unlabelled Gaussian `mu` random intercepts, such as `sd(id) ~ x_group` and
  `sd(site) ~ site_type`; predictors must be constant within the named grouping
  variable after missing-row filtering.
- Diagonal and dense full known-covariance Gaussian meta-analysis is
  implemented.
- Fixed-effect bivariate Gaussian location-scale-coscale models are
  implemented with `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` formulas.
- Intercept-only phylogenetic random effects are implemented in univariate
  Gaussian location formulas as `phylo(1 | species, tree = tree)`. The tree
  must be an ultrametric `phylo` object with positive branch lengths, and every
  observed species must match a tip label.
- Structured-effect markers outside that first path, such as
  `phylo(1 + x | species, tree = tree)`, phylogenetic terms in `sigma`, and
  `spatial(1 | site, coords = coords)`, are parsed and rejected clearly, but
  they are not yet routed into fitted likelihoods.
- Internal phylogenetic tree validation, dense Brownian covariance comparators,
  sparse augmented Brownian precision helpers, pure-R prior checks, hidden TMB
  prior parity checks, and fitted univariate Gaussian `mu` simulation tests now
  exist.
- The TMB template currently supports fixed effects, univariate Gaussian `mu`
  random intercepts, numeric random-slope terms, ordinary correlated
  intercept-slope blocks with optional covariance-block labels, and univariate
  Gaussian residual-scale random intercepts in `sigma`, intercept-only
  phylogenetic location effects, plus one or more unlabelled Gaussian `mu`
  random-intercept scale formulae through `sd(group) ~ x_group`, and
  fixed-effect univariate Student-t models with `mu`, `sigma`, and `nu`.
- Cross-formula labelled covariance sharing, residual-scale random slopes,
  slope-specific random-effect scale targets, labelled-block random-effect
  scale targets, bivariate random-effect scale targets, Student-t random
  effects, Student-t known-covariance models, Student-t phylogenetic models,
  bivariate Student-t models, and non-Gaussian families beyond the first
  fixed-effect univariate Student-t path are planned but not yet implemented.
- Users should not substitute `sigma ~ x + (1 | id)` for `sd(id) ~ x_group`
  unless their scientific question is residual variability rather than
  among-group variation in the mean model.
- Sparse known sampling covariance for large meta-analysis and spatial
  workloads is planned but not yet implemented. The first sparse phylogenetic
  route is implemented for univariate Gaussian `mu` random intercepts only.
