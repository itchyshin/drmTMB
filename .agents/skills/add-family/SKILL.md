---
name: add-family
description: Add a new drmTMB distribution family with likelihood, simulation, tests, and documentation.
---

# Add a Distribution Family

Use this skill when adding a new response family to `drmTMB`.

## Required Outputs

- R family constructor.
- TMB density implementation or template integration.
- Simulation function.
- Parameter-recovery tests.
- Documentation and examples.
- Update to `docs/design/02-family-registry.md`.
- Update to `docs/design/03-likelihoods.md`.

## Checklist

1. Define response dimension: univariate or bivariate.
2. Define distributional parameters.
3. Define links and inverse links.
4. Define valid parameter bounds.
5. Write likelihood on numerically stable scales.
6. Add starting-value strategy.
7. Add simulation tests for typical and boundary cases.
8. Add user-facing documentation.

Do not add families just because they are available elsewhere. Families should
serve a clear distributional-regression use case.
