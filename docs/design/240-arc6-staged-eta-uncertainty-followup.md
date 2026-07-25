# Arc 6 staged-eta uncertainty follow-up

> **Supersession (2026-07-25).** The former full-refit-bootstrap proposal is
> still stopped; its partial outputs remain non-evidential provenance. A
> developer-only stacked-score/Godambe candidate is now being built under
> [`243-arc6-staged-eta-godambe-se.md`](243-arc6-staged-eta-godambe-se.md).
> This does not make a public SE, Wald interval, profile, `confint()`, or
> coverage claim available. Any small full-refit comparison requires the
> frozen-method gate and separate owner approval.

## Status and boundary

This is a design handoff, not an implemented uncertainty method. It applies
only to the reviewed fixed-effect literal-Bernoulli × ordinary-NB2
`associate_pairs()` route, including its one numeric `association = ~ x` beta
extension. It does not grant `vcov()`, Wald standard errors, likelihood
profiles, confidence intervals, coverage, random effects, missingness, or a
generic cross-family inference claim.

## Why the current curvature is not an interval estimator

The staged object first estimates margin parameters \(\hat\psi_1\) and
\(\hat\psi_2\), then freezes their fitted probability, mean, and dispersion
vectors while optimizing association coefficients \(\hat\alpha\). The current
stage-2 curvature therefore describes

\[
I_{\alpha\alpha\mid\hat\psi_1,\hat\psi_2},
\]

not the sampling variance of the two-stage estimator. It omits margin
uncertainty and cross-stage covariance. Profiling that same conditional
objective has the same defect: it is not a profile of a joint likelihood.

Until a validated stacked-score Godambe estimator exists, the admissible route
is a full-refit parametric bootstrap. The package must keep conditional
Hessian, `profile()`, and `confint()` unavailable in the meantime.

## Later full-refit bootstrap contract

1. Fit the two declared margin models on their complete matched rows and fit
   `associate_pairs()` with the original association formula, controls, and
   response order.
2. Hold the observed covariate design fixed. For each row draw coupled latent
   normals using fitted \(\eta_i = 0.999999\tanh(X_{Ai}\hat\alpha)\), map the
   first through the Bernoulli threshold and the second through the fitted NB2
   quantile (`size = sigma^{-2}`).
3. In every bootstrap replicate, refit **both** margin models from scratch and
   then rerun the association fit. Do not reuse fitted margin vectors or use a
   conditional stage-2 refit as a shortcut.
4. Start with 399 attempted refits and use plain percentile intervals on the
   association-link coefficients. For `association = ~ x`, report derived
   `eta(x)` only at predeclared `x = -1, 0, 1`, transforming each bootstrap
   draw before taking quantiles.
5. Retain every stage-1 and stage-2 status, score/curvature/multistart
   diagnostic, response-pattern count, endpoint/integration diagnostic, seed,
   and failure message. An interval is available only with at least 380
   resolved associations; report availability over all outer attempts and both
   conservative all-attempt and conditional coverage.

## First simulation ladder

Before implementing an interval API, establish point recovery and bootstrap
feasibility over this immutable grid:

- `n = 120, 240, 480`, with `x` equally spaced on `[-1.4, 1.4]`;
- Bernoulli logit intercept `-1.4` or `-0.2`, plus slope `0.3`;
- NB2 `mu = exp(0.7 + 0.2 x)` and `sigma = 0.25` or `0.65`;
- association coefficients `(alpha0, alpha1) = (0, 0)` or `(-0.15, 0.65)`.

This 24-cell grid uses 200 retained outer attempts per cell and 399 full-refit
bootstrap attempts per outer fit. It is DRAC-scale, not a GitHub Actions job,
and requires a fresh compute approval after a non-empty smoke.

## References to the implemented boundary

The current staged estimator and its withheld inference API are documented in
`R/associate-pairs.R` and the Bernoulli × NB2 contract
`docs/design/236-arc6-6-bernoulli-nbinom2-contract.md`. The direct
`biv_lognormal()` campaign is irrelevant to this two-stage uncertainty claim:
it validates an exact joint likelihood, not frozen-margin `eta`.
