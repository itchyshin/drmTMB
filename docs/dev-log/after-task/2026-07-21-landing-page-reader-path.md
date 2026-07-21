# After Task: landing-page reader path

## Goal

Replace the long capability inventory on the pkgdown home page with a compact
reader path, without changing the package capability surface or its claims.

## Implemented

`README.md` now routes readers to a first model, family/scale choice,
diagnostics, bivariate/meta-analysis, structured effects, and the maintained
model, implementation, and capability-limit maps. It retains the experimental
0.6 release-candidate, not-on-CRAN, one/two-response, and optional-Julia
boundaries.

## Mathematical Contract

No likelihood, estimator, formula grammar, or capability tier changed. The
existing Gaussian location-scale example still pairs the model equation,
`drm_formula(y ~ x1, sigma ~ x1)`, and log-SD interpretation.

## Files Changed

- `README.md`
- `docs/dev-log/after-task/2026-07-21-landing-page-reader-path.md`

## Checks Run

- `pkgdown::build_site()` rebuilt the candidate site successfully after an
  initial sandbox-only CRAN DNS failure; the approved rerun could obtain CRAN
  metadata.
- `pkgdown::build_home(); pkgdown::check_pkgdown()` passed after the final
  revision.
- `python3 tools/capability_ledger.py --check` passed.
- `Rscript tools/check-capability-runtime.R` passed: 18 routes, G0/G1/G2 all
  zero, 18 verified.
- Pat approved the rendered reader path; Rose approved the final claim audit.

## Tests Of The Tests

The change is prose and routing only. The rebuilt HTML was checked for exactly
seven visible home-page headings and the links resolved in the candidate site.

## Consistency Audit

The page directs unfamiliar random/structured-effect requests to the model
map, implementation map, and capabilities-and-limits guide rather than
repeating a second status inventory. The fixed capability sources remain
unchanged; no stale claim was introduced.

## GitHub Issue Maintenance

`gh issue list --state open --search 'landing page pkgdown README' --limit 20`
returned no matching open issue. No issue action: this is a bounded reader-path
revision on the existing pre-CRAN content-review branch, not a new capability
or defect.

## What Did Not Go Smoothly

The first full site build could not resolve `cloud.r-project.org` inside the
sandbox. A permitted rerun rebuilt the site, and the final home-only rebuild
passed normally.

## Team Learning

The home page should route rather than duplicate the capability ledger; the
maps are the maintained detailed surfaces.

## Known Limitations

The candidate remains experimental and pre-CRAN. This revision does not
deploy Pages, merge the PR, or alter any capability claim.

## Next Actions

Review and merge the existing content-review PR when its broader release gate
permits it; deploy through the normal pkgdown path only after merge.
