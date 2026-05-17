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
  `sd(site) ~ site_type`, and for bivariate Gaussian location random
  intercepts as `sd1(id) ~ x_group` and `sd2(id) ~ x_group`; predictors must be
  constant within the named grouping variable after missing-row filtering.
  These direct-SD formulae target location random effects only. Names such as
  `sd_sigma1()` and `sd_sigma2()` are rejected because residual scale should be
  modelled through `sigma1` / `sigma2` formulas or through Family A scale
  random effects, not by mixing both formulations for the same latent layer.
  The same direct-SD syntax is rejected for a group that is already using the
  all-four ordinary q=4 Family A covariance block, because that would require a
  predictor-dependent four-dimensional covariance model.
  Explicit coefficient-specific targets such as
  `sd(id, dpar = "mu", coef = "x1") ~ x_group` are parsed as reserved grammar
  but rejected by `drmTMB()` until random-slope SD regression has a covariance
  model and tests.
- Diagonal and dense full known-covariance Gaussian meta-analysis is
  implemented. Full-matrix `meta_known_V(V = V)` currently stores the retained
  covariance as a dense R matrix; `check_drm()` reports that row as a note with
  dimension, density, size, rank, and conditioning because dense `V` is a
  small-to-moderate route until sparse or block-sparse storage exists.
- Sparse fixed-effect matrices are implemented only for the first univariate
  Gaussian `mu` path through `drm_control(sparse_fixed = TRUE)`. The model must
  have fixed effects only, intercept-only `sigma`, no known covariance, no
  ordinary random effects, no direct-SD formulas, and no phylogenetic or
  spatial structured effects. Sparse `sigma`, bivariate, non-Gaussian,
  random-effect, and structured-effect fixed-effect matrices remain planned.
- Gaussian sufficient-statistic aggregation is implemented only for the first
  opt-in univariate Gaussian fixed-effect path through
  `drm_control(aggregate_gaussian = TRUE)`. Rows can be collapsed only when
  they share the same processed `mu` and `sigma` design state after row
  filtering. Random effects, direct-SD formulas, phylogenetic or spatial
  structured effects, known sampling covariance, bivariate models,
  non-Gaussian families, non-unit likelihood weights, and combined sparse
  fixed-effect matrices remain out of scope. Fitted-row predictions and
  residuals still use stored original-row model matrices and response vectors;
  no cell-level residual method is exposed yet.
- Bivariate Gaussian location-scale-coscale models are implemented with `mu1`,
  `mu2`, `sigma1`, `sigma2`, and `rho12` formulas. The first group-level
  bivariate covariance slices are implemented for matching labelled
  random-intercept terms in `mu1`/`mu2`, `sigma1`/`sigma2`, and one
  same-response `mu`/`sigma` pair such as `mu1` with `sigma1`. The same labelled
  random-intercept term can also be used in all four bivariate formulas to fit
  one ordinary q=4 location-scale covariance block with all six latent
  correlations. `check_drm()` reports a first q4 diagnostic for group
  replication, tiny component SDs, and near-boundary latent correlations.
  Bivariate random slopes, random effects in `rho12`, predictor-dependent q=4
  phylogenetic correlations, and spatial q=4 blocks are still planned;
  residual `rho12` should not be interpreted as a phylogenetic, spatial, or
  group-level covariance parameter.
- Phylogenetic random slopes and richer spatial random slopes should stay staged
  behind recovery evidence. The first coordinate-spatial `mu` slope is fitted as
  independent intercept and slope fields with no intercept-slope `corpair()`
  row. Multiple random factors should be separate additive blocks, not one
  enlarged cross-factor covariance model. A later coefficient-aware `corpair()`
  design may target the bivariate slope1-slope2 plasticity-syndrome case for
  the same covariate across responses.
- Matching intercept-only `phylo(1 | species, tree = tree)` terms are fitted
  in bivariate Gaussian `mu1` and `mu2` formulas. This first phylogenetic
  bivariate slice estimates two phylogenetic location SDs and one phylogenetic
  mean-mean correlation while keeping `sigma1`, `sigma2`, and residual `rho12`
  as fixed-effect distributional parameters. Matching labelled phylogenetic
  terms across `mu1`, `mu2`, `sigma1`, and `sigma2` fit the first constant q=4
  location-scale block. A CRAN-safe recovery test checks broad fixed-effect,
  SD, residual-correlation, finite-gradient, and q=4 diagnostic behavior, but
  the six q=4 correlation intervals are currently derived targets rather than
  direct profile-ready targets. `summary(fit)$covariance` reports the fitted
  phylogenetic variance and covariance point summaries, and `check_drm()`
  reports separate bivariate phylogenetic q=2 and q=4 covariance diagnostics
  for near-boundary `corpars$phylo` values, weak species replication, location
  SDs that are tiny relative to matching residual scales, and tiny log-`sigma`
  endpoint SDs in q=4 models. Family B direct structured-SD formulas such as
  `sd_phylo(species) ~ x_species` are implemented for univariate phylogenetic
  location models, and `sd_phylo1()` / `sd_phylo2()` are implemented for
  matching bivariate phylogenetic location models. Spatial direct-SD siblings
  remain planned. `check_drm()` reports species replication
  and the fitted species-level SD range for each univariate or bivariate
  `sd_phylo*()` direct-SD endpoint, but broad recovery grids across tree shape,
  predictor strength, and weak SD surfaces remain future validation work. The
  bivariate `sd_phylo1()` / `sd_phylo2()` path is implemented as a
  location-only response-specific direct-SD model; it is not a way to model
  residual `sigma1` / `sigma2` random-effect SDs or q=4 phylogenetic
  location-scale endpoint SDs.
- `corpairs()` currently reports only correlations that are already fitted:
  residual bivariate `rho12` summaries and ordinary univariate Gaussian `mu`
  random-effect correlations, plus the implemented univariate `mu`/`sigma`
  mean-scale random-intercept correlation and bivariate `mu1`/`mu2`
  random-intercept, `sigma1`/`sigma2` random-intercept, and same-response
  bivariate `mu`/`sigma` random-intercept correlations. It reports all six
  ordinary q=4 all-four bivariate random-intercept correlations when that block
  is fitted, and it also reports the fitted bivariate phylogenetic mean-mean
  correlation and the six phylogenetic q=4 endpoint correlations when that
  block is fitted. For the first ordinary q=2 predictor-dependent
  `corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ x`
  route, `corpairs()` reports the fitted mean, range, and number of group-level
  latent correlation values. Spatial and study-level correlation pairs remain
  planned.
- Singular endpoint-specific `corpair()` formula syntax is fitted for ordinary
  q=2 and phylogenetic q=2 `mu1`/`mu2` location-location routes. Spatial,
  location-scale, scale-scale, and q=4 predictor-dependent latent correlation
  regressions remain planned. The fitted phylogenetic
  `corpair(..., level = "phylogenetic") ~ w` route uses two independent unit
  phylogenetic fields and species-specific loadings, targets only the
  phylogenetic `mu1`-`mu2` location-location row, and reports modelled mean,
  range, and species counts through `corpairs()`. Phylogenetic location-scale
  and scale-scale correlation regressions require a q=4 contract and remain
  deferred. Use `rho12 = ~ x` for residual within-observation correlation. For
  fitted q=2 `corpair()` routes,
  `confint(fit, parm = "corpair(...)", newdata = ...)` can profile
  response-scale latent correlations at supplied group-level predictor rows,
  but `corpairs(conf.int = TRUE)` still marks the summary row as
  `newdata_required` because it reports a mean and range over groups.
  - Internal q4 phylogenetic algebra, the hidden TMB prior probe, and the public
    bivariate Gaussian q=4 phylogenetic location-scale endpoint now use the same
    endpoint order. The ordinary grouped q4 location-scale block,
    `mu1`/`mu2` phylogenetic location slice, and constant phylogenetic q4
    location-scale block are fitted. Predictor-dependent structured
    correlations, spatial q=4 blocks, and direct profile intervals for q4
    derived correlations remain planned.
- `summary()`, `predict_parameters()`, and `marginal_parameters()` expose
  fitted response-scale parameter summaries for interpretation. `summary()` can
  attach opt-in Wald intervals and direct profile intervals for profile-ready
  rows, including the first univariate and same-response bivariate `mu`/`sigma`,
  bivariate `mu1`/`mu2`, and bivariate `sigma1`/`sigma2` random-intercept
  correlations, plus the first bivariate phylogenetic `mu1`/`mu2` mean-mean
  correlation. Ordinary q4 unstructured-correlation rows are listed by
  `profile_targets()` but are not direct profile-ready targets yet because the
  optimized `theta_re_cov` coordinates are not pairwise atanh correlations.
  Interval-aware summaries now carry explicit `conf.status` values, and profile
  interval rows carry `profile.boundary` plus `profile.message`. Direct
  response-scale `summary()` parameter rows can report delta-method standard
  errors when `TMB::sdreport()` succeeds, but descriptive fitted ranges and
  derived variance ratios still do not have standard errors. The current
  boundary diagnostics are endpoint flags, not a full profile-shape classifier:
  one-sided intervals, automatic recovery from non-monotone profiles, and
  bootstrap fallback remain planned. Calls such as
  `confint(fit, method = "bootstrap")`,
  `summary(fit, conf.int = TRUE, method = "bootstrap")`, and
  `corpairs(fit, conf.int = TRUE, method = "bootstrap")` error before interval
  work begins because public bootstrap intervals are not implemented yet. The
  first marginal helper computes
  unweighted plug-in means only; it does not yet compute uncertainty, standard
  errors, contrasts, plots, or full `emmeans`-style marginalisation.
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
  Gaussian `mu` formulas and matching bivariate Gaussian `mu1`/`mu2` formulas
  as `phylo(1 | species, tree = tree)`. The tree must be an ultrametric
  `phylo` object with positive branch lengths, and every observed species must
  match a tip label.
- Structured-effect markers outside the fitted paths, such as
  `phylo(1 + x | species, tree = tree)`, phylogenetic terms in `sigma`, and
  `spatial(1 | site, mesh = mesh)`, are parsed and rejected clearly, but they
  are not yet routed into fitted likelihoods. The coordinate-based spatial
  paths, `spatial(1 | site, coords = coords)` and
  `spatial(1 + x | site, coords = coords)`, are fitted only for univariate
  Gaussian `mu` and use a fixed coordinate covariance foundation. They are not
  the scalable mesh/SPDE route. The mesh/SPDE design gate is recorded in
  `docs/design/09-phylogenetic-and-spatial-speed.md`, while spatial `sigma`,
  bivariate spatial q=4 blocks, spatial slope correlations, and spatial
  `corpair()` regressions remain planned.
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
  labelled bivariate Gaussian `mu1`/`mu2`, `sigma1`/`sigma2`, and same-response
  `mu`/`sigma` random-intercept covariance blocks, and fixed-effect univariate
  Student-t models with `mu`, `sigma`, and `nu`.
  It also supports fixed-effect univariate lognormal models with `mu` and
  `sigma` on the log-response scale, fixed-effect univariate Gamma mean-CV
  models with positive response mean `mu` and coefficient of variation
  `sigma`, fixed-effect univariate Poisson mean models, fixed-effect
  univariate negative-binomial 2 mean-dispersion models, zero-inflated variants
  for Poisson and NB2 through `zi ~ predictors`, a zero-truncated NB2 path for
  positive counts, a hurdle NB2 path through `hu ~ predictors`, a
  fixed-effect univariate cumulative-logit ordinal path, and a fixed-effect
  univariate beta-binomial path.
- Cross-formula labelled covariance sharing beyond the implemented univariate
  intercept-only `mu`/`sigma` blocks, the first same-parameter bivariate
  intercept blocks, same-response bivariate `mu`/`sigma` pairs, and the ordinary
  all-four bivariate q4 intercept block, correlated residual-scale random-slope
  blocks, labelled `mu`/`sigma` random-slope covariance, slope-specific
  random-effect scale targets, labelled-block random-effect
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
- Sparse or block-sparse known sampling covariance for large meta-analysis and
  spatial workloads is planned but not yet implemented. The first sparse
  phylogenetic routes are implemented for univariate Gaussian `mu` random
  intercepts and matching bivariate Gaussian `mu1`/`mu2` random intercepts.
- `weights =` is implemented as ordinary likelihood weights: one
  non-negative finite weight per observation for univariate models, and one
  weight per complete response pair for bivariate models. Known sampling
  covariance remains `meta_known_V(V = V)`, not `weights`. Full dense
  `meta_known_V(V = V)` covariance paths currently reject non-unit weights
  because they are joint MVN likelihood blocks.
- The first large-data storage controls are implemented through
  `drm_control(keep_data = FALSE, keep_model_frame = FALSE, keep_tmb_object = FALSE)`,
  including nested model-frame caches for direct-SD and fitted q=2
  `corpair()` models. Current fits still build ordinary R model frames and
  dense fixed-effect model matrices before optimization. Before claiming
  readiness for millions of rows, `drmTMB` still needs broader sparse
  fixed-effect matrices where appropriate, broader aggregation paths for
  repeated Gaussian rows, and repeated large phylogenetic benchmark runs beyond
  the initial optional harness in
  `bench/large-phylo-location.R`.
