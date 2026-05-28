# Phase 18 Comparator And Support-Boundary Decisions, Slices 1631-1632 and 1685-1686

This note records the next two-team design decisions after the semantic
boundary tests. Its reader is the contributor deciding whether the next slice
should add more comparator tests or start source-level skew-normal density
tests.

## Team A: Tweedie Weights And Offsets

Top-level `weights =` already reaches the fitted Tweedie likelihood through
the shared row log-likelihood multiplier path. The TMB branch multiplies each
Tweedie row contribution by `weights(i)`, and the R builder filters weights
with the same model rows as the response and predictors.

Do not add a weighted `glmmTMB::tweedie()` comparator cell in the current
zero-regime fixture. Weighted comparison needs a separate source check that
names both packages' weighting semantics, confirms whether reported
log-likelihood attributes are directly comparable, and chooses integer
duplication or explicit row multipliers as the independent target. Until that
check is written, the existing unweighted `glmmTMB` comparator remains the
honest cross-package overlap.

Offsets also stay outside the first Tweedie comparator pass. The current
formula grammar implements standard R `offset(log(exposure))` in the `mu`
formula for count-family exposure models such as Poisson and NB2. The Tweedie
builder rejects `offset()` through the shared phase-one unsupported-term gate.
Opening Tweedie offsets would require an explicit positive-exposure
interpretation, prediction-offset tests, and documentation. It should not be
bundled into comparator hardening.

## Team B: Skew-Normal Support And Rank Decisions

The first skew-normal implementation should accept one finite continuous
response after ordinary model-frame filtering. Missing response or predictor
rows should be removed before support validation, matching the current
family-builder pattern used by fitted univariate families. Non-finite response
values should fail after filtering. There is no bounded support beyond the
real line.

Rank-deficiency handling should use the shared fixed-effect design-matrix and
optimization infrastructure at first. Do not add a skew-normal-specific rank
policy before density normalization, normal-limit, sign-orientation, and
false-positive tests exist. If those tests reveal a family-specific weak
identification pattern for `nu`, record that as a diagnostic or starting-value
issue rather than changing formula grammar.

## Slice Status

| Slice | Status | Evidence |
| --- | --- | --- |
| 1631 | Done | Weighted Tweedie comparison is postponed until a dedicated row-weighting comparator target is specified. |
| 1632 | Done | Tweedie offsets stay outside the first comparator pass because offset syntax is currently count-family `mu` exposure syntax. |
| 1685 | Done | Future skew-normal support validation should run after model-frame filtering and require finite continuous responses. |
| 1686 | Done | Skew-normal rank-deficiency handling should initially use shared fixed-effect infrastructure unless density tests expose a family-specific issue. |

## Closed Boundaries

This slice does not add weighted Tweedie comparator tests, Tweedie offsets,
`nu ~ x`, random effects, structured effects, bivariate Tweedie, or any
skew-normal code. It also does not add `skew_normal()`, `skew ~ x`,
`skew(id) ~ x`, `rho12`, bivariate skew-normal, mixed responses, or C++
density code.
