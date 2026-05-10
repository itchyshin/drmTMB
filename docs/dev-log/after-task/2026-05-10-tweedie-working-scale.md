# After Task: Tweedie Working Scale Recommendation

## Goal

Turn the Tweedie wish-list note from an unresolved scale choice into a clearer
working recommendation while keeping the family future-only.

## Implemented

- Recorded `sigma = sqrt(phi)` as the current working recommendation in the
  Tweedie design gate.
- Clarified that first implementation should use intercept-only `nu ~ 1`.
- Updated the roadmap, distribution roadmap, family registry, and design-gate
  after-task report.
- Created GitHub issue #2 for future Tweedie implementation tracking.

## Mathematical Contract

No likelihood or formula grammar changed. The future working contract is:

```text
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

The comparator scale remains Tweedie dispersion `phi`, so tests against
software that reports `phi` should compare `sigma^2` with `phi`.

## Team Review

Noether, Boole, and Curie agreed that `sigma = sqrt(phi)` is the cleaner
working direction because it keeps `sigma` scale-like for users. Boole also
recommended `nu ~ 1` for the first implementation, with predictor-dependent
`nu` deferred until identifiability and optimizer behaviour are clearer. Curie
recommended separating fast CRAN-safe recovery tests from longer optional
Tweedie recovery grids.

## Known Limitations

No Tweedie likelihood, exported family helper, simulation method, comparator
test, or real-data tutorial exists yet.
