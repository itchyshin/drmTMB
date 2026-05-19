# After Task: Slice 273 Bivariate Random-Slope Boundary Audit

## Goal

Audit bivariate Gaussian random-slope combinations before Phase 18 treats any
bivariate slope grid as fitted.

## Implemented

- Added focused bivariate Gaussian boundary tests for the first planned
  slope-only `mu1`/`mu2` target, intercept-plus-slope q=4 location requests,
  residual-scale slope pairs, same-response location-scale slope combinations,
  and all-four q=8-style slope requests.
- Updated the Phase 6c random-effect design note, pre-simulation readiness
  matrix, roadmap, and NEWS so the new evidence reads as rejection coverage, not
  fitting support.

## Mathematical Contract

The implemented bivariate Gaussian random-effect covariance paths remain
intercept-only: matching labelled `mu1`/`mu2`, matching labelled
`sigma1`/`sigma2`, one same-response `mu`/`sigma` pair, and all-four
`mu1`/`mu2`/`sigma1`/`sigma2` intercept blocks. Slice 273 does not add a
random-slope likelihood. Matching slope-only `mu1`/`mu2` blocks remain the first
future target, while intercept-plus-slope q=4 and all-four q=8-style
location-scale slope blocks stay closed until recovery, diagnostics,
`corpairs()`, and interval targets exist.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/after-task/2026-05-18-slice-273-bivariate-slope-boundary.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-193146-codex-checkpoint.md`
- `tests/testthat/test-biv-gaussian.R`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/33-phase-6c-core-random-effects.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-273-bivariate-slope-boundary.md docs/dev-log/recovery-checkpoints/2026-05-18-193146-codex-checkpoint.md tests/testthat/test-biv-gaussian.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian', reporter = 'summary')"`:
  passed.
- `rg -n 'Slice 273|Bivariate random-slope combination|slope-only|q=8-style|Residual-scale random slopes|same-response location-scale|location-scale covariance blocks are intercept-only|bivariate slope grid|bivariate Gaussian boundary tests' NEWS.md ROADMAP.md docs/design/33-phase-6c-core-random-effects.md docs/design/46-pre-simulation-readiness-matrix.md tests/testthat/test-biv-gaussian.R`:
  confirmed the test, roadmap, NEWS, and readiness-matrix boundary text.
- `rg -n 'bivariate random slopes.*implemented|slope1-slope2.*implemented|q=8.*implemented|residual-scale slope.*implemented|same-response location-scale slope.*implemented|bivariate slope grid.*ready' README.md ROADMAP.md NEWS.md docs/design vignettes tests/testthat --glob '!docs/dev-log/**'`:
  returned only planned-context wording, not a bivariate slope implementation
  claim.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 273 bivariate random-slope boundary" --next "stage, commit, push, and open draft PR"`:
  wrote `docs/dev-log/recovery-checkpoints/2026-05-18-193146-codex-checkpoint.md`.

## Tests Of The Tests

The new cases would fail if slope-only `mu1`/`mu2` syntax started fitting before
its output contract existed, if q=4 location-slope or q=8-style all-four slope
requests bypassed the intercept-only guard, or if bivariate residual-scale
random slopes entered the likelihood without the intended diagnostics and
interval targets.

## Consistency Audit

Ada kept the slice as a boundary audit. Boole checked that the error messages
name the first future target and the closed q=4/q=8 neighbours. Fisher kept
Phase 18 simulation admission tied to fitted random-intercept covariance only.
Curie added malformed-neighbour tests rather than a broad simulation. Pat
checked that readers see what smaller model to fit today. Grace checked the
focused test file, pkgdown, and diff hygiene. Rose checked stale wording for
accidental bivariate slope implementation claims.

## Known Limitations

- No bivariate random-slope likelihood was added.
- No slope1-slope2 `corpairs()` row, coefficient-aware `corpair()` syntax,
  direct slope-correlation profile target, or simulation recovery grid was added.
- Same-response location-scale slope covariance and all-four q=8-style
  location-scale slope covariance remain planned.

## Next Actions

Slice 274 should move to convergence controls and keep these bivariate slope
boundaries out of any robust-control examples unless a separate implementation
slice lands first.
