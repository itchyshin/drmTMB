# After Task: Phase 6b Follow-Through After Phases 10-13

## Goal

Refresh the tutorial front door after the local Phase 10-13 closures so applied
readers see the current implemented map before returning to the next Phase 6b
tutorial-quality lane.

## Implemented

- Updated `vignettes/drmTMB.Rmd` so the opening implementation summary now names
  ordinary bivariate covariance blocks, phylogenetic Gaussian covariance slices,
  coordinate spatial `mu` intercept and one-slope fields, and the model-workflow
  interval-status path.
- Expanded the getting-started learning path with rows for `corpairs()`,
  `corpair()`, `sd_phylo*()`, `spatial()`, `profile_targets()`, and
  `conf.status`.
- Replaced stale "spatial fields planned" front-door wording with the narrower
  current boundary: coordinate spatial intercept and one numeric slope are fitted
  first slices; richer spatial correlation rows remain planned.
- Updated `vignettes/bivariate-coscale.Rmd` so its `corpairs()` prose no longer
  describes ordinary group-level and phylogenetic rows as only future design
  targets.

## Mathematical Contract

No fitted-model behavior changed. The documentation now separates these layers:

```text
rho12                                 -> residual within-observation coupling
ordinary corpairs(level = "group")    -> group-level covariance rows
corpairs(level = "phylogenetic")      -> phylogenetic structured-effect rows
spatial(1 + x | site, coords = ...)   -> coordinate spatial intercept and
                                         one numeric slope fields in mu
conf.status                           -> interval availability or failure status
```

The tutorial still keeps richer spatial correlations, bivariate spatial
covariance, mesh/SPDE fields, structured `rho12`, and nonlinear derived
intervals as planned neighbours rather than implemented claims.

## Files Changed

- `vignettes/drmTMB.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-phase-6b-follow-through-after-10-13.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format vignettes/drmTMB.Rmd vignettes/bivariate-coscale.Rmd`:
  passed.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::build_site()'`:
  passed and rendered the updated getting-started and bivariate-coscale articles.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'pkgdown::check_pkgdown()'`:
  passed with no problems found.
- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH Rscript -e 'devtools::check(error_on = "never", env_vars = c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))'`:
  passed with 0 errors, 0 warnings, and 0 notes in 2m 33.5s.
- `git diff --check`: passed.
- Fixed-string stale scans over `vignettes/drmTMB.Rmd`,
  `vignettes/bivariate-coscale.Rmd`, `pkgdown-site/articles/drmTMB.html`, and
  `pkgdown-site/articles/bivariate-coscale.html` found no remaining matches for
  the old front-door phrases:
  - `intercept-only phylogenetic Gaussian location effects`
  - `Future phylogenetic and spatial correlations`
  - `spatial fields and richer structured covariance blocks`
  - matching labelled bivariate `mu1`/`mu2` random intercepts
  - `design target for future group-level`
- Positive scans confirmed the source and rendered site mention the updated
  tutorial claims, including ordinary bivariate `corpairs()` rows, coordinate
  spatial `mu` intercept and one numeric slope, fitted interval-status flags, and
  richer spatial correlation rows remaining planned.

## Tests Of The Tests

No new testthat file was added because this was documentation-only. The broad
validation was full R CMD check plus source and rendered-site stale wording
scans.

## Consistency Audit

Ada kept this as a Phase 6b tutorial follow-through, not a Phase 10-13 model
expansion. Pat and Darwin checked that the getting-started path still begins
with a one-response location-scale example, then sends readers to the model map
when they need bivariate or structured-effect status. Noether and Gauss checked
that the prose does not merge residual `rho12`, group-level correlation,
phylogenetic correlation, and coordinate spatial fields into one estimand.
Grace verified pkgdown and full package checks. Rose checked stale wording in
source and rendered HTML.

## What Did Not Go Smoothly

One scratch stale-wording command used backticks inside a double-quoted shell
pattern, which made the shell try to execute `mu1` and `mu2`. I reran the actual
audit as fixed-string `rg -F` scans before recording the result.

## Team Learning

- Ada: after local phase closures, the tutorial landing page should be refreshed
  before starting the next tutorial-improvement pass.
- Pat: reader-facing status belongs near the front door, but worked examples
  should stay simple enough for a first applied analysis.
- Noether: every correlation sentence should name the layer before naming the
  extractor.
- Grace: rendered-site scans are still useful even when only Rmd files are
  tracked.
- Rose: stale wording after a phase closure is validation debt, not merely prose
  polish.

## Known Limitations

This task did not add new model behavior, new examples, new visual helpers, or
new interval algorithms. Tutorial Phase 6b still needs a slower applied-user
pass over examples and interpretation after the Phase 10-13 closeout is fully
settled. GitHub Actions remains PR-side validation.

## Next Actions

1. Commit this follow-through patch with the current Phase 10-13 documentation
   branch.
2. Finish any remaining Phase 10-13 wrap-up tasks if a review finds drift.
3. Return to Phase 6b tutorial quality, starting with applied-user example flow
   and interpretation rather than new model implementation.
