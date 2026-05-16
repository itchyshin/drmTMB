# After Task: Phase 6b Conf-Status Action Table

## Goal

Make the post-fit workflow tutorial tell applied readers what to do when they
see each `conf.status` value.

## Implemented

- Added a compact action table to `vignettes/model-workflow.Rmd`.
- Covered `wald`, `profile`, `profile_ready`, `newdata_required`,
  `derived_interval_unavailable`, `wald_unavailable`, `target_unavailable`,
  `profile_unavailable`, and `not_requested`.
- Kept the table operational: each status has a next action rather than only a
  definition.

## Mathematical Contract

No fitted-model behavior changed. The tutorial now follows the existing
interval-status contract:

```text
wald/profile                         -> interval returned
profile_ready                        -> direct target, request profile interval
newdata_required                     -> profile a supplied row
derived_interval_unavailable         -> no validated derived interval yet
wald_unavailable                     -> Wald uncertainty absent for that row
target_unavailable/profile_unavailable -> no current direct interval target
not_requested                        -> point estimate shown without interval request
```

## Files Changed

- `vignettes/model-workflow.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-phase-6b-conf-status-action-table.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format vignettes/model-workflow.Rmd`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed and rendered `articles/model-workflow.html`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed with 0 errors, 0 warnings, and 0 notes in 2m 30.1s.
- `git diff --check`: passed.
- `rg -n 'Read \`conf\\.status\` as an action column|profile_ready|derived_interval_unavailable|target_unavailable|not_requested' vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html --glob '!pkgdown-site/search.json'`:
  confirmed the source and rendered model-workflow article carry the action
  table.

## Tests Of The Tests

No testthat file was added because this is documentation-only and uses existing
status values already covered by profile and summary tests. Rendering the article
is the executable check that the table syntax and examples remain valid.

## Consistency Audit

Ada kept the table in the post-fit workflow guide rather than scattering status
definitions through every tutorial. Pat checked that each status has a concrete
next step. Noether checked that the table mirrors
`docs/design/12-profile-likelihood-cis.md` and the summary status vocabulary.
Rose checked rendered HTML for the new rows.

## What Did Not Go Smoothly

No issue beyond choosing how much vocabulary to expose. The table includes the
rare `profile_unavailable` status because the summary code can emit it if no
profile note is available.

## Team Learning

- Pat: status columns become useful only when the tutorial says what action to
  take next.
- Noether: the status vocabulary should stay centralized in one workflow guide
  and link out conceptually from model-specific tutorials.
- Rose: rendered-site scans are enough for this documentation-only table, but
  the final bundle should still get a broad check before handoff.

## Known Limitations

This task did not add interval methods. Derived intervals, automatic intervals
for every covariance summary, and recovery from failed or non-monotone profiles
remain planned.

## Next Actions

1. Commit this focused tutorial slice.
2. Continue only with similarly small documentation cleanup before the away-period
   handoff.
