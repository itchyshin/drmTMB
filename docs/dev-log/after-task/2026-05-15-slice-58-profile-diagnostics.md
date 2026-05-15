# Slice 58 profile diagnostics

Date: 2026-05-15

## Goal

Make profile interval outputs and profile failure messages more diagnostic
before adding stronger profile-recovery methods.

## What changed

- Added `profile.boundary` and `profile.message` to `confint()` output rows.
- Propagated those columns to interval-aware `summary()` coefficient and
  parameter tables.
- Flagged transformed SD intervals near zero and transformed correlation
  intervals near the correlation boundary.
- Updated profile failure messages to name boundary, one-sided, non-monotone,
  and failed-inner-optimization profiles as possible causes.
- Updated the profile-CI design note, roadmap, NEWS, and generated Rd files.

## Standing-review notes

- Ada: this is a diagnostic-output slice, not a profile-recovery slice.
- Fisher: boundary flags help users treat variance-component and correlation
  intervals with caution.
- Gauss: no likelihood or optimizer path changed; diagnostics are added after
  interval transformation.
- Noether: diagnostics are keyed to the reported response-scale interval, so
  the flag matches what the reader sees.
- Pat: the error message now gives users a reason to try wider profile controls
  or inspect `check_drm()` rather than treating the failure as mysterious.
- Grace: focused profile-target and summary tests are the local gate before the
  broader package and pkgdown checks.
- Rose: one-sided intervals, non-monotone profile recovery, and bootstrap
  fallback remain future work.

## Checks

- `Rscript -e 'devtools::test(filter = "profile-targets|summary", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::document()'`:
  passed and updated `man/confint.drmTMB.Rd`.
- `Rscript -e 'devtools::test(filter = "profile-targets|summary|corpairs|covariance-block-registry", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`:
  passed.
- `pkgdown::build_site()` and `pkgdown::check_pkgdown()`:
  passed.
- `git diff --check` and source/rendered wording scans:
  passed.

## Known limitations

- The boundary diagnostics are lightweight endpoint flags.
- The slice does not implement one-sided intervals, profile recovery, profile
  plotting, or bootstrap fallback.
