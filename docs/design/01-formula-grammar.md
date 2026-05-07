# Formula Grammar

The formula grammar is the heart of `drmTMB`. Every estimated parameter gets a
formula. The family decides which parameters exist.

## Univariate Syntax

The unnamed response formula is interpreted as the location (`mu`) formula:

```r
bf(
  y ~ x,
  sigma ~ z
)
```

Equivalent explicit form:

```r
bf(
  mu = y ~ x,
  sigma = ~ z
)
```

## Meta-Analysis Syntax

Meta-analysis is Gaussian regression with known sampling covariance. It is not
a separate family.

```r
bf(
  yi ~ moderator + meta_known_V(V = vi),
  sigma ~ moderator
)
```

`meta_known_V(V = vi)` supplies known sampling variances or a known covariance
matrix. The response is already on the left-hand side, so the marker does not
repeat the response name.

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
bf(y ~ x, sigma ~ z)
```

Use `sd(group) ~` for random-effect scale components:

```r
bf(
  y ~ x + (1 | id1) + (1 | id2),
  sd(id1) ~ z1,
  sd(id2) ~ z2
)
```

Use brms-style ID labels for correlated random-effect blocks:

```r
bf(
  mu = y ~ x + (1 + x | p | id),
  sigma = ~ z + (1 | p | id)
)
```

Matching `p` labels request a shared group-level covariance block. These
correlations are constant in the first implementation. Formulae for
group-level correlations are reserved for later.

## Distributional Parameters

Formulae may target distributional parameters such as:

- `mu`, `mu1`, `mu2`;
- `sigma`, `sigma1`, `sigma2`;
- `shape`, `skew`, `nu`;
- `zi`, `zoi`, `coi`, `hu`;
- `rho12`;
- `sd(group)` for random-effect scale models.

## Rules

- Only one or two responses are allowed.
- Distributional parameter names must be family-supported.
- Missing dpar formulae use family-defined intercept-only defaults.
- `rho12` is allowed only for bivariate families.
- `rho` may become a convenience alias, but `rho12` is canonical.
- `meta_known_V(V = V)` is a known-covariance marker, not a predictor.
- The parser should reject unsupported formulae early with clear errors.

## Not in the MVP

- Smooths.
- Nonlinear formulae.
- Autocorrelation syntax.
- Arbitrary custom likelihood syntax.
- More than two response variables.
