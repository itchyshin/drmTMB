# After Task: Reference Surface Refresh

## Goal

Bring the main `drmTMB()` reference description up to date with the Phase 10-13
model surfaces.

## Implemented

- Updated the `drmTMB()` roxygen description to mention coordinate-based spatial
  random intercepts and one numeric coordinate-spatial slope in univariate
  Gaussian `mu`.
- Added the first all-four q=4 ordinary random-intercept covariance blocks and
  predictor-dependent q=2 ordinary or phylogenetic `corpair()` regressions to
  the same reference description.
- Regenerated `man/drmTMB.Rd` with `devtools::document()`.

## Mathematical Contract

No fitting behavior changed. The reference page now names already fitted
surfaces only:

```text
spatial(1 | site, coords = coords)       -> fitted univariate Gaussian mu
spatial(1 + x | site, coords = coords)   -> fitted one numeric mu slope
ordinary q=4 random-intercept block      -> fitted first slice
ordinary/phylogenetic q=2 corpair()      -> fitted predictor-dependent slice
```

## Files Changed

- `R/drmTMB.R`
- `man/drmTMB.Rd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-reference-surface-refresh.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/drmTMB.R`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::document()'`:
  passed and wrote `man/drmTMB.Rd`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed and rendered `reference/drmTMB.html`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed with 0 errors, 0 warnings, and 0 notes in 2m 29.8s.
- `git diff --check`: passed.
- `rg -n 'coordinate-based spatial random intercepts and one|all-four q=4 ordinary random-intercept covariance blocks|predictor-dependent q=2 ordinary or phylogenetic' R/drmTMB.R man/drmTMB.Rd pkgdown-site/reference/drmTMB.html --glob '!pkgdown-site/search.json'`:
  confirmed source, generated Rd, and rendered reference page wording.

## Tests Of The Tests

No new tests were needed because this patch changes roxygen prose only. The full
package check rebuilt vignettes, reference docs, and tests after documentation
regeneration.

## Consistency Audit

Ada kept the reference description as a current surface map, not a roadmap.
Jason found the stale omission. Noether checked the named surfaces against the
model-map boundaries. Grace verified roxygen, pkgdown, and full package checks.
Rose checked source, Rd, and rendered HTML.

## What Did Not Go Smoothly

No issue. This was a straight roxygen refresh.

## Team Learning

- Jason: after phase closures, scan roxygen reference pages as well as vignettes.
- Pat: a user who starts from `?drmTMB` should see the same current fitted
  surfaces as the tutorials.
- Grace: regenerate Rd rather than hand-editing generated reference files.

## Known Limitations

This task did not expand model support. Mesh/SPDE spatial fields, spatial
`sigma`, bivariate spatial covariance, spatial `corpair()`, phylogenetic slopes,
predictor-dependent q=4 phylogenetic correlations, and broad derived intervals
remain planned.

## Next Actions

1. Commit this reference refresh.
2. Create a recovery checkpoint for the away-period handoff.
