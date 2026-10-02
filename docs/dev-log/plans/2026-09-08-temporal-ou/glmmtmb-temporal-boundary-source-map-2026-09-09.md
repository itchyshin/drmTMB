# glmmTMB temporal covariance and boundary source map

**Checked:** 2026-09-09

**Installed comparison package:** `glmmTMB` 1.1.14
**Sources read:** installed `doc/covstruct.rmd` and `doc/troubleshooting.rmd`.

## What drmTMB can learn

The installed covariance guide specifies AR1 as a unit-spaced structure with
a process SD and signed correlation, and OU as a coordinate-based structure
with process SD plus rate `exp(theta)`, where correlation at distance `d` is
`exp(-exp(theta) * d)`. This agrees with drmTMB's separate temporal process
and residual `sigma`, its signed integer-gap AR1, and its positive-decay
elapsed-time OU parameterization. Its AR1 example also makes the series
independence contract explicit: each group has its own latent vector and all
groups share covariance parameters.

The troubleshooting guide treats a non-positive-definite Hessian, zero random
effect variance, and near-zero dispersion as model-geometry and
identifiability signals. It suppresses ordinary likelihood summaries for such
fits rather than treating a numerically nearby positive-definite point as a
repair. This matches the retained C1 diagnosis.

For a boundary covariance parameter, the guide illustrates likelihood-profile
intervals, including a one-sided result when the lower bound is not defined.
That is useful precedent for a future drmTMB profile-likelihood lane. It does
not validate the present required target: Wald intervals for mean regression
coefficients based on the full observed Hessian while nuisance residual scale
is on a boundary. Any adaptation would need a new target registry, a profile
algorithm that permits the residual boundary, deterministic oracles, and a
separate calibration campaign.

## What drmTMB should not copy

`glmmTMB` represents AR1 occasions as explicit factor levels. That interface
can accidentally erase missing integer levels; drmTMB's temporal provider
keeps numeric occasions and genuine gaps, which is required for its stated
model. The available local `glmmTMB` source checkout contains zero-byte
placeholder files, so this note relies only on installed documentation and
imports no code or unverified implementation detail.

## Decision for the current lane

No inference change follows from this comparison. Keep C1 intervals
unavailable and counted as uncovered in any later calibration, keep OU Wald
inference guarded, and do not expand the interface until a separately
approved profile or boundary-inference plan is written.
