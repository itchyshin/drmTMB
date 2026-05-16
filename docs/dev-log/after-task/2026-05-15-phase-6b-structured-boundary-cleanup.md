# After Task: Phase 6b Structured-Boundary Cleanup

## Goal

Remove stale broad structured-effect wording that survived the Phase 10 and
Phase 12 closures, without changing model behavior.

## Implemented

- Updated the structured-effect rejection message in `R/drmTMB.R` so unsupported
  structured markers point users to the current fitted exceptions:
  univariate phylogenetic `mu`, matching bivariate phylogenetic `mu1`/`mu2`, and
  coordinate-spatial univariate `mu` intercept or one numeric slope.
- Updated the Gaussian location-scale tutorial caveats so "spatial terms" and
  "phylogenetic sigma terms" are no longer broad planned buckets.
- Added explicit tutorial wording that coordinate-spatial random effects are
  fitted in univariate Gaussian `mu` as `spatial(1 | site, coords = coords)` and
  one numeric `spatial(1 + x | site, coords = coords)` slope.

## Mathematical Contract

No likelihood or parser behavior changed. The supported boundary remains:

```text
phylo(1 | species, tree = tree)           -> fitted univariate Gaussian mu
matching bivariate phylo() mu1/mu2        -> fitted first slices
spatial(1 | site, coords = coords)        -> fitted univariate Gaussian mu
spatial(1 + x | site, coords = coords)    -> fitted one numeric mu slope
spatial sigma, mesh/SPDE, bivariate
spatial covariance, multiple slopes       -> planned
standalone or partial phylogenetic scale  -> planned
```

## Files Changed

- `R/drmTMB.R`
- `vignettes/location-scale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-phase-6b-structured-boundary-cleanup.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/drmTMB.R vignettes/location-scale.Rmd`:
  passed.
- `rg -n -F 'phylogenetic \`sigma\` terms, spatial terms' R vignettes README.md ROADMAP.md NEWS.md docs/design tests/testthat --glob '!docs/dev-log/**'`:
  returned no matches.
- `rg -n -F 'spatial terms and structured effects in other parameters are still planned' R vignettes README.md ROADMAP.md NEWS.md docs/design tests/testthat --glob '!docs/dev-log/**'`:
  returned no matches.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::test(filter = "gaussian-location-scale|spatial-gaussian|package-skeleton", reporter = "summary")'`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed and rendered `articles/location-scale.html`.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed with 0 errors, 0 warnings, and 0 notes in 2m 28s.
- `git diff --check`: passed.
- `rg -n 'Coordinate-spatial random effects are implemented|spatial \`sigma\`, bivariate spatial covariance|Implemented structured paths are intercept-only|coordinate-spatial .*spatial\\(1 \\+ x' R/drmTMB.R vignettes/location-scale.Rmd pkgdown-site/articles/location-scale.html pkgdown-site/reference/drmTMB.html --glob '!pkgdown-site/search.json'`:
  confirmed the updated source and rendered article wording.

## Tests Of The Tests

The targeted test run exercised the unsupported structured-marker paths in
`test-gaussian-location-scale.R`, the formula marker parsing checks in
`test-package-skeleton.R`, and the fitted coordinate-spatial intercept and
one-slope paths in `test-spatial-gaussian.R`.

## Consistency Audit

Ada kept this as a wording and diagnostics cleanup. Gauss checked that no TMB
likelihood branch or parser grammar changed. Noether checked that the supported
syntax and planned-neighbour list match the model-map and structured-dependence
tutorial. Pat checked that the error-message hint now tells users what to try
next. Rose checked stale wording in source and rendered HTML.

## What Did Not Go Smoothly

One exploratory `rg` pattern included backticks inside a double-quoted shell
string, so the shell tried to execute `sigma`. The recorded scans use fixed
strings or quoted regexes that do not have that problem.

## Team Learning

- Ada: stale scope wording often sits in tutorial caveats and error-message
  hints after implementation phases move forward.
- Pat: planned-feature errors are teaching surfaces; they should name the
  closest supported syntax.
- Noether: broad terms like "spatial terms" are too coarse once one spatial
  slice exists.
- Rose: repeat stale scans with shell-safe quoting before recording evidence.

## Known Limitations

This task did not add model behavior. Spatial `sigma`, bivariate spatial
covariance, mesh/SPDE fields, multiple spatial slopes, spatial `corpair()`,
phylogenetic slopes, standalone or partial phylogenetic scale terms, and
structured `rho12` remain planned.

## Next Actions

1. Commit this focused cleanup.
2. Continue Phase 6b applied-user tutorial cleanup only where stale wording or
   missing interpretation is concrete.
