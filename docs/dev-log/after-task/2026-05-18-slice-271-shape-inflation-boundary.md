# After Task: Slice 271 Shape and Inflation Boundary Audit

## Task

Audit shape and inflation random-effect slopes before Phase 18, and only open a
likelihood path if the model is identifiable and already designed.

## What Changed

- Kept shape and inflation random-effect slopes blocked rather than adding a
  new likelihood.
- Added random-slope-specific boundary tests for zero-inflated Poisson,
  zero-inflated NB2, hurdle NB2, beta `zoi`/`coi`, and beta-binomial
  `zoi`/`coi` requests.
- Preserved the existing Student-t `nu` random-intercept and random-slope shape
  boundary.
- Updated the validation-debt register, pre-simulation readiness matrix,
  roadmap, NEWS, and check log, with the recovery checkpoint recorded for
  handoff.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/after-task/2026-05-18-slice-271-shape-inflation-boundary.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-185741-codex-checkpoint.md`
- `tests/testthat/test-beta-binomial.R`
- `tests/testthat/test-beta-location-scale.R`
- `tests/testthat/test-hurdle-nbinom2.R`
- `tests/testthat/test-zi-nbinom2.R`
- `tests/testthat/test-zi-poisson.R`

## Checks

- `air format tests/testthat/test-student-location-scale.R tests/testthat/test-zi-poisson.R tests/testthat/test-zi-nbinom2.R tests/testthat/test-hurdle-nbinom2.R tests/testthat/test-beta-location-scale.R tests/testthat/test-beta-binomial.R NEWS.md ROADMAP.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-271-shape-inflation-boundary.md docs/dev-log/recovery-checkpoints/2026-05-18-185741-codex-checkpoint.md`
- `Rscript -e "devtools::test(filter = 'student-location-scale|zi-poisson|zi-nbinom2|hurdle-nbinom2|beta-location-scale|beta-binomial', reporter = 'summary')"`
- `rg -n "Slice 271|random-slope-specific|nu.*random-slope|zi.*random-slope|hu.*random-slope|zoi|coi|shape-specific test gate" NEWS.md ROADMAP.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md tests/testthat/test-student-location-scale.R tests/testthat/test-zi-poisson.R tests/testthat/test-zi-nbinom2.R tests/testthat/test-hurdle-nbinom2.R tests/testthat/test-beta-location-scale.R tests/testthat/test-beta-binomial.R docs/dev-log/check-log.md`
- `rg -n "nu.*random effects.*implemented|zi.*random effects.*implemented|hu.*random effects.*implemented|zoi.*implemented|coi.*implemented|shape random effects.*fitted|inflation random effects.*fitted" README.md ROADMAP.md NEWS.md docs/design vignettes tests/testthat --glob '!docs/dev-log/**'`
  returned only negative, fixed-effect, or future-evidence boundary wording,
  not fitted shape or inflation random-effect claims.
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept the slice as an audit and stopped short of unsupported likelihood
  work.
- Boole checked that the blocked grammar remains component-specific rather than
  a generic parse failure.
- Curie broadened tests to random-slope requests across `zi`, `hu`, `zoi`, and
  `coi`.
- Fisher kept the identifiability bar high for shape, inflation, hurdle, and
  one-inflation random effects.
- Pat checked the readiness wording: the reader sees what smaller model to fit
  next.
- Grace checked focused tests, pkgdown, and diff hygiene.
- Rose checked stale claims that these paths might be implemented.

## Known Limits

- No shape, zero-inflation, hurdle, zero-one-inflation, or one-inflation
  random-effect likelihood was added.
- Future work needs fixed-effect likelihood recovery where missing, then
  extractor, interval, diagnostic, weak-boundary, and simulation evidence before
  any random-effect slope in these components enters Phase 18 grids.
