# Profile-Likelihood Confidence Intervals

Profile-likelihood confidence intervals should become part of `drmTMB` once
random-effect variance components, phylogenetic effects, spatial effects, and
double-hierarchical models are stable enough to need serious inference on
variance and correlation quantities.

## Core Definition

For a single parameter `theta`, the likelihood-ratio statistic is:

```text
D(theta_0) = 2 * (logLik_hat - logLik_profile(theta_0))
```

where `logLik_hat` is the joint maximum log likelihood and
`logLik_profile(theta_0)` is the maximum log likelihood after fixing `theta` at
`theta_0` and re-optimizing all other free parameters.

A 95% profile-likelihood confidence interval is the set of values where:

```text
logLik_hat - logLik_profile(theta) <= qchisq(0.95, df = 1) / 2
```

The right-hand side is approximately `1.92`.

This is a profile, not a slice: all nuisance parameters are re-optimized at each
candidate value.

## Preferred Implementation

The first implementation should use:

- `TMB::tmbprofile()` for direct TMB parameters;
- `uniroot()` to find the two threshold crossings;
- warm starts from the joint MLE wherever possible;
- response-scale transformations after profiling on the stable internal scale.

This is preferable to a dense grid because most grid points do not matter. A
grid can still be useful for diagnostics and teaching plots.

## Quantity Classes

### Direct TMB Parameters

Examples:

- log random-effect SDs;
- log residual SD or dispersion parameters;
- ordinal cutpoints;
- transformed correlation parameters when they are direct entries in the TMB
  parameter vector.

These are the first target because `TMB::tmbprofile()` can profile them
directly by name.

### Linear Combinations

Examples:

- total variance as the sum of two variance components;
- simple contrasts of direct parameters on an internal scale.

Use TMB's `lincomb` machinery where the target is truly linear in the internal
parameterization.

### Nonlinear Derived Quantities

Examples:

- ICCs;
- repeatability;
- heritability-like ratios;
- cross-trait correlations derived from covariance matrices;
- correlations among personality, plasticity, predictability, and malleability
  components in double-hierarchical individual-differences models.

These are not direct `tmbprofile()` targets. The first robust path should be a
fix-and-refit profile:

1. choose a candidate derived value;
2. impose the corresponding constraint through a mapped or rebuilt TMB object;
3. re-optimize all other parameters;
4. use `uniroot()` to find where the profile log likelihood drops by `1.92`.

An alternative is to create a new TMB parameterization where the derived
quantity is a direct parameter, such as `(logit_ICC, log_total_variance)`, but
that is more invasive and should be reserved for high-value quantities.

## Correlation Intervals

For a covariance matrix `Sigma`, a correlation is:

```text
rho_ij = Sigma[i, j] / sqrt(Sigma[i, i] * Sigma[j, j])
```

For a candidate `rho_0`, the constrained profile should enforce:

```text
Sigma[i, j] = rho_0 * sqrt(Sigma[i, i] * Sigma[j, j])
```

and then re-optimize all other parameters. This applies to group-level
correlations, not residual `rho12 ~ predictors`, unless the residual correlation
parameter is being profiled directly.

## Pitfalls And Fallbacks

- Boundary variance components can produce one-sided intervals. Return the
  boundary, such as zero, and flag the interval.
- Non-monotone or multi-modal profiles can invalidate simple `uniroot()` logic.
  Detect these cases and fall back to a plotted profile or parametric bootstrap.
- Constrained inner optimizations can fail near boundaries. Retry with perturbed
  starts before falling back.
- Wald intervals for variance components and correlations should not be the main
  default because they are often poor near boundaries.

## Implementation Stage

Do not make profile CIs part of the Gaussian MVP. Add them after:

1. random-effect variance components are represented cleanly in fitted objects;
2. profile targets can be named consistently;
3. refit/update machinery can fix or map parameters reliably;
4. simulation tests cover boundary and sparse-group cases.

The first user-facing function should likely be:

```r
confint(fit, parm = "sd_id", method = "profile")
```

with later support for named derived quantities.
