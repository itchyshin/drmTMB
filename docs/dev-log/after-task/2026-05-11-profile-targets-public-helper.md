# After Task: Public Profile Target Discovery

## Goal

Give users a supported way to discover valid `confint()` and
profile-likelihood target names before they run an expensive profile.

## Implemented

- Added exported `profile_targets()` in `R/profile.R`.
- `profile_targets(fit)` returns the fitted-model target table used by the
  profile/confidence-interval machinery.
- `profile_targets(fit, ready_only = TRUE)` keeps only rows whose
  `profile_ready` column is `TRUE`.
- Invalid inputs now fail clearly when `object` is not a `drmTMB` fit or
  `ready_only` is not a single logical value.
- `NAMESPACE`, `man/profile_targets.Rd`, `_pkgdown.yml`, `NEWS.md`,
  `ROADMAP.md`, and `docs/design/12-profile-likelihood-cis.md` now include the
  public helper.

## Mathematical Contract

This task does not change likelihoods, parameter estimates, or confidence
interval calculations. It exposes the same target inventory already used by
`confint.drmTMB()`: target names, target classes, fitted estimates, internal
TMB parameter names, transformation labels, and profile-readiness notes.

The helper is intentionally descriptive. A row with `profile_ready = TRUE` says
that the current direct-profile machinery can attempt the target; a row with
`profile_ready = FALSE` tells the user and developer that the target is known
but still needs a later profiling path.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `NAMESPACE`
- `man/profile_targets.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-profile-targets-public-helper.md`

## Checks Run

- `air format R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md _pkgdown.yml`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'profile-targets')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE)"`
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE, env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/profile.R tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md man/profile_targets.Rd _pkgdown.yml NAMESPACE`

The focused profile-target suite passed with 89 expectations, no failures, no
warnings, and no skips. The full package test suite passed with 1569
expectations, no failures, no warnings, and no skips. Pkgdown rebuilt and
`pkgdown::check_pkgdown()` found no problems. The first `devtools::check()` run
had only the known local clock note. The rerun with `_R_CHECK_SYSTEM_CLOCK_ =
FALSE` passed with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The new test checks that `profile_targets(fit)` matches the internal inventory
exactly, includes fixed-effect, random-effect SD, and random-effect correlation
targets, and that `ready_only = TRUE` returns only ready rows. It also checks
two input errors so the public helper does not silently accept unsupported
objects or malformed arguments.

## Consistency Audit

- The helper appears in `NAMESPACE`, the generated Rd page, and the pkgdown
  reference index.
- `NEWS.md`, `ROADMAP.md`, and the profile-likelihood design note all describe
  the helper as target discovery, not as a new interval method.
- No likelihood or formula grammar changed.
- This task keeps the existing boundary: transformed ordinal, modelled
  group-SD, residual response-scale `rho12`, and derived-summary profile
  intervals remain planned.

## What Did Not Go Smoothly

The first `devtools::check()` command was run without the local clock override
and produced the familiar `unable to verify current time` note. The closure
workflow now records the clean rerun explicitly so Grace can separate a local
environment note from package quality.

## Team Learning

Pat's lens drove this slice: users should not have to guess long target names
from documentation examples. Boole's lens kept the function small and
descriptive instead of adding another profiling API. Rose's lens kept the docs
honest that target discovery is not the same thing as implementing every
profile interval.

## Known Limitations

- `profile_targets()` lists known target rows; it does not make unsupported
  target classes profile-ready.
- The table exposes internal TMB parameter names because they are useful for
  contributors and debugging. User-facing tutorials should still explain the
  scientific quantity first.
- Derived summaries still need named extractors and profile/refit machinery
  before they can become ready targets.

## Next Actions

1. Add residual `rho12` profile coverage that distinguishes coefficient-scale
   intervals from response-scale row correlations.
2. Add a phylogenetic SD profile test before claiming phylogenetic SD intervals.
3. Use `profile_targets()` in tutorials or examples once Phase 6 has one more
   profile target class covered.
