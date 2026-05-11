# After Task: Internal Fixed-Effect Profile Engine

## Goal

Turn the profile-target inventory into one working internal profile-confidence
interval path for direct fixed-effect targets, while keeping the public
`confint()` API closed until the grammar and unsupported-target messages have
one more review pass.

## Implemented

- Added private `drm_profile_confint()` and supporting helpers in `R/profile.R`.
- The helper matches requested target names against `drm_profile_targets()`.
- Direct fixed-effect targets are profiled with `TMB::tmbprofile()` through a
  one-hot linear combination of the optimized TMB parameter vector.
- Unsupported target classes, unknown target names, and invalid confidence
  levels fail before profiling starts.
- Added focused tests that compare `drm_profile_confint()` against a manual
  `TMB::tmbprofile()` call for `fixef:mu:x`.
- Updated `docs/design/12-profile-likelihood-cis.md` to record the private
  helper and its current scope.

## Mathematical Contract

For a target such as `fixef:mu:x`, the helper constructs a vector `v` with one
entry equal to one at the corresponding optimized TMB parameter and zero
elsewhere. `TMB::tmbprofile()` then profiles the scalar linear combination
`sum(v * theta)`, re-optimizing nuisance parameters along the profile. The
returned interval is on the fitted link scale for the fixed-effect coefficient.

This slice does not transform the interval onto response-scale summaries. For
example, `fixef:rho12:w` is still a coefficient on the `rho12` linear predictor,
not a row-specific residual correlation interval.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-profile-fixed-effect-engine.md`

## Checks Run

- `air format R/profile.R tests/testthat/test-profile-targets.R`
- `Rscript -e "devtools::test(filter = 'profile-targets')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `git diff --check`
- `rg -n "confint\\.drmTMB\\(method = \\\"profile\\\"\\).*implemented|profile.*public.*implemented|O'Dea/Nakagawa|O'Dea-style|O’Dea-style" R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md docs/dev-log/after-task/2026-05-10-profile-fixed-effect-engine.md ROADMAP.md README.md NEWS.md vignettes`

The focused profile-target suite passed with 59 expectations, no warnings, and
no skips after adding the internal profile engine. The full package test suite
passed with 1539 expectations, no warnings, and no skips. The pkgdown site
rebuilt successfully. The stale-public-claim scan found only the expected
after-task limitation that `confint.drmTMB(method = "profile")` is still not
implemented.

## Tests Of The Tests

The new positive-path test compares the wrapper output against a manual
`TMB::tmbprofile()` call with the same one-hot linear combination. The negative
tests check unsupported random-effect SD targets, unknown target names, and
invalid confidence levels.

## Consistency Audit

- The helper remains private and is documented as an internal seed, not as a
  public user feature.
- No `NAMESPACE`, `_pkgdown.yml`, or `NEWS.md` update is required yet because no
  public function was added.
- The design doc still says `confint.drmTMB(method = "profile")` is future
  work.

## What Did Not Go Smoothly

The first instinct was to jump straight to `confint.drmTMB()`. Holding it
private for this slice is the safer route: it lets us exercise the optimizer,
target grammar, and unsupported-target messages before promising a stable user
API.

## Team Learning

Fisher should now review the interval logic before public exposure: the wrapper
can call `TMB::tmbprofile()`, but coverage, boundary behavior, and transformed
quantity interpretation are separate statistical claims. Boole should review
whether the public `parm` grammar should accept both `mu:x` and
`fixef:mu:x`, or only the inventory target names.

## Known Limitations

- `confint.drmTMB(method = "profile")` is still not implemented.
- Only direct fixed-effect inventory rows are profiled.
- Random-effect SDs, correlations, ordinal transformed cutpoints, and derived
  summaries are rejected for now.

## Next Actions

1. Decide the public `confint.drmTMB()` grammar and return shape.
2. Add direct fixed-effect profile intervals to the public API behind explicit
   `method = "profile"`.
3. Add Fisher's boundary and coverage checks before moving to SD and
   correlation targets.
