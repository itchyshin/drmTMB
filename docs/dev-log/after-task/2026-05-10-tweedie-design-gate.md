# After Task: Tweedie Design Gate

## Goal

Turn the Tweedie real-data wish-list item into a concrete design gate without
implying that `drmTMB` can already fit Tweedie models.

## Implemented

- Added `docs/design/27-tweedie-family-plan.md`.
- Linked the design gate from `ROADMAP.md`.
- Linked the design gate from `docs/design/06-distribution-roadmap.md`.

## Mathematical Contract

No likelihood or formula grammar changed. The future candidate contract is
documented as:

```text
E[y_i] = mu_i
Var[y_i] = phi_i * mu_i^nu_i
1 < nu_i < 2
```

The design note originally left the public `sigma` mapping unresolved. A
follow-up team review now records `sigma = sqrt(phi)` as the working
recommendation, pending owner confirmation before likelihood code lands:

```text
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

## Files Changed

- `ROADMAP.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/27-tweedie-family-plan.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-tweedie-design-gate.md`

## Checks Run

- Web source check: glmmTMB family documentation lists
  `tweedie(link = "log")`, writes `V = phi * mu^power`, and restricts power to
  `1 < power < 2`.
- Web source check: glmmTMB `family_params()` documentation describes Tweedie
  power as an additional family-specific parameter.
- Prose-style review lens applied for applied eco-evo readers and package
  contributors.

## Tests Of The Tests

This was design documentation only, so no model tests were added. The useful
check is whether the note blocks premature implementation until the `sigma`
scale, density, simulation, comparator, and provenance questions are answered.

## Consistency Audit

The note says `tweedie()` is not implemented, keeps `sigma` and `nu` terminology
stable, and does not add examples to user-facing tutorials. It keeps the first
implementation univariate and fixed-effect only, consistent with the package's
one-response/two-response scope.

## What Did Not Go Smoothly

The main risk was making future syntax look runnable. The note marks the
`nu ~ 1` example as future syntax and keeps implementation out of this patch.

## Team Learning

Darwin's reader lens matters for family prioritization: Tweedie is useful
because it maps to common field responses, not because it expands the family
list. Noether and Fisher should own the scale mapping and comparator tests
before Gauss works on likelihood code.

## Known Limitations

No Tweedie likelihood, exported family helper, simulation path, or comparator
test exists yet.

## Next Actions

- Confirm or revise the working recommendation that public `sigma` is
  `sqrt(phi)`.
- Add likelihood equations and simulation design before implementation.
- Choose one real eco-evo teaching dataset after simulated recovery tests pass.
