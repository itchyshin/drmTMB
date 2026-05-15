# Profile-Likelihood Confidence Intervals

Profile-likelihood confidence intervals should become part of `drmTMB` once
random-effect variance components, phylogenetic effects, spatial effects, and
double-hierarchical models are stable enough to need serious inference on
variance and correlation quantities.

## Current Status

Profile-likelihood confidence intervals are partly implemented. `confint(fit)`
returns Wald fixed-effect intervals by default, and
`confint(fit, parm = "fixef:mu:x", method = "profile")` profiles explicit
direct targets. Direct ordinary random-effect SD, ordinary random-effect
correlation, and phylogenetic `mu` SD targets are transformed back to the
response scale. Constant `sigma`, `sigma1`, `sigma2`, and residual `rho12` can
also be profiled as direct response-scale targets with names such as
`parm = "sigma"` or `parm = "rho12"`. When `sigma`, `sigma1`, `sigma2`, or
`rho12` depends on predictors, use `confint()` with `method = "profile"` and
`newdata` to profile each supplied row. The corresponding `rho12` call profiles
the fixed-effect linear predictor for that row and transforms the interval to
the response scale. The first direct covariance rows are also profile-ready:
the univariate and same-response bivariate `mu`/`sigma` random-intercept
correlations in `corpars$mu_sigma`, the bivariate `mu1`/`mu2` random-intercept
correlation in `corpars$mu`, and the bivariate `sigma1`/`sigma2`
random-intercept correlation in `corpars$sigma`. The fitted bivariate
phylogenetic `mu1`/`mu2` SDs and mean-mean correlation are also profile-ready
direct targets, and the first smoke test verifies that the phylogenetic
correlation interval is transformed back to the bounded correlation scale.
`summary(conf.int = TRUE, method = "profile", ci_parm = ...)` can attach these
direct profile intervals to the same parameter rows shown in
`summary(fit)$parameters`. `corpairs(conf.int = TRUE)` can attach
profile-likelihood intervals to fitted correlation-pair rows when their target
is profile-ready, and it records explicit status values for rows that are not
ready yet. `profile_targets(fit)` lists fitted-object target names and
readiness notes; row-specific `newdata` targets are generated at call time.
Transformed ordinal, modelled group-SD, custom multi-row contrasts, conditional
random-effect mode intervals, and derived summary profile intervals remain
planned.

## Phase 6 Slice 51 Target Audit

Slice 51 records the profile-inference boundary before adding more intervals.
The package already has profile code, but the next work should harden the
target inventory and output contracts rather than add undocumented profile
paths.

| Surface | Current interval status | Next Phase 6 work |
| --- | --- | --- |
| Fixed-effect coefficients | Wald intervals by default; selected direct profile targets are available by explicit `fixef:<dpar>:<coef>` names. | Audit target names across families and improve failure messages for unsupported targets. |
| Constant residual scale and residual `rho12` | Direct profile intervals are available for constant `sigma`, `sigma1`, `sigma2`, and `rho12`. | Keep response-scale transformations explicit and test boundary behavior. |
| Predictor-dependent response-scale values | `confint(..., method = "profile", newdata = ...)` profiles supplied rows for scale, residual `rho12`, and fitted q2 `corpair()` values. | Broaden row-specific tests and reject ambiguous multi-parameter requests early. |
| Ordinary random-effect SDs and correlations | Selected direct SD and correlation targets are profile-ready and appear in `profile_targets()`. | Align `summary()`, `corpairs()`, and target names for every fitted direct registry row. |
| Phylogenetic SDs and q2 correlations | Implemented direct targets include the first bivariate phylogenetic `mu1`/`mu2` SD and mean-mean correlation path. | Keep phylogenetic targets separate from residual `rho12`; add clearer diagnostics for weak SDs and boundary correlations. |
| Spatial SDs | The first univariate coordinate-spatial `mu` SD target is direct and profile-ready where the fitted object retained the TMB object. | Add coverage that spatial profile labels and diagnostics stay distinct from phylogenetic labels. |
| q4 ordinary and phylogenetic correlations | Point estimates are reported, but q4 unstructured-correlation rows are derived targets and not direct profile-ready. | Preserve explicit unavailable statuses until a direct or fix-and-refit derived method exists. |
| ICCs, repeatability, phylogenetic signal, and other nonlinear summaries | Planned only. | Design a fix-and-refit or reparameterized profile path after extractors and diagnostics are stable. |

The linked Phase 6 tracking issue is
<https://github.com/itchyshin/drmTMB/issues/30>. The companion Phase 6b
tutorial issue is <https://github.com/itchyshin/drmTMB/issues/31>, because
profile intervals will need examples that show what is profile-ready and what
is status-only.

The first implementation must therefore start from a stable target inventory,
not from ad hoc parameter names in the C++ template. Public targets should be
named using user-facing quantities:

```text
fixef:mu:x
fixef:sigma:x
sigma
sigma1
sigma2
sd:mu:(1 | id)
sd:sigma:(1 | id)
sd:mu:phylo(1 | species)
sd:mu:mu1:phylo(1 | species)
cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)
cor:mu:cor((Intercept),x | id)
cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)
cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)
fixef:rho12:(Intercept)
rho12
```

These targets use labels stored in the fitted object, such as `sdpars` and
`corpars`, not the full model-building syntax. For example,
`sd:mu:phylo(1 | species)` identifies the fitted phylogenetic standard
deviation even though the original formula must provide the tree object through
syntax such as `phylo(1 | species, tree = tree)`.
For the first bivariate phylogenetic location slice,
`sd:mu:mu1:phylo(1 | species)` and `sd:mu:mu2:phylo(1 | species)` identify the
two fitted phylogenetic location SDs, while
`cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)` identifies
the phylogenetic mean-mean correlation. These names remain separate from the
residual target `rho12`.

Those names can then map internally to TMB parameters such as `beta_mu`,
`beta_sigma`, `log_sd_mu`, `log_sd_sigma`, `log_sd_phylo`, `eta_cor_mu`,
`eta_cor_mu_sigma`, `beta_sd_mu`, and `beta_rho12`. The short `sigma`,
`sigma1`, `sigma2`, and `rho12` targets are available only when the
corresponding model formula is constant. Predictor-dependent scale and
residual-correlation models expose their link-scale coefficients in
`profile_targets(fit)` and support row-specific response-scale profiles through
`newdata`; arbitrary contrasts remain planned.

## Phase 6 Slice 52 Target Namespace Contract

Slice 52 turns the target inventory into a small tested contract. Every row in
`profile_targets(fit)` must use these public columns:

```text
parm
target_class
dpar
term
tmb_parameter
index
estimate
link_estimate
scale
transformation
target_type
profile_ready
profile_note
```

The target name in `parm` is the string users pass to `confint()`. It should be
stable, user-facing, and based on fitted-model labels, not on raw TMB storage
details. `tmb_parameter` and `index` are allowed to expose the implementation
mapping because they are diagnostic columns, but they are not the public target
name.

`target_type` has only two meanings:

| Value | Meaning | Interval status |
| --- | --- | --- |
| `direct` | The row maps to one fitted TMB parameter or one TMB linear combination. | Can be profile-ready when the fitted object kept `fit$obj` and the internal parameter is present. |
| `derived` | The row is a reported point estimate from a transformed, multi-parameter, or surface-level quantity. | Not directly profile-ready until a direct reparameterization or fix-and-refit method exists. |

`profile_ready = TRUE` is deliberately stricter than "the optimizer vector has
this parameter". It means a direct target is available and the fitted object
retained the TMB automatic-differentiation object needed by
`TMB::tmbprofile()`. Memory-light fits created with
`drm_control(keep_tmb_object = FALSE)` still list their target names, but their
direct rows use:

```text
profile_ready = FALSE
profile_note = "tmb_object_required"
```

The currently allowed `profile_note` values are:

| Value | Use |
| --- | --- |
| `ready` | The direct target can be sent to `confint(..., method = "profile")`. |
| `tmb_object_required` | The target is otherwise direct, but the fit dropped `fit$obj`; refit with `drm_control(keep_tmb_object = TRUE)`. |
| `missing_tmb_parameter` | The fitted object does not contain the internal parameter needed for that direct target. |
| `derived_target` | The row is a derived SD or fitted surface, not a one-parameter profile target. |
| `derived_unstructured_correlation` | The row is an unstructured q4 correlation derived from a Cholesky-style covariance parameterization. |

The currently allowed `transformation` values are `linear_predictor`, `exp`,
`rho12_tanh`, `tanh`, `derived_group_scale`, `unstructured_corr`, and
`ordered_cutpoint`. Slice 52 tests representative fixed-effect,
distributional-scale, random-effect SD, random-effect correlation, residual
correlation, ordinal cutpoint, modelled-SD, q4 derived-correlation, and
memory-light fitted-object rows against this contract.

## Phase 6 Slice 53 Direct Profile Robustness

Slice 53 keeps the same statistical targets but hardens the failure boundary
around direct profile calculations. `drmTMB` controls the target-specific
arguments passed to `TMB::tmbprofile()`:

```text
obj
name
lincomb
trace
```

Users choose the target with `parm` and may still tune profile controls such as
`ystep`, `ytol`, `maxit`, `parm.range`, `slice`, and `adaptive`. Passing
`obj`, `name`, `lincomb`, or `trace` through `...` now errors before entering
TMB, because those arguments would otherwise create ambiguous "which target is
being profiled?" calls.

Direct profile failures are caught and rethrown with the public target name:

```text
Profile likelihood failed while profiling target "fixef:mu:x".
```

The message points users back to `profile_targets(fit)`, profile controls, and
`check_drm(fit)`. Interval extraction from a completed TMB profile is also
wrapped separately, because a profile can be computed yet fail to cross the
likelihood-ratio threshold on both sides. This slice does not change the
likelihood, the target transformations, or which derived targets are
profile-ready.

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
log_sd_phylo       -> sdpars$mu["spatial(1 | site)"] in the first spatial slice
eta_cor_mu         -> corpars$mu
eta_cor_mu_sigma   -> corpars$mu_sigma
beta_rho12         -> fixed effects in residual correlation formulae
```

For `beta_rho12`, the profile is on the atanh linear-predictor scale unless a
single interpretable row-specific value is requested with `newdata` and
transformed back through `tanh()`.

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
fixed-effect, constant distributional-scale, ordinary random-effect SD,
ordinary random-effect correlation, phylogenetic `mu` SD, constant residual
`rho12`, univariate `mu`/`sigma` random-intercept covariance target rows,
bivariate Gaussian group-level `mu1`/`mu2` random-intercept SD and correlation
target rows, and row-specific `newdata` profiles for predictor-dependent
`sigma`, `sigma1`, `sigma2`, `rho12`, and fitted ordinary q=2 `corpair()`
values. `summary(conf.int = TRUE, method = "profile")` reuses the same direct
target table when `ci_parm` names one of these rows. Unsupported
ordinal-transform, modelled group-SD, custom multi-row contrast, and
derived-summary targets still fail before doing expensive optimization.

The first fitted targets should be direct parameters in this order:

1. fixed-effect coefficients for `mu`, `sigma`, `nu`, `zi`, `hu`, and `rho12`;
2. constant `sigma`, `sigma1`, `sigma2`, residual `rho12`, and row-specific
   `newdata` profiles for predictor-dependent scale, residual-correlation, and
   fitted ordinary q=2 `corpair()` values;
3. ordinary Gaussian random-effect SDs in `sdpars$mu`;
4. ordinary Gaussian random-effect correlations in `corpars$mu`;
5. univariate `mu`/`sigma` random-intercept SD and correlation rows, with the
   fitted correlation in `corpars$mu_sigma`;
6. bivariate Gaussian group-level `mu1`/`mu2` random-intercept SDs and
   correlations, still under the `mu` random-effect target namespace;
7. phylogenetic `mu` SDs;
8. ordinal cutpoints.

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
confint(
  fit,
  parm = "cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)",
  method = "profile"
)
confint(fit, parm = "sd:mu:mu1:(1 | p | id)", method = "profile")
confint(
  fit,
  parm = "cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)",
  method = "profile"
)
confint(fit, parm = "sd:mu:phylo(1 | species)", method = "profile")
confint(fit, parm = "cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)", method = "profile")
confint(fit, parm = "cor:mu:cor((Intercept),x | id)", method = "profile")
confint(fit, parm = "sigma", method = "profile", newdata = data.frame(x = 0))
confint(fit, parm = "rho12", method = "profile", newdata = data.frame(w = 0))
confint(
  fit,
  parm = 'corpair(id, level = "group", block = "p", from = "mu1", to = "mu2")',
  method = "profile",
  newdata = data.frame(w = 0)
)
confint(fit, parm = "derived:ICC(id)", method = "profile")
```

Multi-coefficient random-effect blocks should keep the fitted-object
coefficient suffix, such as `:x`, in the canonical target name. Intercept-only
blocks can keep the shorter target name shown by `sdpars`.
Bivariate `mu1`/`mu2` covariance blocks keep the response label in the term so
users can tell group-level targets such as `sd:mu:mu1:(1 | p | id)` apart from
the residual-correlation target `rho12`.

For the first fitted ordinary q=2 `corpair()` regression, `newdata` must contain
the group-level predictors used on the right-hand side of the `corpair()`
formula. The interval is for the response-scale latent random-effect
correlation at that supplied predictor row. The `corpairs(conf.int = TRUE)`
extractor still reports `newdata_required` for modelled rows because its
summary row is a mean and range over many fitted group-level correlations, not
one profile target.

The implementation should reject unsupported profile targets with a message
that lists available targets from the fitted object.

## Tests Required Before Implementation Is Done

Profile-likelihood support is done only when these checks exist:

- direct `log_sd_mu` and `log_sd_sigma` intervals recover the simulated SD on
  the response scale;
- `log_sd_phylo` profile intervals work for the implemented
  `phylo(1 | species, tree = tree)` path and for the first fitted
  `spatial(1 | site, coords = coords)` path, where the same internal TMB
  parameter stores the single structured-effect SD;
- `profile_targets()` lists the fitted bivariate phylogenetic `mu1`/`mu2` SDs
  and mean-mean correlation separately from residual `rho12`;
- `eta_cor_phylo` profile intervals transform to bounded bivariate
  phylogenetic `mu1`/`mu2` correlations;
- `eta_cor_mu` profile intervals transform to bounded group-level correlations;
- `eta_cor_mu_sigma` profile intervals transform to bounded `mu`/`sigma`
  group-level correlations;
- `summary(conf.int = TRUE, method = "profile")` attaches finite bounds to
  profile-ready direct covariance rows;
- boundary SDs return one-sided intervals with `boundary = TRUE`;
- a small diagnostic grid agrees with the `uniroot()` bounds in at least one
  simple model;
- unsupported derived targets fail with a clear available-target message;
- long simulations compare profile, Wald, and bootstrap coverage for a small
  set of variance components.
