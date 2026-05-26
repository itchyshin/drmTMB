# Phase 18 Current-State Revalidation Through Slices 909-1008

## Goal

Ada rehydrated the crashed Phase 18 handoff, treated the older May 20
implementation notes for Slices 909-1008 as historical evidence, and checked
whether the current source still supports stopping at the broader focused
validation gate.

No implementation code changed for this revalidation.

## Repository State

The latest recovery checkpoint before this pass said the Phase 18 first-wave
summary validation had advanced through Slices 899-908 and recommended
continuing with the rendered `n_rep = 2` reusable-runner smoke for Slices
909-918.

The current source already records Slices 909-1008 in
`docs/design/41-phase-18-simulation-programme.md`, with old May 20 after-task
notes for each slice. This pass did not rewrite those slice notes.

## Artifact Check

The saved rendered smoke reports are present for the historical 909-1008 lane:

- `inst/sim/results/slice-909-first-wave-runner-nrep2-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- `inst/sim/results/slice-919-first-wave-runner-four-surface-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- `inst/sim/results/slice-929-first-wave-runner-five-surface-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- `inst/sim/results/slice-939-first-wave-runner-six-surface-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- `inst/sim/results/slice-949-first-wave-runner-six-surface-nrep2-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- `inst/sim/results/slice-959-interval-heavy-runner-smoke/interval-heavy-summary/report/phase18-first-wave-summary.html`
- `inst/sim/results/slice-969-interval-heavy-profile-smoke/interval-heavy-summary/report/phase18-first-wave-summary.html`
- `inst/sim/results/slice-979-interval-heavy-bootstrap-smoke/interval-heavy-summary/report/phase18-first-wave-summary.html`

## Current Validation

Command:

```sh
Rscript -e "devtools::test(filter = '^phase18-', reporter = 'summary')"
```

Result:

- Passed with exit code 0.
- The run covered the current Phase 18 focused suite, including first-wave
  report staging, interval-heavy staging, Student-t shape, bivariate residual
  `rho12`, Poisson/NB2 random-effect surfaces, Poisson/NB2 q1 phylogenetic
  surfaces, Gaussian random slopes, spatial `mu` slopes, meta-analysis, and
  simulation infrastructure tests.

## Non-Gaussian Status Answer

The current status is partial, not complete across all non-Gaussian families.

Implemented and tested:

- ordinary non-zero-inflated Poisson and NB2 `mu` random intercepts;
- ordinary Poisson and NB2 `mu` independent numeric random slopes;
- ordinary NB2 log-`sigma` random intercepts;
- ordinary Poisson and NB2 q=1 phylogenetic `mu` intercepts.

Still planned or unsupported:

- non-Gaussian structured slopes such as Poisson/NB2 `phylo(1 + x | ...)`;
- non-Gaussian spatial, animal, and `relmat()` structured effects outside the
  admitted q=1 phylogenetic `mu` intercept gates;
- NB2 `sigma` slopes, structured NB2 `sigma`, zero-inflated or hurdle
  random-effect routes, mixed-response bivariate non-Gaussian models, and most
  non-Gaussian random-effect covariance.

So the answer to "did we finish all the non-Gaussian stuff with random
intercept and maybe at least one random slope?" is: no, not all of it. The
ordinary Poisson/NB2 `mu` random-intercept plus independent-slope lane is fitted
and tested, NB2 log-`sigma` has an ordinary random-intercept gate, and q=1
Poisson/NB2 phylogenetic `mu` intercepts have smoke/formal evidence. Structured
non-Gaussian slopes and broader non-Gaussian random-effect covariance remain
deliberately closed.

## Team Read

- Ada: stop at the 1008 gate and plan again before adding or rerunning larger
  grids.
- Boole: keep the public syntax narrow; do not blur ordinary `(0 + x | id)`
  count slopes with structured `phylo(1 + x | id)` slopes.
- Fisher: the 909-1008 evidence is smoke and focused-validation evidence, not
  final operating-characteristic evidence.
- Curie: the current `^phase18-` pass is the right current-state guard before a
  planning reset.
- Grace: no new multicore work was launched beyond the focused test suite.
- Rose: the next plan should explicitly separate ordinary non-Gaussian mixed
  effects from structured non-Gaussian effects.

## Next Planning Boundary

Plan before continuing. The next decision should choose whether to:

1. refresh the post-1008 health gates on the current tree: full tests,
   pkgdown, and package check;
2. build a small formal-admission lane for one non-Gaussian structured
   extension, probably a narrow q=1/q2 target with explicit exclusion tests; or
3. stop Phase 18 implementation work and split the dirty tree into small
   reviewable pull requests before any new model surface.
