# Phase 18 Skew-Normal Fixed-Effect Formal Recovery Design

## Purpose

This note defines the smallest formal recovery gate for the fitted univariate
fixed-effect `skew_normal()` first slice. It is a design gate, not a completed
simulation result. The current implementation already fits

```r
bf(y ~ x, sigma ~ z, nu ~ ...)
```

with public `mu = E[y]`, public `sigma = SD[y]`, and `nu` as residual slant.
The formal recovery grid should ask whether fixed-effect location, scale, and
slant parameters are recovered under ordinary ecological sample sizes before
the package advertises more than smoke/artifact readiness.

## Admitted Model

The admitted formal grid is univariate and fixed-effect only:

```r
bf(y ~ x, sigma ~ z, nu ~ 1)
```

and, in a second tier only after the intercept-slant grid passes,

```r
bf(y ~ x, sigma ~ z, nu ~ w)
```

The first tier estimates five formula coefficients:

| Distributional parameter | Formula | Truth columns |
| --- | --- | --- |
| location `mu` | `y ~ x` | `beta_mu_intercept`, `beta_mu_x` |
| scale `sigma` | `sigma ~ z` | `beta_sigma_intercept`, `beta_sigma_z` |
| slant `nu` | `nu ~ 1` | `beta_nu_intercept` |

The response is generated through the package's public-parameter
skew-normal simulator, so the DGP and fitted model share the same public
`mu`/`sigma`/`nu` scale.

## First Condition Grid

The first formal grid should cross:

- sample size: `n = 320, 720`;
- true slant: `beta_nu_intercept = -1.2, 0, 1.2`;
- scale heterogeneity: `beta_sigma_z = 0, 0.25`;
- location/scale predictor correlation: `rho_xz = 0, 0.35`.

That gives 24 cells before replication. The symmetric `nu = 0` cells are not
optional: they are the false-positive guard and should be summarised both in
the main recovery table and the false-positive table.

## Estimands

For each formula coefficient, report:

- bias and RMSE on the modelled coefficient scale;
- convergence rate;
- positive-Hessian rate;
- warning rate;
- `check_drm()` `skew_normal_nu` status rates;
- Monte Carlo standard error for bias and RMSE where available.

For symmetric cells, additionally report:

- `mean(abs(fitted_nu))`;
- `max(abs(fitted_nu))`;
- `mean(abs(fitted_nu) > 0.5)`;
- `mean(check_drm(fit)$skew_normal_nu$status == "note")`.

These false-positive summaries should be interpreted as diagnostics, not as a
claim that `nu = 0` has a calibrated hypothesis test.

## Stop Rules

Do not promote fixed-effect skew-normal beyond smoke/artifact readiness if any
of the following hold in the first formal grid:

- convergence rate below 0.90 in any non-boundary cell;
- positive-Hessian rate below 0.90 in any non-boundary cell;
- systematic sign reversal for `beta_nu_intercept` in left or right slant
  cells;
- symmetric cells regularly produce large fitted slant
  `abs(fitted_nu) > 0.5`;
- `check_drm()` frequently reports large-slant notes under `nu = 0`.

If a cell fails only because the sample size is too small, keep the result as a
diagnostic lower-boundary row and add a second design note before changing the
grid.

## Explicit Non-Goals

This design does not admit:

- skew-normal random effects;
- structured effects from `phylo()`, `spatial()`, `animal()`, or `relmat()`;
- bivariate skew-normal models;
- residual `rho12` in skew-normal models;
- latent `skew(id) ~ ...` syntax;
- skew-t or second-shape `tau` routes;
- known sampling covariance or meta-analysis syntax.

Those routes need separate likelihood, grammar, and simulation decisions.

## Current Evidence Boundary

The current package state has deterministic source tests, a fixed-effect smoke
artifact lane, and a symmetric false-positive artifact lane. That is enough to
say the first fixed-effect skew-normal route is runnable and diagnostically
inspectable. It is not yet enough to claim formal recovery, coverage, power, or
general skew-family robustness.
