# After-Task Report: Parallel Correlated Random-Block Design

Date: 2026-05-07

## Task

Use the parallel review team to prepare the next correlated random-effect block
phase without editing the TMB likelihood prematurely.

## Parallel Team Inputs

- Jason reviewed related package designs in `lme4`, `glmmTMB`, `brms`, and
  local `gllvmTMB`.
- Gauss proposed the TMB data structures and non-centered parameterization for
  ordinary correlated Gaussian `mu` blocks.
- Curie designed simulation and comparator tests for `(1 + x | id)`.
- Rose audited docs and logs for stale wording around `rho12`, random slopes,
  future grammar, and comparator claims.

## Outcome

Created `docs/design/17-correlated-random-effect-blocks.md` as the
source-of-truth design target for the next feature.

Core decision:

```r
bf(y ~ x + (1 + x | id), sigma ~ z)
```

will mean a correlated ordinary random intercept and random slope, matching the
usual `lme4`/`glmmTMB` semantics.

The current independent syntax remains:

```r
bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ z)
```

Labelled blocks such as `(1 + x | p | id)` remain a later extension for
cross-formula or cross-parameter group-level covariance. The label is not a
grouping variable and is not residual `rho12`.

## Rose Audit Fixes

Applied wording fixes for:

- generic `rho` wording that should be `rho12`;
- `X_rho` notation that should be `X_rho12`;
- future grammar written as if it were current API;
- ambiguous "single numeric random slopes" wording;
- stale "future random-slope SD" wording;
- missing user-facing phylogenetic/spatial structured-slope staging;
- comparator results that should state optional package tests can skip.

## Validation

Commands run:

```text
git diff --check
rg stale-wording scans
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
```

Results:

- `git diff --check`: passed;
- stale-wording scans: remaining matches are only in audit/check-log text that
  documents the wording issues, not active user-facing guidance;
- `devtools::test()`: 191 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: built the local site successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

## Tests Of The Tests

This task did not add executable tests because it was a design and audit phase.
It constrained the next implementation phase by specifying required comparator
tests against `lme4`, simulation recovery tests for positive, negative, and
near-zero group-level correlations, and malformed-input tests for ambiguous
random-effect syntax.

## What Did Not Go Smoothly

- The app assigned auto nicknames to spawned agents that did not match our
  standing team names. I tracked outputs by assigned role rather than nickname.
- The first spawn attempt tried to combine full-history forking with named
  specialist agents, which the app rejected. The second attempt passed explicit
  context and worked.

## Team Learning

- Parallel agents are most valuable for bounded read-only tasks: landscape
  scouting, TMB design review, simulation planning, and systems audit.
- Implementation tasks that touch the same parser/TMB/test files should stay
  integrated by Ada or be split into disjoint file ownership.
- Rose's stale-wording scan should become a routine part of every random-effect
  phase.

## Known Limitations

- Correlated random-effect covariance blocks such as `(1 + x | id)` are still
  not implemented.
- Labelled covariance blocks such as `(1 + x | p | id)` remain a later
  extension.
- This design covers ordinary Gaussian `mu` blocks first; phylogenetic and
  spatial structured slopes need separate simulation evidence before
  implementation.

## Next Actions

- Implement ordinary unlabelled Gaussian `mu` `(1 + x | id)` blocks.
- Add strict `lme4` comparator tests for the overlapping Gaussian ML model.
- Add simulation recovery and malformed-syntax tests before changing public
  examples to show the new block as implemented.
