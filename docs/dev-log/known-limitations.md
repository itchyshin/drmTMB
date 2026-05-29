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
  implemented. Full-matrix `meta_V(V = V)` currently stores the retained
  covariance as a dense R matrix, with deprecated `meta_known_V(V = V)` retained
  only as a compatibility alias; `check_drm()` reports that row as a note with
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
  random-intercept terms in `mu1`/`mu2`, `sigma1`/`sigma2`, and one or more
  same-response `mu`/`sigma` pairs such as `mu1` with `sigma1` and `mu2` with
  `sigma2` under separate labels. The same labelled
  random-intercept term can also be used in all four bivariate formulas to fit
  one ordinary q=4 location-scale covariance block with all six latent
  correlations. `check_drm()` reports a first q4 diagnostic for group
  replication, tiny component SDs, and near-boundary latent correlations.
  Bivariate intercept-plus-slope q=4 blocks, random effects in `rho12`, and
  predictor-dependent q=4 phylogenetic or spatial correlations are still
  planned; residual `rho12` should not be interpreted as a phylogenetic,
  spatial, or group-level covariance parameter.
- Phylogenetic, coordinate-spatial, animal-model, and `relmat()` random slopes
  should stay staged behind recovery evidence. The first univariate Gaussian
  `mu` slope is fitted for each structured route as independent intercept and
  slope fields with no intercept-slope `corpair()` row. Multiple random factors
  should be separate additive blocks, not one enlarged cross-factor covariance
  model. A later coefficient-aware `corpair()` design may target the bivariate
  slope1-slope2 plasticity-syndrome case for the same covariate across
  responses.
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
  location-scale endpoint SDs. Matching labelled `animal()` and `relmat()`
  known-matrix terms are fitted for bivariate Gaussian q=2 `mu1`/`mu2`
  location covariance and for constant all-four q=4 location-scale blocks when
  `A`/`Ainv` or `K`/`Q` is supplied. Those rows use `corpars$animal` or
  `corpars$relmat`, `corpairs()`, `summary()$covariance`, profile-target
  status, and known-relatedness diagnostics. Pedigree construction at scale,
  multiple animal/`relmat()` slopes, residual-scale structured slopes, slope
  correlations, predictor-dependent structured `corpair()` regressions, and
  generic direct-SD grammar remain planned.
- `corpairs()` currently reports only correlations that are already fitted:
  residual bivariate `rho12` summaries and ordinary univariate Gaussian `mu`
  random-effect correlations, plus the implemented univariate `mu`/`sigma`
  mean-scale random-intercept correlation and bivariate `mu1`/`mu2`
  random-intercept, `sigma1`/`sigma2` random-intercept, and response-specific
  bivariate `mu`/`sigma` random-intercept correlations. It reports all six
  ordinary q=4 all-four bivariate random-intercept correlations when that block
  is fitted, and it also reports the fitted bivariate phylogenetic mean-mean
  correlation, the six phylogenetic q=4 endpoint correlations,
  coordinate-spatial q=2 and constant q=4 rows, and animal/`relmat()`
  known-matrix q=2 and constant q=4 rows when those blocks are fitted. For the
  first ordinary q=2 predictor-dependent
  `corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ x`
  route, `corpairs()` reports the fitted mean, range, and number of group-level
  latent correlation values. Study-level correlation pairs remain planned.
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
  endpoint order. The ordinary grouped q4 location-scale block, `mu1`/`mu2`
  phylogenetic location slice, and constant phylogenetic q4 location-scale block
  are fitted. Constant coordinate-spatial, animal, and `relmat()` q=4
  location-scale blocks are also fitted first slices. Predictor-dependent
  structured correlations and direct profile intervals for q4 derived
  correlations remain planned.
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
  one-sided intervals and automatic recovery from non-monotone profiles remain
  planned. `confint(fit, method = "bootstrap")` is now implemented for direct
  fitted-model targets with stored model data, including direct fixed-effect,
  scale, random-effect SD, random-effect correlation, and residual-correlation
  rows. It is a slower simulation-refit audit rather than a replacement for
  Wald or endpoint-profile intervals. `summary(fit, conf.int = TRUE,
  method = "bootstrap")`, `corpairs(fit, conf.int = TRUE,
  method = "bootstrap")`, `newdata` bootstrap intervals, and bootstrap
  intervals for derived targets remain unsupported. The first marginal helper
  computes
  unweighted plug-in means only; it does not yet compute uncertainty, standard
  errors, contrasts, plots, or full `emmeans`-style marginalisation.
- Univariate lognormal location-scale models are implemented for positive
  finite responses. `mu` and `sigma` are on the log-response scale, and
  ordinary unlabelled `mu` random intercepts and independent numeric slopes
  such as `(1 | id) + (0 + x | id)` are fitted. Correlated slopes, labelled
  covariance blocks, `sigma` random effects, known sampling covariance,
  phylogenetic terms, and bivariate lognormal models are not yet implemented.
- Univariate Student-t location-scale-shape models are implemented for robust
  continuous responses, including fixed-effect `mu`, `sigma`, and `nu` formulas
  plus ordinary unlabelled `mu` random intercepts and independent numeric
  slopes. Student-t `nu` is a fixed-effect tail-shape parameter; random effects
  in `sigma` or `nu`, future skew-normal or skew-t shape random effects,
  correlated Student-t slopes, and latent ID-level skewness syntax such as
  `skew(id) ~ x` are not yet implemented.
- Univariate Gamma mean-CV models are implemented for positive finite responses
  with `family = Gamma(link = "log")`. `mu` is the response mean and `sigma` is
  the coefficient of variation, and ordinary unlabelled `mu` random intercepts
  and independent numeric slopes such as `(1 | id) + (0 + x | id)` are fitted.
  Non-log Gamma links, correlated slopes, labelled covariance blocks, `sigma`
  random effects, known sampling covariance, phylogenetic terms, and bivariate
  or mixed Gamma models are not yet implemented.
- Fixed-effect univariate Poisson mean models are implemented for
  non-negative integer counts with `family = poisson(link = "log")`.
  The `mu` formula supports standard R exposure offsets such as
  `offset(log(trap_nights))`. Ordinary unlabelled `mu` random intercepts and
  independent numeric slopes such as `(1 | id) + (0 + x | id)` are implemented
  for non-zero-inflated Poisson models and enter the log-mean predictor.
  Zero-inflated Poisson models are implemented by
  adding `zi ~ predictors`; here `mu` is the conditional count mean and `zi` is
  the structural-zero probability, but `zi` random effects and `mu` random
  effects in the zero-inflated route remain planned and now error with
  zero-inflation-specific boundary messages. There is no modelled `sigma`
  parameter. The first structured count routes are fitted for one unlabelled
  q=1 `phylo()`, `spatial()`, `animal()`, or `relmat()` intercept in ordinary
  Poisson `mu`. Overdispersion, correlated Poisson slope blocks, labelled
  Poisson covariance blocks, known sampling covariance, structured count
  slopes, zero-inflated structured effects, simultaneous structured types, and
  bivariate or mixed Poisson models remain planned.
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
  Ordinary non-zero-inflated NB2 `mu` random intercepts and independent numeric
  slopes, the first ordinary NB2 log-`sigma` random intercept, and ordinary
  zero-truncated NB2 `mu` random intercepts and independent numeric slopes are
  fitted. Random effects in `zi`, `hu`, or the count-side `mu` path of
  zero-inflated or hurdle models are not implemented yet, and cross-parameter
  covariance among count, dispersion, inflation, hurdle, or shape random effects
  remains future work. Ordinary NB2 fits one q=1 `phylo()`, `spatial()`,
  `animal()`, or `relmat()` structured `mu` intercept on the log-mean scale,
  but structured `sigma`, structured slopes, labelled count covariance,
  zero-inflated structured effects, known sampling covariance, correlated
  zero-truncated slopes, and bivariate or mixed negative-binomial models are
  not yet implemented.
- Fixed-effect univariate cumulative-logit ordinal models are implemented for
  ordered responses with `family = cumulative_logit()`. The first path supports
  only a `mu` location formula, ordered cutpoints, and a fixed latent logistic
  scale. Ordinal `mu` random-effect bar terms now error with an
  ordinal-specific boundary; the first future mixed-model target is a random
  intercept such as `(1 | id)`, with ordinal random slopes later. Ordinal
  `sigma` or discrimination formulas, known sampling covariance, phylogenetic
  terms, bivariate or mixed ordinal models, and non-logit ordinal links are not
  yet implemented.
- Fixed-effect univariate beta-binomial models are implemented for counted
  successes and failures with `family = beta_binomial()`. The first path
  supports `cbind(successes, failures)` responses, fixed-effect `sigma`
  formulas, known trial totals from row sums, and ordinary unlabelled `mu`
  random intercepts and independent numeric slopes. There are no `sigma`
  random effects, correlated beta-binomial slopes, known sampling covariance,
  phylogenetic terms, bivariate or mixed beta-binomial models, or
  successes/trials response alias. Zero-one-inflated
  bounded-response models for percentage or proportion data are planned:
  fixed-effect `zoi` and `coi` likelihoods should come before random effects
  or covariance among bounded-response distributional parameters, and current
  `zoi`/`coi` formulas error with fixed-effect-first or random-effect boundary
  messages.
- Phylogenetic random effects are implemented for univariate Gaussian `mu` and
  `sigma` intercepts, matching univariate `mu`/`sigma` structured correlations,
  one numeric univariate Gaussian `mu` slope, matching bivariate Gaussian
  `mu1`/`mu2` location covariance, constant q=4 location-scale blocks, direct
  `sd_phylo*()` surfaces, q=2 phylogenetic `corpair()` regression, and ordinary
  Poisson q=1 `mu` intercepts. The tree must be an ultrametric `phylo` object
  with positive branch lengths, and every observed species must match a tip
  label.
- Animal-model and generic known-relatedness structured effects have fitted
  Gaussian slices for `animal(1 | id, pedigree = pedigree)`,
  `animal(1 | id, A = A)`, `animal(1 | id, Ainv = Ainv)`,
  `relmat(1 | id, K = K)`, and `relmat(1 | id, Q = Q)` in `mu` and/or
  `sigma`; one numeric univariate Gaussian `mu` slope; matching labelled
  bivariate q=2 `mu1`/`mu2` location covariance; and constant all-four q=4
  location-scale blocks. Sparse large-pedigree construction, multiple
  structured slopes, residual-scale structured slopes, slope correlations,
  predictor-dependent `corpair()` regression, non-Gaussian relatedness effects,
  and generic direct-SD grammar remain planned. These relatedness inputs are
  distinct from meta-analysis `meta_V(V = V)`, which supplies known sampling
  covariance.
- Structured-effect markers outside the fitted paths, such as
  `spatial(1 | site, mesh = mesh)`, multiple structured slopes, residual-scale
  structured slopes, predictor-dependent q=4 correlations, and non-Gaussian
  structured effects, are parsed and rejected clearly, but they are not yet
  routed into fitted likelihoods. The coordinate-based spatial paths,
  `spatial(1 | site, coords = coords)` and
  `spatial(1 + x | site, coords = coords)`, are fitted for univariate Gaussian
  `mu`; matching labelled bivariate `mu1`/`mu2`
  `spatial(1 | p | site, coords = coords)` terms fit the first q=2 spatial
  location covariance; and matching labelled all-four terms fit the constant
  q=4 spatial location-scale block. They are not the scalable mesh/SPDE route.
  The mesh/SPDE design gate is recorded in
  `docs/design/09-phylogenetic-and-spatial-speed.md`, while spatial slope
  correlations, spatial direct-SD surfaces, spatial `corpair()` regressions,
  count spatial slopes or labels, and zero-inflated spatial effects remain
  planned.
- Except for the ordinary Poisson/NB2 q=1 `mu` intercept routes, non-Gaussian
  structured random effects are not implemented. `phylo()`, `spatial()`,
  `animal()`, and `relmat()` markers outside ordinary count `mu` now error in
  non-Gaussian models with a structured non-Gaussian boundary. Count structured
  slopes, labelled q=2/q=4 count blocks, bounded, ordinal, shape, inflation,
  hurdle, and one-inflation structured effects need ordinary family-specific
  random-effect recovery and interval evidence before entering the fitted
  surface.
- Internal phylogenetic tree validation, dense Brownian covariance comparators,
  sparse augmented Brownian precision helpers, pure-R prior checks, hidden TMB
  prior parity checks, and fitted univariate Gaussian `mu` simulation tests now
  exist.
- The TMB template currently supports fixed effects, univariate Gaussian `mu`
  random intercepts, numeric random-slope terms, ordinary correlated
  intercept-slope blocks with optional covariance-block labels, univariate
  Gaussian residual-scale random intercepts and independent random slopes in
  `sigma`, the first labelled univariate `mu`/`sigma` random-intercept
  covariance block, phylogenetic location and residual-scale structured
  intercepts, one-slope structured `mu` paths, q=2 and q=4 structured
  covariance slices, first-slice known-relatedness Gaussian intercepts,
  plus one or more unlabelled Gaussian `mu` random-intercept scale formulae
  through `sd(group) ~ x_group`, matched labelled bivariate Gaussian `mu1`/`mu2`,
  `sigma1`/`sigma2`, and response-specific `mu`/`sigma` random-intercept
  covariance blocks, and univariate Student-t models with fixed-effect `mu`,
  `sigma`, and `nu` plus ordinary unlabelled `mu` random intercepts and
  independent numeric slopes.
  It also supports univariate lognormal models with `mu` and `sigma` on the
  log-response scale, univariate Gamma mean-CV models with positive response
  mean `mu` and coefficient of variation `sigma`, ordinary unlabelled
  zero-truncated NB2/lognormal/Gamma/beta/beta-binomial `mu` random intercepts
  and independent numeric slopes, univariate
  beta mean-scale models for strict `(0, 1)` proportions, fixed-effect univariate
  Poisson mean models, fixed-effect
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
  scale targets, bivariate random-effect scale targets, correlated Student-t
  random slopes, Student-t `sigma` or `nu` random effects, Student-t known-covariance
  models, Student-t phylogenetic models, bivariate Student-t models,
  correlated lognormal/Gamma/beta/beta-binomial random slopes,
  lognormal/Gamma/beta/beta-binomial `sigma` random effects,
  lognormal/Gamma/beta/beta-binomial structured-effect models,
  beta exact-boundary mass, ordinal scale or discrimination models,
  count covariance labels and correlated count slopes, count hurdle or
  zero-inflation with random effects or structured effects, non-Gaussian
  structured routes beyond the ordinary Poisson q=1 phylogenetic `mu` slice,
  and additional non-Gaussian families beyond the first Student-t, lognormal,
  Gamma, beta, beta-binomial, Poisson, negative-binomial, zero-inflated,
  zero-truncated, and hurdle paths are planned but not yet implemented.
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
  covariance remains `meta_V(V = V)`, not `weights`. Full dense
  `meta_V(V = V)` covariance paths currently reject non-unit weights because
  they are joint MVN likelihood blocks; deprecated `meta_known_V(V = V)` remains
  a compatibility alias.
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
