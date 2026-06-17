# After Task: log(sigma) clamp sensitivity pilot

## Goal

Turn Hao Qin's numerical-guard concern into executable evidence without touching
the Claude-owned Gaussian density seam. The first slice asks a narrow question:
for fixed-effect Gaussian location-scale models, does the exposed
`drm_control(logsigma_clamp = ...)` knob show that the default clamp is
negligible when inactive and consequential when it binds?

## Implemented

- Added the artifact
  `docs/dev-log/simulation-artifacts/2026-06-17-logsigma-clamp-sensitivity-pilot/`.
- Committed `run-pilot.R` beside the artifact so the CSVs, session info, and
  diagnostic PNG can be regenerated from the worktree.
- Ran four fixed-effect Gaussian cells: ordinary scale, large scale still inside
  the default identity band, legitimate huge scale above the default band, and
  legitimate tiny scale below the default band.
- Compared three configurations: `logsigma_clamp = NULL`, default
  `c(-12, 12)` with margin 3, and wide `c(-25, 25)` with margin 3.
- Updated the numerical-guard design note and mission-control dashboard so the
  row is now `partial` for simulation/visual evidence rather than merely
  planned.

## Results

The pilot attempted 300 fits and returned 300 `ok` rows. There were no error
rows and no captured warnings.

- Default versus unclamped, inactive cells: maximum `logLik` difference
  `2.046363e-11`; maximum `sigma` intercept difference `1.168681e-08`.
- Wide versus unclamped, all cells: maximum `logLik` difference `0`; maximum
  `sigma` intercept difference `0`.
- Default versus unclamped, binding cells: maximum `logLik` difference
  `526.8952`; maximum `sigma` intercept difference `32.38647`.
- The upper out-of-band cell had default clamp activation rate `1.00`,
  convergence rate `1.00`, and `pdHess` rate `1.00`, showing why convergence
  alone is not enough when a guard is active.
- The lower out-of-band cell had default clamp activation rate `1.00`,
  convergence rate `0.00`, and `pdHess` rate `1.00`, showing that Hessian status
  and optimizer status need to be read together.

## Checks Run

```sh
Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-17-logsigma-clamp-sensitivity-pilot/run-pilot.R
```

Additional validation follows in the PR checklist: JSON parsing, mission-control
validator, served artifact link, browser DOM check, conflict-marker scan,
forbidden-framing scan, and `git diff --check`.

## Boundary

This is not a broad numerical-guard promotion study. It covers only fixed-effect
Gaussian `sigma ~ x` models and only the configurable `log(sigma)` clamp. It
does not test scale-side phylogenetic fields, random effects, bivariate scale
routes, Student-t finite-variance restrictions, beta support floors, correlation
open-interval guards, interval coverage, or release readiness.

## Team

Gauss and Fisher framed the numerical question, Curie kept the pilot small and
replicable, Rose kept the claim boundary visible, Grace checked artifact
provenance, Florence required the diagnostic plot, Pat kept the user-facing rule
plain, and Ada kept the slice out of the Claude-owned engine seam.
