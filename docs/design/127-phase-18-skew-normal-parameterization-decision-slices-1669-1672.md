# Phase 18 Skew-Normal Parameterization Decision, Slices 1669-1672

This note closes the first Team B follow-on gate after the skew-normal source
map. It does not implement `skew_normal()`. Its reader is the future
implementation contributor who must know what `mu`, `sigma`, and `nu` mean
before adding a constructor or TMB density branch.

## Decision

Use the moment parameterization for the first fitted skew-normal lane:

```text
mu_i = E[y_i]
sigma_i = SD[y_i]
nu_i = alpha_i
```

The internal likelihood may still evaluate a native Azzalini density with
location `xi`, scale `omega`, and slant `alpha`. If so, the TMB branch should
transform from public moments to native parameters:

```text
delta_i = alpha_i / sqrt(1 + alpha_i^2)
omega_i = sigma_i / sqrt(1 - 2 * delta_i^2 / pi)
xi_i = mu_i - omega_i * delta_i * sqrt(2 / pi)
```

Then the density is evaluated as `SN(xi_i, omega_i, alpha_i)`. At `nu_i = 0`,
`delta_i = 0`, `omega_i = sigma_i`, and `xi_i = mu_i`, so the model reduces to
the Gaussian location-scale interpretation.

## Why Moment Parameters

The first skew-normal family should preserve the public semantics users already
expect from `drmTMB` fixed-effect families:

- `fitted()` should return the response mean, not a hidden native location.
- `sigma()` should report the response standard deviation, not a native scale
  whose interpretation changes with skewness.
- `predict(dpar = "nu")` should return the skew-normal slant or shape
  parameter on the response scale implied by the identity link.

This decision aligns `drmTMB` with `brms::skew_normal()` and
`glmmTMB::skewnormal()` as the most useful fitted-model comparators. It still
keeps `sn::dsn()` and `RTMBdist::dskewnorm()` useful as density comparators
after transforming public moments to native parameters.

## Consequences For The First Implementation

The first runnable implementation should use:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = skew_normal(),
  data = dat
)
```

where `mu` is the response mean, `sigma` is the response standard deviation,
and `nu` is residual skewness. Positive and negative `nu` must have documented
residual-skew directions. `nu = 0` must match the Gaussian location-scale
likelihood, fitted values, `sigma()`, simulation, and log-likelihood under the
chosen constants.

The first implementation still excludes random effects in `nu`, latent
skewness such as `skew(id) ~ x`, `skew` as a public alias, random-effect scale
models, structured effects, meta-analysis known-`V`, bivariate skew-normal
models, and `rho12`.

## Slice Status

| Slice | Status | Evidence |
| --- | --- | --- |
| 1669 | Done | The skew-normal source map and issue #3 still mark the family as design-only. |
| 1670 | Done | The first reader-facing question is residual asymmetry after `mu` and `sigma`, not latent-effect skewness. |
| 1671 | Done | This note compares native Azzalini and moment parameterizations. |
| 1672 | Done | The decision is moment parameters for the first fitted lane. |

## Documents Synced Before C++

This slice updated the planned skew-normal sections in
`docs/design/02-family-registry.md`, `docs/design/03-likelihoods.md`, and
`docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md` so they
all describe the moment-parameter contract. The formula grammar does not need
to change because the public syntax remains `mu`, `sigma`, and `nu`.
