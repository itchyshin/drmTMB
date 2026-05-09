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
- Fixed-effect univariate lognormal location-scale models are implemented for
  positive finite responses. `mu` and `sigma` are on the log-response scale;
  random effects, known sampling covariance, phylogenetic terms, and bivariate
  lognormal models are not yet implemented.
- Fixed-effect univariate Gamma mean-CV models are implemented for positive
  finite responses with `family = Gamma(link = "log")`. `mu` is the response
  mean and `sigma` is the coefficient of variation; non-log Gamma links,
  random effects, known sampling covariance, phylogenetic terms, and bivariate
  or mixed Gamma models are not yet implemented.
- Fixed-effect univariate Poisson mean models are implemented for
  non-negative integer counts with `family = poisson(link = "log")`.
  Zero-inflated Poisson models are implemented by adding `zi ~ predictors`;
  here `mu` is the conditional count mean and `zi` is the structural-zero
  probability. There is no modelled `sigma` parameter. Overdispersion, random
  effects, known sampling covariance, phylogenetic terms, and bivariate or
  mixed Poisson models are not yet implemented.
- Fixed-effect univariate negative-binomial 2 mean-dispersion models are
  implemented for overdispersed counts with `family = nbinom2()`. `mu` is the
  count mean and `sigma` is an overdispersion scale in
  `Var(y) = mu + sigma^2 * mu^2`; it is not a residual standard deviation or
  NB size parameter. Random effects, zero inflation, hurdle components, known
  sampling covariance, phylogenetic terms, and bivariate or mixed
  negative-binomial models are not yet implemented.
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
  It also supports fixed-effect univariate lognormal models with `mu` and
  `sigma` on the log-response scale, fixed-effect univariate Gamma mean-CV
  models with positive response mean `mu` and coefficient of variation
  `sigma`, fixed-effect univariate Poisson mean models, and fixed-effect
  univariate negative-binomial 2 mean-dispersion models.
- Cross-formula labelled covariance sharing, residual-scale random slopes,
  slope-specific random-effect scale targets, labelled-block random-effect
  scale targets, bivariate random-effect scale targets, Student-t random
  effects, Student-t known-covariance models, Student-t phylogenetic models,
  bivariate Student-t models, lognormal random-effect and structured-effect
  models, Gamma random-effect and structured-effect models, Poisson and
  negative-binomial random-effect models, zero-inflation and hurdle count
  models, and additional non-Gaussian families beyond the first Student-t,
  lognormal, Gamma, Poisson, and negative-binomial paths are planned but not
  yet implemented.
- Users should not substitute `sigma ~ x + (1 | id)` for `sd(id) ~ x_group`
  unless their scientific question is residual variability rather than
  among-group variation in the mean model.
- Sparse known sampling covariance for large meta-analysis and spatial
  workloads is planned but not yet implemented. The first sparse phylogenetic
  route is implemented for univariate Gaussian `mu` random intercepts only.
