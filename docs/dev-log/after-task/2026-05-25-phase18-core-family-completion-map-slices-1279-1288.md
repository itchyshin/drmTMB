# Slices 1279-1288: Phase 18 Core Family Completion Map

## Goal

Ada recorded the next Phase 18 routing decision after the current-state
revalidation through Slices 909-1008: broaden the first public story across core
one-response data types before adding richer covariance or shape syntax.

## What Changed

- Added
  `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`.
- Updated `docs/design/41-phase-18-simulation-programme.md` to register Slices
  1279-1288.
- Updated `ROADMAP.md` to name the next implementation order.
- Updated `docs/dev-log/check-log.md` with the evidence and status answer.

## Status Answer

Counts are close for the first ordinary mixed-model story, but not finished in
the broad ecological sense. Ordinary Poisson/NB2 `mu` random intercepts and
independent slopes are fitted and staged; NB2 log-`sigma` random intercepts are
fitted and staged; Poisson/NB2 q=1 phylogenetic `mu` intercepts have
smoke/formal infrastructure. Zero-inflation random effects, hurdle random
effects, correlated count slopes, count spatial/animal/`relmat()` routes, and
structured count slopes remain planned or unsupported.

Proportions are the next best implementation lane. Fixed-effect `beta()` and
`beta_binomial()` are fitted and have an ADEMP sheet, but they still need the
same DGP/summariser/smoke/grid artifact path that counts already have.

Positive continuous responses are fitted for fixed-effect lognormal and Gamma,
but those families also need Phase 18 artifact lanes before the first public
simulation story is balanced.

Shape data are partly done. Fixed-effect Student-t `nu` is fitted and
simulation-staged. Skew-normal and skew-t are not fitted; they remain planned
gates. `tau` is reserved only for a future second shape parameter, not current
syntax.

## Team Read

- Ada: the next work should be breadth-first across core data types, not another
  deep count covariance extension.
- Boole: `nu` must stay stable as the first shape parameter; do not present
  `skew_normal()` or `skew_t()` syntax as runnable.
- Fisher: proportions and positive-continuous lanes need artifact evidence
  before user-facing simulation claims.
- Pat: users need a measurement-process map: counts, proportions, positive
  continuous responses, ordinal responses, and shape questions.
- Rose: the map prevents nearby fitted cells from being generalized into broad
  non-Gaussian support.

## Validation

This was a documentation and planning slice. No R code changed.

```sh
air format ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-25-phase18-core-family-completion-map-slices-1279-1288.md
git diff --check
```

- `air format` completed without output.
- `git diff --check` was clean.
