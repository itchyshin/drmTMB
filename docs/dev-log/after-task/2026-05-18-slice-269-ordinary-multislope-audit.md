# After Task: Slice 269 Ordinary Multi-Slope Audit

## Task

Confirm that ordinary Gaussian `mu` random-slope blocks are not limited to the
first q=3 recovery example, and make the user-facing boundary visible.

## What Changed

- Added a q=4 ordinary Gaussian `mu` random-slope test with syntax
  `(1 + x1 + x2 + x3 | id)`.
- Checked the fitted SD names, six derived correlation names, `corpairs()`
  classes, covariance-block random-effect length, and `profile_targets()`
  status.
- Updated README, model-map, which-scale, Phase 6c design, roadmap, NEWS, and
  the pre-simulation readiness matrix so q > 2 ordinary `mu` blocks are
  described as fitted but sample-size hungry.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/after-task/2026-05-18-slice-269-ordinary-multislope-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-184656-codex-checkpoint.md`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `vignettes/model-map.Rmd`
- `vignettes/which-scale.Rmd`

## Checks

- `air format tests/testthat/test-gaussian-random-intercepts.R README.md NEWS.md ROADMAP.md vignettes/model-map.Rmd vignettes/which-scale.Rmd docs/design/33-phase-6c-core-random-effects.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-269-ordinary-multislope-audit.md docs/dev-log/recovery-checkpoints/2026-05-18-184656-codex-checkpoint.md`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts', reporter = 'summary')"`
- `rg -n "q=4 output-name check|larger ordinary multi-slope|ordinary q > 2 numeric multi-slope|derived-unavailable for direct profile" README.md NEWS.md ROADMAP.md docs/design/33-phase-6c-core-random-effects.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/model-map.Rmd vignettes/which-scale.Rmd tests/testthat/test-gaussian-random-intercepts.R docs/dev-log/check-log.md`
- `rg -n "ordinary q > 2.*planned|ordinary q > 2.*not ready|multi-slope.*planned|q > 2.*unsupported" README.md ROADMAP.md docs/design vignettes NEWS.md --glob '!docs/dev-log/**'`
  returned only neighbouring planned-boundary text on the same rows, not a
  claim that ordinary q > 2 `mu` blocks remain planned.
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept the slice as a confirmation/audit rather than a new random-effects
  feature.
- Boole checked that the syntax stays ordinary grouped `mu` syntax and does not
  imply bivariate, phylogenetic, spatial, or `sigma` covariance expansion.
- Curie kept the new test self-contained and focused on output contracts
  rather than slow recovery.
- Fisher kept q > 2 correlations marked as derived-unavailable for direct
  profile intervals.
- Pat checked README, model-map, and which-scale wording for a user trying to
  fit a reaction-norm model.
- Grace checked focused tests, pkgdown, and diff hygiene.
- Rose checked stale wording around q > 2 being planned or unsupported.

## Known Limits

- The new q=4 test is an output-contract smoke check, not a parameter-recovery
  or coverage simulation.
- Larger q blocks remain advanced fits. Phase 18 still needs grids for
  convergence, weak slope SDs, boundary rates, bias, interval status, and sample
  size before examples teach them as routine.
