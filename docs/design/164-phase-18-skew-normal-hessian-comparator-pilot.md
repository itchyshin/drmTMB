# Phase 18 Skew-Normal Hessian And Comparator Pilot

This note records the fixed-effect `skew_normal()` inference rescue slice after
the first false-positive and formal-pilot artifacts. The reader is the
contributor deciding whether the fitted first slice needs a parameterization
change, a simpler simulation gate, or external comparator evidence before a
formal recovery grid.

## Fitted Surface

The current fitted surface is univariate and fixed-effect:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ 1),
  family = skew_normal(),
  data = dat
)
```

Public `mu` is `E[y]`, public `sigma` is `SD[y]`, and `nu` is residual slant.
The TMB likelihood transforms internally to the native skew-normal location,
scale, and shape parameters. Random effects, structured effects, known sampling
covariance, bivariate skew-normal, residual `rho12`, skew-t, and latent
`skew(id)` remain outside this slice.

## Why This Pilot Was Needed

The earlier three-cell formal pilot converged 9/9 fits, but all nine fits used
the smoke helper with `se = FALSE`; no positive-Hessian evidence was computed.
The symmetric false-positive cell also showed that a true `nu = 0` data set can
fit a large nonzero slant value. That combination is enough to keep
`skew_normal()` in first-slice/pilot status, but it does not explain whether the
problem is sample size, heteroscedastic confounding, predictor-varying `nu`, or
Hessian computation.

## Local Hessian Pilot

The 2026-06-08 Hessian/comparator pilot wrote
`docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-hessian-comparator-pilot/`.
It fit eight small models with `se = TRUE` and
`optimizer_preset = "careful"`:

- three constant-scale `sigma ~ 1`, `nu ~ 1` cells for left, symmetric, and
  right slant;
- three heteroscedastic `sigma ~ z`, `nu ~ 1` cells for left, symmetric, and
  right slant;
- one predictor-varying true-slant cell fit with misspecified `nu ~ 1`;
- the same predictor-varying true-slant cell fit with `nu ~ w`.

All eight fits converged and all eight had `pdHess = TRUE`. This is a useful
contrast with the earlier smoke artifacts: fixed-effect skew-normal Hessian
evidence can be available when the pilot is deliberately simple, uses
`se = TRUE`, and stays in a small fixed-effect surface.

The estimates still support caution. In the constant-scale symmetric cell,
`nu:(Intercept)` was about `-0.702` even though the true value was zero. In the
heteroscedastic symmetric cell, `nu:(Intercept)` was about `0.315`. In the
predictor-varying slant cell, the `nu ~ w` fit recovered the sign of the slope,
but estimated about `0.566` for a true slope of `1.2`; the misspecified
`nu ~ 1` fit estimated a nonzero intercept around `0.693`.

## Comparator Availability

The local pilot checked for `sn` and `gamlss`. Neither package was available in
the current local library, so no external comparator fit was run. The follow-up
scale-map slice is now recorded in
`docs/design/166-phase-18-skew-normal-comparator-scale-map.md`: `sn::dsn()` and
`RTMBdist::dskewnorm()` compare on native Azzalini `xi`, `omega`, and `alpha`;
`RTMBdist::dskewnorm2()`, `brms::skew_normal()`, and
`glmmTMB::skewnormal()` compare on public moment `mu`, `sigma`, and `alpha`;
and `gamlss.dist::SN2` is a different two-piece skew-normal family, not a
same-density comparator.

## Decision

The fixed-effect skew-normal route can produce positive-Hessian fits in simple
fixed-effect settings. The next formal grid should start with the simple
`sigma ~ 1`, `nu ~ 1` cells and then add `sigma ~ z` and `nu ~ w` as separate
stress tiers. Do not use the earlier false-positive cell or the new
predictor-varying pilot as promotion evidence; use them as warning rows that
shape and scale effects can confound each other in small samples.
