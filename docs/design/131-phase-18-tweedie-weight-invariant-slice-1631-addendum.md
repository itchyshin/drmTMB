# Phase 18 Tweedie Weight Invariant, Slice 1631 Addendum

This note adds implementation evidence after the comparator-boundary decision
in `docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md`.
Its reader is the package contributor who needs to distinguish an internal
row-weight invariant from an external weighted comparator.

## Decision

The weighted `glmmTMB::tweedie()` comparator remains postponed until a future
slice names both packages' weighting semantics and log-likelihood attributes.
This addendum does not change that decision.

The package can still test its own row-weight contract now. For fitted
Tweedie fixed-effect models, top-level `weights =` should behave as ordinary
row log-likelihood multipliers:

```text
logLik(weights = 2) = 2 * logLik(weights = 1)
integer row weights = explicit row duplication
```

`tests/testthat/test-tweedie-location-scale.R` now checks those invariants for
`bf(y ~ x, sigma ~ z, nu ~ 1)`, including `mu`, `sigma`, intercept-only `nu`,
stored `weights()`, and log-likelihood.

## Closed Boundaries

This test does not compare weighted fits across packages. It does not add
Tweedie offsets, predictor-dependent `nu`, random effects, structured effects,
bivariate Tweedie, zero-inflation aliases, or hurdle aliases.
