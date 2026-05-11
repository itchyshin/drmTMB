# Profile-Likelihood Confidence Intervals

Profile-likelihood confidence intervals should become part of `drmTMB` once
random-effect variance components, phylogenetic effects, spatial effects, and
double-hierarchical models are stable enough to need serious inference on
variance and correlation quantities.

## Current Status

Profile-likelihood confidence intervals are partly implemented. `confint(fit)`
returns Wald fixed-effect intervals by default, and
`confint(fit, parm = "fixef:mu:x", method = "profile")` profiles explicit direct
targets. Direct ordinary random-effect SD and correlation targets are
transformed back to the response scale. `profile_targets(fit)` lists the target
names and readiness notes for a fitted model. Transformed ordinal, modelled
group-SD, and derived-summary profile intervals remain planned.

The first implementation must therefore start from a stable target inventory,
not from ad hoc parameter names in the C++ template. Public targets should be
named using user-facing quantities:

```text
fixef:mu:x
fixef:sigma:x
sd:mu:(1 | id)
sd:sigma:(1 | id)
sd:mu:phylo(1 | species)
cor:mu:cor((Intercept),x | id)
fixef:rho12:(Intercept)
```

These targets use labels stored in the fitted object, such as `sdpars` and
`corpars`, not the full model-building syntax. For example,
`sd:mu:phylo(1 | species)` identifies the fitted phylogenetic standard
deviation even though the original formula must provide the tree object through
syntax such as `phylo(1 | species, tree = tree)`.

Those names can then map internally to TMB parameters such as `beta_mu`,
`beta_sigma`, `log_sd_mu`, `log_sd_sigma`, `log_sd_phylo`, `eta_cor_mu`,
`beta_sd_mu`, and `beta_rho12`.

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
- `uniroot()` to find lower and upper threshold crossings when both exist;
- warm starts from the joint MLE wherever possible;
- response-scale transformations after profiling on the stable internal scale.

This is preferable to a dense grid because most grid points do not matter. A
grid can still be useful for diagnostics and teaching plots.

The profile API should return a tidy data frame with at least:

```text
parm
estimate
conf.low
conf.high
scale
method
boundary
converged
message
```

Boundary and convergence flags are part of the result, not optional warnings
that disappear in scripts.

Boundary control flow should be explicit. If a lower variance-component bound
is the parameter-space boundary, such as `sd = 0`, the lower endpoint should be
reported as that boundary and `boundary = TRUE`. If only one interior root
exists, the other endpoint should be encoded as the boundary or as missing with
a clear `message`, depending on the parameter space. Nonregular cases should
not be silently turned into symmetric intervals.

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

Current high-value direct targets are:

```text
log_sd_mu          -> sdpars$mu
log_sd_sigma       -> sdpars$sigma
log_sd_phylo       -> sdpars$mu["phylo(1 | species)"]
eta_cor_mu         -> corpars$mu
beta_rho12         -> fixed effects in residual correlation formulae
```

For `beta_rho12`, the profile is on the atanh linear-predictor scale unless a
single interpretable contrast is requested and transformed back through
`tanh()`.

### Linear Combinations

Examples:

- total variance as the sum of two variance components;
- simple contrasts of direct parameters on an internal scale.

Use TMB's `lincomb` machinery where the target is truly linear in the internal
parameterization.

Do not use `lincomb` for sums of variances unless the internal parameters are
already variances. A sum such as `sigma_phylo^2 + sigma_species^2` is nonlinear
in `log_sd_phylo` and `log_sd_mu`.

### Nonlinear Derived Quantities

Examples:

- ICCs;
- repeatability;
- heritability-like ratios;
- cross-trait correlations derived from covariance matrices;
- correlations among individual averages, mean-model slopes, residual scale,
  and scale-model slopes in double-hierarchical individual-difference models.

These are not direct `tmbprofile()` targets. The first robust path should be a
fix-and-refit profile:

1. choose a candidate derived value;
2. impose the corresponding constraint through a mapped or rebuilt TMB object;
3. re-optimize all other parameters;
4. use `uniroot()` to find where the profile log likelihood drops by `1.92`.

An alternative is to create a new TMB parameterization where the derived
quantity is a direct parameter, such as `(logit_ICC, log_total_variance)`, but
that is more invasive and should be reserved for high-value quantities.

For `drmTMB`, the first nonlinear derived targets are likely:

```text
ICC_study = omega_study^2 / (omega_study^2 + sigma^2)
phylogenetic_signal = sigma_phylo^2 /
  (sigma_phylo^2 + sigma_species^2 + sigma^2)
repeatability = sigma_group^2 / (sigma_group^2 + sigma^2)
```

These should be implemented only after the corresponding variance components
have stable extractors and simulation tests.

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

Candidate correlations should be searched on the open bounded response scale,
with numerical guards such as `(-0.999999, 0.999999)` rather than exactly
`[-1, 1]`. Direct TMB parameters such as `eta_cor_mu` and residual-correlation
linear predictors such as `beta_rho12` can be profiled internally on an
unbounded scale, but reported intervals for correlations must be transformed
back through `tanh()`. Profiles that approach the numerical guard should be
flagged as near-boundary intervals.

## Pitfalls And Fallbacks

- Boundary variance components can produce one-sided intervals. Return the
  boundary, such as zero, and flag the interval.
- Non-monotone or multi-modal profiles can invalidate simple `uniroot()` logic.
  Detect these cases and fall back to a plotted profile or parametric bootstrap.
- Constrained inner optimizations can fail near boundaries. Retry with perturbed
  starts before falling back.
- Wald intervals for variance components and correlations should not be the main
  default because they are often poor near boundaries.

## First Implementation Slice

The first code slice should not attempt every interval type. It should expose a
target inventory while keeping the internal TMB mapping in one helper:

```r
profile_targets(fit)
```

This public helper is the target table behind the profile/confidence interval
API. It returns target names, target classes, internal TMB parameter names,
current estimates, transformation labels, whether the target is direct or
derived, and a short note explaining whether the target is ready for direct
profiling. `confint(fit, method = "profile")` accepts targets from this table.
Unsupported targets fail before expensive optimization.

A second internal helper now profiles direct fixed-effect targets from this
inventory, and the public `confint()` method exposes the first user-facing
slice:

```r
confint(fit, parm = "fixef:mu:x", method = "profile")
```

By default, `confint(fit)` returns fast Wald intervals for fixed-effect
coefficients on their link scales. Profile intervals must be requested by name
because they can be slow. The profile path wraps `TMB::tmbprofile()` for ready
fixed-effect, ordinary random-effect SD, and ordinary random-effect correlation
target rows. Unsupported ordinal-transform, modelled group-SD, and
derived-summary targets still fail before doing expensive optimization.

The first fitted targets should be direct parameters in this order:

1. fixed-effect coefficients for `mu`, `sigma`, `nu`, `zi`, `hu`, and `rho12`;
2. residual-scale parameters where they are direct TMB parameters;
3. ordinary Gaussian random-effect SDs in `sdpars$mu`;
4. ordinary Gaussian random-effect correlations in `corpars$mu`;
5. phylogenetic `mu` SDs;
6. ordinal cutpoints.

Ordinal rows in the internal inventory currently refer to raw `theta_ord`
parameters. A later user-facing interval table can add transformed cutpoint
rows, but it should keep `theta_ord` visible as the profiled TMB parameter.

Derived summaries such as repeatability, ICC, phylogenetic signal, and
double-hierarchical correlation-pair summaries should wait until direct
profiles are stable and the derived quantity has a named extractor.

## Implementation Stage

Do not treat profile CIs as complete for the Gaussian random-effect and
correlation phases. Add broader profile support after:

1. random-effect variance components are represented cleanly in fitted objects;
2. profile targets can be named consistently;
3. refit/update machinery can fix or map parameters reliably;
4. simulation tests cover boundary and sparse-group cases.

The first user-facing function should use the same target grammar exposed by
the fitted object:

```r
confint(fit, parm = "sd:mu:(1 | id)", method = "profile")
confint(fit, parm = "sd:mu:(1 + x | p | id):x", method = "profile")
confint(fit, parm = "sd:mu:phylo(1 | species)", method = "profile")
confint(fit, parm = "cor:mu:cor((Intercept),x | id)", method = "profile")
confint(fit, parm = "derived:ICC(id)", method = "profile")
```

Multi-coefficient random-effect blocks should keep the fitted-object
coefficient suffix, such as `:x`, in the canonical target name. Intercept-only
blocks can keep the shorter target name shown by `sdpars`.

The implementation should reject unsupported profile targets with a message
that lists available targets from the fitted object.

## Tests Required Before Implementation Is Done

Profile-likelihood support is done only when these checks exist:

- direct `log_sd_mu` and `log_sd_sigma` intervals recover the simulated SD on
  the response scale;
- `log_sd_phylo` profile intervals work for the implemented
  `phylo(1 | species, tree = tree)` path;
- `eta_cor_mu` profile intervals transform to bounded group-level correlations;
- boundary SDs return one-sided intervals with `boundary = TRUE`;
- a small diagnostic grid agrees with the `uniroot()` bounds in at least one
  simple model;
- unsupported derived targets fail with a clear available-target message;
- long simulations compare profile, Wald, and bootstrap coverage for a small
  set of variance components.
