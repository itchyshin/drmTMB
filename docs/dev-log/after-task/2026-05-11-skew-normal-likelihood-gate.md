# After-Task Report: Skew-Normal Likelihood Gate

## Task

Record the first design gate for issue #3 before implementing
`skew_normal()`.

## Reader

This note is for R package contributors and statistical method developers who
need to see the likelihood contract before touching parser, family registry, or
TMB code.

## What Changed

- Added a planned skew-normal location-scale-shape section to
  `docs/design/03-likelihoods.md`.
- Recorded the candidate Azzalini-style density, response-scale transforms, and
  `nu` sign convention.
- Added a planned `skew_normal()` registry contract to
  `docs/design/02-family-registry.md`, using canonical `mu`, `sigma`, and
  `nu`.
- Kept the change documentation-only; no family constructor, parser route, TMB
  branch, examples, or tests were added.

## Design Decisions

The proposed first implementation uses `nu` as the unrestricted native
asymmetry parameter. Positive `nu` means right-skewed residuals, `nu = 0`
recovers the Gaussian location-scale likelihood, and negative `nu` means
left-skewed residuals. The design notes label this as a comparator-check
requirement so implementation work does not silently swap the sign convention.

The notes also separate skew-normal location `mu` from the arithmetic response
mean. If `fitted()` returns response means for this family, implementation must
use the documented mean formula instead of returning the native location when
`nu != 0`.

## Checks Run

- `air format docs/design/03-likelihoods.md docs/design/02-family-registry.md docs/dev-log/after-task/2026-05-11-skew-normal-likelihood-gate.md docs/dev-log/check-log.md`:
  passed.
- `rg -n "Planned Skew-Normal|skew_normal\\(|nu_i = eta_nu_i|right-skewed|left-skewed|issue #3" docs/design/03-likelihoods.md docs/design/02-family-registry.md docs/design/14-gamlss-parameter-names.md docs/design/19-phylogenetic-location-scale-shape.md docs/dev-log/after-task/2026-05-11-skew-normal-likelihood-gate.md`:
  confirmed the design contract and existing naming notes.
- `git diff --check`: passed.

## Known Limitations

- This does not implement `skew_normal()`.
- The `nu` sign convention still needs a comparator check before code is added.
- Simulation recovery, malformed-input tests, normal-limit tests, and
  false-positive heteroscedasticity checks remain issue #3 implementation work.
