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
    mu1 = y1 ~ x1 + x2 + (1 | p | id),
    mu2 = y2 ~ x1      + (1 | p | id),
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

Use `sd(group) ~` for random-effect scale components:

```r
bf(
  y ~ x1 + x2 + (1 | id1) + (1 | id2),
  sd(id1) ~ x1,
  sd(id2) ~ x1 + x2
)
```

Use brms-style ID labels for correlated random-effect blocks:

```r
bf(
  mu = y ~ x1 + (1 + x1 | p | id),
  sigma = ~ x1 + (1 | p | id)
)
```

Matching `p` labels request a shared group-level covariance block. These
correlations are constant in the first implementation. Formulae for
group-level correlations are reserved for later.

## Correlation Namespace

Use `rho12` only for residual or response-level correlation between response 1
and response 2 in a bivariate likelihood:

```r
bf(
  mu1 = y1 ~ x1 + x2,
  mu2 = y2 ~ x1,
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

Do not use `rho12` for group-level random-effect correlations. O'Dea-style
double-hierarchical models contain several interpretable correlations among
random intercepts, random slopes, random scale intercepts, and random scale
slopes. Those correlations belong to labelled group-level covariance blocks
such as `(1 + x1 | p | id)`, not to residual `rho12 ~`.

Random intercept/slope correlations are likely to be estimated as constant
covariance-block parameters. The main predictor-dependent `rho` formulas in
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
- `shape`, `skew`, `nu`;
- `zi`, `zoi`, `coi`, `hu`;
- `rho12`;
- `sd(group)` for random-effect scale models.

## Random-Effect Eligibility

Not every parameter should accept random effects at the same development stage.

| Parameter class | Random effects policy |
|---|---|
| `mu`, `mu1`, `mu2` | Yes; random intercepts implemented first, then slopes and covariance blocks. |
| `sigma`, `sigma1`, `sigma2` | Later; needed for O'Dea-style predictability/malleability, but higher identifiability risk. |
| `sd(group)` | Later; explicit random-effect scale model, not the same as residual `sigma`. |
| `rho12` | No random effects initially; predictor-dependent fixed effects only. |
| `shape`, `skew`, `kurtosis`, `nu` | Fixed effects first; random effects only after simulations show identifiability. |
| `zi`, `hu`, `zoi`, `coi` | Fixed effects first; random effects later only for high-value use cases. |
| `meta_known_V()` | Never; it is known sampling covariance, not an estimated parameter. |

## Rules

- Only one or two responses are allowed.
- Distributional parameter names must be family-supported.
- Missing dpar formulae use family-defined intercept-only defaults.
- `rho12` is allowed only for bivariate families.
- `rho` may become a convenience alias, but `rho12` is canonical.
- `meta_known_V(V = V)` is a known-covariance marker, not a predictor.
- Random intercepts are currently implemented only for the univariate Gaussian
  `mu` formula.
- The parser should reject unsupported formulae early with clear errors.

## Not in the MVP

- Smooths.
- Nonlinear formulae.
- Autocorrelation syntax.
- Arbitrary custom likelihood syntax.
- More than two response variables.
