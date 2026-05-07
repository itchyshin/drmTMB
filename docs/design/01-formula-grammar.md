# Formula Grammar

The formula grammar is the heart of `drmTMB`. Every estimated parameter gets a
formula. The family decides which parameters exist.

The package should learn from `brms` without copying it wholesale. The prototype
uses `bf()` because it is short and familiar, but the stable API may use a
package-specific constructor such as `drm_formula()` if that is clearer for
`drmTMB` users. Avoid a public helper named `formula()` because it would be easy
to confuse with base R's formula tools.

Canonical long-form direction:

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

## Univariate Syntax

The unnamed response formula is interpreted as the location (`mu`) formula:

```r
bf(
  y ~ x1 + x2,
  sigma ~ x1
)
```

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

## Bivariate Syntax

Canonical bivariate models use separate response formulas:

```r
bf(
  mu1 = y1 ~ x1 + x2 + (1 | p | id),
  mu2 = y2 ~ x1      + (1 | p | id),
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

The `mvbind()` form is only shorthand for identical location formulas:

```r
bf(mvbind(y1, y2) ~ x)
```

expands internally to separate `mu1 = y1 ~ x` and `mu2 = y2 ~ x`.

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

Future random-effect scale components should use `sd(group) ~`:

```r
bf(
  y ~ x1 + x2 + (1 | id1) + (1 | id2),
  sd(id1) ~ x1,
  sd(id2) ~ x1 + x2
)
```

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

Future bivariate random-effect syntax should keep labelled group-level
covariance blocks distinct from residual `rho12`:

```r
bf(
  mu1 = y1 ~ x1 + x2 + (1 + x2 | p | ID),
  mu2 = y2 ~ x1      + (1 + x2 | p | ID),
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
group-level covariance blocks such as `(1 + x1 | p | id)`, not to residual
`rho12 ~`.

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
```

For bivariate models, prefer a vector/list of response families:

```r
family = c(gaussian(), gaussian())
family = c(gaussian(), poisson())
```

This makes mixed-response bivariate models natural. The current
`biv_gaussian()` prototype can remain a temporary convenience or lower-level
family object, but it should not force the public grammar into a separate
family name for every response combination.

## Distributional Parameters

Formulae may target distributional parameters such as:

- `mu`, `mu1`, `mu2`;
- `sigma`, `sigma1`, `sigma2`;
- `nu`, `tau`;
- `zi`, `zoi`, `coi`, `hu`;
- `rho12`;
- `sd(group)` for random-effect scale models.

`nu` and `tau` follow the GAMLSS convention for the first and second shape
parameters. Family documentation should explain whether `nu` means skewness,
tail weight, count dispersion, or another shape quantity.

## Random-Effect Eligibility

Not every parameter should accept random effects at the same development stage.

| Parameter class | Random effects policy |
|---|---|
| `mu`, `mu1`, `mu2` | Yes for univariate Gaussian `mu`; random intercepts, independent numeric random slopes, and labelled or unlabelled ordinary correlated intercept-slope blocks are implemented. Bivariate `mu1`/`mu2` random effects are later. |
| `sigma`, `sigma1`, `sigma2` | Later; needed for predictability/malleability models, but higher identifiability risk. |
| `sd(group)` | Later; explicit random-effect scale model, not the same as residual `sigma`. |
| `rho12` | No random effects initially; predictor-dependent fixed effects only. |
| `nu`, `tau` | Fixed effects first; random effects only after simulations show identifiability. |
| `zi`, `hu`, `zoi`, `coi` | Fixed effects first; random effects later only for high-value use cases. |
| `meta_known_V()` | Never; it is known sampling covariance, not an estimated parameter. |

## Rules

- Only one or two responses are allowed.
- Distributional parameter names must be family-supported.
- Missing dpar formulae use family-defined intercept-only defaults.
- `rho12` is allowed only for bivariate families.
- `rho` may become a convenience alias, but `rho12` is canonical.
- `meta_known_V(V = V)` is a known-covariance marker, not a predictor.
- Random intercepts, random slopes with one numeric predictor per random-slope
  term, and labelled or unlabelled ordinary correlated intercept-slope blocks
  are currently implemented only for the univariate Gaussian `mu` formula;
  multiple separate independent slope terms are allowed.
- The parser should reject unsupported formulae early with clear errors.

## Not in the MVP

- Smooths.
- Nonlinear formulae.
- Autocorrelation syntax.
- Arbitrary custom likelihood syntax.
- More than two response variables.
