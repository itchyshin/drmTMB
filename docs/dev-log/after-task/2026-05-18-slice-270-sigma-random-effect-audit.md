# After Task: Slice 270 Sigma Random-Effect Audit

## Task

Confirm the fitted Gaussian `sigma` random-effect boundary for independent
residual-scale slope terms, and keep correlated residual-scale slope covariance
outside the implemented claim.

## What Changed

- Added a cross-group Gaussian `sigma` test with
  `sigma ~ z + (0 + w_id | id) + (0 + w_site | site)`.
- Checked that the two residual-scale slope SDs are named, finite, direct
  `log_sd_sigma` profile targets, and that no residual-scale correlation rows
  are produced.
- Updated README, model-map, which-scale, Phase 6c design, roadmap, NEWS, and
  the pre-simulation readiness matrix so multiple independent `sigma` slopes
  are visible while correlated residual-scale slope blocks remain planned.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/after-task/2026-05-18-slice-270-sigma-random-effect-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-185313-codex-checkpoint.md`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `vignettes/model-map.Rmd`
- `vignettes/which-scale.Rmd`

## Checks

- `air format tests/testthat/test-gaussian-random-intercepts.R README.md NEWS.md ROADMAP.md vignettes/model-map.Rmd vignettes/which-scale.Rmd docs/design/33-phase-6c-core-random-effects.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-270-sigma-random-effect-audit.md docs/dev-log/recovery-checkpoints/2026-05-18-185313-codex-checkpoint.md`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts', reporter = 'summary')"`
- `rg -n "cross-group Gaussian sigma|multiple independent sigma slopes|0 \\+ w_id|0 \\+ w_site|log_sd_sigma" README.md NEWS.md ROADMAP.md docs/design/33-phase-6c-core-random-effects.md docs/design/46-pre-simulation-readiness-matrix.md vignettes/model-map.Rmd vignettes/which-scale.Rmd tests/testthat/test-gaussian-random-intercepts.R docs/dev-log/check-log.md`
- `rg -n "correlated residual-scale slope blocks.*fitted|residual-scale slope covariance.*implemented|cor:sigma" README.md ROADMAP.md NEWS.md docs/design vignettes tests/testthat/test-gaussian-random-intercepts.R --glob '!docs/dev-log/**'`
  returned only the separate bivariate `sigma1`/`sigma2` namespace and explicit
  `expect_false()` checks for residual-scale `cor:sigma` rows.
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept this as a boundary confirmation, not a new correlated `sigma`
  covariance feature.
- Boole checked that the syntax stays inside ordinary independent
  residual-scale terms.
- Curie kept the new test focused on two grouping factors, output names, and
  profile-target status.
- Fisher kept residual-scale correlations absent until there is a direct
  covariance model and interval plan.
- Pat checked README, model-map, and which-scale wording for a user deciding
  whether `sigma` or `sd(group)` is the right scale.
- Grace checked focused tests, pkgdown, and diff hygiene.
- Rose checked stale wording around correlated residual-scale slope covariance.

## Known Limits

- The new test is an output-contract check, not a full residual-scale slope
  recovery simulation.
- Correlated residual-scale slope blocks, labelled residual-scale slope
  covariance, and slope-level `mu`/`sigma` covariance remain planned.
