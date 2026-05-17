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

| Syntax | Current status | Notes |
| --- | --- | --- |
| `drm_formula()` and `bf()` | Implemented | `drm_formula()` is the explicit constructor; `bf()` is a short alias. |
| `y ~ x1`, `sigma ~ x1` | Implemented | Univariate Gaussian location-scale model. |
| `y ~ x1`, `sigma ~ x1`, `nu ~ x2` | Implemented | Fixed-effect univariate Student-t location-scale-shape model. Random effects, known sampling covariance, phylogenetic terms, and bivariate Student-t models are later. |
| `y ~ x1`, `sigma ~ x1`, `family = lognormal()` | Implemented | Fixed-effect univariate lognormal model for positive responses; `mu` and `sigma` are on the log-response scale. |
| `y ~ x1`, `sigma ~ x1`, `family = Gamma(link = "log")` | Implemented | Fixed-effect univariate Gamma mean-CV model for positive responses; `mu` is the response mean and `sigma` is the coefficient of variation. |
| `y ~ x1`, `sigma ~ x2`, `family = beta()` | Implemented | Fixed-effect beta mean-scale model for strict continuous proportions in `(0, 1)`; public `sigma` maps internally to `phi = 1 / sigma^2`. |
| `y ~ x1`, `family = poisson(link = "log")` | Implemented | Fixed-effect univariate Poisson mean model for non-negative integer counts. |
| `y ~ x1 + offset(log(exposure))`, `family = poisson(link = "log")` | Implemented | Exposure/rate Poisson model using standard R `offset()` syntax in the `mu` formula. |
| `y ~ x1`, `zi ~ x2`, `family = poisson(link = "log")` | Implemented | Fixed-effect zero-inflated Poisson model; `mu` is the conditional count mean, `zi` is the structural-zero probability, and `fitted()` returns `(1 - zi) * mu`. |
| `y ~ x1`, `sigma ~ x1`, `family = nbinom2()` | Implemented | Fixed-effect univariate negative-binomial 2 model for overdispersed counts; `sigma` is an overdispersion scale in `Var(y) = mu + sigma^2 * mu^2`. |
| `y ~ x1 + offset(log(exposure))`, `sigma ~ x2`, `family = nbinom2()` | Implemented | Exposure/rate NB2 model; the offset enters the `mu` linear predictor and `sigma` remains overdispersion. |
| `y ~ x1`, `sigma ~ x1`, `zi ~ x2`, `family = nbinom2()` | Implemented | Fixed-effect zero-inflated NB2 model; `mu` and `sigma` describe the conditional NB2 count component and `zi` is the structural-zero probability. |
| `y ~ x1`, `sigma ~ x2`, `family = truncated_nbinom2()` | Implemented | Fixed-effect zero-truncated NB2 model for positive counts; `mu` and `sigma` describe the untruncated NB2 component and `fitted()` returns the positive-count mean. |
| `y ~ x1`, `sigma ~ x2`, `hu ~ x3`, `family = truncated_nbinom2()` | Implemented | Fixed-effect hurdle NB2 model; `hu` is the hurdle-zero probability and nonzero counts come from the zero-truncated NB2 component. |
| `(1 | id)`, `(0 + x1 | id)`, `(1 + x1 | id)` in `mu` | Implemented | Ordinary Gaussian location random effects; one-slope correlated blocks may be labelled as `(1 + x1 | p | id)`. |
| `(1 | id)` and `(0 + x1 | id)` in `sigma` | Implemented | Residual-scale random intercepts and independent numeric random slopes. Multiple independent terms may be combined, but residual-scale slope correlations are fixed at zero in this phase. |
| `(1 | p | id)` in both `mu` and `sigma` | Implemented | Matching labelled random intercepts create mean-scale group-level correlations. More than one independent matched block can be fitted, such as `(1 | p | id)` and `(1 | q | site)` in both formulas. |
| `sd(id) ~ x_group` | Implemented | Random-effect scale model for one or more distinct unlabelled Gaussian `mu` random intercepts. |
| `sd(id, dpar = "mu", coef = "x1") ~ x_group` | Reserved | Planned explicit coefficient-specific random-effect SD syntax for random slopes; `drmTMB()` rejects it until the covariance model and tests exist. |
| `meta_known_V(V = V)` | Implemented | Known diagonal, block-diagonal, or dense sampling covariance with `family = gaussian()`; bivariate Gaussian known `V` uses a complete-row `2n` by `2n` row-paired matrix. |
| `meta_V(value, V = V)` | Planned | Possible future umbrella spelling for additive known sampling covariance. If implemented, `meta_known_V()` should become a deprecated alias for the known-`V` form, not a separate likelihood. |
| `meta_V(value, w = w, scale = "proportional")` | Planned | Possible future proportional sampling-variance spelling for models such as `pi_i ~ Normal(0, phi_pi / w_i)`. This is not implemented and is not a CRAN-blocking requirement. |
| `mu1`, `mu2`, `sigma1`, `sigma2`, `rho12` | Implemented for fixed effects | Bivariate Gaussian location-coscale model with predictor-dependent residual correlation. |
| `(1 | p | id)` in both bivariate `mu1` and `mu2` | Implemented | First bivariate group-level covariance slice: matching labelled random intercepts create `mu1`/`mu2` random-intercept SDs and one group-level correlation. |
| `(1 | p | id)` in both bivariate `sigma1` and `sigma2` | Implemented | First bivariate residual-scale covariance slice: matching labelled random intercepts enter `log(sigma1)` and `log(sigma2)` and create one scale-scale group-level correlation. |
| `(1 | p | id)` in same-response bivariate `mu1` and `sigma1`, or in `mu2` and `sigma2` | Implemented first slice | One matching labelled random-intercept pair creates a mean-scale group-level correlation for that response. |
| `(1 | p | id)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first slice | One ordinary q=4 random-intercept covariance block reports all six latent location-location, location-scale, and scale-scale correlations. |
| `sd1(id) ~ x_group` or `sd2(id) ~ x_group` with the same all-four q=4 block | Rejected | This would mix the Family A joint location-scale covariance block with Family B direct location-SD regression for the same group. |
| `family = c(gaussian(), gaussian())` | Implemented | Public bivariate Gaussian family direction; mixed composed families are planned. |
| `mvbind(y1, y2) ~ x1` | Implemented | Shorthand for identical bivariate location formulas; explicit `mu1`/`mu2` remains preferred for different predictors. |
| `phylo(1 | species, tree = tree)` in `mu` | Implemented | Intercept-only univariate Gaussian phylogenetic location effect; requires an ultrametric tree with branch lengths. |
| matching `phylo(1 | species, tree = tree)` in bivariate `mu1` and `mu2` | Implemented first slice | Correlated phylogenetic random intercepts enter the two response means; `sigma1`, `sigma2`, and residual `rho12` remain ordinary fixed-effect distributional parameters. |
| labelled `phylo(1 | p | species, tree = tree)` in matching bivariate `mu1` and `mu2` | Implemented | The label is preserved in SD, correlation, `corpairs()`, and profile-target names for the phylogenetic mean-mean path. |
| labelled `phylo(1 | p | species, tree = tree)` in all four bivariate `mu1`, `mu2`, `sigma1`, and `sigma2` formulas | Implemented first slice | One constant q=4 phylogenetic location-scale block estimates four endpoint SDs and six latent phylogenetic correlations. Partial, unlabelled, mismatched, and slope forms remain rejected. |
| `sd_phylo(species) ~ x_species` | Implemented | Family B direct-SD model for a univariate Gaussian phylogenetic location random effect; predictors must be constant within species and scale observed tips through the `D_tip A_tip D_tip` contract. |
| bivariate `sd_phylo1(species) ~ x_species` / `sd_phylo2(species) ~ x_species` | Implemented | Response-specific bivariate phylogenetic location direct-SD models. They target only `mu1` and `mu2` phylogenetic location SDs, keep the latent phylogenetic location-location correlation separate, and are rejected with q=4 phylogenetic location-scale blocks. |
| `weights = w` | Implemented | Top-level likelihood weights, not formula syntax. Known sampling covariance remains `meta_known_V(V = V)`. |
| `y ~ x1`, `family = cumulative_logit()` | Implemented | Fixed-effect univariate ordinal model for ordered scores with cutpoints; `mu` is a latent location and ordinal scale formulas are planned. |
| `cbind(successes, failures) ~ x1`, `family = beta_binomial()` | Implemented | Fixed-effect denominator-aware model for success counts with known trial totals; `sigma` is extra-binomial variation. |
| `phylo(1 + x1 | species, tree = tree)` | Planned | Structured slopes come after the intercept-only path is hardened. The first path should fit one structured `mu` slope; two slopes are the near-term upper bound. |
| `spatial(1 | site, coords = coords)` | Implemented first slice | Univariate Gaussian `mu` spatial random intercept using a fixed coordinate covariance foundation. |
| `spatial(1 | site, mesh = mesh)` | Planned | Mesh/SPDE spatial fitting remains planned after the coordinate foundation. |
| `corpair(id, level = "group", block = "p", from = "mu1", to = "mu2") ~ x_group` | Implemented | Predictor-dependent ordinary q=2 location-location latent random-effect correlation regression for matching labelled `mu1`/`mu2` random intercepts. Predictors must be constant within `id`. |
| `corpair(species, level = "phylogenetic", block = "p", from = "mu1", to = "mu2") ~ ecology` | Implemented | Predictor-dependent phylogenetic q=2 location-location latent random-effect correlation regression for matching labelled `mu1`/`mu2` `phylo()` terms. Predictors must be constant within `species`. Location-scale, scale-scale, q=4, and spatial `corpair()` regressions remain planned. |
| Matching slope-only `(0 + x | p | id)` in bivariate `mu1` and `mu2` | Planned first bivariate slope target | This is the intended first bivariate random-slope path because it can target the slope1-slope2 plasticity-syndrome correlation without also estimating intercept-slope correlations. It remains rejected until fitting, recovery tests, diagnostics, `corpairs()`, and profile-target names exist. |
| Intercept-plus-slope bivariate blocks such as `(1 + x | p | id)` in both `mu1` and `mu2` | Planned later | These would require a q=4 location block with intercept-intercept, intercept-slope, and slope-slope correlations. They are not opened by the first bivariate one-slope policy. |
| All-four bivariate location-scale slope blocks across `mu1`, `mu2`, `sigma1`, and `sigma2`; spatial q4 covariance blocks; predictor-dependent phylogenetic/spatial q4 correlations; or `rho12` random effects | Planned | Requires larger structured covariance parameterizations, simulation recovery, and naming checks. Do not use all-four slope terms to request a q=8 endpoint covariance block in this phase. Do not treat intercept-slope `corpair()` rows as a near-term target; a later slope1-slope2 bivariate plasticity-syndrome target needs coefficient-aware syntax. |

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
  yi ~ x1 + x2 + meta_known_V(V = V),
  sigma ~ x1
)
```

`meta_known_V(V = V)` supplies known sampling variances, a diagonal covariance
structure, a block-diagonal covariance matrix, or a full known sampling
covariance matrix. The response is already on the left-hand side, so the marker
does not repeat the response name. Meta-analysis is still regression; Gaussian
meta-analysis should normally use `family = gaussian()`, not a special
meta-analysis family.

For bivariate Gaussian meta-analysis, `meta_known_V(V = V)` marks one
location formula and `V` is a dense `2n` by `2n` row-paired matrix. The fitted
`rho12` is then the residual covariance component after known within-study
sampling covariance has been included. It should not be called a study-level
correlation unless a separate study-level random effect is fitted.

Future design should leave room for a single `meta_V()` keyword that can cover
both the current additive known-`V` route and a proportional sampling-variance
route. The current release should not implement this. The possible spelling is:

```r
meta_V(value, V = V)
meta_V(value, w = w, scale = "proportional")
```

In the additive route, the supplied `V` is known sampling covariance and enters
the marginal covariance as `V + Omega_estimated`, matching the current
`meta_known_V(V = V)` contract. In the proportional route, the sampling-error
term would be modelled as `pi_i ~ Normal(0, phi_pi / w_i)` or, for correlated
sampling errors, through a weighted covariance matrix. This proportional route
is not ordinary likelihood weighting: the top-level `weights = w` argument still
multiplies log-likelihood contributions. Additive known `V` and non-unit
top-level weights should continue to be rejected together until joint-block
weighting has its own design and tests.

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
between-group associations after the fixed effects are included. One
same-response `mu`/`sigma` random-intercept pair is also implemented. Reusing
the same label and group in all four `mu1`, `mu2`, `sigma1`, and `sigma2`
formulas requests one ordinary q=4 random-intercept block with all six latent
correlations. Bivariate random slopes and `rho12` random effects remain
planned.

The first bivariate random-slope target is intentionally narrower than the
full endpoint. A matching slope-only location block such as
`(0 + x | p | id)` in both `mu1` and `mu2` is the first planned slope path.
It would estimate the group-level association between individual differences
in the two response-specific slopes. Intercept-plus-slope location blocks
such as `(1 + x | p | id)` in both responses are a later q=4 location block,
and all-four location-scale slope terms across `mu1`, `mu2`, `sigma1`, and
`sigma2` are a q=8 endpoint. Both remain rejected until the covariance naming,
diagnostics, recovery tests, and interval targets are in place.

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

The same pairwise bridge is implemented for one response in a bivariate
Gaussian model:

```r
bf(
  mu1 = y1 ~ x1 + (1 | p | id),
  mu2 = y2 ~ x1,
  sigma1 = ~ x1 + (1 | p | id),
  sigma2 = ~ x1,
  rho12 = ~ x1
)
```

Here the shared `p` label fits a group-level mean-scale correlation for response
1, reported as `corpars$mu_sigma` and a `corpairs()` `mean-scale` row with
`from_dpar = "mu1"` and `to_dpar = "sigma1"`. A matching `mu2`/`sigma2` pair is
also supported. The larger all-four labelled block is also supported for
intercept-only terms when the same label appears in `mu1`, `mu2`, `sigma1`, and
`sigma2`; it reports one location-location row, four location-scale rows, and
one scale-scale row.

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

Future generic aliases can use `level` in the same spirit as `corpair()`, for
example `sd(species, level = "phylogenetic") ~ z`. The implemented
`sd_phylo()` names remain the stable public path for now because they make the
tree-scaled `D_tip A_tip D_tip` contract explicit and avoid confusing
phylogenetic species effects with ordinary independent species effects.

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
metadata. The first fitted paths are intercept-only phylogenetic structure in
the univariate Gaussian `mu` formula, matching bivariate `mu1`/`mu2`
formulas, matching labelled bivariate q=4
`mu1`/`mu2`/`sigma1`/`sigma2` phylogenetic blocks, and coordinate-based
univariate Gaussian spatial `mu` random intercept and one-slope terms.
Mesh/SPDE spatial fields, phylogenetic slopes, multiple spatial slopes,
univariate phylogenetic `sigma` terms, spatial bivariate blocks, and structured
`rho12` effects remain planned.

The canonical phylogenetic syntax is:

```r
bf(y ~ x1 + phylo(1 | species, tree = tree), sigma ~ x2)
```

Here `tree` is the name of an ultrametric phylogeny object with branch lengths.
The fitted implementation builds the sparse augmented A-inverse internally
using the Hadfield and Nakagawa route. Dense covariance matrices are lower-level
comparator or `gr()` inputs, not the main public phylogeny API.

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

The parser currently reserves intercept-only and one-slope forms. Fitted forms
are intercept-only phylogenetic `mu`, coordinate-spatial intercept `mu`, and one
coordinate-spatial `mu` slope:

```r
phylo(1 | species, tree = tree)
phylo(1 + x1 | species, tree = tree)
spatial(1 | site, coords = coords)
spatial(1 + depth | site, coords = coords)
```

Multiple structured slopes, interaction slopes, structured `sigma` effects,
structured `rho12` effects, bivariate structured effects beyond matching
`mu1`/`mu2`, and richer structured q=4 blocks remain planned until the fitted
paths have simulation and comparator coverage. The near-term ceiling remains two
`mu` slopes. Intercept-slope `corpair()` rows stay distant-future; a later
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
group-level covariance blocks such as `(1 | p | id)` now and
`(1 + x1 | p | id)` once bivariate random slopes are implemented, not to
residual `rho12 ~`.

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
| `mu`, `mu1`, `mu2` | Yes for univariate Gaussian `mu`; random intercepts, independent numeric random slopes, and labelled or unlabelled ordinary correlated intercept-slope blocks are implemented. For bivariate Gaussian models, matching labelled random intercepts in `mu1` and `mu2`, such as `(1 | p | id)` in both formulas, are implemented. Bivariate random slopes are later. |
| `sigma`, `sigma1`, `sigma2` | Yes for univariate Gaussian `sigma` random intercepts and independent numeric random slopes. Unlabelled terms such as `sigma ~ x + (1 | id)` and `sigma ~ x + (0 + w | id)` are independent scale effects, and multiple independent terms can be combined with zero correlations among their latent effects. Matching labelled `mu` and `sigma` intercepts such as `(1 | p | id)` fit mean-scale covariance blocks, with one row per independent matched label/group pair. For bivariate Gaussian models, matching labelled random intercepts in `sigma1` and `sigma2` are implemented as a scale-scale block. Correlated residual-scale slope blocks, labelled `mu`/`sigma` slope covariance, bivariate scale slopes, and non-Gaussian scale random effects are later. |
| `sd(group)` | Implemented for one or more distinct unlabelled univariate Gaussian `mu` random intercepts, such as `sd(id) ~ x_group` and `sd(site) ~ site_type`; predictors must be constant within group after missing-row filtering. Labelled scale targets, slopes, `sigma` random-effect scales, bivariate models, and non-Gaussian models are later. |
| `rho12` | No random effects initially; predictor-dependent fixed effects only. |
| `nu`; future `tau` | Fixed effects first; random effects only after simulations show identifiability. `tau` is reserved for a possible second shape parameter and is not current syntax. |
| `zi`, `hu`, `zoi`, `coi` | Fixed effects first; random effects later only for high-value use cases. |
| `meta_known_V()` | Never; it is known sampling covariance, not an estimated parameter. |
| `phylo(1 | species, tree = tree)` | Implemented structured random intercept for univariate Gaussian `mu`; `tree` must be an ultrametric phylogeny with branch lengths. |
| `phylo(1 | p | species, tree = tree)` | Implemented as a label for matching bivariate `mu1`/`mu2` phylogenetic location terms and for the matching all-four q=4 bivariate phylogenetic location-scale block. Partial, unlabelled, mismatched, and slope forms remain rejected. |
| `phylo(1 + x | species, tree = tree)` | Planned structured random slope syntax after intercept-only phylogeny is tested; one slope first, two slopes as the near-term advanced path. |
| `spatial(1 | site, coords = coords)` | Implemented first structured spatial random intercept for univariate Gaussian `mu`; coordinates define a fixed coordinate covariance foundation. Mesh/SPDE fitting remains planned. |
| `spatial(1 + x | site, coords = coords)` | Implemented one numeric structured spatial random slope for univariate Gaussian `mu`; it estimates independent `spatial(1 | site)` and `spatial(0 + x | site)` fields with no slope correlation. Multiple spatial slopes remain planned. |

## Rules

- Only one or two responses are allowed.
- Distributional parameter names must be family-supported.
- Missing dpar formulae use family-defined intercept-only defaults.
- `rho12` is allowed only for bivariate families.
- `rho` may become a convenience alias, but `rho12` is canonical.
- `meta_known_V(V = V)` is a known-covariance marker, not a predictor.
- `offset()` terms are implemented only in the `mu` formula for Poisson and
  `nbinom2()` count models, including their zero-inflated paths. Use standard
  exposure syntax such as `offset(log(trap_nights))`. Offsets in `sigma`, `zi`,
  `hu`, Gaussian, bivariate, meta-analytic, phylogenetic, or spatial formulas
  must be rejected rather than accepted silently.
- Random intercepts, random slopes with one numeric predictor per random-slope
  term, and labelled or unlabelled ordinary correlated intercept-slope blocks
  are currently implemented for the univariate Gaussian `mu` formula; multiple
  separate independent slope terms are allowed.
- Residual-scale random intercepts are currently implemented for the
  univariate Gaussian `sigma` formula.
- Random-effect scale formulae are currently implemented as
  `sd(group) ~ x_group` for one or more distinct unlabelled univariate Gaussian
  `mu` random intercepts.
- Phylogenetic and spatial terms are structured random effects. The first
  fitted phylogenetic path is `phylo(1 | species, tree = tree)` in univariate
  Gaussian `mu`; fitted coordinate spatial paths are
  `spatial(1 | site, coords = coords)` and one numeric
  `spatial(1 + x | site, coords = coords)` slope in univariate Gaussian `mu`.
  Later paths should support `phylo(1 + x | species, tree = tree)`, multiple
  spatial slopes, and slope correlations only after separate recovery evidence.
  Public `phylo()` should require an ultrametric tree with branch lengths; dense
  covariance matrices belong to lower-level comparators or `gr()`-style
  structured covariance inputs, not the main phylogeny API.
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
