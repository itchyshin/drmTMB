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

## Team B: Skew-Normal First-Slice Boundary

This note originally recorded the pre-implementation skew-normal boundary.
The 2026-06-08 fixed-effect first slice superseded that gate:
`tests/testthat/test-skew-normal-boundary.R` was replaced by
`tests/testthat/test-skew-normal-location-scale.R` plus the density-contract
tests. Those tests now check that the first-slice contract:

- admits the exported `skew_normal()` constructor only for fixed-effect
  `mu`, `sigma`, and `nu` formulas;
- checks the density normalization, Gaussian normal limit, sign orientation,
  independent objective calculation, simulation, residuals, and methods;
- keeps `rho12` outside the first skew-normal lane.

This is still a narrow boundary. It does not admit random effects, structured
effects, known sampling covariance, bivariate skew-normal models, composed
families, mixed responses, residual `rho12`, or latent `skew(id)` syntax.

## Slice Status

| Slice | Status | Evidence |
| --- | --- | --- |
| 1629 | Done | Low-zero and high-zero comparator cells now assert `fitted(fit) == predict(fit, dpar = "mu")`. |
| 1630 | Done | Low-zero and high-zero comparator cells now assert response-scale `nu` stays in `(1, 2)` and matches the inverse-link transform. |
| 1687 | Superseded | The first-slice tests read the first-test contract as an implemented fixed-effect boundary. |
| 1688 | Superseded | The boundary now expects the exported constructor and rejects unsupported neighbouring syntax. |

## What Remains Closed

Team A has not opened Tweedie `nu ~ x`, random effects, structured effects,
bivariate Tweedie, zero-inflation aliases, or hurdle aliases. Team B has opened
only fixed-effect `skew_normal()` with `mu`, `sigma`, and `nu`; it has not
opened `skew ~ x`, `skew(id) ~ x`, `rho12`, random effects, structured
effects, bivariate skew-normal, composed families, or mixed responses.
