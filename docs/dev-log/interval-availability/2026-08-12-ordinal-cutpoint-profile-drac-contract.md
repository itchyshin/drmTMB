# Immutable DRAC campaign contract: ordinal cutpoint profile intervals

Status: **NO COMPUTE.** This contract records the approved design only. It
does not authorize a local smoke, DRAC submission, fit, artifact creation, or
G5/calibration claim. After one local timing smoke for every DGP × information
rung × missingness mechanism, the campaign requires explicit DRAC approval.

## Purpose and estimands

This campaign asks two separate questions for applied ecology and evolution
users of `cumulative_logit()`: how often does the explicit constrained profile
return an interval for a public `ordinal:cutpoint:<label>` target, and how does
that interval cover the known cutpoint under repeated sampling? A cutpoint is
an ordered latent-logistic threshold, not an ordinary response quantity. The
raw `theta_ord` coordinates are internal and are never campaign estimands.

The campaign evaluates the ML/Laplace `cumulative_logit()` route only, with
`confint(..., method = "profile", profile_engine = "auto")`. It does not test
Wald or bootstrap cutpoint intervals and does not broaden default interval
methods. Location means the latent ordinal shift; scale is fixed for this
ordinal model; shape is not fitted; and coscale means residual correlation such
as `rho12`, which is outside this univariate campaign.

## Frozen design

The DGP factor is fixed at three levels:

| DGP | Cutpoint targets | Purpose |
| --- | --- | --- |
| Existing `K = 3` thresholds | 2 | Baseline ordered response. |
| Balanced `K = 5` thresholds | 4 | More category boundaries with balanced frequencies. |
| Close-gap/rare-category `K = 5` thresholds | 4 | Near thresholds and sparse categories. |

Cross each DGP with missingness mechanism `{complete, 25% MCAR}` and
information rung `{0.5x, 1x, 2x}`. This yields 18 condition cells and 10
named public cutpoint targets across the three DGPs. Run 1,200 attempts per
DGP × mechanism × rung: `3 × 2 × 3 × 1,200 = 21,600` fits. Each successful or
failed target request is retained, so the expected target-interval ledger has
`10 × 2 × 3 × 1,200 = 72,000` records. The denominator is **all attempts**;
an unavailable interval receives no unconditional-coverage success.

Deterministic seeds, cutpoint-scale truth values, the input-manifest hash, and
host labels must be frozen and recorded before execution. Each record must
retain fit status, convergence, Hessian status, interval status, endpoint
finiteness, one-sided/boundary flags, below-fitted-objective flags, and
directional misses. No failed fit, unavailable interval, or malformed target
may be silently dropped.

## Required summaries and gates

For every target × rung × mechanism cell, report the number attempted, number
available, interval availability, unconditional coverage, conditional coverage
among available intervals, an exact binomial interval for each coverage rate,
MCSE, counts of one-sided/boundary outcomes, convergence/Hessian outcomes,
below-fit flags, and lower/upper directional misses. Label conditional coverage
as conditional; it must not replace unconditional coverage.

The predeclared gates are:

| Requirement | Gate |
| --- | --- |
| Interval availability | at least 0.99, using all 1,200 attempts as denominator |
| Unconditional coverage | inside `[0.925, 0.975]` |
| Monte Carlo precision | MCSE at most `0.01` |
| Constraint validity | zero order or scale violations |

These gates evaluate an implemented interval route; they do not create a
simultaneous cutpoint band, a category-probability interval, or any broader
ordinal claim. They are a precondition for later review, not an automatic G5
promotion.

## Execution firewall

Before any DRAC submission, run exactly one local timing smoke for each of the
18 DGP × rung × mechanism cells and report the timing evidence and projected
DRAC request. Stop there and obtain explicit DRAC approval. The campaign must
then preserve the frozen seeds, truth table, manifest hash, DGP definitions,
profile call, and denominators above. Any needed change creates a new contract;
this file remains immutable.
