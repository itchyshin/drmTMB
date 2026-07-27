# Arc 6 F5 public S3 design — B x ordinary-NB2 alpha uncertainty

## Purpose and status

This is a **design-only** blueprint for a possible later F5.  It authorizes
neither implementation nor any public inference claim.  The present
`vcov.drm_pair_association()` and `confint.drm_pair_association()` methods must
continue to fail closed until the frozen F4 campaign has passed and the owner
has separately approved F5.

The sole candidate domain is a fixed-effect ML, complete-pair Bernoulli x
ordinary-NB2 association made with
`associate_pairs(..., kernel = latent_normal(), association = ~ 1)`.  No
decision here transfers to another pair, an association slope, eta intervals,
random or structured effects, missingness, weights, offsets, REML, `rho12`, or
any profile/bootstrap interface.

## Candidate methods

When, and only when, F5 is approved after a PASS F4 panel:

```r
vcov(fit)
confint(fit, level = 0.95)
```

would be admitted only for that domain.  `vcov()` would return a named 1 x 1
matrix whose sole row and column are `alpha`; its entry would be the private
two-stage Godambe alpha covariance.  `confint()` would return one named row,
`alpha`, and two columns, `2.5 %` and `97.5 %`, computed as the untransformed
alpha Wald endpoints `alpha + c(-1, 1) * qnorm(0.975) * alpha_se`.

The methods must not substitute eta-scale intervals, conditional association
curvature, transformed endpoints, an automatic bootstrap, a profile, or a
numerical boundary clamp.  A point with an unavailable private Godambe result,
or a non-interior/boundary association result, is an informative failure rather
than a finite interval.

## Dispatch and failure contract

F5 implementation should first identify an exact validated-route predicate:

1. both frozen margins are fixed-effect ML, complete-pair Bernoulli and
   ordinary-NB2 in either response order;
2. the kernel is `latent_normal()` and the association formula is exactly
   intercept-only; and
3. the association result is interior and its private alpha covariance and SE
   meet the same finite, scalar, positive conditions used by F4.

Only then may the methods return results.  Every other
`drm_pair_association` object keeps the existing informative failure, naming
the unsupported route and explaining that current evidence does not validate
its uncertainty.  This conservative dispatch prevents evidence from one pair
being silently inherited by a broader class.

## Required F5 evidence and tests

F5 begins only after the F4 completion panel independently confirms all 24
cells meet the frozen bias, availability, SE/empirical-SD, coverage, and MCSE
requirements, with all attempts and unavailable results retained.  The F5
change then needs focused tests for:

- a named symmetric 1 x 1 alpha covariance and its numerical equality to the
  private Godambe extraction;
- a 95% alpha-Wald interval with the expected endpoints;
- a clear error for every excluded pair, association slope, eta request,
  boundary/unavailable result, and absent private variance; and
- roxygen/reference rendering that states the exact validated domain and does
  not imply generic mixed-outcome association inference.

Package tests, documentation, and CI must be green before any merge or public
claim.  A passing F4 campaign is evidence for considering F5, not an automatic
exposure decision.
