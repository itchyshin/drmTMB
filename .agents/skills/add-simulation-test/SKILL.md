---
name: add-simulation-test
description: Add simulation-based parameter-recovery tests for drmTMB models.
---

# Add a Simulation Test

Use this skill when testing model likelihoods, links, and fitting workflows.

## Procedure

1. Simulate data from known parameters.
2. Fit the intended `drmTMB` model.
3. Check convergence diagnostics.
4. Check estimates on the modelled scale and the response scale.
5. Test edge cases that are scientifically likely and numerically risky.

## CRAN-Safe Tests

Keep CRAN tests small and deterministic. Use fixed seeds and moderate
tolerances. Put long simulation studies in `data-raw/` or an optional workflow,
not in routine package checks.

## Required Edge Cases

- `sigma` small and large.
- `rho12` near 0, positive, and negative.
- Factor predictors.
- Missing data handling.
- Shape parameters near weak-identification regions.
