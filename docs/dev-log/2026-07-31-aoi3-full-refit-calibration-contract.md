# AOI-3 Bernoulli x ordinary-NB2 full-refit calibration contract

## Status

**SUPERSEDED FOR EXECUTION — historical contract only.** The owner-authorized
local smoke failed and its reducer recorded
`AOI3_LOCAL_SMOKE_FAIL_DRAC_BLOCKED`; therefore this contract authorizes
neither a retry nor a DRAC campaign. The prospective diagnostic successor is
the AOI-3R2 contract and manifest, which independently require a new owner
authorization. This historical record does not expose a public standard error,
interval, `vcov()`, `confint()`, capability tier, or reader-facing claim.

## Estimand and scope

Outer data sets use literal Bernoulli and ordinary-NB2 margins on complete rows,
fixed-effect ML margins, and the latent-normal association link
`eta = 0.999999 * tanh(X_A alpha)`. The only formulae are AOI-1's additive,
mixed, factor-interaction, numeric-interaction, and transformation classes.
Random effects, missingness, weights, offsets, REML, new family pairs, and
public methods remain excluded.

The unexported `drm_pair_general_eta_sandwich()` is the candidate estimator.
The comparator fully refits: every inner replicate simulates both responses
from the fitted outer margins and association, then refits both margins,
rebuilds its association design, refits association, and recomputes the private
sandwich. It never reuses outer stage-2 curvature.

## Frozen hierarchy and all-attempt rule

Every outer DGP has known `alpha`, independent seed, and fixed covariate/design
regime. Every generated data set is retained. Margin, association, provenance,
private-sandwich, and finite-covariance failures are retained. An unavailable
outer sandwich has no inner substitute and is non-covering.

Every scheduled inner resample is retained, including failed margin,
association, or sandwich states. The alpha candidate interval is
`alpha_hat +/- qnorm(0.975) * sandwich_se`. The eta candidate uses the
link-scale delta interval at fixed new-data rows, transformed through `tanh()`.
Unavailable/non-finite intervals are non-covering. Within each eligible outer
fit, the empirical covariance of available inner alpha estimates is comparator
output only; it never replaces unavailable sandwich intervals. Coverage is over
all outer attempts against the known DGP truth, never over inner draws.

Private and empirical covariance outputs carry the exact frozen association
column order; non-finite, asymmetric, or non-PSD values are unavailable.

## Local smoke

The authorized smoke executes one outer data set for every formula class at
`n = 720`, interior strength, and seven complete inner refits. Its seeds are
frozen in `tools/run-aoi3-bernoulli-nb2-full-refit.R`.

It passes only if all five outer fits are interior with an available private
sandwich of finite ordered alpha terms, and all 35 inner complete refits have
finite ordered alpha estimates. It is a mechanical/provenance gate, not a
coverage or calibration estimate. Any failure stops DRAC submission without
changing AOI-2's HOLD or any public surface.

## Conditional DRAC campaign

After a smoke pass receipt, submit exactly 30 cells: five formula classes x
`n = {360, 720, 1440}` x `{interior, near_boundary}`. Each cell uses 200 outer
data sets and 199 inner resamples per eligible outer. Outer IDs are partitioned
into ten immutable 20-outer shards (300 tasks; at most 1,194,000 inner refits).
Wall-time/memory come from the smoke peak; no seed, DGP, formula, or decision
rule changes are allowed.

Report all-attempt availability; coefficient-wise private-versus-empirical
covariance, SE/SimSE, and 95% marginal coverage; eta(newdata)
delta-versus-empirical variance and coverage; covariance PSD/order diagnostics;
and the complete failure taxonomy. No public uncertainty is proposed unless a
later claim review evaluates every planned cell, counting unavailable intervals
as non-covering.

## Provenance and stopping rules

The runner records source SHA, truth, fixed new-data design, seed maps,
`sessionInfo()`, and output schema. Output roots are immutable. Changed SHA,
duplicate seed, unexpected design columns, non-finite covariance, or row-count
mismatch is an execution failure, never a reason to pool or repair results.
This contract neither repairs nor clears the AOI-2 point-recovery HOLD.
