# After Task: Random-Slope Tutorial Ledger

## Goal

Close #444 by turning the supported random-slope and structured-dependence
status into a reader-facing tutorial path and release ledger.

## Implemented

The package now has an issue-linked #444 ledger that points readers from the
model map into the location-scale, bivariate-coscale, scale, and structural
articles, while preserving explicit planned boundaries for neighbouring
random-slope cells.

## Mathematical Contract

No likelihood or formula grammar changed. The documentation now pairs the
ordinary Gaussian `mu` slope, residual-scale independent `sigma` slope, and
first bivariate `mu1`/`mu2` slope-slope covariance slices with symbolic
equations, matching R syntax, output rows, diagnostics, and profile-target
status. Residual `rho12`, singular `corpair()`, and plural `corpairs()` remain
separate concepts.

## Files Changed

- `vignettes/location-scale.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/model-map.Rmd`
- `docs/design/151-phase6c-random-slope-tutorial-ledger.md`
- `docs/design/37-worked-example-inventory.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-01-random-slope-tutorial-ledger.md`

## Checks Run

```sh
air format vignettes/location-scale.Rmd vignettes/model-map.Rmd vignettes/bivariate-coscale.Rmd docs/design/151-phase6c-random-slope-tutorial-ledger.md docs/design/37-worked-example-inventory.md ROADMAP.md
Rscript --vanilla -e "pkgdown::build_article('location-scale', new_process = FALSE, quiet = FALSE)"
Rscript --vanilla -e "pkgdown::build_article('bivariate-cosscale', new_process = FALSE, quiet = FALSE)"
Rscript --vanilla -e "pkgdown::build_article('bivariate-coscale', new_process = FALSE, quiet = FALSE)"
Rscript --vanilla -e "pkgdown::build_article('model-map', new_process = FALSE, quiet = FALSE)"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
Rscript --vanilla -e "devtools::test(filter = '^biv-gaussian$|^corpairs$|^gaussian-random-intercepts$', reporter = 'summary')"
rg -n "random_effect_scale_formulas|rho12|corpair|corpairs|phylo|spatial|animal|relmat|check_drm|profile_targets" _pkgdown.yml
rg -n "First slope-slope covariance slice|Residual-scale random effects live|Do high-baseline populations|Do repeated groups need non-Gaussian|groups differ in residual-scale slopes|Random-slope tutorial and release ledger|Issue #444 can close|phase6c-random-slope-tutorial-ledger" vignettes docs ROADMAP.md pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/location-scale.html pkgdown-site/articles/model-map.html
rg -n 'random effects in `rho12` (are )?(fitted|implemented)|correlated residual-scale slope.*(is|are )?(fitted|implemented)|coefficient-specific `sd\(\)`.*(is|are )?(fitted|implemented)|intercept-plus-slope q4.*(is|are )?(fitted|implemented)|p8/q8.*(is|are )?(fitted|implemented)|multiple structured slopes.*(is|are )?(fitted|implemented)' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes
git diff --check
```

## Tests Of The Tests

This was documentation work, so no new unit test was added. The focused test
rerun exercised the existing bivariate slope-slope covariance row, `corpairs()`
class filtering, and ordinary Gaussian random-slope extraction paths that the
new tutorial text references.

## Consistency Audit

`pkgdown::check_pkgdown()` passed. The reference-index scan found
`random_effect_scale_formulas`, `rho12`, `corpair`, `corpairs`, `phylo`,
`spatial`, `animal`, `relmat`, `check_drm`, and `profile_targets` in
`_pkgdown.yml`. The rendered article scan found the new wording in the built
`location-scale`, `bivariate-coscale`, and `model-map` pages.

The unsupported-boundary scan returned intentional planning or boundary
wording only. It did not find a new claim that random effects in `rho12`,
correlated residual-scale slope covariance, coefficient-specific `sd()` slope
models, intercept-plus-slope q4 blocks, p8/q8 endpoint covariance, or multiple
structured slopes are routine fitted tutorial syntax.

## GitHub Issue Maintenance

This task is intended to close #444 after PR merge. Parent issues #31, #33,
#342, #436, #59, #61, and #147 remain open where their broader tutorial,
simulation, release, or structured-effect work extends beyond this ledger.

## What Did Not Go Smoothly

I mistyped the bivariate article slug once as `bivariate-cosscale`. That command
failed before rendering. The corrected `bivariate-coscale` render passed.

## Team Learning

The fastest safe closeout was not a new long tutorial. The existing
location-scale and bivariate-coscale articles already carried most of the
reader path; the missing piece was a compact slope-slope article section plus a
finished-versus-planned ledger.

## Known Limitations

The fuller simulated bivariate plasticity-syndrome worked example remains
future work. Intercept-plus-slope q4 blocks, p8/q8 endpoint covariance,
correlated residual-scale slopes, coefficient-specific `sd()` slope models,
multiple structured slopes, structured slope correlations, structured
residual-scale slopes, random effects in `rho12`, and broad non-Gaussian
structured slopes remain planned.

## Next Actions

After #444 closes, continue with either #437/#436 coordination closure or the
smallest remaining Phase 18/#59 simulation-reporting slice that does not touch
the missing-data lane.
