# GAMLSS Parameter Names

Rigby and Stasinopoulos (2005) is the foundational naming and conceptual source
for `drmTMB` distributional parameters.

The default vocabulary is:

```text
mu     location or mean-like parameter
sigma  scale, residual SD, or dispersion-like parameter
nu     first shape parameter
tau    second shape parameter
```

This gives users a small set of names to remember across families. It also
keeps the package close to the location-scale-shape literature.

## Important Nuance

`nu` and `tau` are shape-parameter positions, not universal biological
meanings. Their interpretation depends on the family:

- Student-t: `nu` is usually tail weight or degrees of freedom.
- Skew normal: `nu` can be the skewness/shape parameter.
- Skew-t: `nu` and `tau` should be documented as asymmetry and tail shape in
  the family-specific order chosen by the likelihood.
- COM-Poisson: `nu` is a count-dispersion/shape parameter.

This means `nu ~ x1` is read as "predictor effects on the first shape
parameter", and the family documentation explains what that shape means.

## Alias Policy

Avoid making `skew`, `df`, `shape`, and `disp` first-class canonical dpar names
too early. They can be tempting, but they fragment the grammar. If needed, add
aliases later that resolve to canonical names and print a clear message.

Preferred:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x1, nu ~ x2),
  family = skew_normal(),
  data = dat
)
```

Only consider:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x1, skew ~ x2),
  family = skew_normal(),
  data = dat
)
```

as a documented alias after the core syntax is stable.

## Testing Implication

Every family test should verify that:

1. the family declares canonical dpar names;
2. aliases, if any, map to canonical names before model-matrix construction;
3. summary, coefficient, prediction, and simulation methods use the same
   canonical names;
4. vignettes use the canonical names unless explicitly teaching an alias.
