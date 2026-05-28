# Phase 18 Semantic Boundary Tests, Slices 1629-1630 and 1687-1688

This note records a narrow test pass after the Tweedie zero-regime comparator
and the skew-normal first-test contract merged. Its reader is the R package
contributor who needs to know which semantics were hardened without opening a
new likelihood surface.

## Team A: Tweedie Semantics

The optional `glmmTMB` comparator cells now reassert two public semantics
inside both low-zero and high-zero regimes:

```text
fitted(fit) = predict(fit, dpar = "mu")
1 < predict(fit, dpar = "nu", type = "response") < 2
```

The response-scale `nu` assertion also checks the inverse-link transform from
the internal link scale. This keeps `fitted()` tied to the unconditional
Tweedie mean `mu`, not a positive conditional mean, and keeps `nu` as the
Tweedie power parameter. The test still does not admit predictor-dependent
`nu`, random effects, structured effects, bivariate Tweedie, zero-inflation
aliases, or hurdle aliases.

## Team B: Skew-Normal No-Fit Boundary

`tests/testthat/test-skew-normal-boundary.R` already required
`skew_normal()` to be absent from the package namespace and checked the source
map for planned-only wording. It now also reads
`docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md` and
checks that the first-test contract:

- labels the example syntax as planned, not fitted;
- keeps the `skew_normal()` constructor absent;
- records no-C++ admission criteria;
- keeps `rho12` outside the first skew-normal lane.

This is still a design-only boundary. It does not add a constructor, R builder,
TMB family enum, source branch, density helper, reference page, or runnable
example.

## Slice Status

| Slice | Status | Evidence |
| --- | --- | --- |
| 1629 | Done | Low-zero and high-zero comparator cells now assert `fitted(fit) == predict(fit, dpar = "mu")`. |
| 1630 | Done | Low-zero and high-zero comparator cells now assert response-scale `nu` stays in `(1, 2)` and matches the inverse-link transform. |
| 1687 | Done | The skew-normal boundary test reads the first-test contract as part of the no-fit boundary scan. |
| 1688 | Done | The boundary test still requires `skew_normal()` to be absent from the namespace. |

## What Remains Closed

Team A has not opened Tweedie `nu ~ x`, random effects, structured effects,
bivariate Tweedie, zero-inflation aliases, or hurdle aliases. Team B has not
opened `skew_normal()`, `skew ~ x`, `skew(id) ~ x`, `rho12`, bivariate
skew-normal, composed families, mixed responses, or C++ density code.
