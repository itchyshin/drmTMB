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
| `(1 | id)` in `sigma` | Implemented | Residual-scale random intercept. |
| `sd(id) ~ x_group` | Implemented | Random-effect scale model for one or more distinct unlabelled Gaussian `mu` random intercepts. |
| `meta_known_V(V = V)` | Implemented | Known diagonal, block-diagonal, or dense sampling covariance with `family = gaussian()`; bivariate Gaussian known `V` uses a complete-row `2n` by `2n` row-paired matrix. |
| `mu1`, `mu2`, `sigma1`, `sigma2`, `rho12` | Implemented for fixed effects | Bivariate Gaussian location-coscale model with predictor-dependent residual correlation. |
| `(1 | p | id)` in both bivariate `mu1` and `mu2` | Implemented | First bivariate group-level covariance slice: matching labelled random intercepts create `mu1`/`mu2` random-intercept SDs and one group-level correlation. |
| `family = c(gaussian(), gaussian())` | Implemented | Public bivariate Gaussian family direction; mixed composed families are planned. |
| `mvbind(y1, y2) ~ x1` | Implemented | Shorthand for identical bivariate location formulas; explicit `mu1`/`mu2` remains preferred for different predictors. |
| `phylo(1 | species, tree = tree)` in `mu` | Implemented | Intercept-only univariate Gaussian phylogenetic location effect; requires an ultrametric tree with branch lengths. |
| `weights = w` | Implemented | Top-level likelihood weights, not formula syntax. Known sampling covariance remains `meta_known_V(V = V)`. |
| `y ~ x1`, `family = cumulative_logit()` | Implemented | Fixed-effect univariate ordinal model for ordered scores with cutpoints; `mu` is a latent location and ordinal scale formulas are planned. |
| `cbind(successes, failures) ~ x1`, `family = beta_binomial()` | Implemented | Fixed-effect denominator-aware model for success counts with known trial totals; `sigma` is extra-binomial variation. |
| `phylo(1 + x1 | species, tree = tree)` | Planned | Structured slopes come after the intercept-only path is hardened. |
| `spatial(1 | site, coords = coords)` and `spatial(1 | site, mesh = mesh)` | Planned | Spatial SPDE/GMRF terms are part of the design but not fitted yet. |
| Bivariate random slopes, `sigma1`/`sigma2` random effects, or `rho12` random effects | Planned | Requires a larger covariance parameterization, simulation recovery, and naming checks. |

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

The first bivariate group-level covariance slice uses separate response
formulas and matching labelled random intercepts:

```r
bf(
  mu1 = y1 ~ x1 + x2 + (1 | p | id),
  mu2 = y2 ~ x1      + (1 | p | id),
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

The shared `p` label requests one group-level covariance block for the
`mu1` and `mu2` random intercepts. This is not residual `rho12`; it describes
between-group association in the two response means after the fixed effects are
included. Bivariate random slopes and residual-scale random effects remain
planned.

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

For this first labelled implementation, `p` is metadata for naming and future
covariance-block matching. It is not looked up in `data`, and it does not yet
share covariance across `mu`, `sigma`, `mu1`, or `mu2` formulas.

The group-level intercept-slope correlation is extracted as `corpars$mu`, not
as residual `rho12`.

Covariance-block labels must not use reserved distributional parameter names
such as `mu`, `sigma`, `rho`, or `rho12`.

Residual-scale random intercepts are implemented in the univariate Gaussian
`sigma` formula:

```r
bf(y ~ x1 + (1 | id), sigma ~ x1 + (1 | id))
```

This models group-to-group variation in residual `sigma_i`. It is not a
random-effect scale formula such as `sd(id) ~ x1`.

The distinction is:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma
```

matches `sigma ~ x1` and models residual or within-observation SD.

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + a_{id[i]}
a_id ~ Normal(0, sd_sigma_id^2)
```

matches `sigma ~ x1 + (1 | id)` and models group-to-group deviations in
residual SD.

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

Random-effect scale components use `sd(group) ~`. The implemented Gaussian
path supports one or more distinct unlabelled `mu` random-intercept targets:

```r
bf(
  y ~ x1 + x2 + (1 | id1) + (1 | id2),
  sigma ~ x1,
  sd(id1) ~ x1,
  sd(id2) ~ x1 + x2
)
```

## Structured Phylogenetic and Spatial Markers

`drm_formula()` parses structured-effect markers and stores them as structured
metadata. The first fitted path is intercept-only phylogenetic structure in the
univariate Gaussian `mu` formula. Spatial terms, phylogenetic slopes,
phylogenetic `sigma` terms, and bivariate structured effects remain planned.

The canonical phylogenetic syntax is:

```r
bf(y ~ x1 + phylo(1 | species, tree = tree), sigma ~ x2)
```

Here `tree` is the name of an ultrametric phylogeny object with branch lengths.
The fitted implementation builds the sparse augmented A-inverse internally
using the Hadfield and Nakagawa route. Dense covariance matrices are lower-level
comparator or `gr()` inputs, not the main public phylogeny API.

Reserved planned spatial syntax is:

```r
bf(y ~ x1 + spatial(1 | site, coords = coords), sigma ~ x2)
bf(y ~ x1 + spatial(1 | site, mesh = mesh), sigma ~ x2)
```

These calls are part of the formula grammar design but are not fitted yet.
Here `coords` or `mesh` names the object that will be used to build an
SPDE/GMRF precision. Exactly one of `coords` or `mesh` should be supplied.

The parser currently reserves intercept-only and one-slope forms, but only the
intercept-only phylogenetic `mu` form is fitted:

```r
phylo(1 | species, tree = tree)
phylo(1 + x1 | species, tree = tree)
spatial(1 | site, coords = coords)
spatial(1 + depth | site, coords = coords)
```

Multiple structured slopes, interaction slopes, structured `sigma` effects,
structured `rho12` effects, and bivariate structured effects remain planned
until intercept-only univariate Gaussian `mu` models have simulation and
comparator coverage.

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
| `sigma`, `sigma1`, `sigma2` | Yes for univariate Gaussian `sigma` random intercepts only, written as `sigma ~ x + (1 | id)`. Residual-scale random slopes, labelled `sigma` blocks, bivariate `sigma1`/`sigma2` random effects, and non-Gaussian scale random effects are later. |
| `sd(group)` | Implemented for one or more distinct unlabelled univariate Gaussian `mu` random intercepts, such as `sd(id) ~ x_group` and `sd(site) ~ site_type`; predictors must be constant within group after missing-row filtering. Labelled blocks, slopes, `sigma` random-effect scales, bivariate models, and non-Gaussian models are later. |
| `rho12` | No random effects initially; predictor-dependent fixed effects only. |
| `nu`; future `tau` | Fixed effects first; random effects only after simulations show identifiability. `tau` is reserved for a possible second shape parameter and is not current syntax. |
| `zi`, `hu`, `zoi`, `coi` | Fixed effects first; random effects later only for high-value use cases. |
| `meta_known_V()` | Never; it is known sampling covariance, not an estimated parameter. |
| `phylo(1 | species, tree = tree)` | Implemented structured random intercept for univariate Gaussian `mu`; `tree` must be an ultrametric phylogeny with branch lengths. |
| `phylo(1 + x | species, tree = tree)` | Planned structured random slope syntax after intercept-only phylogeny is tested. |
| `spatial(1 | site, coords = coords)` | Planned structured spatial random intercept for univariate Gaussian `mu`; coordinates or a mesh must define the SPDE/GMRF structure. |
| `spatial(1 + x | site, coords = coords)` | Planned structured spatial random slope syntax after intercept-only spatial fields are tested. |

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
  fitted path is `phylo(1 | species, tree = tree)` in univariate Gaussian
  `mu`; later paths should support `phylo(1 + x | species, tree = tree)` and
  spatial analogues. Public `phylo()` should require an ultrametric tree with
  branch lengths; dense covariance matrices belong to lower-level comparators
  or `gr()`-style structured covariance inputs, not the main phylogeny API.
- Spatial syntax should mirror this pattern with terms such as
  `spatial(1 | site, coords = coords)` and later
  `spatial(1 + x | site, coords = coords)`, using coordinates or mesh objects
  to build SPDE/GMRF precision matrices.
- The parser should reject unsupported formulae early with clear errors.

## Not in the MVP

- Smooths.
- Nonlinear formulae.
- Autocorrelation syntax.
- Arbitrary custom likelihood syntax.
- More than two response variables.
