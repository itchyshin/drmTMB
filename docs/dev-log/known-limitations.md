# Known Limitations

Read this ledger together with
`docs/design/168-r-julia-finish-capability-matrix.md`; when a status boundary
differs, the stricter fitted, planned, or unsupported row governs public claims.

- The Q-Series v1.0 release boundary is generated in
  `docs/dev-log/release-audits/q-series-v1-release-status.md`. It separates
  implemented/basic-working Gaussian structured-effect rows and
  basic-distribution recovery rows from post-v1.0 `inference_ready` and
  `supported` validation. This boundary does not authorize coverage, q4/q8
  promotion, broad bridge support, REML, AI-REML, or public-support wording.
- Gaussian location-scale models are implemented with fixed effects and
  ordinary `mu` random effects: random intercepts, independent random slopes,
  one-slope correlated random intercept-slope blocks such as `(1 + x | id)` or
  `(1 + x | p | id)`, and q > 2 numeric multi-slope blocks such as
  `(1 + x1 + x2 | id)`. Larger q blocks are advanced, sample-size hungry fits;
  q > 2 SDs are direct profile targets, but q > 2 correlations are not direct
  profile interval targets yet.
- Residual-scale random intercepts, independent numeric random slopes, and
  UNLABELLED correlated intercept-slope blocks are implemented on log-`sigma` in
  the `sigma` formula as `sigma ~ x + (1 | id)`, `sigma ~ x + (0 + w | id)`, and
  `sigma ~ x + (1 + w | id)` (also the multi-slope `(1 + w1 + w2 | id)`). The
  correlated block was added 2026-07-08: the univariate C++ likelihood applies the
  same-dpar `eta_cor_sigma` conditioning, mirroring the `mu` loop; recovery of
  (SD-intercept, SD-slope, correlation) is validated in
  `scratchpad/correlated_scale_slope_recovery.R` (biases <= 0.006 at n_id=150,
  n_each=20). Consequently `y ~ x + (1 + x | id)` with `sigma ~ x + (1 + x | id)`
  -- the ordinary two-level DHGLM with correlated random slopes on BOTH the
  location and the scale -- now fits under ML and REML. Still planned: LABELLED
  univariate residual-scale slope covariance (`sigma ~ x + (1 + x | p | id)`) and
  the labelled cross-formula `mu`-`sigma` SLOPE block, i.e. the remaining q12
  mean-scale slope cross-correlation.
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
- A current inference limitation affects some Gaussian location-scale
  meta-analysis fits with known per-effect sampling variance and
  predictor-dependent residual heterogeneity, for example
  `bf(y ~ moderator + meta_V(V = v), sigma ~ moderator)`. These fits can
  converge and return plausible `mu` and `sigma` point estimates while
  `TMB::sdreport()` reports `pdHess = FALSE`. Treat Wald SEs and Wald
  confidence intervals from that fit as unreliable until `check_drm()` reports
  a positive-definite Hessian or a profile/bootstrap diagnostic supports the
  target. This is a Hessian/inference limitation, not a change to the additive
  known-`V` likelihood.
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
- Missing-data support is a bounded current-preview surface, not a general
  missing-data analysis framework. `miss_control(response = "include")` is G3
  recovery-verified for univariate Gaussian, independent-observation bivariate
  Gaussian, Student-t, skew-normal, lognormal, Gamma, Tweedie, beta,
  zero-one beta, beta-binomial, cumulative-logit, binomial, Poisson, NB2, and
  non-hurdle truncated-NB2 responses, plus fixed-effect ZIP, ZINB2, and hurdle
  NB2 mixtures. Student-t, lognormal, Gamma,
  beta-binomial, and truncated NB2 have ordinary random-intercept recovery
  evidence; cumulative logit, skew-normal, Tweedie, and zero-one beta are
  fixed-effect only. The three count mixtures also have fixed-effect masking
  evidence only; their random and structured routes do not inherit the tick.
  These route-level ticks do not establish masking for every structured
  modifier. The fitted object preserves retained row accounting and fitted
  values while returning `NA` residuals for masked univariate responses. Dense
  known sampling covariance with partial bivariate response rows remains
  unsupported.
  `miss_control(predictor = "model")` fits one explicit `mi()` missing
  predictor at a time in univariate Gaussian location models, with fixed-effect
  family-aware predictor models plus the grouped and structured Gaussian
  covariate routes. Poisson, binomial, NB2, and beta response models separately
  support one fixed-effect binary `mi()` predictor when the response is
  complete. Beta-binomial masking requires a complete success/failure pair per
  observed row; cumulative-logit masking requires an ordered factor and every
  declared category among observed responses. Multiple missing predictors,
  non-binary missing predictors in non-Gaussian response models, grouped or
  structured non-Gaussian predictor models,
  transformed or interacted `mi()` terms, EM/profile engines, REML for
  explicit missing-data routes, simulation-based imputation summaries,
  response imputation, measurement-error models, and pigauto interoperability
  remain planned.
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
  Matching q=4 and q=6 location blocks in `mu1` and `mu2` are also fitted with
  smoke artifact routing. The matching residual-scale q=2 intercept block,
  `sigma1 = ~ 1 + (1 | p | id)` with `sigma2 = ~ 1 + (1 | p | id)`, has smoke
  and recovery artifact routing (`biv_gaussian_q2_scale`). The matching
  residual-scale q=2 slope-only block,
  `sigma1 = ~ x + (0 + x | p | id)` with
  `sigma2 = ~ x + (0 + x | p | id)`, has smoke and recovery artifact routing
  (`biv_gaussian_q2_scale_slope`). These two scale blocks report direct scale
  SDs in `sdpars$sigma`; the scale-scale correlations are group-level
  `corpars$sigma` rows and are separate from residual `rho12`. Matching
  same-response q=2 location-scale slope-only blocks, such as
  `mu1 = y1 ~ x + (0 + x | p | id)` with
  `sigma1 = ~ x + (0 + x | p | id)`, are also fitted with smoke and recovery
  artifact routing (`biv_gaussian_mu_sigma_slope`). The 2026-06-06 local
  500-replicate formal audit for that route is diagnostic rather than
  promotion evidence because convergence/positive-Hessian rates were 0.856 and
  0.884 and all-replicate fixed-effect Wald coverage was 0.796-0.850. A
  follow-up hardening audit refit the 130 weak replicates with stronger
  controls and did not rescue any of them; all remained false-convergence,
  `pdHess = FALSE` fits. The already-converged interval-available fits had
  fixed-effect Wald coverage of 0.930-0.972, and endpoint profiles worked on
  two clean representative fits for `rho12`, both slope SDs, and the
  same-response correlation, but broad profile/bootstrap coverage remains
  unrun. Random effects in `rho12`
  and predictor-dependent q=4 phylogenetic or spatial correlations are still
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
  location-scale endpoint SDs. Native `REML = TRUE` admits, for phylogenetic
  structured effects: mean-side (`mu`/`mu1`/`mu2`) effects; a matched
  mean-and-scale q2 block (univariate `mu`+`sigma` with a `1 | p | id`
  correlation, supported with N >= 250 to identify and N >= 1000 for the
  loc-scale correlation, doc 221); a direct-SD phylo scale (`sd_phylo*() ~ x`);
  and the bivariate BLOCK-DIAGONAL location-scale layout (a phylo mean block
  independent of a phylo scale block, distinct labels such as `1 | p | id` on
  `mu` and `1 | ps | id` on `sigma`). The block-diagonal scale-side random
  phylo is identifiable WITH per-group replication (the replication ladder
  shows n_each >= 5 -> ~100% pdHess and biases -> 0 at n_tip >= 150); it
  collapses at 1 obs/species (pdHess FALSE, scale correlation -> boundary),
  where a fixed `sd_phylo*()` scale (Model A+) should be used instead.
  UNIVARIATE ordinary (non-phylo) sigma random effects are also admitted under
  REML (2026-07-08): a residual-scale random intercept `(1 | id)`, an independent
  random slope `(0 + x | id)`, and the correlated mu-sigma block `(1 | p | id)`.
  REML debiases the scale-side variance component with adequate within-group
  REPLICATION (n_each >= ~8; at n_each = 3 it underperforms ML -- weak
  identification). A BIVARIATE labelled scale-side sigma block `(1 | s | id)` on
  `sigma1`/`sigma2` is likewise admitted under REML (2026-07-08): both scale-RE SDs
  recover under ML and REML, REML at least as good, pdHess 1.00. UNIVARIATE
  scale-side STRUCTURED effects -- `sigma ~ spatial(...)`, `sigma ~ animal(...)`,
  `sigma ~ relmat(...)` -- are also admitted under REML (2026-07-08, C1): a recovery
  ladder debiases the scale-side intercept SD 400/400 across the three providers
  (bias -> 0 with the group count) and REML profile-CI coverage clears the small-`g`
  inference floor (>= 0.926 vs 0.91). MEAN-side non-phylogenetic structured effects
  under REML remain UNVALIDATED and rejected, as does the bivariate scale-side
  structured path. The DENSE
  (unstructured) q4 phylogenetic location-scale block is ALSO admitted under REML
  (2026-07-08): the earlier "sign-flip" verdict is superseded -- the DGP-to-endpoint
  mapping is correct (a single nonzero DGP correlation lands on the right pair with
  the right sign), and the apparent flip was an under-powered fit whose variance
  component collapsed, leaving its correlations unidentified. With adequate
  information (n_tip >= ~200 AND per-species replication n_each >= ~10) the dense q4
  converges and recovers, and REML is STRICTLY better than ML there (higher
  pdHess/convergence rate, variance components debiased toward truth). At 1
  obs/species it still collapses -- use the block-diagonal layout or a fixed
  `sd_phylo*()` scale. Bivariate mean-scale (`mu`-`sigma`) random-effect correlations
  and q > 2 labelled LOCATION covariance blocks are likewise admitted under REML
  (REML consistently less biased than ML on the block SDs). UNLABELLED correlated
  residual-scale intercept-slope blocks (`sigma ~ x + (1 + x | id)`) are also
  implemented and admitted under REML (2026-07-08). Still NOT implemented (under ML
  or REML): LABELLED univariate residual-scale slope covariance blocks, and the
  labelled cross-formula `mu`-`sigma` SLOPE block (the remaining q12 mean-scale
  slope cross-correlation). Matching labelled `animal()` and `relmat()`
  known-matrix terms are fitted for bivariate Gaussian q=2 `mu1`/`mu2`
  location covariance and for constant all-four q=4 location-scale blocks when
  `A`/`Ainv` or `K`/`Q` is supplied. Those rows use `corpars$animal` or
  `corpars$relmat`, `corpairs()`, `summary()$covariance`, profile-target
  status, and known-relatedness diagnostics. Pedigree construction at scale,
  multiple animal/`relmat()` slopes, residual-scale structured slopes, slope
  correlations, predictor-dependent structured `corpair()` regressions, and
  generic direct-SD grammar remain planned.
- A phylogenetic random field on the **scale** (the `sigma1` / `sigma2`
  log-scale endpoints, and therefore the scale-scale and mean-scale q=4
  phylogenetic correlations) is **weakly identified, not non-identified**, at
  approximately one observation per tip. A per-species dispersion has no
  within-species replication to separate it from residual noise, so the
  likelihood is nearly flat in that direction; plain ML can diverge or sit on a
  near-flat ridge (`convergence = 1`, `pdHess = FALSE`, and the tiny-endpoint-SD
  note in `check_drm()`). A prior or penalty is what makes the component
  estimable, which is why a Bayesian fit returns a bounded but prior-sensitive
  estimate (de Villemereuil & Nakagawa 2014; Nakagawa et al. 2025). The
  supported analysis at one record per species is the mean-side phylogenetic
  model with a fixed-effect `sigma ~ predictors` scale (two location SDs, the
  mean-mean phylogenetic correlation, and residual `rho12`). The scale-side
  phylogenetic block needs either within-species replication (about five to ten
  records per species) or an explicit penalty/prior (the planned
  `estimator = "penalized"` path, or a Bayesian fit with a prior-sensitivity
  analysis). `pdHess = FALSE` here is a Wald-inference warning, not a reason to
  discard the point fit.
  Direct DRM.jl q4 profile/bootstrap machinery is useful design evidence, but
  it is not a native TMB route or an R-via-Julia bridge claim. Current
  mission-control rows keep direct Julia interval status, known bootstrap
  undercoverage, and unevaluated drmTMB coverage as separate facts.
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
  such as `(1 | id) + (0 + x | id)` are fitted. One ordinary log-`sigma`
  random intercept is also fitted; its exact Arc 4a ledger domain is
  inference-ready with caveats and mildly anti-conservative coverage. The
  `mu` and `sigma` random-effect routes must be fitted separately; combining
  them is rejected.
  Correlated or labelled slopes, `sigma` slopes, known sampling covariance,
  phylogenetic terms, and bivariate lognormal models are not yet implemented.
- Univariate Student-t location-scale-shape models are implemented for robust
  continuous responses, including fixed-effect `mu`, `sigma`, and `nu` formulas
  plus ordinary unlabelled `mu` random intercepts and independent numeric
  slopes. One row-specific Q-Series v1.0 local fit-only gate also fits
  `nu ~ phylo(1 | id, tree = tree)` and exposes extractors, but it has no
  interval, coverage, or broad shape-support claim. Student-t `nu` otherwise
  remains a fixed-effect tail-shape parameter; random effects in `sigma` or
  `nu`, skew-t shape random effects, correlated Student-t slopes, and latent
  ID-level skewness syntax such as `skew(id) ~ x` are not yet implemented.
- Univariate skew-normal location-scale-shape models are implemented as a
  fixed-effect first slice for residual asymmetry with `family = skew_normal()`.
  Public `mu` is the response mean, public `sigma` is the response standard
  deviation, and `nu` is residual slant on the identity scale. Random effects in
  `mu`, `sigma`, or `nu`, `sd(group)` scale formulae, known sampling covariance,
  structured effects, bivariate skew-normal models, residual `rho12`, latent
  `skew(id)` syntax, and `skew` aliases are not yet implemented. The current
  evidence is focused source tests plus a repeatable Phase 18 smoke/grid
  artifact lane; it is not a formal 500- or 1000-replicate operating
  characteristics result.
- Univariate Gamma mean-CV models are implemented for positive finite responses
  with `family = Gamma(link = "log")`. `mu` is the response mean and `sigma` is
  the coefficient of variation, and ordinary unlabelled `mu` random intercepts
  and independent numeric slopes such as `(1 | id) + (0 + x | id)` are fitted.
  One ordinary log-`sigma` random intercept is fitted at point-recovery grade.
  The `mu` and `sigma` random-effect routes must be fitted separately;
  combining them is rejected.
  Non-log Gamma links, correlated or labelled slopes, `sigma` slopes, known
  sampling covariance, phylogenetic terms, and bivariate
  or mixed Gamma models are not yet implemented.
- Fixed-effect univariate Poisson mean models are implemented for
  non-negative integer counts with `family = poisson(link = "log")`.
  The `mu` formula supports standard R exposure offsets such as
  `offset(log(trap_nights))`. Ordinary unlabelled `mu` random intercepts and
  independent numeric slopes such as `(1 | id) + (0 + x | id)` are implemented
  for non-zero-inflated Poisson models and enter the log-mean predictor.
  Zero-inflated Poisson models are implemented by
  adding `zi ~ predictors`; here `mu` is the conditional count mean and `zi` is
  the structural-zero probability. One row-specific Q-Series v1.0 local
  fit-only gate also fits `zi ~ spatial(1 | id, coords = coords)` and exposes
  extractors, but it has no interval, coverage, or broad inflation-support
  claim. Other `zi` random effects and `mu` random effects in the
  zero-inflated route remain planned and now error with zero-inflation-specific
  boundary messages. There is no modelled `sigma`
  parameter. The first structured count routes are fitted for one unlabelled
  q=1 `phylo()`, `spatial()`, `animal()`, or `relmat()` intercept in ordinary
  Poisson `mu`. Overdispersion, correlated Poisson slope blocks, labelled
  Poisson covariance blocks, known sampling covariance, structured count
  slopes, zero-inflated structured effects beyond the exact Poisson spatial `zi`
  local-fit gate, simultaneous structured types, and bivariate or mixed Poisson
  models remain planned.
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
  fitted. Apart from the exact Poisson spatial `zi`, NB2 fixed-`zi` spatial
  `mu`, and truncated-NB2 hurdle `hu ~ relmat(1 | id, Q = Q)` local
  fit-only gates, random effects in `zi`, `hu`, or the count-side `mu` path of
  zero-inflated or hurdle models are not implemented yet, and cross-parameter
  covariance among count, dispersion, inflation, hurdle, or shape random
  effects remains future work. Ordinary NB2 fits one q=1
  `phylo()`, `spatial()`, `animal()`, or `relmat()` structured `mu` intercept
  on the log-mean scale, but structured `sigma`, structured slopes, labelled
  count covariance, zero-inflated or hurdle structured effects beyond the exact
  Poisson spatial `zi`, NB2 fixed-`zi` spatial `mu`, and truncated-NB2
  relmat `hu` local-fit gates, known sampling covariance, correlated
  zero-truncated slopes, and bivariate or mixed
  negative-binomial models are not yet implemented.
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
  messages. Beta-binomial evidence does not promote plain binomial interval
  calibration.
- Univariate Bernoulli/binomial logit models are implemented with
  `family = stats::binomial(link = "logit")`. The first path supports explicit
  0/1 event indicators and `cbind(successes, failures)` responses, stores
  trial totals from row sums, includes the binomial normalizing constant for
  `stats::glm()` log-likelihood, AIC, and BIC parity, and has no public
  `sigma`. Ordinary `mu` random intercepts and independent numeric slopes are
  fitted first slices. The exact independent-slope domain in capability cell
  `mc-0061` is inference-ready with caveats; it does not authorize neighbouring
  random-effect designs. Non-logit links, factor response ordering, proportions plus
  `weights`, `weights = trials`, correlated or labelled random slopes, structured effects,
  bivariate or mixed responses, and `engine = "julia"` remain unsupported.
- Phylogenetic random effects are implemented for univariate Gaussian `mu` and
  `sigma` intercepts, matching univariate `mu`/`sigma` structured correlations,
  one numeric univariate Gaussian `mu` slope, matching bivariate Gaussian
  `mu1`/`mu2` location covariance, constant q=4 location-scale blocks, direct
  `sd_phylo*()` surfaces, q=2 phylogenetic `corpair()` regression, and ordinary
  Poisson q=1 `mu` intercepts. The tree must be an ultrametric `phylo` object
  with positive branch lengths, and every observed species must match a tip
  label.
- `phylo_interaction(1 | partner1:partner2, tree1 = tree1, tree2 = tree2)`
  is fitted as one q=1 pair-level phylogenetic field for univariate Gaussian
  `mu` and ordinary Poisson/NB2 `mu`. It does not yet combine with separate
  partner main phylogenies, binary/Bernoulli incidence families, structured
  pair slopes, labelled count covariance, or simultaneous structured layers.
  Independent pair effects should use ordinary random effects with a
  precomputed pair column.
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
  count spatial slopes or labels, and zero-inflated spatial effects beyond the
  exact Poisson spatial `zi` and NB2 fixed-`zi` spatial `mu` local-fit gates
  remain planned.
- Except for ordinary Poisson/NB2 q=1 `mu` routes, the row-specific Student-t
  `nu ~ phylo(1 | id, tree = tree)` local-fit gate, the row-specific
  zero-inflated Poisson `zi ~ spatial(1 | id, coords = coords)` local-fit gate,
  and the row-specific zero-inflated NB2 fixed-`zi`
  `mu ~ spatial(1 | id, coords = coords)` local-fit gate, non-Gaussian
  structured random effects are not implemented. `phylo()`,
  `spatial()`, `animal()`, and `relmat()` markers outside those exact routes
  now error in non-Gaussian models with a structured non-Gaussian boundary.
  The exact Poisson labelled-scalar spatial count route
  `mu ~ spatial(1 | p | site, coords = coords)` also fits locally, but it is
  not q2/q4 covariance support. Count structured slopes, labelled q=2/q=4
  count covariance, simultaneous structured count types, bounded, ordinal,
  shape, inflation,
  hurdle, and one-inflation structured effects need ordinary family-specific
  random-effect recovery and interval evidence before entering the fitted
  surface.
- `nbinom2()` structured `sigma` intercept-plus-one-slope terms
  (`sigma ~ phylo(1 + x | id, tree = tree)`, `spatial(...)`, `animal(...)`,
  `relmat(...)`) correctly target the scale predictor `log_sigma` as of 0.4.0.
  Earlier versions carried a routing bug that applied the structured
  contribution to the mean predictor `eta_mu` instead (`model_type == 7` lacked
  the `phylo_mu_dpar == 1` branch that the beta-family route at
  `src/drmTMB.cpp:2631-2643` uses), so a `sigma ~ phylo(...)` fit was numerically
  identical to a mean-phylo fit even though the reported SD was labelled
  `*_sigma`; 0.4.0 mirrors the beta dispatch in `model_type == 7`. These four
  rows are **recovery-grade only**: point-fit recovery is verified
  (`tests/testthat/test-nbinom2-sigma-structured-recovery.R` — a scale-DGP
  logLik gain with fitted-`sigma`-vs-truth correlation, plus a mean-DGP mis-wire
  regression guard), but intervals, coverage, and `supported` status remain out
  of scope.
- **Cross-platform reproducibility of recovery-grade structured routes.** The
  near-boundary optimizations these routes use — `nbinom2()`
  `sigma ~ phylo(1 + x | id)` dispersion structure, and REML q2 matched
  mean-and-scale phylogenetic location-scale blocks — are ill-conditioned near
  the variance boundary, so the optimizer can select a different local optimum or
  return a different convergence code across BLAS/LAPACK builds
  (macOS / Linux / Windows). A tight cross-platform assertion (exact
  `convergence == 0L`, or a delta-logLik threshold) is therefore not reproducible.
  Recovery is validated on the reference platform;
  `tests/testthat/test-nbinom2-sigma-structured-recovery.R` and
  `test-reml-phylo-location.R` are gated with `skip_fragile_recovery()` (skipped
  on CI by default, opt in with `DRMTMB_RUN_FRAGILE_RECOVERY=1`) so the
  release-tag full-OS-matrix check is not red on these recovery-grade
  diagnostics. This is a property of the estimator near the boundary, not a
  defect in the shipped fixed-effect / inference-ready surface.
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
  through `sd(group) ~ x_group`, matched labelled bivariate Gaussian
  `mu1`/`mu2` intercept and slope-only covariance blocks, matched labelled
  bivariate Gaussian `sigma1`/`sigma2` intercept and slope-only covariance
  blocks, response-specific `mu`/`sigma` random-intercept covariance blocks, and
  univariate Student-t models with fixed-effect `mu`,
  `sigma`, and `nu` plus ordinary unlabelled `mu` random intercepts and
  independent numeric slopes, plus the row-specific local fit-only Student-t
  `nu ~ phylo(1 | id, tree = tree)` gate.
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
  row-specific local fit-only zero-inflated Poisson
  `zi ~ spatial(1 | id, coords = coords)` gate, a row-specific local fit-only
  zero-inflated NB2 fixed-`zi`
  `mu ~ spatial(1 | id, coords = coords)` gate, a fixed-effect univariate
  cumulative-logit ordinal path, and a fixed-effect univariate beta-binomial
  path.
- Cross-formula labelled covariance sharing beyond the implemented univariate
  intercept-only `mu`/`sigma` blocks, the first same-parameter bivariate
  intercept blocks, same-response bivariate `mu`/`sigma` pairs, and the ordinary
  all-four bivariate q4 intercept block plus the matching q4 and q6 bivariate
  location blocks, matching q2 bivariate `sigma1`/`sigma2` slope-only block,
  and matching same-response bivariate `mu`/`sigma` random-slope covariance,
  univariate correlated residual-scale random-slope blocks, slope-specific
  random-effect scale targets, labelled-block random-effect
  scale targets, bivariate random-effect scale targets, correlated Student-t
  random slopes, Student-t `sigma` or `nu` random effects beyond the exact
  row-specific phylo `nu` gate, Student-t known-covariance
  models, broad Student-t phylogenetic models, bivariate Student-t models,
  correlated lognormal/Gamma/beta/beta-binomial random slopes,
  lognormal/Gamma `sigma` slopes, labelled or combined `sigma` random effects,
  beta/beta-binomial `sigma` random effects,
  lognormal/Gamma/beta/beta-binomial structured-effect models,
  beta exact-boundary mass, ordinal scale or discrimination models,
  count covariance labels and correlated count slopes, count hurdle or
  zero-inflation with random effects or structured effects beyond the exact
  Poisson spatial `zi` and NB2 fixed-`zi` spatial `mu` local-fit gates,
  non-Gaussian structured routes beyond the ordinary Poisson/NB2 q=1 `mu`
  intercept slices for `phylo()`, `spatial()`, `animal()`, and `relmat()` and
  beyond the exact Student-t phylo `nu`, Poisson spatial `zi`, and NB2
  fixed-`zi` spatial `mu` local-fit gates,
  and additional non-Gaussian families beyond the first Student-t, skew-normal,
  lognormal, Gamma, beta, beta-binomial, Poisson, negative-binomial,
  zero-inflated, zero-truncated, and hurdle paths are planned but not yet
  implemented.
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
  a compatibility alias. `REML = TRUE` is available for univariate Gaussian
  known-`V` fits only inside the current intercept-only `sigma` REML boundary.
- **Distributional-adequacy diagnostic scope.** `residuals(fit, type =
  "quantile")`, `worm_plot()`, and `qq_plot()` (#747) and
  `predict(type = "quantile")`/`exceedance()`/`centile_chart()`/plug-in
  intervals (#748) are built on a per-family `{d,p,q}` foundation
  (`fitted_distribution()`) promoted to `status = "reference"` for all 18
  fitted families, but the diagnostic has a narrower detection scope than
  "checks the model." A 400-seed gated campaign across all 18 families
  (tweedie: 99 of 400 seeds locally, 66/99 dispersion-arm non-convergence,
  full run deferred to Totoro)
  (`docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm-gated/`,
  `summary-gated-full.tsv`) confirms type-I error at or below the nominal
  rate under a correctly specified fit (0.0025-0.025 at alpha = 0.05; the
  underlying KS+PIT statistic is conservative, so power is understated, not
  overstated). It reliably **detects** distributional shape/atom
  mis-specification a family cannot reabsorb through its own free
  parameters -- heavy tails fit as Gaussian, overdispersion or
  zero-inflation ignored by a family with no free dispersion parameter,
  ignored truncation, a missing zero/one atom -- with gated power >= 0.8 at
  n = 300-400 per arm (commonly 0.9-1.0). It has a genuine **structural
  blind spot**: a mis-specification that a fitted family's own free
  nuisance/dispersion/inflation parameter absorbs leaves the fitted-model
  residual marginally N(0,1) and is **not detectable** here -- for example
  heteroscedasticity absorbed by Student-t `nu` (power 0.035 at n = 300,
  versus 1.0 for the same heteroscedasticity under Gaussian, which has no
  absorbing parameter), missing zero-inflation absorbed by `nbinom2`
  `sigma` (power 0.035, versus 0.9625 under Poisson), a family's own
  constant dispersion parameter partially soaking up a truly
  covariate-varying dispersion (`beta_binomial`/`truncated_nbinom2`/
  `tweedie`: power 0.01-0.14, versus 0.81-1.0 for the same mis-specification
  in Gamma/beta/lognormal, which lack a matching absorbing structure), and
  zero-inflation/hurdle/zero-one-inflation *mechanism* mis-specification (a
  constant inflation probability fit when it truly varies with a covariate),
  which largely re-converges to the type-I rate regardless of sample size
  (tested to n = 3000: power stays at or below about 0.11 for
  `zi_nbinom2`/`zi_poisson`, flat at or below about 0.025 for
  `hurdle_nbinom2`/`zero_one_beta`). A mean-structure diagnostic, not this
  one, is what catches an absorbed mis-specification. Separately,
  `gamma`-vs-`lognormal` wrong-family detection is sample-size limited
  rather than structurally blind: power rises from about 0.19 at n = 300 to
  0.79 at n = 1000 and 1.0 at n = 3000, so that specific mis-specification
  needs n well above 1000 to be reliably caught. Throughout: adequacy is
  worded "no detectable departure", never "adequate"; residuals and centile
  outputs are fixed-effect-only (conditional on the fixed-effect prediction
  for random-effect or structured fits, not marginal); plug-in intervals
  carry `attr(., "calibrated") <- FALSE` and do not propagate `theta_hat`
  uncertainty; and a distributional-output/adequacy tick never changes or
  implies anything about a family's own inference-tier status (e.g.
  skew-normal's `diagnostic_hold` fit-quality status is unaffected by its
  DG2/DG3 promotion) -- see `tests/testthat/test-dg-firewall.R`. Calibrated
  coverage (DG4/DG5), uncertainty beyond `theta_hat`, random-effect/
  structured residual adequacy, and bivariate joint (non-marginal) outputs
  are separately authorized future work.
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
