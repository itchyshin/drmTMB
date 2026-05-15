# Slice 59 profile inference docs

Date: 2026-05-15

## Goal

Make the public documentation teach the profile-likelihood interval status
contract that Slices 57 and 58 implemented.

## What changed

- Added a README boundary paragraph for Wald defaults, direct profile targets,
  `conf.status`, `profile.boundary`, and `profile.message`.
- Updated known limitations so q=4 derived correlations are not described as
  direct profile targets.
- Updated model workflow, model map, bivariate coscale, and structured
  dependence tutorials to tell readers how to read interval statuses before
  interpreting bounds.
- Added a Slice 59 reader-facing contract to the profile-CI design note.
- Marked Slice 59 done in the roadmap.

## Standing-review notes

- Ada: this slice keeps the Phase 6 story coherent before the final gate.
- Pat: the workflow article now tells an applied reader what to do when a row
  says `newdata_required` or `derived_interval_unavailable`.
- Fisher: the prose keeps derived q=4 intervals, conditional random-effect mode
  intervals, and bootstrap fallback outside the implemented claim.
- Grace: pkgdown build and check were the main gate because the changes are
  reader-facing.
- Rose: stale wording that implied "direct profile intervals for derived q4
  correlations" was replaced with "derived-profile intervals".

## Checks

- `Rscript -e 'devtools::test(filter = "profile-targets|summary", reporter = "summary")'`:
  passed.
- `pkgdown::build_site()`:
  passed.
- `pkgdown::check_pkgdown()`:
  passed with no problems found.
- `git diff --check`:
  passed.
- Source and rendered-site scans confirmed `conf.status`,
  `profile.boundary`, `profile.message`, `newdata_required`, and
  `derived_interval_unavailable` wording on the expected pages.

## Known limitations

- No new interval method was added in this slice.
- One-sided intervals, profile recovery, bootstrap fallback, derived q=4
  correlation intervals, and conditional random-effect mode intervals remain
  future work.

## Next actions

- Slice 60 should close Phase 6 with a full after-phase audit, checks, PR,
  GitHub Actions, and merge.
