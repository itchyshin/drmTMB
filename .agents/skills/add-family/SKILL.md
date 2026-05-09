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
- Update to `docs/design/19-family-link-contract.md` when the family adds a
  new link, fitted-response rule, variance rule, or parameter meaning.

## Checklist

1. Define response dimension: univariate or bivariate.
2. Define distributional parameters.
3. Define links and inverse links.
4. Define native parameter meanings.
5. Define what `predict(type = "response")`, `fitted()`, and `sigma()` return.
6. Define the variance rule or explain why no finite variance is available.
7. Define valid parameter bounds.
8. Write likelihood on numerically stable scales.
9. Add starting-value strategy.
10. Add simulation tests for typical and boundary cases.
11. Add tests for link-scale predictions, response-scale predictions, and
    fitted response summaries.
12. Add user-facing documentation.

Do not add families just because they are available elsewhere. Families should
serve a clear distributional-regression use case.
