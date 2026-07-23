# Formula Grammar

The formula grammar is the heart of `drmTMB`. Every estimated parameter gets a
formula. The family decides which parameters exist.

The package should learn from `brms` without copying it wholesale.
`drm_formula()` is the primary public constructor because it is explicit and
package-specific. `bf()` remains a short alias. Avoid a public helper named
`formula()` because it would be easy to confuse with base R's formula tools and
with `formula(fit)` extractors.

Long-term bivariate direction, beyond the current implemented random-intercept
surface:

```r
drmTMB(
  formula = drm_formula(
    mu1 = y1 ~ x1 + x2 + (1 + x2 | p | id),
    mu2 = y2 ~ x1      + (1 + x2 | p | id),
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

Use generic predictor names such as `x1`, `x2`, and `x3` in design examples.
Different distributional parameters often share predictors, with parameter-
specific coefficients:

## Current Status Map

Use three status words consistently across documentation:

- implemented: parsed, fitted, documented, and tested;
- reserved: parsed or reserved as public grammar, but rejected by `drmTMB()`
  until the likelihood and tests exist;
- planned: shown only to explain the roadmap.

In this table, "coscale" means a model for residual correlation, currently
`rho12` in two-response Gaussian models.

### Implemented post-fit mixed-pair association (development worktree)

`associate_pairs()` is an implemented post-fit interface in this post-0.6
development worktree, not another `drmTMB()` formula or a `biv_*()` family.
The initial pair classes are deliberately narrow:

```r
assoc <- associate_pairs(
  fit_gaussian, fit_nbinom2,
  kernel = latent_normal(),
  association = ~ 1
)
```

Both supplied fits must be fixed-effect models fitted on the same externally
constructed, complete paired analysis rows. One margin must be Gaussian and
the other either a literal 0/1 Bernoulli response or ordinary `nbinom2()` with
log `mu` and log `sigma` margins; either input order is accepted. Binomial
trial counts and zero-modified NB2 variants are not included.
`associate_pairs()` freezes every stage-1 margin vector rather than refitting,
profiling, updating, or reweighting it. The sole stage-2 predictor is the
intercept-only association predictor `association = ~ 1`.

The output is a point estimate of latent-normal association `eta`
and numerical/data diagnostics. It is not `rho12`, an observed-scale Pearson
correlation, or `corpairs()`. The formula marker `corpair()` remains distinct
from the extractor. Association slopes, random, phylogenetic, and
structured effects, missing or partial pairs, offsets, weights, `mi()`,
`meta_V()`, REML, standard errors, intervals, profiles, `vcov()`, residuals,
quantiles, and `emmeans` are all outside this contract. It is not a released
0.6.0 analysis surface. Arc 6.1 regression and Arc 6.2 new-pair local smokes
are recorded separately; they do not authorize recovery, interval or coverage
claims, or capability promotion.

Exported formula markers may be written unqualified after `library(drmTMB)` or
namespace-qualified as `drmTMB::marker(...)`. The parser normalizes the marker
call name before matching implemented markers such as `phylo()`, `spatial()`,
`animal()`, `relmat()`, `phylo_interaction()`, `meta_V()`, `sd_phylo()`, and
`corpair()`. This is a marker-specific rule; arbitrary namespaced R functions
are not treated as fitted structured-effect syntax.

### Left-hand-side interpretation

The parser reads each formula's left-hand side (LHS) as follows:

- A named formula (`sigma = ~ x`) always names the distributional parameter;
  the LHS, if present, is the response for that parameter.
- An unnamed formula whose LHS is a keyed marker call (`sd(id) ~ x`,
  `corpair(...) ~ x`) is a random-effect scale or correlation-pair formula.
- An unnamed formula whose LHS is a bare **non-location** distributional
  parameter symbol (`sigma ~ x`, `nu ~ x`, `zi ~ x`, `shape ~ x`, ...) is a
  parameterless dpar formula: it sets that parameter and has no response.
- Every other unnamed formula with an LHS is a response formula for the
  location parameter `mu`. **Location-parameter names (`mu`, `mu1`, `mu2`) are
  never treated as bare dpar symbols**, because a location parameter always
  carries a response. `bf(mu ~ x)` therefore parses as `mu ~ x` with response
  `mu`, not as a parameterless location formula. If a response column happens to
  be named after a non-location parameter (for example a column literally named
  `nu`), name the location formula explicitly to disambiguate: `mu = nu ~ x`.

### Parser invariants

- **One formula per plain non-location distributional parameter.**
  `drm_formula()` rejects a repeated plain scale or auxiliary dpar (for example
  `bf(y ~ x, sigma ~ a, sigma ~ b)`) at parse time, naming the repeated
  parameter, rather than deferring to each family consumer. Three cases are
  excluded from this check: `sd*()` random-effect scale formulas (keyed by
  group) and `corpair()` correlation-pair formulas (keyed by group and
  endpoints), which legitimately repeat; and the location parameter `mu`. A
  mistyped or unsupported bare-symbol parameter (for example `phi ~ 1`) becomes
  a second `mu` response, and each family already guards the location count and
  emits a family-specific message (for example "requires exactly one location
  formula", "only support `mu` and `sigma`", or the skew-normal "Latent
  skewness syntax" note). Enforcing `mu` uniqueness at parse time would hide
  those clearer messages, so `mu` multiplicity is left to the family consumers.
- **`corpair()` endpoints are bivariate.** `from` and `to` must name two
  different bivariate endpoints from `mu1`, `mu2`, `sigma1`, `sigma2`; the
  univariate names `mu` and `sigma` are not accepted, because a latent
  correlation requires two distinct parameters.
- **Deprecated markers are flagged wherever they appear.** The
  `meta_known_V()` deprecation notice fires whether the marker is on the LHS or
  the RHS of a formula.
- **Unknown structured markers fail loudly.** Only the registered structured
  markers (`animal`, `phylo`, `phylo_interaction`, `relmat`, `spatial`) are
  parsed; an unregistered marker aborts rather than being silently treated as a
  spatial term.

| Syntax | Current status | Notes |
| --- | --- | --- |
| `drm_formula()` and `bf()` | Implemented | `drm_formula()` is the explicit constructor; `bf()` is a short alias. |
| `associate_pairs(fit_gaussian, fit_bernoulli_or_nbinom2, kernel = latent_normal(), association = ~ 1)` | Implemented development slice | A post-fit, margin-first Gaussian × literal-Bernoulli or ordinary-NB2 association object for exactly matched complete rows and fixed-effect ML margins. Stage 1 is frozen; stage 2 estimates intercept-only latent-normal `eta` with point estimate and diagnostics only. It is neither a `drmTMB()` formula nor mixed-family `rho12`, and is not a released 0.6.0 surface. Inference, broader families, association slopes, random/structured effects, partial pairs, offsets, weights, `mi()`, `meta_V()`, and REML are outside these slices; no recovery, interval, coverage, or capability claim follows. |
| `y ~ x1`, `sigma ~ x1` | Implemented | Univariate Gaussian location-scale model. |
| `y ~ x1`, `sigma ~ x1`, `nu ~ x2` | Implemented | Fixed-effect univariate Student-t location-scale-shape model. One exact q1 `nu ~ phylo()` intercept is diagnostic-only; the q1 `mu ~ spatial()` intercept is also diagnostic-only, while its intercept-plus-one-slope route is recovery-grade. Other shape random effects, known sampling covariance, structured providers, and bivariate Student-t models are later. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x1`, `nu ~ 1`, `family = student()` | Implemented first slice | Ordinary Student-t `mu` random intercepts and independent numeric slopes enter the identity-location predictor. The exact q1 `nu ~ phylo()` and intercept-only `mu ~ spatial()` gates are diagnostic-only; `mu ~ spatial(1 + x | ...)` is recovery-grade without interval or coverage promotion. Correlated slopes, labelled covariance blocks, `sigma` random effects, other `nu` random effects, other structured routes, known covariance, and bivariate Student-t models remain planned. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x2`, `nu ~ x3`, `family = skew_normal()` | Implemented first slice | Skew-normal ordinary `mu` random intercepts and independent numeric slopes enter the response-mean predictor. The exact independent-slope ledger cell is inference-ready with caveats for true SD 0.50 and M>=16. Public `sigma` is response SD and `nu` is residual slant. Correlated or labelled slopes, random effects outside `mu`, structured effects, bivariate routes, and broader calibration remain planned. |
| `y ~ x1`, `sigma ~ x1`, `family = lognormal()` | Implemented | Fixed-effect univariate lognormal model for positive responses; `mu` and `sigma` are on the log-response scale. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x1`, `family = lognormal()` | Implemented first slice | Ordinary lognormal `mu` random intercepts and independent numeric slopes enter the log-response location. Arc 3a separately admits one unlabelled q1 `phylo()` or `relmat()` intercept using `K` or `Q` in `mu`. Correlated or labelled slopes, other structured routes, known covariance, and broader bivariate lognormal extensions remain planned. |
| `bf(mu1 = y1 ~ x1, mu2 = y2 ~ x2, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1)`, `family = biv_lognormal()` | Implemented development slice | Exact bivariate lognormal model for complete finite positive pairs with implicit likelihood weights of one; a `weights` argument is not supported. `rho12` is residual correlation on the log-response scale, not `eta` or raw-scale correlation. Only fixed-effect locations and constant log-scale SD/correlation terms are admitted; all random/structured effects, sigma/rho predictors, offsets, `meta_V`, `mi()`, REML, intervals, coverage, and capability promotion are deferred. |
| `y ~ x1`, `sigma ~ x1 + (1 | id)`, `family = lognormal()` | Implemented first slice | An ordinary lognormal `sigma` random intercept enters log-`sigma`; only its exact ledger domain is inference-ready with caveats. This scale route cannot be combined with a `mu` random effect, and `sigma` slopes or labels remain unsupported. |
| `y ~ x1`, `sigma ~ x1`, `family = Gamma(link = "log")` | Implemented | Fixed-effect univariate Gamma mean-CV model for positive responses; `mu` is the response mean and `sigma` is the coefficient of variation. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x1`, `family = Gamma(link = "log")` | Implemented first slice | Ordinary Gamma `mu` random intercepts and independent numeric slopes enter the log-mean predictor. The established `relmat()` intercept/one-slope route and the Arc 3a unlabelled q1 `phylo()` intercept are separate structured gates. Correlated or labelled slopes, other structured routes, known covariance, and bivariate or mixed Gamma models remain planned. |
| `y ~ x1`, `sigma ~ x1 + (1 | id)`, `family = Gamma(link = "log")` | Implemented first slice | An ordinary Gamma `sigma` random intercept enters log-CV at recovery grade. This scale route cannot be combined with a `mu` random effect, and `sigma` slopes or labels remain unsupported. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x2`, `nu ~ 1`, `family = tweedie()` | Implemented first slice | Tweedie ordinary `mu` random intercepts and independent numeric slopes enter the log-mean predictor. The exact independent-slope ledger cell is inference-ready with caveats for true SD 0.50 and M>=16. Public `sigma` maps to `phi = sigma^2`, and `nu` is constrained to `1 < nu < 2`. Predictor-dependent `nu`, random effects outside ordinary `mu`, structured effects, and bivariate or mixed-response routes remain planned. |
| `y ~ x1`, `sigma ~ x2`, `family = beta()` | Implemented | Fixed-effect beta mean-scale model for strict continuous proportions in `(0, 1)`; public `sigma` maps internally to `phi = 1 / sigma^2`. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x2`, `family = beta()` | Implemented first slice | Ordinary beta `mu` random intercepts and independent numeric slopes enter the logit-mean predictor for strict `(0, 1)` responses. Exact q1 `mu ~ animal()` intercept/one-slope and `sigma ~ animal()` intercept gates are recovery-grade, one endpoint at a time. Correlated slopes, labelled covariance blocks, ordinary `sigma` random effects, exact 0/1 boundary mass, `zoi`/`coi`, other structured effects, known covariance, beta-binomial denominators, and bivariate or mixed bounded-response models remain planned. |
| `y ~ x_mu + phylo(1 \| spp_id, tree = tree)`, `sigma ~ x_sigma`, `sd(spp_id, level = "phylogenetic") ~ x_tau`, `family = beta()` | Implemented narrow recovery slice | The exact univariate ML q1 Beta phylogenetic location model has prospective recovery evidence under a machine-strict conditional-Beta interior DGP, with promotion assessed only at the two `g = 1024, m = 4` arms. The direct-SD formula models latent location-field SD `tau_s`, while the family `sigma_i` remains a fixed-effect response-scale parameter with `phi_i = sigma_i^-2`. It does not admit family-`sigma` phylogeny, random RHS effects in `sd()`, slopes, labels/q>1, REML, missing routes, intervals, or coverage. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x2`, `zoi ~ x3`, `coi ~ x4`, `family = zero_one_beta()` | Implemented first slice | Zero-one beta model for continuous proportions on `[0, 1]` with exact structural boundary mass and ordinary `mu` random intercepts or independent numeric slopes. The exact independent-slope ledger cell is inference-ready with caveats for true SD 0.50 and M>=16; rare machine-exact endpoints from nominally interior beta draws require a strictly-interior rerun before claiming exactly 15% observed boundary mass. `mu` and `sigma` describe the interior beta component, `zoi` is the exact-boundary probability, `coi` is the probability of an exact one conditional on the boundary, and `fitted()` includes boundary mass. Random effects in `sigma`, `zoi`, or `coi`, correlated or labelled covariance, structured effects, denominators, and bivariate or mixed bounded-response models remain planned. |
| `y ~ x1`, `family = poisson(link = "log")` | Implemented | Fixed-effect univariate Poisson mean model for non-negative integer counts. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `family = poisson(link = "log")` | Implemented first slice | Ordinary Poisson `mu` random intercepts and independent numeric slopes; the group effects enter the log-mean predictor. One exact q1 `zi ~ spatial()` intercept is diagnostic-only. Correlated Poisson slope blocks, labelled covariance blocks, zero-inflated Poisson random effects beyond that exact gate, and cross-parameter covariance remain planned. |
| `y ~ x1 + offset(log(exposure))`, `family = poisson(link = "log")` | Implemented | Exposure/rate Poisson model using standard R `offset()` syntax in the `mu` formula. |
| `y ~ x1`, `zi ~ x2`, `family = poisson(link = "log")` | Implemented | Fixed-effect zero-inflated Poisson model; `mu` is the conditional count mean, `zi` is the structural-zero probability, and `fitted()` returns `(1 - zi) * mu`. |
| `y ~ x1`, `sigma ~ x1`, `family = nbinom2()` | Implemented | Fixed-effect univariate negative-binomial 2 model for overdispersed counts; `sigma` is an overdispersion scale in `Var(y) = mu + sigma^2 * mu^2`. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x2`, `family = nbinom2()` | Implemented first slice | Ordinary NB2 `mu` random intercepts and independent numeric slopes; group effects enter the log-mean predictor while `sigma` remains fixed-effect overdispersion. Correlated NB2 slope blocks, labelled covariance blocks, zero-inflated NB2 random effects outside the exact diagnostic-only fixed-`zi` spatial structured-`mu` local-fit gate, and joint `mu`/`sigma` random effects remain planned. |
| `y ~ x1`, `sigma ~ x2 + (1 | id)`, `family = nbinom2()` | Implemented first slice | Ordinary NB2 grouped overdispersion random intercepts; group effects enter the log-`sigma` predictor while `mu` has fixed effects only. Exact q1 structured `sigma` intercept-plus-one-slope routes for `phylo()`, `spatial()`, `animal()`, and `relmat()` are also fitted at recovery grade. Ordinary NB2 `sigma` slopes, labelled covariance blocks, joint `mu`/`sigma` random effects, zero-inflated/truncated/hurdle scale random effects, richer structured sigma blocks, and structured-sigma intervals/coverage remain planned. |
| `y ~ x1 + offset(log(exposure))`, `sigma ~ x2`, `family = nbinom2()` | Implemented | Exposure/rate NB2 model; the offset enters the `mu` linear predictor and `sigma` remains overdispersion. |
| `y ~ x1`, `sigma ~ x1`, `zi ~ x2`, `family = nbinom2()` | Implemented | Fixed-effect zero-inflated NB2 model; `mu` and `sigma` describe the conditional NB2 count component and `zi` is the structural-zero probability. |
| `y ~ x1 + spatial(1 | site, coords = coords)`, `sigma ~ 1`, `zi ~ 1`, `family = nbinom2()` | Implemented local fit-only gate | Row-specific Q-Series v1.0 local evidence for fixed-covariance spatial structured `mu` with fixed zero inflation. This exposes `sdpars$mu`, `ranef("spatial_mu")`, and a direct `profile_targets()` row, but intervals, coverage, `inference_ready`, `supported`, labelled q2/q4 count covariance, zero-inflated NB2 structured `zi`, structured `sigma`, REML, AI-REML, and bridge support remain unavailable. |
| `y ~ x1`, `sigma ~ x2`, `family = truncated_nbinom2()` | Implemented | Fixed-effect zero-truncated NB2 model for positive counts; `mu` and `sigma` describe the untruncated NB2 component and `fitted()` returns the positive-count mean. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `sigma ~ x2`, `family = truncated_nbinom2()` | Implemented first slice | Ordinary zero-truncated NB2 `mu` random intercepts and independent numeric slopes enter the log-mean predictor while `sigma` remains fixed-effect overdispersion. One exact q1 `hu ~ relmat(K/Q)` intercept is diagnostic-only when the hurdle route is active; ordinary count-side `mu` random effects then remain blocked. Correlated slopes, labelled covariance blocks, hurdle-side random effects beyond that exact gate, `sigma` random effects, other structured effects, and bivariate count models remain planned. |
| `y ~ x1`, `sigma ~ x2`, `hu ~ x3`, `family = truncated_nbinom2()` | Implemented | Fixed-effect hurdle NB2 model; `hu` is the hurdle-zero probability and nonzero counts come from the zero-truncated NB2 component. |
| `(1 | id)`, `(0 + x1 | id)`, `(1 + x1 | id)` in `mu` | Implemented | Ordinary Gaussian location random effects; one-slope correlated blocks may be labelled as `(1 + x1 | p | id)`. |
| `(1 | id)`, `(0 + x1 | id)`, and `(1 + x1 | id)` in `sigma` | Implemented | Residual-scale random intercepts, independent numeric slopes, and unlabelled ordinary correlated intercept-slope or multi-slope blocks. Separate terms remain independent; a single multi-coefficient bar term estimates its within-block correlations. Labelled and cross-formula residual-scale slope covariance remain planned. |
| `(1 | p | id)` in both `mu` and `sigma` | Implemented | Matching labelled random intercepts create mean-scale group-level correlations. More than one independent matched block can be fitted, such as `(1 | p | id)` and `(1 | q | site)` in both formulas. |
| `sd(id) ~ x_group` | Implemented | Random-effect scale model for one or more distinct unlabelled Gaussian `mu` random intercepts. |
| `sd(id, dpar = "mu", coef = "x1") ~ x_group` | Reserved | Planned explicit coefficient-specific random-effect SD syntax for random slopes; `drmTMB()` rejects it until the covariance model and tests exist. |
| `meta_V(V = V)` | Implemented | Preferred spelling for additive known sampling covariance; `V` may be a vector, column, diagonal matrix, block-diagonal matrix, or dense matrix. |
| `meta_known_V(V = V)` | Deprecated compatibility alias | Warns and then uses the same additive known sampling covariance path as `meta_V(V = V)`. New code should use `meta_V(V = V)`. |
| `meta_V(w = w, scale = "proportional")` | Planned | Possible future proportional sampling-variance spelling for models such as `pi_i ~ Normal(0, phi_pi / w_i)`. This is not implemented and is not a CRAN-blocking requirement. |
| `mu1`, `mu2`, `sigma1`, `sigma2`, `rho12` | Implemented for fixed effects | Bivariate Gaussian location-coscale model with predictor-dependent residual correlation. |
| `(1 | p | id)` in both bivariate `mu1` and `mu2` | Implemented | First bivariate group-level covariance slice: matching labelled random intercepts create `mu1`/`mu2` random-intercept SDs and one group-level correlation. |
| `(1 | p | id)` in both bivariate `sigma1` and `sigma2` | Implemented | First bivariate residual-scale covariance slice: matching labelled random intercepts enter `log(sigma1)` and `log(sigma2)` and create one scale-scale group-level correlation. |
| `(0 + x | p | id)` in both bivariate `sigma1` and `sigma2` | Implemented first slice | Matching labelled random slopes enter `log(sigma1)` and `log(sigma2)` as `x * a_id`, creating one group-level scale-slope correlation `cor(sigma1:x,sigma2:x | p | id)`. |
| `(0 + x | p | id)` in same-response bivariate `mu1` and `sigma1`, or `mu2` and `sigma2` | Implemented first slice with smoke/recovery routing | Matching labelled random slopes create one response-specific mean-scale-slope correlation such as `cor(mu1:x,sigma1:x | p | id)`. Cross-response slope labels and mismatched coefficients remain planned. |
| `(1 | p | id)` in same-response bivariate `mu1` and `sigma1`, with optional independent `(1 | q | id)` in `mu2` and `sigma2` | Implemented first slice | Each matching labelled random-intercept pair creates its own response-specific mean-scale group-level correlation; residual `rho12` stays separate. |
| `(1 | p | id)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first slice | One ordinary q=4 random-intercept covariance block reports all six latent location-location, location-scale, and scale-scale correlations. |
| `(1 + x | p | id)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first q8 slice with diagnostic smoke/recovery/staged-start artifacts | One ordinary all-endpoint location-scale slope block estimates eight endpoint SDs and 28 latent group-level correlations. The four formulas must use the same label, group, and coefficient set. Coverage, power, predictor-dependent `corpair()` regressions, structured q8 siblings, non-Gaussian q8 blocks, and random `rho12` remain planned. |
| `sd1(id) ~ x_group` or `sd2(id) ~ x_group` with the same all-four q=4 block | Rejected | This would mix the Family A joint location-scale covariance block with Family B direct location-SD regression for the same group. |
| `family = c(gaussian(), gaussian())` | Implemented | Public bivariate Gaussian family direction; mixed composed families are planned. |
| `mvbind(y1, y2) ~ x1` | Implemented | Shorthand for identical bivariate location formulas; explicit `mu1`/`mu2` remains preferred for different predictors. |
| `phylo(1 | species, tree = tree)` in univariate `mu` and/or `sigma` | Implemented | Intercept-only univariate Gaussian phylogenetic location and residual-scale structured effects; matching `mu`/`sigma` terms estimate one mean-scale phylogenetic correlation on the latent field. Requires an ultrametric tree with branch lengths. |
| matching `phylo(1 | species, tree = tree)` in bivariate `mu1` and `mu2` | Implemented first slice | Correlated phylogenetic random intercepts enter the two response means; `sigma1`, `sigma2`, and residual `rho12` remain ordinary fixed-effect distributional parameters. |
| labelled `phylo(1 | p | species, tree = tree)` in matching bivariate `mu1` and `mu2` | Implemented | The label is preserved in SD, correlation, `corpairs()`, and profile-target names for the phylogenetic mean-mean path. |
| labelled `phylo(1 | p | species, tree = tree)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first slice | One constant q=4 phylogenetic location-scale block estimates four endpoint SDs and six latent phylogenetic correlations. Partial, unlabelled, unsupported mismatched, and block-diagonal slope forms remain rejected or planned. |
| labelled `phylo(1 + x | p | species, tree = tree)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first point-fit/extractor slice | One shared-label all-four one-slope phylogenetic block creates eight endpoint members and 28 derived latent phylogenetic correlations (q8). This is native ML point-fit/extractor evidence only; bridge parity, intervals, coverage, REML, AI-REML, and block-diagonal slope layouts remain planned. |
| labelled `phylo(1 + x + z | p | species, tree = tree)` in bivariate `mu1` and `mu2` only (M2 q6) | Implemented point-fit/recovery slice | One shared-label two-slope location phylogenetic block creates six endpoint members and 15 derived correlations (q6). The same holds for `spatial()`, `animal()`, and `relmat()`. Recovery evidence only (`pdHess=TRUE` at Santi-scale); intervals/coverage route through profile/bootstrap and remain planned. |
| labelled `phylo(1 + x + z | p | species, tree = tree)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas (M3 q12) | Implemented point-fit/recovery slice | One shared-label two-slope all-four phylogenetic block creates twelve endpoint members and 66 derived correlations (q12). The same holds for `spatial()`, `animal()`, and `relmat()`. Recovery evidence only; `pdHess=FALSE` is expected (66-correlation weak-ID) so the correlations route through profile/bootstrap (ELR excluded); intervals/coverage remain planned. Block-diagonal and partial-endpoint two-slope layouts stay rejected. |
| labelled `phylo(1 | pl | species, tree = tree)` in `mu1` and `mu2` plus labelled `phylo(1 | ps | species, tree = tree)` in `sigma1` and `sigma2` | Implemented | Block-diagonal q=4 fallback: one q=2 phylogenetic mean-mean block and one independent q=2 phylogenetic scale-scale block for the same tree. It reports two `corpairs()` rows and no mean-scale phylogenetic correlations. |
| `count ~ x + phylo(1 + x | species, tree = tree)` or `count ~ x + spatial(1 + x | site, coords = coords)`, `family = poisson(link = "log")` | Implemented first one-slope slice | Ordinary non-zero-inflated Poisson q=1 structured `mu` intercepts and unlabelled intercept-plus-one-slope terms on the log-mean scale for one of `phylo()`, `spatial()`, `animal()`, or `relmat()`. Pure structured slopes, multiple structured slopes, labelled q=2/q=4 count blocks, zero-inflated structured effects outside exact row-specific local-fit gates, simultaneous structured types within Poisson, and combinations with ordinary count random effects remain planned. |
| `count ~ x + phylo(1 + x | species, tree = tree)` or `count ~ x + relmat(1 + x | id, Q = Q)`, `sigma ~ z`, `family = nbinom2()` | Implemented first one-slope slice | Ordinary non-zero-inflated NB2 q=1 structured `mu` intercepts and unlabelled intercept-plus-one-slope terms on the log-mean scale for one of `phylo()`, `spatial()`, `animal()`, or `relmat()`, while `sigma` remains fixed-effect overdispersion unless using a separate fitted sigma route. Exact q1 structured `sigma` intercept-plus-one-slope routes for those four providers are recovery grade. One exact crossed `mu ~ spatial(1 | site, coords = coords) + relmat(1 | id, Q = Q)` route is recovery-only. Pure or multiple structured `mu` slopes, labelled q2/q4 count blocks, zero-inflated NB2 structure outside the exact local-fit gate, richer or labelled structured sigma, structured-sigma intervals/coverage, simultaneous structured types beyond that exact crossed gate, and joint `mu`/`sigma` random effects remain planned. |
| `biomass ~ x + phylo(1 | species, tree = tree)`, `sigma ~ z`, `family = lognormal()` or `Gamma(link = "log")` | Arc 3a q1 intercept slice at `point_fit_recovery` | One unlabelled structured intercept enters `mu`: the log-response location for lognormal and the log-mean for Gamma. Both families admit `phylo()`; lognormal also admits `relmat(1 | id, K = K)` or `relmat(1 | id, Q = Q)`. Gamma's pre-existing `relmat()` intercept-plus-one-slope route remains separate. New-route slopes, labels, q2+, `sigma` structure, joint `mu`/`sigma` random effects, simultaneous structured providers, spatial/animal, bivariate, REML, intervals, and coverage remain rejected. |
| `count ~ x + phylo_interaction(1 | partner1:partner2, tree1 = tree1, tree2 = tree2)` or Gaussian `y ~ x + phylo_interaction(...)` | Implemented first slice | Single q=1 location random intercept for a two-partner phylogenetic interaction in univariate Gaussian `mu` and ordinary Poisson/NB2 `mu`. Internally this builds a sparse Kronecker precision from the two augmented phylogenetic precisions. `relmat(1 | pair, Q = Q_pair)` remains the lower-level escape hatch. Binary/Bernoulli incidence models and additive models that combine partner main phylogenies plus `phylo_interaction()` remain planned. |
| `sd_phylo(species) ~ x_species` | Implemented | Family B direct-SD model for a univariate Gaussian phylogenetic location random effect; predictors must be constant within species and scale observed tips through the `D_tip A_tip D_tip` contract. |
| bivariate `sd_phylo1(species) ~ x_species` / `sd_phylo2(species) ~ x_species` | Implemented | Response-specific bivariate phylogenetic location direct-SD models. They target only `mu1` and `mu2` phylogenetic location SDs, keep the latent phylogenetic location-location correlation separate, and are rejected with q=4 phylogenetic location-scale blocks. |
| `phylo(1 | species, A = A)` or `phylo(1 | species, Ainv = Ainv)` | Planned | Future phylogenetic known-relatedness input for users who already have a validated phylogenetic covariance or precision matrix. The implemented public phylo path still requires `tree = tree`. |
| `animal(1 | id, pedigree = ped)` | Implemented first slice | Univariate Gaussian `mu` animal-model random intercept using a dense additive relationship matrix built from `id`, `dam`, and `sire` pedigree columns. This is a sibling of `phylo()` and `spatial()`, not a new family; large-pedigree sparse precision construction remains planned. |
| `animal(1 | id, A = A)` or `animal(1 | id, Ainv = Ainv)` in univariate `mu` and/or `sigma` | Implemented first slice | Univariate Gaussian animal-model random intercepts for location and residual scale using a precomputed additive relatedness or inverse-relatedness matrix; matching `mu`/`sigma` terms estimate one animal mean-scale correlation. Matching labelled bivariate q=2 `mu1`/`mu2` intercept and slope-only terms, constant all-four q=4 location-scale terms, and `animal(1 + x | id, A = A)` sigma-only and matched `mu+sigma` one-slope native point-fit/extractor cells are implemented where documented. Large-pedigree sparse precision construction, multiple slopes, intercept-plus-slope labelled structured covariance, predictor-dependent `corpair()`, bridge/inference for matched slope cells, and direct-SD grammar remain planned. Use `pedigree`, `A`, or `Ainv` for latent relatedness; keep `V` reserved for known sampling covariance in meta-analysis. |
| labelled `animal(1 | p | id, pedigree = ped)`, `animal(1 | p | id, A = A)`, or `animal(1 | p | id, Ainv = Ainv)` in bivariate `mu1` and `mu2` | Implemented first q=2 slice | Matching labelled animal-model terms estimate two location SDs and one animal mean-mean correlation from the same pedigree-derived or known matrix. |
| labelled `animal(0 + x | p | id, A = A)` or `animal(0 + x | p | id, Ainv = Ainv)` in bivariate `mu1` and `mu2` | Implemented first q=2 slope-only slice | Matching labelled animal-model slope-only terms estimate two location-slope SDs and one `cor(mu1:x,mu2:x | p | id)` correlation from the same known matrix. This row is not promoted by the q2 phylo/relmat small-sample interval evidence; animal q2 interval and coverage status remain future row-level work. This is separate from the exact all-four shared-label `animal(1 + x | p | id, A = A)` cell; partial or location-only intercept-plus-slope labelled structured covariance remains planned. |
| labelled `animal(1 | p | id, pedigree = ped)`, `animal(1 | p | id, A = A)`, or `animal(1 | p | id, Ainv = Ainv)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first q=4 slice | One constant all-four animal-model location-scale block estimates four endpoint SDs and six latent animal correlations from the same matrix. Partial, unlabelled, mismatched, slope, direct-SD, and predictor-dependent `corpair()` forms remain rejected or planned. |
| labelled `animal(1 + x | p | id, A = A)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first point-fit/extractor slice | One shared-label A-matrix animal all-four one-slope block creates eight endpoint members and 28 derived latent animal correlations. This is native ML point-fit/extractor evidence only; pedigree/Ainv bridge marshalling, bridge parity, intervals, coverage, REML, AI-REML, block-diagonal slope layouts, partial endpoint layouts, multiple slopes, and public support remain planned. |
| `animal(1 + x | id, pedigree = ped)` | Implemented first one-slope slice; A-matrix sigma-only row is `inference_ready` with caveats | Univariate Gaussian `mu` path with independent animal-model intercept and slope fields; A-matrix `animal(1 + x | id, A = A)` also has first sigma-only and matched `mu+sigma` native point-fit/extractor cells. The exact q1 sigma one-slope A-matrix row is `inference_ready` under raw uncorrected log-SD Wald-z intervals, with asymmetric one-sided misses and conservative `sigma:x` coverage; this is not `supported`, and the location-axis bias+t correction does not apply to sigma. Multiple animal slopes, broader intercept-plus-slope labelled structured covariance, pedigree/Ainv bridge marshalling, bridge/inference for matched slope cells, and slope correlations remain planned. Covariance labels in univariate `mu` or `sigma` remain rejected; use matching `animal(0 + x | p | id, A/Ainv = ...)` in bivariate `mu1`/`mu2` for the first slope-only q2 cell, or the exact all-four shared-label `animal(1 + x | p | id, A = A)` cell when all four endpoints share the same label. |
| `relmat(1 | id, K = K)` or `relmat(1 | id, Q = Q)` in univariate `mu` and/or `sigma` | Implemented first slice | Lower-level user-supplied relatedness route for univariate Gaussian location and residual-scale structured intercepts; matching `mu`/`sigma` terms estimate one relatedness mean-scale correlation. Matching labelled bivariate q=2 `mu1`/`mu2` terms are implemented in the detailed rules below. This replaces the deprecated `gr()` wording for known latent relatedness matrices. |
| labelled `relmat(1 | p | id, K = K)` or `relmat(1 | p | id, Q = Q)` in bivariate `mu1` and `mu2` | Implemented first q=2 slice | Matching labelled lower-level relatedness terms estimate two location SDs and one mean-mean correlation from the same known latent matrix. |
| matching labelled `relmat(1 | p | id, K = K)` in bivariate `mu1` and `mu2`, with `REML = TRUE` | Arc 1b-S2R exact cell at `point_fit_recovery` | Native-TMB REML admits this supplied-`K`, location-only bivariate Gaussian cell when both endpoints use the same label, group, matrix, and level ordering; `sigma1`, `sigma2`, and `rho12` are intercept-only; response pairs are complete; weights are one; and there is no extra random-effect layer. The route reuses the existing exact-Gaussian REML engine. `Q = Q`, `animal()`, unlabelled or unmatched terms, slopes, q4+, scale-side structure, missing or weighted pairs, non-Gaussian families, intervals, and coverage remain rejected or unclaimed. |
| labelled `relmat(0 + x | p | id, K = K)` or `relmat(0 + x | p | id, Q = Q)` in bivariate `mu1` and `mu2` | Implemented first q=2 slope-only slice; interval and coverage `inference_ready` for the row-level SD targets | Matching labelled lower-level relatedness slope-only terms estimate two location-slope SDs and one `cor(mu1:x,mu2:x | p | id)` correlation from the same known latent matrix. The default `confint()` small-sample correction covers this exact location-axis q2 slope SD row; `supported` is withheld because right-tail miss asymmetry and g-dependence remain measured defects. This is separate from the exact all-four shared-label `relmat(1 + x | p | id, K/Q = ...)` cell; partial or location-only intercept-plus-slope labelled structured covariance remains planned. |
| labelled `relmat(1 | p | id, K = K)` or `relmat(1 | p | id, Q = Q)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first q=4 slice | One constant all-four lower-level known-matrix location-scale block estimates four endpoint SDs and six latent relatedness correlations from the same matrix. Partial, unlabelled, mismatched, slope, direct-SD, and predictor-dependent `corpair()` forms remain rejected or planned. |
| labelled `relmat(1 + x | p | id, K = K)` or `relmat(1 + x | p | id, Q = Q)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first point-fit/extractor slice | One shared-label K/Q lower-level relatedness all-four one-slope block creates eight endpoint members and 28 derived latent relatedness correlations. This is native ML point-fit/extractor evidence only; Q bridge marshalling, bridge parity, intervals, coverage, REML, AI-REML, block-diagonal slope layouts, partial endpoint layouts, multiple slopes, and public support remain planned. |
| `relmat(1 + x | id, K = K)` or `relmat(1 + x | id, Q = Q)` | Implemented first one-slope slice; sigma-only row is `inference_ready` with caveats | Univariate Gaussian `mu`, sigma-only, and matched `mu+sigma` native point-fit/extractor paths with independent relatedness intercept and slope fields. The exact q1 sigma one-slope relmat K/Q row is `inference_ready` under raw uncorrected log-SD Wald-z intervals, with near-nominal asymmetric intercept coverage and conservative `sigma:x` coverage; this is not `supported`, and the location-axis bias+t correction does not apply to sigma. Multiple `relmat()` slopes, broader intercept-plus-slope labelled structured covariance, bridge/inference for matched slope cells, and slope correlations remain planned. Covariance labels in univariate `mu` or `sigma` remain rejected; use matching `relmat(0 + x | p | id, K/Q = ...)` in bivariate `mu1`/`mu2` for the first slope-only q2 cell, or the exact all-four shared-label `relmat(1 + x | p | id, K/Q = ...)` cell when all four endpoints share the same label. |
| `weights = w` | Implemented | Top-level likelihood weights, not formula syntax. Known sampling covariance remains a separate marker: `meta_V(V = V)` is preferred, and deprecated `meta_known_V(V = V)` remains a compatibility alias. |
| `y ~ x1 + (1 | id) + (0 + x1 | id)`, `family = cumulative_logit()` | Implemented first mixed-model slice | Univariate ordinal model for ordered scores with cutpoints; `mu` is a latent location. Ordinary unlabelled `mu` random intercepts and independent numeric slopes are recovery-grade, and one exact q1 `mu ~ phylo(1 | id, tree = tree)` intercept has local point-fit/extractor evidence. Correlated/labelled or other structured neighbours, ordinal scale/discrimination formulas, and interval/coverage promotion remain planned. |
| `y01 ~ x1 + (1 | id) + (0 + x1 | id)`, `family = stats::binomial(link = "logit")` | Implemented first slice | Plain Bernoulli response model for 0/1 event data. It fits fixed-effect `mu` plus ordinary random intercepts and independent numeric slopes, with `mu` as event probability. Only the exact independent-slope ledger domain is inference-ready with caveats. Non-logit links, factor-response ordering, proportions plus `weights`, `weights = trials`, `successes / trials`, `sigma`, `nu`, `zi`, `zoi`, `coi`, correlated or labelled slopes, structured effects, bivariate responses, mixed responses, and `engine = "julia"` remain unsupported. |
| `cbind(successes, failures) ~ x1 + (1 | id) + (0 + x1 | id)`, `family = stats::binomial(link = "logit")` | Implemented first slice | Plain binomial response model for counted events out of known trials, with `trials = successes + failures`, fixed effects plus ordinary `mu` random intercepts and independent slopes, and no extra-binomial variation. This is the ordinary binomial likelihood, not `beta_binomial()`, not a continuous-proportion beta model, and not the internal binary missing-predictor imputation route. |
| `cbind(successes, failures) ~ x1 + (1 | id) + (0 + x1 | id)`, `family = beta_binomial()` | Implemented first slice | Denominator-aware model for success counts with known trial totals; ordinary `mu` random intercepts and independent numeric slopes enter the logit success-probability predictor and `sigma` is fixed-effect extra-binomial variation. |
| `phylo(0 + x | p | species, tree = tree)` in bivariate `mu1` and `mu2` | Implemented first q=2 slope-only slice; interval and coverage `inference_ready` for the row-level SD targets | Matching labelled phylogenetic slope-only terms estimate two location-slope SDs and one `cor(mu1:x,mu2:x | p | species)` correlation. The default `confint()` small-sample correction covers this exact location-axis q2 slope SD row; `supported` is withheld because right-tail miss asymmetry and g-dependence remain measured defects. The separate shared-label all-four `phylo(1 + x | p | species, tree = tree)` cell has native point-fit/extractor evidence only; bridge parity, broader q8 variants, REML, AI-REML, and public support remain planned. |
| `phylo(1 + x1 | species, tree = tree)` | Implemented first one-slope slice; sigma-only row is `inference_ready` with caveats | Univariate Gaussian `mu`, sigma-only, and matched `mu+sigma` native point-fit/extractor paths with independent phylogenetic intercept and slope fields. The exact q1 sigma one-slope phylo row is `inference_ready` under raw uncorrected log-SD Wald-z intervals, with near-nominal asymmetric intercept coverage and conservative `sigma:x` coverage; this is not `supported`, and the location-axis bias+t correction does not apply to sigma. The exact shared-label all-four bivariate `phylo(1 + x | p | species, tree = tree)` block is a separate native point-fit/extractor cell. Multiple phylogenetic slopes, block-diagonal labelled slope covariance, bridge/inference for matched slope cells, and slope correlations remain planned. Covariance labels in univariate `mu` or `sigma` remain rejected; use matching `phylo(0 + x | p | species, tree = tree)` in bivariate `mu1`/`mu2` for the first slope-only q2 cell. |
| `spatial(1 | site, coords = coords)` | Implemented first slice | Univariate Gaussian `mu` spatial random intercept using a fixed coordinate covariance foundation. |
| `spatial(1 | site, mesh = mesh)` | Planned | Mesh/SPDE spatial fitting remains planned after the coordinate foundation. |
| `spatial(0 + x | p | site, coords = coords)` in bivariate `mu1` and `mu2` | Implemented first q=2 slope-only slice | Matching labelled fixed-covariance spatial slope-only terms estimate two location-slope SDs and one `cor(mu1:x,mu2:x | p | site)` correlation. Unlike the phylo and relmat q2 rows, this spatial row has not been promoted to `inference_ready`; interval and coverage status remain a future row-level climb. The separate shared-label all-four `spatial(1 + x | p | site, coords = coords)` cell has native point-fit/extractor evidence only; bridge parity, range-estimating spatial support, and broader q8 variants remain planned. |
| labelled `spatial(1 + x | p | site, coords = coords)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first point-fit/extractor slice | One shared-label fixed-covariance spatial all-four one-slope block creates eight endpoint members and 28 derived latent spatial correlations. This is native ML point-fit/extractor evidence only; range-estimating spatial support, bridge parity, intervals, coverage, REML, AI-REML, block-diagonal slope layouts, multiple slopes, and public support remain planned. |
| `spatial(1 + x | site, coords = coords)` | Implemented first one-slope slice | Univariate Gaussian `mu`, sigma-only, and matched `mu+sigma` native point-fit/extractor paths with independent coordinate-spatial intercept and slope fields; the exact shared-label all-four bivariate `spatial(1 + x | p | site, coords = coords)` block is a separate native point-fit/extractor cell. Multiple spatial slopes, block-diagonal labelled slope covariance, bridge/inference for matched slope cells, slope correlations, and mesh/SPDE one-slope paths remain planned. Covariance labels in univariate `mu` or `sigma` remain rejected; use matching `spatial(0 + x | p | site, coords = coords)` in bivariate `mu1`/`mu2` for the first fixed-covariance slope-only q2 cell. |
| `spatial(1 | p | site, coords = coords)` in matching bivariate `mu1` and `mu2` | Implemented first q=2 slice | Matching labelled spatial terms estimate two location SDs and one latent coordinate-spatial mean-mean correlation. |
| `spatial(1 | p | site, coords = coords)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first q=4 slice | One constant coordinate-spatial location-scale block estimates four endpoint SDs and six latent spatial correlations. Partial, unlabelled, mismatched, and slope forms remain rejected. |
| `corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ x_group` | Implemented | Predictor-dependent ordinary q=2 location-location latent random-effect correlation regression for matching labelled `mu1`/`mu2` random intercepts. Predictors must be constant within `id`. |
| `corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ ecology` | Implemented | Predictor-dependent phylogenetic q=2 location-location latent random-effect correlation regression for matching labelled `mu1`/`mu2` `phylo()` terms. Predictors must be constant within `species`. Location-scale, scale-scale, q=4, and spatial `corpair()` regressions remain planned. |
| Matching slope-only `(0 + x | p | id)` in bivariate `mu1` and `mu2` | Implemented first bivariate slope slice | This route targets the slope1-slope2 plasticity-syndrome correlation without also estimating intercept-slope correlations. The fitted row is exposed through SD/correlation extractors, `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()`. |
| Matching one-slope intercept-plus-slope `(1 + x | p | id)` blocks in bivariate `mu1` and `mu2` | Implemented first q=4 location slice | This route estimates two response-specific location intercept SDs, two location slope SDs, and six group-level latent correlations among those four location effects. The four SDs are direct profile targets; the six correlations are derived-unavailable interval rows. |
| Multiple-slope bivariate location blocks beyond the fitted q4/q6 location lanes; q8 coefficient sets beyond one shared slope; predictor-dependent phylogenetic/spatial q4 correlations; predictor-dependent q8 `corpair()` regressions; structured or non-Gaussian q8 blocks; or `rho12` random effects | Planned | Requires larger structured covariance parameterizations, simulation recovery, and naming checks. Do not treat intercept-slope `corpair()` rows as a near-term target; later slope-correlation regressions need coefficient-aware syntax. |
| `missing = miss_control(response = "drop")` | Implemented | Default top-level missing-data policy. It keeps the existing complete-case behaviour before likelihood construction. |
| `missing = miss_control(response = "include")` with `family = gaussian()` | Implemented first slice | Retains rows with missing univariate Gaussian responses when predictors, grouping variables, structured inputs, weights, and known sampling variances are complete. Missing response rows contribute zero Gaussian response likelihood, `fit$missing_data` stores original-row accounting, `nobs()` counts likelihood-contributing rows, and response residuals are `NA` for masked responses. |
| `missing = miss_control(response = "include")` with `family = biv_gaussian()` or `family = c(gaussian(), gaussian())` | Implemented independent-observation slice | Retains bivariate Gaussian rows with `y1` missing, `y2` missing, or both responses missing when predictors and grouping or structured inputs are complete and no dense known `meta_V(V = V)` matrix is supplied. Complete pairs use the bivariate density with residual `rho12`; one-response rows use the appropriate marginal Gaussian density and do not directly identify `rho12`; both-missing rows contribute zero response likelihood while preserving original-row accounting. Dense known-`V` partial-response slicing, imputation summaries, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(x)` with `impute = list(x = x ~ z)` and `missing = miss_control(predictor = "model")` | Implemented first missing-predictor slice | Retains rows where one numeric Gaussian location predictor `x` is missing, fits a fixed-effect Gaussian predictor model for `x`, and integrates missing `x` values with the Laplace approximation. This route is univariate Gaussian only. |
| `y ~ z + mi(x)` with `impute = list(x = x ~ z + (1 \| group))` and `missing = miss_control(predictor = "model")` | Implemented grouped missing-predictor slice | Extends the same univariate Gaussian `mi(x)` route to one independent random-intercept covariate model for `x`. Multiple missing predictors, transformed or interacted `mi()` terms, covariate random slopes, simulation-based imputation summaries, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(x)` with `impute = list(x = x ~ z + relmat(1 \| line, Q = Q))` and `missing = miss_control(predictor = "model")` | Implemented structured missing-predictor slice | Extends the same univariate Gaussian `mi(x)` route to one explicit intercept-only structured covariate model using `phylo()`, coordinate `spatial()`, `animal()`, or `relmat()`. Structured covariate slopes, simultaneous grouped and structured covariate effects, `phylo_interaction()`, automatic inheritance from the response model, joint response-covariate structured correlations, structured non-Gaussian predictor models, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(treatment)` with `impute = list(treatment = impute_model(treatment ~ z, family = binomial()))` and `missing = miss_control(predictor = "model")` | Implemented binary missing-predictor slice | Fits one fixed-effect Bernoulli/logit predictor model for a missing binary `mi()` predictor and sums exactly over the two possible states when the predictor is missing. Grouped or structured binary predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `count ~ z + mi(treatment)` with `family = poisson()`, `impute = list(treatment = impute_model(treatment ~ z, family = binomial()))`, and `missing = miss_control(predictor = "model")` | Implemented first non-Gaussian response missing-predictor slice | Fits one fixed-effect Bernoulli/logit predictor model for a missing binary `mi()` predictor inside an ordinary Poisson response mean model, summing exactly over the two binary states with the Poisson response likelihood. Zero-inflated, random-effect, or structured Poisson response models with `mi()`, non-binary missing predictors in Poisson response models, and missing Poisson responses remain planned. |
| `y ~ z + mi(score)` with `impute = list(score = impute_model(score ~ z, family = cumulative_logit()))` and `missing = miss_control(predictor = "model")` | Implemented ordered missing-predictor slice | Fits one fixed-effect cumulative-logit predictor model for a missing ordered categorical `mi()` predictor and sums exactly over all ordered states when the predictor is missing. Grouped or structured ordered predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(habitat)` with `impute = list(habitat = impute_model(habitat ~ z, family = categorical()))` and `missing = miss_control(predictor = "model")` | Implemented unordered missing-predictor slice | Fits one fixed-effect baseline-category softmax predictor model for a missing unordered categorical `mi()` predictor and sums exactly over all unordered states when the predictor is missing. Grouped or structured unordered predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(cover)` with `impute = list(cover = impute_model(cover ~ z, family = beta()))` and `missing = miss_control(predictor = "model")` | Implemented strict proportion missing-predictor slice | Fits one fixed-effect beta predictor model for a missing strict proportion `mi()` predictor in `(0, 1)` and integrates missing values by deterministic quadrature. Grouped or structured beta predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(cover)` with `impute = list(cover = impute_model(cover ~ z, family = zero_one_beta()))` and `missing = miss_control(predictor = "model")` | Implemented boundary-proportion missing-predictor slice | Fits one fixed-effect zero-one beta predictor model for a missing proportion `mi()` predictor in `[0, 1]`, estimates constant predictor-model `sigma`, `zoi`, and `coi`, and integrates missing values over exact zero mass, exact one mass, and deterministic interior beta quadrature. Grouped or structured zero-one beta predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(cover)` with `impute = list(cover = impute_model(success ~ z, family = beta_binomial(), trials = trials))` and `missing = miss_control(predictor = "model")` | Implemented denominator-aware proportion missing-predictor slice | Fits one fixed-effect beta-binomial predictor model for a missing proportion `mi()` predictor when success counts and complete known trial denominators are available. Missing success counts are integrated by deterministic finite summation over `0, ..., trials_i`; `imputed()` reports the conditional proportion mean. Grouped or structured beta-binomial predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(abundance)` with `impute = list(abundance = impute_model(abundance ~ z, family = poisson()))` and `missing = miss_control(predictor = "model")` | Implemented Poisson count missing-predictor slice | Fits one fixed-effect Poisson/log predictor model for a missing non-negative integer `mi()` predictor and integrates missing counts by deterministic finite summation over count states. Use `nbinom2()` for overdispersed count predictors; grouped or structured count predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(abundance)` with `impute = list(abundance = impute_model(abundance ~ z, family = nbinom2()))` and `missing = miss_control(predictor = "model")` | Implemented negative-binomial count missing-predictor slice | Fits one fixed-effect NB2/log-mean predictor model for a missing non-negative integer `mi()` predictor, estimates the predictor overdispersion scale, and integrates missing counts by deterministic finite summation over count states. Grouped or structured count predictor models, hurdle count predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(abundance)` with `impute = list(abundance = impute_model(abundance ~ z, family = truncated_nbinom2()))` and `missing = miss_control(predictor = "model")` | Implemented zero-truncated count missing-predictor slice | Fits one fixed-effect zero-truncated NB2/log-mean predictor model for a missing positive integer `mi()` predictor, estimates the predictor overdispersion scale, and integrates missing positive counts by deterministic finite summation over positive count states. Grouped or structured count predictor models, hurdle count predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(biomass)` with `impute = list(biomass = impute_model(biomass ~ z, family = lognormal()))` and `missing = miss_control(predictor = "model")` | Implemented lognormal positive-continuous missing-predictor slice | Fits one fixed-effect lognormal predictor model for a missing positive continuous `mi()` predictor and integrates missing values by deterministic log-scale quadrature. Grouped or structured positive-continuous predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(biomass)` with `impute = list(biomass = impute_model(biomass ~ z, family = Gamma(link = "log")))` and `missing = miss_control(predictor = "model")` | Implemented Gamma positive-continuous missing-predictor slice | Fits one fixed-effect Gamma mean-CV predictor model for a missing positive continuous `mi()` predictor and integrates missing values by deterministic quadrature under the fitted Gamma model. Grouped or structured positive-continuous predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `y ~ z + mi(biomass)` with `impute = list(biomass = impute_model(biomass ~ z, family = tweedie()))` and `missing = miss_control(predictor = "model")` | Implemented Tweedie semi-continuous missing-predictor slice | Fits one fixed-effect Tweedie predictor model for a missing non-negative semi-continuous `mi()` predictor with exact zeros, fixes predictor-model power at 1.5, estimates the predictor mean and scale, and integrates missing values over exact zero mass plus deterministic positive-support quadrature. Estimated or predictor-dependent Tweedie power, grouped or structured semi-continuous predictor models, multiple missing predictors, EM engines, REML for missing-data routes, and measurement-error models remain planned. |
| `imputed(fit)` for a fitted MD3a/MD3b/MD4/MD6a/MD6b/MD6c/MD7a/MD7b/MD7c/MD7d/MD7e/MD7f/MD8a/MD8b/MD8c/MD9a `mi(x)` model | Implemented missing-predictor summary slice | Reports conditional modes for fitted Gaussian missing predictor values, conditional probabilities for fitted binary missing predictor values, conditional expected scores for fitted ordered missing predictor values, conditional modal category scores for fitted unordered predictor values, conditional means for fitted strict proportion, boundary proportion, denominator-aware beta-binomial, lognormal, Gamma, and Tweedie predictor values, and conditional expected counts for fitted Poisson, NB2, and zero-truncated NB2 missing predictor values. Gaussian routes include likelihood-based conditional standard errors when `sdreport()` is available; the first finite-state, beta/proportion, boundary-proportion, beta-binomial, count, lognormal, Gamma, and Tweedie routes report `NA` standard errors. This is not response imputation, simulation-based multiple imputation, posterior summaries, credible intervals, EM engines, REML for missing-data routes, or measurement-error modelling. |

## Univariate Syntax

The unnamed response formula is interpreted as the location (`mu`) formula:

```r
bf(
  y ~ x1 + x2,
  sigma ~ x1
)
```

Fixed-effect formulas use base R's ordinary formula machinery. Transformations
and interaction expansions such as `poly(x1, 2)`, `I(x1^2)`, `x1 * x2`, and
`(x1 + x2 + x3)^2` are supported wherever fixed effects are implemented for a
distributional parameter. Ecological examples should usually keep polynomial
orders modest, commonly second order and only rarely third order, so the fitted
curves remain interpretable.

Equivalent explicit form:

```r
bf(
  mu = y ~ x1 + x2,
  sigma = ~ x1
)
```

## Meta-Analysis Syntax

Meta-analysis is Gaussian regression with known sampling covariance. It is not
a separate family.

```r
bf(
  yi ~ x1 + x2 + meta_V(V = V),
  sigma ~ x1
)
```

The preferred `meta_V(V = V)` spelling supplies known sampling variances, a
diagonal covariance structure, a block-diagonal covariance matrix, or a full
known sampling covariance matrix. Deprecated `meta_known_V(V = V)` remains a
compatibility alias for the same additive known-covariance likelihood path, not
a separate likelihood. The response is already on the left-hand side, so the
marker does not repeat the response name. Meta-analysis is still regression;
Gaussian meta-analysis should normally use `family = gaussian()`, not a special
meta-analysis family.

For bivariate Gaussian meta-analysis, `meta_V(V = V)` should mark one location
formula and `V` is a dense `2n` by `2n` row-paired matrix. The fitted `rho12`
is then the residual covariance component after known within-study sampling
covariance has been included. It should not be called a study-level correlation
unless a separate study-level random effect is fitted.

The single `meta_V()` keyword should also leave room for a proportional
sampling-variance route:

```r
meta_V(w = w, scale = "proportional")
```

In the additive route, the supplied `V` is known sampling covariance and enters
the marginal covariance as `V + Omega_estimated`, matching the implemented
`meta_V(V = V)` contract. In the proportional route, the sampling-error term
would be modelled as `pi_i ~ Normal(0, phi_pi / w_i)` or, for correlated
sampling errors, through a weighted covariance matrix. This proportional route
is not ordinary likelihood weighting: the top-level `weights = w` argument
still multiplies log-likelihood contributions. Diagonal/vector known `V` may
be combined with ordinary likelihood weights; full matrix-`V` fits reject
non-unit weights until joint-block weighting has its own design and tests.

## Bivariate Syntax

Implemented bivariate Gaussian models usually use separate response formulas
and fixed effects only:

```r
bf(
  mu1 = y1 ~ x1 + x2,
  mu2 = y2 ~ x1,
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

The first bivariate group-level covariance slices use separate response
formulas and matching labelled random intercepts:

```r
bf(
  mu1 = y1 ~ x1 + x2 + (1 | p | id),
  mu2 = y2 ~ x1      + (1 | p | id),
  sigma1 = ~ x1 + x2 + (1 | q | id),
  sigma2 = ~ x1      + (1 | q | id),
  rho12 = ~ x1 + x2
)
```

The shared `p` label requests one group-level covariance block for the `mu1`
and `mu2` random intercepts. The shared `q` label requests a separate
scale-scale block for the `sigma1` and `sigma2` random intercepts on the
log-`sigma` scale. Neither block is residual `rho12`: they describe
between-group associations after the fixed effects are included. One or more
same-response `mu`/`sigma` random-intercept pairs are also implemented when
each response-specific pair has its own label. Reusing the same label and group
in all four `mu1`, `mu2`, `sigma1`, and `sigma2` formulas requests one ordinary
q=4 random-intercept block with all six latent
correlations. For phylogenetic all-four terms, using one label for `mu1` and
`mu2` and a different label for `sigma1` and `sigma2` requests the
block-diagonal fallback: two independent q=2 tree blocks, with mean-mean and
scale-scale phylogenetic correlations but no mean-scale phylogenetic rows.
All-four endpoint bivariate random slopes are now source-tested for the
ordinary one-slope q8 Gaussian route when all four formulas use matching
`(1 + x | p | id)` terms. Random effects in `rho12`, structured q8 siblings,
non-Gaussian q8 blocks, and broader coefficient sets remain planned. The first
same-response q2 `mu`/`sigma` slope route is a separate fitted slice.

The first bivariate random-slope targets are intentionally narrower than the
full endpoint and are now fitted for location and scale-scale q2 terms. A
matching slope-only location block such as `(0 + x | p | id)` in both `mu1`
and `mu2` estimates the
group-level association between individual differences in the two
response-specific slopes without also estimating intercept-slope correlations.
A matching one-slope location block such as `(1 + x | p | id)` in both
responses fits a q=4 location block with two intercept SDs, two slope SDs, and
six latent location correlations. Matching two-slope location blocks such as
`(1 + x + z | p | id)` in both responses are also fitted and
smoke-artifact-routed as q=6 ordinary location covariance blocks with six SDs
and 15 latent location correlations. The SDs are direct `log_sd_re_cov` profile targets, while q > 2
correlations are derived and unavailable for direct profile intervals. The
matching q2 `sigma1`/`sigma2` scale-slope block is fitted separately, as is one
matching same-response q2 `mu`/`sigma` slope-only block. Matching all-four
location-scale slope terms across `mu1`, `mu2`, `sigma1`, and `sigma2` now fit
the first ordinary q8 endpoint with eight direct SD targets and 28
derived-unavailable correlations. That q8 path now has diagnostic Phase 18
smoke/recovery artifacts, but it still needs coverage evidence and power checks
before it can be taught as a routine model.

The first fitted bivariate phylogenetic location slice uses matching
intercept-only `phylo()` terms in the two location formulas:

```r
bf(
  mu1 = y1 ~ x1 + phylo(1 | species, tree = tree),
  mu2 = y2 ~ x1 + phylo(1 | species, tree = tree),
  sigma1 = ~ 1,
  sigma2 = ~ 1,
  rho12 = ~ x1
)
```

Both `phylo()` terms must use the same grouping variable and the same tree.
The fitted block estimates `sd_phylo_mu1`, `sd_phylo_mu2`, and one
phylogenetic mean-mean correlation. This correlation is separate from
residual `rho12`, which still describes within-observation response coupling
after fixed effects, residual scales, and phylogenetic mean deviations are
included.

When the same labelled phylogenetic intercept appears in `mu1`, `mu2`,
`sigma1`, and `sigma2`, `drmTMB()` fits one constant q=4 phylogenetic
location-scale block. The two scale effects enter the `log(sigma1)` and
`log(sigma2)` predictors, so their SDs and correlations live on the residual-SD
linear-predictor scale:

```r
bf(
  mu1 = y1 ~ x1 + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x1 + phylo(1 | p | species, tree = tree),
  sigma1 = ~ z + phylo(1 | p | species, tree = tree),
  sigma2 = ~ z + phylo(1 | p | species, tree = tree),
  rho12 = ~ x1
)
```

This block reports one location-location row, four location-scale rows, and one
scale-scale row in `corpairs(level = "phylogenetic")`. These six latent
phylogenetic correlations are not residual `rho12`.

Use the same label and grouping variable across all four bivariate location and
scale formulas only when the target is one full ordinary q=4 random-intercept
block across `mu1`, `mu2`, `sigma1`, and `sigma2`. Use distinct labels, such as
`p` and `q`, when the target is two separate mean-mean and scale-scale blocks.
The q=4 path is currently intercept-only; random-slope endpoint blocks remain
planned.

The singular `corpair()` formula marker is reserved for later
predictor-dependent latent random-effect correlations:

```r
bf(
  mu1 = y1 ~ x + (1 | p | id),
  mu2 = y2 ~ x + (1 | p | id),
  sigma1 = ~ z + (1 | p | id),
  sigma2 = ~ z + (1 | p | id),
  rho12 = ~ w,
  corpair(id, level = "group", block = "p", from = "mu1", to = "sigma2") ~ w
)
```

Naming rule: keep `corpair()` for the formula target and `corpairs()` for the
extractor. Do not introduce `cor12()` for this layer. The suffix `12` belongs
to the residual two-response parameter `rho12`, while latent random-effect
correlations can be `mu1`-`mu2`, the four location-scale pairs
`mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`, and `mu2`-`sigma2`,
`sigma1`-`sigma2`, and later slope pairs. The cross-trait location-scale pairs
are statistically part of the q=4 block even when they need careful biological
interpretation. A `cor12()` formula would make location-scale and scale-scale
targets look like residual response correlations, which is exactly the
ambiguity this grammar is trying to avoid.

Slice 12 implements the first endpoint-specific `corpair()` model for ordinary
q=2 location-location covariance blocks. The fitted path identifies the exact
latent endpoints and covariance level:

```r
corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ w
```

The same grammar is implemented for the q=2 phylogenetic location-location
level:

```r
corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ ecology
```

Unlike the ordinary grouped q=2 route, a predictor-dependent phylogenetic
correlation must produce one positive-definite covariance matrix for all
species coupled by the tree. The fitted design contract is a two-field loading
model: a species predictor changes the local same-species phylogenetic
correlation while preserving a valid full covariance matrix. This selected
contract covers only `from = "mu1", to = "mu2"`; phylogenetic location-scale
and scale-scale correlation regressions need a q=4 contract and remain
deferred.

The older `class = "location-scale"` spelling remains useful as an extraction
filter and as a possible later shared-class model, but it should not be the
first fitted q=4 correlation-regression target. The `level` argument keeps
ordinary, phylogenetic, and spatial latent-correlation targets in one grammar
without adding `corpair_phylo()` or `corpair_spatial()` function families.

Use `rho12 = ~ w` for residual within-observation correlation, and use
`corpairs(fit)` to extract fitted latent random-effect correlations. For the
ordinary q=2 `mu1`/`mu2` path, `corpairs()` reports the fitted response-scale
mean, minimum, maximum, and number of group-level correlation values; `coef()`,
`summary()`, `vcov()`, and `profile_targets()` expose the link-scale
`corpair()` regression coefficients.
Because older fitted rows currently report `mean-mean` and `mean-scale`,
`corpairs()` accepts `location-location` and `location-scale` as class filter
aliases while the output naming remains stable.

For the current 35-slice covariance route, only the ordinary q=2
location-location `corpair()` route is fitted. In a q=4 block,
`class = "location-scale"` can refer to four different endpoint pairs, so a
fitted formula needs either a class-wide shared-correlation contract or
endpoint-specific syntax before it can be statistically clear. Full q=4
correlation regression also needs a positive-definite matrix parameterization
rather than independent pairwise `tanh()` regressions.

The `mvbind()` form is implemented as shorthand for identical location
formulas:

```r
bf(mvbind(y1, y2) ~ x)
```

It expands internally to separate `mu1 = y1 ~ x` and `mu2 = y2 ~ x`.
Do not combine `mvbind()` with explicit `mu1` or `mu2` formulas. Use explicit
formulas whenever the two responses need different predictors.

## Random Effects and Scale Components

Use residual `sigma` for observation-level scale:

```r
bf(y ~ x1 + x2, sigma ~ x1)
```

Implemented univariate Gaussian location random intercepts:

```r
bf(y ~ x1 + (1 | id), sigma ~ x1)
```

Multiple additive random-intercept terms in `mu` are implemented for the
univariate Gaussian path:

```r
bf(y ~ x1 + (1 | site) + (1 | observer), sigma ~ x1)
```

Simple numeric random-slope terms are also implemented in the univariate
Gaussian `mu` path when written as a separate `0 + x` term:

```r
bf(y ~ x1 + (0 + x1 | id), sigma ~ x1)
```

The current independent intercept-plus-slope form is:

```r
bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1)
```

Multiple ordinary random slopes may be written as separate independent terms:

```r
bf(
  y ~ x1 + x2 + (1 | id) + (0 + x1 | id) + (0 + x2 | id),
  sigma ~ x1
)
```

Interactions are not parsed directly as random slopes yet. For now, create the
interaction column explicitly:

```r
dat$x1_x2 <- dat$x1 * dat$x2
bf(y ~ x1 * x2 + (0 + x1_x2 | id), sigma ~ x1)
```

Ordinary correlated random intercept-slope blocks are implemented for the
univariate Gaussian `mu` path:

```r
bf(y ~ x1 + (1 + x1 | id), sigma ~ x1)
```

The same one-slope block may carry a covariance-block label:

```r
bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x1)
```

For labelled `mu` intercept-slope blocks, `p` is metadata for naming and
future covariance-block matching. It is not looked up in `data`. Matching
labelled `mu` and `sigma` random intercepts use the same label to fit the
first cross-formula mean-scale covariance block.

The group-level intercept-slope correlation is extracted as `corpars$mu`, not
as residual `rho12`.

Covariance-block labels must not use reserved distributional parameter names
such as `mu`, `sigma`, `rho`, or `rho12`.

Residual-scale random intercepts and independent numeric random slopes are
implemented in the univariate Gaussian `sigma` formula:

```r
bf(y ~ x1 + (1 | id), sigma ~ x1 + (1 | id) + (0 + w | id))
```

This models group-to-group variation in residual `sigma_i`, including
group-specific changes in the residual-scale effect of `w`. It is not a
random-effect scale formula such as `sd(id) ~ x1`.

Matching labelled random intercepts in `mu` and `sigma` fit one group-level
mean-scale covariance block:

```r
bf(y ~ x1 + (1 | p | id), sigma ~ x1 + (1 | p | id))
```

The fitted correlation is reported under `corpars$mu_sigma` and in
`corpairs()` as a `mean-scale` row. It describes whether group deviations in
the mean and residual scale are associated.

The same pairwise bridge is implemented for one or both responses in a
bivariate Gaussian model:

```r
bf(
  mu1 = y1 ~ x1 + (1 | p | id),
  mu2 = y2 ~ x1 + (1 | q | id),
  sigma1 = ~ x1 + (1 | p | id),
  sigma2 = ~ x1 + (1 | q | id),
  rho12 = ~ x1
)
```

Here the shared `p` label fits a group-level mean-scale correlation for response
1, reported as `corpars$mu_sigma` and a `corpairs()` `mean-scale` row with
`from_dpar = "mu1"` and `to_dpar = "sigma1"`. The independent `q` label fits a
second group-level mean-scale correlation for response 2. Because the labels
are response-specific, this model does not add a `mu1`/`mu2` or
`sigma1`/`sigma2` latent correlation; use matching labels in same-parameter
formulas for those blocks. The larger all-four labelled block is also supported
for intercept-only terms when the same label appears in `mu1`, `mu2`,
`sigma1`, and `sigma2`; it reports one location-location row, four
location-scale rows, and one scale-scale row.

The distinction is:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma
```

matches `sigma ~ x1` and models residual or within-observation SD.

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + a_{id[i]} + w_i c_{id[i]}
a_id ~ Normal(0, sd_sigma_id^2)
c_id ~ Normal(0, sd_sigma_w^2)
```

matches `sigma ~ x1 + (1 | id) + (0 + w | id)` and models group-to-group
deviations in residual SD and in the residual-scale slope of `w`.

```text
b_id ~ Normal(0, sd_mu_id^2)
log(sd_mu_id) = W_id alpha_id
```

matches implemented `sd(id) ~ x1` when `id` targets exactly one unlabelled
univariate Gaussian `mu` random intercept. Several distinct unlabelled
intercept targets can be modelled in the same Gaussian fit, such as `sd(id) ~
x_id` and `sd(site) ~ x_site`. The syntax models the standard deviation of a
`mu` random effect, not residual `sigma`. Detailed rules are in
`docs/design/18-random-effect-scale-models.md`.

For bivariate Gaussian location random effects, the implemented direct-SD
syntax uses response-specific names:

```r
bf(
  mu1 = y1 ~ x + (1 | p | id),
  mu2 = y2 ~ x + (1 | p | id),
  sigma1 = ~ 1,
  sigma2 = ~ 1,
  rho12 = ~ 1,
  sd1(id) ~ z1,
  sd2(id) ~ z2
)
```

Here `sd1(id)` models the SD of the `mu1` location random intercept and
`sd2(id)` models the SD of the `mu2` location random intercept. These are
Family B direct variance-component scale models. They are not residual
`sigma1` or `sigma2` models, and they do not target random effects inside the
`sigma1` or `sigma2` formulas.

The implemented phylogenetic bivariate sibling uses the same response-specific
idea:

```r
bf(
  mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
  sigma1 = ~ w1,
  sigma2 = ~ w2,
  rho12 = ~ context,
  sd_phylo1(species) ~ z1,
  sd_phylo2(species) ~ z2
)
```

`sd_phylo1(species)` targets the `mu1` phylogenetic location-effect SD surface
and `sd_phylo2(species)` targets the `mu2` surface. The bivariate design keeps a
constant latent phylogenetic location-location correlation, reported by
`corpairs()`, and keeps residual `rho12` as the within-observation coscale
parameter. It is not syntax for phylogenetic residual-scale SDs or q=4
location-scale endpoint SDs.

The project direction is generic `sd*()` direct-SD grammar, not a permanent
explosion of structure-specific helper names. The `sd*()` family now has a
single generic phylogenetic spelling: `sd(species, level = "phylogenetic") ~ z`,
`sd1(species, level = "phylogenetic") ~ z`, and
`sd2(species, level = "phylogenetic") ~ z` parse to the identical `sd_phylo(...)`
/ `sd_phylo1(...)` / `sd_phylo2(...)` dpar string that the legacy spellings
already emit, so every downstream branch and every fitted example is
unaffected. `level` is consumed entirely by the parser and never appears in
the dpar string. The historical `sd_phylo()`, `sd_phylo1()`, and `sd_phylo2()`
spellings remain valid, working compatibility aliases; parsing one fires a
one-time-per-session `lifecycle::deprecate_warn()` and new examples should
prefer the `level = "phylogenetic"` spelling. Supplying `level = "phylogenetic"`
on an already-`sd_phylo*()` call is rejected as redundant.
`sd(site, level = "spatial") ~ z`, `sd(id, level = "animal") ~ z`, and
`sd(line, level = "relmat") ~ z` are reserved: the parser recognises the
`level` argument and its allowed values, but rejects them as not yet
implemented (no `sd_spatial()`/`sd_animal()`/`sd_relmat()` helper names exist
or are planned). Those levels should land only with a fitted variance model,
parser tests, examples, reference-index discoverability, and a clear migration
note, mirroring the phylogenetic route.

Reserved explicit random-effect scale targets use `dpar`, `coef`, and optional
`block` arguments:

```r
bf(
  y ~ x1 + (1 + x1 | id),
  sigma ~ x2,
  sd(id, dpar = "mu", coef = "(Intercept)") ~ x_group,
  sd(id, dpar = "mu", coef = "x1") ~ x_group
)
```

`drm_formula()` parses this grammar so future examples have one spelling, but
`drmTMB()` rejects it until random-slope SD regression has a fitted covariance
model and simulation tests. The implemented shorthand `sd(id) ~ x_group`
remains limited to the unambiguous case with exactly one unlabelled Gaussian
`mu` random intercept for `id`.

Future correlated multi-slope syntax should allow larger model-matrix terms
such as:

```r
bf(y ~ x1 * x2 + (1 + x1 + x2 + x1:x2 | id), sigma ~ x1)
```

or labelled covariance blocks:

```r
bf(y ~ x1 * x2 + (1 + x1 + x2 + x1:x2 | p | id), sigma ~ x1)
```

A block with `q` random coefficients has `q * (q + 1) / 2` covariance
parameters, so large random-slope blocks need simulation checks and clear user
warnings.

Random-effect scale components use `sd(group) ~` in univariate Gaussian models
and `sd1(group) ~` / `sd2(group) ~` in bivariate Gaussian models. The
implemented univariate Gaussian path supports one or more distinct unlabelled
`mu` random-intercept targets:

```r
bf(
  y ~ x1 + x2 + (1 | id1) + (1 | id2),
  sigma ~ x1,
  sd(id1) ~ x1,
  sd(id2) ~ x1 + x2
)
```

The implemented bivariate Gaussian path supports labelled location
random-intercept targets in `mu1` and `mu2`, for example `sd1(id) ~ x_id` and
`sd2(id) ~ x_id`. Names such as `sd_sigma1()` and `sd_sigma2()` are rejected
because they invite the unsupported mixture of a scale-formula random effect
and a direct SD model for the same latent layer.

The same guard applies to all-four ordinary q=4 blocks. A model with matching
`(1 | p | id)` terms in `mu1`, `mu2`, `sigma1`, and `sigma2` already estimates
one joint latent covariance matrix for `id`. `sd1(id) ~ x_id` or
`sd2(id) ~ x_id` is therefore rejected for that same group until a future
heterogeneous covariance-block model is designed and tested.

## Structured Phylogenetic and Spatial Markers

`drm_formula()` parses structured-effect markers and stores them as structured
metadata. The fitted Gaussian paths include univariate `mu` and `sigma`
intercepts, one numeric `mu` slope, first sigma-only structured one-slope cells,
matching bivariate q=2 `mu1`/`mu2` blocks, and constant q=4 location-scale
blocks for supported `phylo()`, `spatial()`, `animal()`, and `relmat()`
markers. Ordinary Poisson/NB2 also fit one q=1 structured `mu` intercept or an
unlabelled intercept-plus-one-slope term.
Mesh/SPDE spatial fields, multiple structured slopes, labelled structured
slope covariance beyond the first slope-only q=2 cells, bridge/inference for
matched `mu+sigma` slope cells, larger structured slope correlations,
pure, labelled, or multiple structured count slopes, labelled count
covariance, and structured `rho12` effects remain planned.

The canonical phylogenetic syntax is:

```r
bf(y ~ x1 + phylo(1 | species, tree = tree), sigma ~ x2)
```

Here `tree` is the name of an ultrametric phylogeny object with branch lengths.
The fitted implementation builds the sparse augmented A-inverse internally
using the Hadfield and Nakagawa route. Dense covariance matrices are lower-level
comparator or `relmat()` inputs; deprecated `gr()` is not the main public
phylogeny API.

The implemented coordinate spatial syntax is:

```r
bf(y ~ x1 + spatial(1 | site, coords = coords), sigma ~ x2)
bf(y ~ x1 + spatial(1 + depth | site, coords = coords), sigma ~ x2)
```

This fitted `coords` path builds a fixed coordinate covariance from the
observed sites and estimates one structured spatial SD per fitted spatial
coefficient in the Gaussian `mu` formula. The slope path estimates independent
intercept and slope fields, labelled `spatial(1 | site)` and
`spatial(0 + depth | site)`, with no intercept-slope correlation. `coords` may
contain one row per site or one row per observation, provided coordinates are
constant within site after model-row filtering.

The planned mesh/SPDE syntax is:

```r
bf(y ~ x1 + spatial(1 | site, mesh = mesh), sigma ~ x2)
```

Here `mesh` names the object that will be used to build an SPDE/GMRF
precision. Exactly one of `coords` or `mesh` should be supplied. `coords` is
the friendly data-level input: observed or site coordinates. `mesh` is the
expert-control input for users who already built the finite-element scaffold.
Mesh is not a biological sampling level; it is the numerical support needed for
the scalable SPDE/GMRF route.

The parser currently reserves intercept-only and one-slope forms. Fitted
univariate Gaussian structured-slope forms are intercept-only and one
numeric-slope phylogenetic, coordinate-spatial, animal-model, and `relmat()`
terms in `mu`, the first `sigma` cells, and matched `mu+sigma` cells:

```r
phylo(1 | species, tree = tree)
phylo(1 + x1 | species, tree = tree)
spatial(1 | site, coords = coords)
spatial(1 + depth | site, coords = coords)
animal(1 + x1 | id, pedigree = ped)
relmat(1 + x1 | id, K = K)
```

Each one-slope path estimates independent intercept and slope fields with
separate SDs and no intercept-slope correlation. A matched `mu+sigma`
one-slope fit has four endpoint members,
`mu:(Intercept)`, `mu:x`, `sigma:(Intercept)`, and `sigma:x`; it is not a
labelled slope-covariance block.

Residual-scale structured intercepts and first one-slope cells share the same
user syntax in the univariate Gaussian `sigma` formula:

```r
sigma ~ phylo(1 | species, tree = tree)
sigma ~ phylo(1 + x | species, tree = tree)
sigma ~ spatial(1 | site, coords = coords)
sigma ~ spatial(1 + x | site, coords = coords)
sigma ~ animal(1 | id, Ainv = Ainv)
sigma ~ animal(1 + x | id, A = A)
sigma ~ relmat(1 | id, Q = Q)
sigma ~ relmat(1 + x | id, Q = Q)
```

Matching intercept-only structured terms in `mu` and `sigma` fit two latent
fields on the same structured precision and estimate one latent structured
`mu`-`sigma` correlation under native ML. Matching unlabelled one-slope terms
in `mu` and `sigma` fit the four independent endpoint members named above, with
no intercept-slope or mean-scale slope correlation. Native `REML = TRUE` is
exact-Gaussian and row-specific. The fitted native phylogenetic routes include
q1 mean-side inference evidence, sigma-only and matched univariate q2 point-fit
evidence, bivariate mean-side q2 point-fit evidence, and block-diagonal or dense
q4 recovery evidence. Separately, Arc 1a admits pure-`mu` spatial, animal, and
`relmat()` intercept or independent intercept-plus-one-slope routes over their
exact recorded discrete domains. The scale-side, q2, and q4 rows do not inherit
q1 mean-side interval or coverage promotion. Labelled structured
slope covariance, interaction slopes, structured `rho12` effects, and bivariate
structured effects beyond the fitted q=2 location paths, the fitted
phylo/spatial/animal/`relmat()` constant q=4 blocks, and the exact shared-label
all-four one-slope cells remain planned until the fitted paths have simulation
and comparator coverage. The near-term ceiling
remains one structured slope per endpoint.
Intercept-slope `corpair()` rows stay distant-future; a later
coefficient-aware design can target a bivariate slope1-slope2
plasticity-syndrome correlation for the same covariate across responses.

Future cross-formula correlated random-effect blocks should use ID labels:

```r
bf(
  mu = y ~ x1 + (1 + x1 | p | id),
  sigma = ~ x1 + (1 | p | id)
)
```

Matching `p` labels will request a shared group-level covariance block once
random effects in multiple distributional parameters are implemented. These
correlations should be constant in the first cross-formula implementation.
Formulae for group-level correlations are reserved for later.

## Correlation Namespace

Use `rho12` only for residual or response-level correlation between response 1
and response 2 in a bivariate likelihood. The current implemented bivariate
form has fixed-effect distributional formulas:

```r
bf(
  mu1 = y1 ~ x1 + x2,
  mu2 = y2 ~ x1,
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

Implemented bivariate random-intercept syntax keeps labelled group-level
covariance blocks distinct from residual `rho12`:

```r
bf(
  mu1 = y1 ~ x1 + x2 + (1 | p | ID),
  mu2 = y2 ~ x1      + (1 | p | ID),
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

Do not use `rho12` for group-level random-effect correlations or as a
covariance-block label.
Double-hierarchical models for individual differences can contain several
interpretable correlations among random intercepts, random slopes, random scale
intercepts, and random scale slopes. Those correlations belong to labelled
group-level covariance blocks such as `(1 | p | id)` and the fitted bivariate
location block `(1 + x1 | p | id)`, not to residual `rho12 ~`. Residual-scale
slope covariance and same-response location-scale slope covariance have named
q2 fitted slices; all-four location-scale slope endpoints are a separate
diagnostic q8 group-level block, not residual `rho12`.

For each response, the mean block may contain at least two group-level scale
terms once random slopes are implemented: the random-intercept SD and the
random-slope SD. Residual `sigma1` and `sigma2` remain separate
within-observation scale parameters. Do not overload `sigma` to mean every
variance component.

Random intercept/slope correlations are likely to be estimated as constant
covariance-block parameters. The main predictor-dependent `rho12` formulas in
`drmTMB` are reserved for correlations between two responses.

## Families For One Or Two Responses

For univariate models, the stable public API should accept one family:

```r
family = gaussian()
family = student()
family = lognormal()
family = Gamma(link = "log")
family = beta()
family = zero_one_beta()
family = poisson(link = "log")
family = nbinom2()
family = truncated_nbinom2()
```

Implemented ordinal and denominator-aware family syntax now includes:

```r
family = cumulative_logit()
family = beta_binomial()
```

This route fits one ordered response with a `mu` location formula and ordered
cutpoints. Ordinal `sigma` or discrimination formulas remain planned and
should produce clear unsupported-feature errors until their likelihood,
simulation path, extractor behaviour, and comparator checks exist.
`zero_one_beta()` fits a single continuous proportion response on `[0, 1]`,
using fixed-effect `zoi` and `coi` formulas for exact-boundary mass. It is not
a denominator-aware count model; use `beta_binomial()` when the number of trials
is part of the sampling process.
`beta_binomial()` fits `cbind(successes, failures)` responses with `mu` as the
success probability and `sigma` as extra-binomial variation. A two-column
successes/trials interface remains a possible later alias, not a second
implemented grammar.

For bivariate models, prefer a vector/list of response families:

```r
family = c(gaussian(), gaussian())
family = list(gaussian(), gaussian())
```

This makes mixed-response bivariate models natural later, but only the
all-Gaussian composed case is implemented now. It works for both `c()` and
`list()` spellings and routes to the same likelihood as `biv_gaussian()`.
Mixed-response bivariate families such as `family = c(gaussian(), poisson())`
remain future work until their joint likelihood and interpretation of `rho12`
are specified.

## Distributional Parameters

Formulae may target distributional parameters such as:

- `mu`, `mu1`, `mu2`;
- `sigma`, `sigma1`, `sigma2`;
- `nu`;
- `zi`, `zoi`, `coi`, `hu`;
- `rho12`;
- `sd(group)` for random-effect scale models.

`nu` follows the GAMLSS convention for the first shape parameter. Family
documentation should explain whether `nu` means skewness, degrees of freedom,
tail shape, count dispersion, or another shape quantity. `tau` is reserved for
a possible second shape parameter in future families; it is not current formula
syntax and should not be used for meta-analytic heterogeneity.

## Random-Effect Eligibility

Not every parameter should accept random effects at the same development stage.

| Parameter class | Random effects policy |
|---|---|
| `mu`, `mu1`, `mu2` | Yes for univariate Gaussian `mu`; random intercepts, independent numeric random slopes, and labelled or unlabelled ordinary correlated intercept-slope blocks are implemented. For non-zero-inflated Poisson and NB2 models, ordinary unlabelled `mu` random intercepts and independent numeric slopes such as `(1 | id) + (0 + x | id)` are implemented on the log-mean scale, one q=1 structured `mu` intercept may use `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, or `relmat()`, and one unlabelled intercept-plus-one-slope term may use `phylo()`, `spatial()`, `animal()`, or `relmat()`. Row-specific zero-inflated gates also accept an intercept-only spatial `mu` field for fixed-`zi` Poisson and fixed-`zi` NB2 at diagnostic-only grade. Ordinary Student-t, zero-truncated NB2, lognormal, Gamma, beta, beta-binomial, and binomial models also support unlabelled `mu` random intercepts and independent numeric slopes such as `(1 | id) + (0 + x | id)`. Beta additionally admits exactly one unlabelled intercept-only `phylo(1 | species, tree = tree)` term in `mu` at `point_fit_recovery` for the exact tested `g = 1024, m = 4` regime; family `sigma` remains fixed-effect-only, and slopes, labels/q2+, direct latent-`sd()` regression, intervals, and coverage remain deferred. Correlated non-Gaussian slopes, covariance labels, pure, labelled, or multiple structured count slopes, zero-inflated structured count effects outside exact local-fit gates, bounded-response exact-boundary random effects, and richer or labelled NB2 structured `sigma` effects beyond the exact q1 recovery-grade routes remain planned. For bivariate Gaussian models, matching labelled random intercepts in `mu1` and `mu2`, such as `(1 | p | id)` in both formulas, matching slope-only `mu1`/`mu2` blocks such as `(0 + x | p | id)`, matching same-response slope-only `mu1`/`sigma1` or `mu2`/`sigma2` blocks, matching one-slope q=4 location blocks such as `(1 + x | p | id)`, matching q=6 location blocks such as `(1 + x + z | p | id)`, and the first all-four q8 endpoint block with matching `(1 + x | p | id)` terms in `mu1`, `mu2`, `sigma1`, and `sigma2` are implemented. Bivariate residual-scale slope-only `sigma1`/`sigma2` blocks are listed under `sigma`; formal simulation recovery for q > 2 bivariate location and q8 blocks is later. |
| `sigma`, `sigma1`, `sigma2` | Yes for univariate Gaussian `sigma` random intercepts, independent numeric random slopes, and unlabelled ordinary correlated intercept-slope or multi-slope blocks. Separate terms such as `sigma ~ x + (1 | id) + (0 + w | id)` are independent; one term such as `sigma ~ x + (1 + w | id)` estimates within-block correlations. Labelled residual-scale blocks and cross-formula `mu`-`sigma` slope covariance remain planned. Univariate Gaussian `sigma` also has first sigma-only structured one-slope cells for `phylo(1 + x | species, tree = tree)`, fixed-covariance `spatial(1 + x | site, coords = coords)`, A-matrix `animal(1 + x | id, A = A)`, and K/Q `relmat(1 + x | id, K/Q = ...)`; matching unlabelled `mu` and `sigma` one-slope structured terms fit the same four endpoint members as native point-fit/extractor cells. Matching labelled `mu` and `sigma` intercepts such as `(1 | p | id)` fit mean-scale covariance blocks, with one row per independent matched label/group pair. For bivariate Gaussian models, matching labelled random intercepts in `sigma1` and `sigma2` are implemented as a scale-scale block, matching slope-only labels such as `(0 + x | p | id)` in both `sigma1` and `sigma2` fit the first scale-slope block, and matching same-response `mu1`/`sigma1` or `mu2`/`sigma2` slope-only labels fit the first mean-scale-slope block. Ordinary non-zero-inflated NB2, lognormal, and Gamma also support a first independent `sigma ~ z + (1 | id)` random-intercept gate; exact q1 NB2 structured `sigma` intercept-plus-one-slope routes for `phylo()`, `spatial()`, `animal()`, and `relmat()` are fitted at recovery grade. Student-t, beta, beta-binomial, truncated NB2, and hurdle NB2 `sigma` formulas remain fixed-effect only; NB2/lognormal/Gamma `sigma` slopes, labelled or combined non-Gaussian `sigma` covariance, zero-inflated NB2 `sigma` random effects, richer or labelled structured non-Gaussian `sigma`, structured bridge/interval/coverage promotion, and all-four bivariate scale endpoints are later. |
| `sd(group)` | Implemented for one or more distinct unlabelled univariate Gaussian `mu` random intercepts, such as `sd(id) ~ x_group` and `sd(site) ~ site_type`; predictors must be constant within group after missing-row filtering. One exact non-Gaussian exception is the Beta q1 phylogenetic location form `sd(spp_id, level = "phylogenetic") ~ x_tau`; it targets latent `tau`, not family `sigma`. Labelled scale targets, slopes, random RHS effects, `sigma` random-effect scales, bivariate models, and other non-Gaussian models are later. |
| `rho12` | No random effects initially; predictor-dependent fixed effects only. |
| `nu`; future `tau` | Fixed effects first, with one exact diagnostic-only Student-t q1 `nu ~ phylo(1 | id, tree = tree)` intercept backed by a single local smoke and no recovery denominator. Other Student-t `nu` random effects, future `nu`/`tau` routes, and ID-level skewness such as `skew(id) ~ x` need their own recovery evidence. `tau` is reserved for a possible second shape parameter and is not current syntax. |
| `zi`, `hu`, `zoi`, `coi` | Fixed effects first, with exact diagnostic-only q1 intercept exceptions for Poisson `zi ~ spatial()` and truncated-NB2 `hu ~ relmat(K/Q)`. A fixed-`zi` Poisson model admits an intercept-only `mu ~ spatial()` gate at diagnostic-only grade, while the corresponding fixed-`zi` NB2 gate is diagnostic-only. Poisson ordinary `mu` random intercepts/slopes require no `zi` formula. An active `hu` formula blocks ordinary count-side `mu` random effects. For percentage data, fixed-effect `zoi` and `coi` are implemented only in `zero_one_beta()`; random effects and covariance beyond these exact gates remain planned. |
| `meta_known_V()` | Never; it is known sampling covariance, not an estimated parameter. |
| `phylo(1 | species, tree = tree)` | Implemented structured random intercept for univariate Gaussian `mu`, univariate Gaussian `sigma`, matching Gaussian `mu`/`sigma` location-scale blocks, ordinary Poisson `mu`, ordinary NB2 `mu`, and the exact univariate ML Beta `mu` q1 cell. The Beta admission is recovery-only for the exact tested `g = 1024, m = 4` regime, with fixed-effect family `sigma`; its slopes, labels, scale-side structure, direct latent-`sd()` regression, intervals, and coverage remain deferred. `tree` must be an ultrametric phylogeny with branch lengths. |
| `phylo(1 | p | species, tree = tree)` / `phylo(0 + x | p | species, tree = tree)` / all-four `phylo(1 + x | p | species, tree = tree)` | Implemented as labels for matching bivariate `mu1`/`mu2` phylogenetic location intercept or slope-only terms; intercept labels also feed the matching all-four q=4 bivariate phylogenetic location-scale block. The exact shared-label all-four one-slope cell has native point-fit/extractor evidence for eight endpoint members and 28 derived correlations. Partial, unlabelled, mismatched, block-diagonal one-slope, bridge, interval, coverage, REML, and AI-REML forms remain rejected or planned. |
| `phylo_interaction(1 | partner1:partner2, tree1 = tree1, tree2 = tree2)` | Implemented first q=1 slice for univariate Gaussian `mu`, ordinary Poisson `mu`, and ordinary NB2 `mu`. It builds the pair-level latent precision as the sparse Kronecker product of the two partner phylogenetic augmented precisions. It is not a full bipartite decomposition yet: additive partner main effects plus interaction require a later multi-structured-layer implementation, and binary incidence needs a Bernoulli/binomial family gate first. |
| `phylo(1 | species, A = A)` or `phylo(1 | species, Ainv = Ainv)` | Planned matrix-input sibling to the tree route; `tree = tree` remains the only implemented public phylogenetic input. |
| `phylo_interaction(1 | partner1:partner2, tree1 = tree1, tree2 = tree2)` | Implemented first q=1 slice for univariate Gaussian `mu`, ordinary Poisson `mu`, and ordinary NB2 `mu`. It builds the pair-level latent precision as the sparse Kronecker product of the two partner phylogenetic augmented precisions. It is not a full bipartite decomposition yet: additive partner main effects plus interaction require a later multi-structured-layer implementation, and binary incidence needs a Bernoulli/binomial family gate first. |
| `animal(1 | id, pedigree = ped)` | Implemented first slice for univariate Gaussian `mu`, univariate Gaussian `sigma`, and matching `mu`/`sigma` animal-model intercepts using a dense additive relationship matrix built from `id`, `dam`, and `sire` columns. |
| `animal(1 | id, A = A)` / `animal(1 | id, Ainv = Ainv)` | Implemented first slice for univariate Gaussian `mu`, univariate Gaussian `sigma`, and matching `mu`/`sigma` animal-model intercepts using a precomputed additive relatedness or inverse-relatedness matrix. |
| `animal(1 | p | id, pedigree = ped)` / `animal(1 | p | id, A = A)` / `animal(1 | p | id, Ainv = Ainv)` / `animal(0 + x | p | id, A/Ainv = ...)` | Implemented first bivariate q=2 Gaussian location-covariance slices when matching labelled intercept-only or slope-only terms appear in `mu1` and `mu2`; matching all-four intercept terms also fit the first constant q=4 location-scale block. Sparse large-pedigree construction, multiple slopes, slope correlations, intercept-plus-slope labelled structured covariance, `corpair()` regressions, and direct-SD grammar remain planned. |
| `animal(1 + x | id, pedigree = ped)` | Implemented one numeric animal-model random slope for univariate Gaussian `mu`; it estimates independent `animal(1 | id)` and `animal(0 + x | id)` fields with no slope correlation. The source-tested residual-scale and matched `mu+sigma` one-slope cells use `animal(1 + x | id, A = A)` as native point-fit/extractor evidence; labels such as `animal(1 + x | p | id, pedigree = ped)` are rejected until larger structured slope covariance blocks are designed. |
| `relmat(1 | id, K = K)` / `relmat(1 | id, Q = Q)` | Implemented first slice for lower-level univariate Gaussian `mu`, univariate Gaussian `sigma`, and matching `mu`/`sigma` structured intercepts with user-supplied latent relatedness covariance or precision. `relmat()` is the public low-level name; `gr()` is deprecated legacy syntax. |
| `relmat(1 | p | id, K = K)` / `relmat(1 | p | id, Q = Q)` / `relmat(0 + x | p | id, K/Q = ...)` | Implemented first bivariate q=2 Gaussian location-covariance slices when matching labelled intercept-only or slope-only terms appear in `mu1` and `mu2`; matching all-four intercept terms also fit the first constant q=4 location-scale block. Multiple slopes, slope correlations, intercept-plus-slope labelled structured covariance, `corpair()` regressions, and direct-SD grammar remain planned. |
| `relmat(1 + x | id, K = K)` / `relmat(1 + x | id, Q = Q)` | Implemented one numeric relatedness random slope for univariate Gaussian `mu`, the first sigma-only residual-scale one-slope cell for univariate Gaussian `sigma`, and the matched `mu+sigma` one-slope native point-fit/extractor cell; it estimates independent `relmat(1 | id)` and `relmat(0 + x | id)` fields with no slope correlation. Labels such as `relmat(1 + x | p | id, Q = Q)` are rejected until larger structured slope covariance blocks are designed. |
| `phylo(1 + x | species, tree = tree)` | Implemented one numeric phylogenetic random slope for univariate Gaussian `mu`, the first sigma-only residual-scale one-slope cell for univariate Gaussian `sigma`, and the matched `mu+sigma` one-slope native point-fit/extractor cell; it estimates independent `phylo(1 | species)` and `phylo(0 + x | species)` fields with no slope correlation. The shared-label all-four bivariate `phylo(1 + x | p | species, tree = tree)` block is implemented as a native point-fit/extractor q8-shaped cell only; univariate labelled one-slope, block-diagonal all-four one-slope, bridge, interval, coverage, REML, and AI-REML routes remain planned. |
| `spatial(1 | site, coords = coords)` | Implemented first structured spatial random intercept for univariate Gaussian `mu`, univariate Gaussian `sigma`, and matching `mu`/`sigma` location-scale blocks; coordinates define a fixed coordinate covariance foundation. Mesh/SPDE fitting remains planned. |
| `spatial(1 + x | site, coords = coords)` | Implemented one numeric structured spatial random slope for univariate Gaussian `mu`, the first fixed-covariance sigma-only residual-scale one-slope cell for univariate Gaussian `sigma`, and the matched fixed-covariance `mu+sigma` one-slope native point-fit/extractor cell; it estimates independent `spatial(1 | site)` and `spatial(0 + x | site)` fields with no slope correlation. The shared-label all-four bivariate `spatial(1 + x | p | site, coords = coords)` block is implemented as a native point-fit/extractor q8-shaped cell only; univariate labelled one-slope, range-estimating spatial, block-diagonal all-four one-slope, bridge, interval, coverage, REML, and AI-REML routes remain planned. Profile-interval and coverage wording for the slope-field SD remains tied to row-specific diagnostic evidence rather than this grammar row. |
| `spatial(1 | p | site, coords = coords)` / `spatial(0 + x | p | site, coords = coords)` in bivariate `mu1`/`mu2` | Implemented first bivariate q=2 Gaussian location-covariance slices when matching labelled intercept-only or slope-only terms appear in `mu1` and `mu2`. The exact matching intercept-only cell also admits native `REML = TRUE` with intercept-only `sigma1`, `sigma2`, and `rho12`, complete response pairs, unit weights, no known `meta_V()` covariance, and no additional ordinary random, direct-SD, or `corpair()` layer, at `point_fit_recovery`; slope-only REML, intervals, coverage, and range estimation remain planned. |
| `spatial(1 | p | site, coords = coords)` / all-four `spatial(1 + x | p | site, coords = coords)` in bivariate `mu1`/`mu2`/`sigma1`/`sigma2` endpoints | Implemented first fixed-covariance q=4 Gaussian location-scale slices. The intercept-only block reports four endpoint SDs and six derived latent spatial correlations; the exact shared-label one-slope block reports eight endpoint SDs and 28 derived latent spatial correlations. Mesh/SPDE, range-estimating spatial support, block-diagonal all-four one-slope blocks, bridge/inference for matched slope cells, `corpair()` regressions, and direct-SD grammar remain planned. |

## Rules

- Only one or two responses are allowed.
- Distributional parameter names must be family-supported.
- Missing dpar formulae use family-defined intercept-only defaults.
- `rho12` is allowed only for bivariate families.
- `rho` may become a convenience alias, but `rho12` is canonical.
- `meta_V(V = V)` is the preferred known-sampling-covariance marker, not a
  predictor. Deprecated `meta_known_V(V = V)` is a compatibility alias for the
  same additive known-covariance path.
- `offset()` terms are implemented only in the `mu` formula for Poisson and
  `nbinom2()` count models, including their zero-inflated paths. Use standard
  exposure syntax such as `offset(log(trap_nights))`. Offsets in `sigma`, `zi`,
  `hu`, Gaussian, bivariate, meta-analytic, phylogenetic, or spatial formulas
  must be rejected rather than accepted silently.
- Random intercepts, random slopes with one numeric predictor per random-slope
  term, and labelled or unlabelled ordinary correlated intercept-slope blocks
  are currently implemented for the univariate Gaussian `mu` formula; multiple
  separate independent slope terms are allowed.
- Structured covariance-block labels support intercept-only covariance blocks
  and the first bivariate Gaussian slope-only `mu1`/`mu2` q=2 blocks. Use
  `phylo(1 | p | species, tree = tree)`,
  `spatial(1 | p | site, coords = coords)`, `animal(1 | p | id, ...)`, or
  `relmat(1 | p | id, ...)` for fitted labelled intercept covariance blocks;
  use matching `phylo(0 + x | p | species, tree = tree)`,
  `spatial(0 + x | p | site, coords = coords)`,
  `animal(0 + x | p | id, ...)`, or `relmat(0 + x | p | id, ...)` in
  bivariate Gaussian `mu1` and `mu2` for the first labelled structured
  slope-only covariance cells; use unlabelled `phylo(1 + x | species,
  tree = tree)`, `spatial(1 + x | site, coords = coords)`,
  `animal(1 + x | id, ...)`, or `relmat(1 + x | id, ...)` for independent
  one-slope paths.
- Residual-scale random intercepts are currently implemented for the
  univariate Gaussian `sigma` formula.
- Random-effect scale formulae are currently implemented as
  `sd(group) ~ x_group` for one or more distinct unlabelled univariate Gaussian
  `mu` random intercepts.
- Animal-model, phylogenetic, spatial, and lower-level known-relatedness terms
  are structured random effects. Teach them in that reader order: `animal()`
  for pedigree or additive relatedness, `phylo()` for macroevolutionary
  dependence, `spatial()` for geographic or environmental structure, then
  combined `phylo()` plus `spatial()` layers, with `relmat()` reserved for other
  validated known-dependence matrices. Fitted univariate Gaussian structured
  intercept paths are `phylo(1 | species, tree = tree)`,
  `spatial(1 | site, coords = coords)`,
  `animal(1 | id, pedigree = ped)`, `animal(1 | id, A = A)`,
  `animal(1 | id, Ainv = Ainv)`,
  `relmat(1 | id, K = K)`, and `relmat(1 | id, Q = Q)` in univariate Gaussian
  `mu` and/or `sigma`; matching univariate `mu`/`sigma` intercept terms estimate
  one latent structured correlation. Fitted one-slope paths now include
  univariate Gaussian `mu`, the first univariate Gaussian `sigma` cells, and the
  matched unlabelled `mu+sigma` cells for the same one covariate, for example
  `spatial(1 + x | site, coords = coords)`,
  `phylo(1 + x | species, tree = tree)`,
  `animal(1 + x | id, A = A)`, and
  `relmat(1 + x | id, K = K)`, plus matching labelled q=2 terms in bivariate
  Gaussian `mu1` and `mu2`, including slope-only `0 + x` terms.
  Slice 39 of the post-0.1.3 parity lane fits one-slope `animal()`,
  `relmat()`, and `phylo()` univariate Gaussian `mu` paths using independent
  intercept and slope fields; later q-series slices added sigma-only and
  matched `mu+sigma` one-slope native point-fit/extractor cells. Later paths
  should support multiple structured slopes, intercept-plus-slope structured
  covariance, bridge/inference, and slope correlations only after separate
  recovery evidence.
  Matrix-input routes should reuse the same structured-effect layer; animal
  `pedigree`/`A`/`Ainv` and relmat `K`/`Q` intercepts have diagnostics,
  extractor labels, profile targets, and recovery tests in the first slices,
  while phylogenetic matrix inputs, multiple or labelled matrix slopes,
  `corpair()`, and direct-SD matrix routes remain unsupported until they have
  their own evidence. The exact A-matrix animal and K/Q relmat q1 `sigma`
  one-slope routes are fitted and inference-ready with caveats; pedigree/Ainv
  bridge marshalling remains a separate gate. Keep `pedigree`, `A`, `Ainv`, `K`, or
  `Q` for relatedness and precision inputs; keep `V` for known sampling covariance in
  the preferred `meta_V(V = V)` design. `gr()` is deprecated legacy syntax
  and should not be taught as a second public low-level path.
- For structured effects, native ML and native REML have different support
  surfaces. Native `REML = TRUE` is exact-Gaussian and row-specific. Current
  phylogenetic routes include q1 mean-side inference evidence, sigma-only and
  matched univariate q2 point-fit evidence, bivariate mean-side q2 point-fit
  evidence, and block-diagonal or dense q4 recovery evidence. Arc 1a separately
  admits exact pure-`mu` spatial, animal, and `relmat()` intercept or independent
  intercept-plus-one-slope domains. Arc 1b-S1 additionally admits the exact
  matching labelled fixed-covariance spatial q2 location-intercept cell in
  bivariate `mu1`/`mu2`, with intercept-only residual parameters, at
  `point_fit_recovery`. Do not infer interval, coverage, or
  `supported` promotion for the scale-side, q2, or q4 rows, and do not transfer
  HSquared AI-REML or direct DRM.jl q4 profile/bootstrap claims into R grammar.
- Spatial syntax mirrors this pattern with terms such as
  `spatial(1 | site, coords = coords)` and
  `spatial(1 + x | site, coords = coords)`. The fitted coordinate paths use
  coordinates directly; mesh objects and scalable SPDE/GMRF precision matrices
  remain planned.
- The parser should reject unsupported formulae early with clear errors.

## Not in the MVP

- Smooths.
- Nonlinear formulae.
- Autocorrelation syntax.
- Arbitrary custom likelihood syntax.
- More than two response variables.
