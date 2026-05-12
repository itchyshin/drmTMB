# Known Limitations

- Gaussian location-scale models are implemented with fixed effects and simple
  `mu` random effects: random intercepts and random slopes with one numeric
  predictor per random-slope term. Multiple separate independent slope terms
  are allowed, and one-slope correlated random intercept-slope blocks are
  implemented as `(1 + x | id)` or `(1 + x | p | id)`.
- Residual-scale random intercepts and independent numeric random slopes are
  implemented in the `sigma` formula as `sigma ~ x + (1 | id)` and
  `sigma ~ x + (0 + w | id)`.
- The first univariate Gaussian cross-formula covariance block is implemented
  for matching labelled `mu` and `sigma` random intercepts, such as
  `y ~ x + (1 | p | id)` with `sigma ~ z + (1 | p | id)`.
- Random-effect scale formulae are implemented for one or more distinct
  unlabelled Gaussian `mu` random intercepts, such as `sd(id) ~ x_group` and
  `sd(site) ~ site_type`; predictors must be constant within the named grouping
  variable after missing-row filtering.
- Diagonal and dense full known-covariance Gaussian meta-analysis is
  implemented.
- Bivariate Gaussian location-scale-coscale models are implemented with `mu1`,
  `mu2`, `sigma1`, `sigma2`, and `rho12` formulas. The first group-level
  bivariate covariance slice is implemented for matching labelled
  random-intercept terms in `mu1` and `mu2`, such as `(1 | p | id)` in both
  response formulas. Bivariate random slopes, residual-scale random effects,
  and double-hierarchical cross-parameter covariance are still planned;
  residual `rho12` should not be interpreted as a phylogenetic, spatial, or
  group-level covariance parameter.
- `corpairs()` currently reports only correlations that are already fitted:
  residual bivariate `rho12` summaries and ordinary univariate Gaussian `mu`
  random-effect correlations, plus the implemented univariate `mu`/`sigma`
  mean-scale random-intercept correlation and bivariate `mu1`/`mu2`
  random-intercept correlation. It does not yet report phylogenetic, spatial,
  or study-level correlation pairs.
- `summary()`, `predict_parameters()`, and `marginal_parameters()` expose
  fitted response-scale parameter summaries for interpretation. `summary()` can
  attach opt-in Wald intervals and direct profile intervals for profile-ready
  rows, including the first `mu`/`sigma` and bivariate `mu1`/`mu2`
  random-intercept correlations. The first marginal helper computes unweighted
  plug-in means only; it does not yet compute uncertainty, standard errors,
  contrasts, plots, or full `emmeans`-style marginalisation.
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
  The `mu` formula supports standard R exposure offsets such as
  `offset(log(trap_nights))`. Zero-inflated Poisson models are implemented by
  adding `zi ~ predictors`; here `mu` is the conditional count mean and `zi` is
  the structural-zero probability. There is no modelled `sigma` parameter.
  Overdispersion, random effects, known sampling covariance, phylogenetic
  terms, and bivariate or mixed Poisson models are not yet implemented.
- Fixed-effect univariate negative-binomial 2 mean-dispersion models are
  implemented for overdispersed counts with `family = nbinom2()`. `mu` is the
  count mean and `sigma` is an overdispersion scale in
  `Var(y) = mu + sigma^2 * mu^2`; it is not a residual standard deviation or
  NB size parameter. The `mu` formula supports standard R exposure offsets
  such as `offset(log(trap_nights))`. Zero-inflated NB2 models are implemented
  by adding `zi ~ predictors`; here `mu` and `sigma` describe the conditional
  count component and `zi` is the structural-zero probability. Zero-truncated NB2
  models are implemented with `family = truncated_nbinom2()` for positive
  counts; here `mu` and `sigma` describe the untruncated count component and
  `fitted()` returns the conditional positive-count mean. Hurdle NB2 models
  are implemented by adding `hu ~ predictors`; `hu` is the hurdle-zero
  probability and nonzero counts come from the zero-truncated NB2 component.
  Random effects, known sampling covariance, phylogenetic terms, and bivariate
  or mixed negative-binomial models are not yet implemented.
- Fixed-effect univariate cumulative-logit ordinal models are implemented for
  ordered responses with `family = cumulative_logit()`. The first path supports
  only a `mu` location formula, ordered cutpoints, and a fixed latent logistic
  scale. Ordinal `sigma` or discrimination formulas, random effects, known
  sampling covariance, phylogenetic terms, bivariate or mixed ordinal models,
  and non-logit ordinal links are not yet implemented.
- Fixed-effect univariate beta-binomial models are implemented for counted
  successes and failures with `family = beta_binomial()`. The first path
  supports `cbind(successes, failures)` responses, fixed-effect `mu` and
  `sigma` formulas, known trial totals from row sums, and no random effects,
  known sampling covariance, phylogenetic terms, bivariate or mixed
  beta-binomial models, or successes/trials response alias.
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
  Gaussian residual-scale random intercepts and independent random slopes in
  `sigma`, the first labelled
  univariate `mu`/`sigma` random-intercept covariance block, intercept-only
  phylogenetic location effects, plus one or more unlabelled Gaussian `mu`
  random-intercept scale formulae through `sd(group) ~ x_group`, matched
  labelled bivariate Gaussian `mu1`/`mu2` random-intercept covariance blocks,
  and fixed-effect univariate Student-t models with `mu`, `sigma`, and `nu`.
  It also supports fixed-effect univariate lognormal models with `mu` and
  `sigma` on the log-response scale, fixed-effect univariate Gamma mean-CV
  models with positive response mean `mu` and coefficient of variation
  `sigma`, fixed-effect univariate Poisson mean models, fixed-effect
  univariate negative-binomial 2 mean-dispersion models, zero-inflated variants
  for Poisson and NB2 through `zi ~ predictors`, a zero-truncated NB2 path for
  positive counts, a hurdle NB2 path through `hu ~ predictors`, a
  fixed-effect univariate cumulative-logit ordinal path, and a fixed-effect
  univariate beta-binomial path.
- Cross-formula labelled covariance sharing beyond the first univariate
  intercept-only `mu`/`sigma` block, correlated residual-scale random-slope
  blocks, slope-specific random-effect scale targets, labelled-block random-effect
  scale targets, bivariate random-effect scale targets, Student-t random
  effects, Student-t known-covariance models, Student-t phylogenetic models,
  bivariate Student-t models, lognormal random-effect and structured-effect
  models, Gamma random-effect and structured-effect models, beta-binomial
  random-effect and structured-effect models, ordinal scale or discrimination
  models, Poisson and negative-binomial random-effect models, hurdle count
  models beyond the fixed-effect NB2 path, count zero-inflation with random
  effects or structured effects, and additional non-Gaussian families beyond
  the first Student-t, lognormal, Gamma, beta, beta-binomial, Poisson,
  negative-binomial, zero-inflated, zero-truncated, and hurdle paths are
  planned but not yet implemented.
- Users should not substitute `sigma ~ x + (1 | id)` for `sd(id) ~ x_group`
  unless their scientific question is residual variability rather than
  among-group variation in the mean model.
- Sparse known sampling covariance for large meta-analysis and spatial
  workloads is planned but not yet implemented. The first sparse phylogenetic
  route is implemented for univariate Gaussian `mu` random intercepts only.
- `weights =` is implemented as ordinary likelihood weights: one
  non-negative finite weight per observation for univariate models, and one
  weight per complete response pair for bivariate models. Known sampling
  covariance remains `meta_known_V(V = V)`, not `weights`. Full dense
  `meta_known_V(V = V)` covariance paths currently reject non-unit weights
  because they are joint MVN likelihood blocks.
- The first large-data storage controls are implemented through
  `drm_control(keep_data = FALSE, keep_model_frame = FALSE, keep_tmb_object = FALSE)`,
  but current fits still build ordinary R model frames and dense fixed-effect
  model matrices before optimization. Before claiming readiness for millions of
  rows, `drmTMB` still needs sparse fixed-effect matrices where appropriate,
  aggregation for repeated Gaussian rows, and repeated large phylogenetic
  benchmark runs beyond the initial optional harness in
  `bench/large-phylo-location.R`.
