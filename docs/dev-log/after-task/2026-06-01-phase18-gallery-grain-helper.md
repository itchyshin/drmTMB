# After Task: Phase 18 Future-Gallery Grain Helper

## Goal

Close #461 by turning the artifact-grain rule from the current count-gallery
predicate into a reusable helper for future Phase 18 galleries.

## Implemented

`inst/sim/R/sim_gallery_grain.R` now provides
`phase18_gallery_can_draw_replicate_cloud()`. A gallery can draw cloud-style
replicate geometry only when its required plot columns are present and the
input table carries either `artifact_grain = "replicate"` or
`replicate_cloud_gate = "replicate_clouds_allowed"`. If both markers are
present, both must permit the cloud, so a conflicting aggregate-grain row stays
aggregate-only.

The count-pilot gallery now sources that helper before drawing the bias panel.

## Mathematical Contract

This task does not change a likelihood, estimator, formula grammar, or
simulation estimand. It changes the reporting contract for display geometry:
replicate-error clouds represent one fitted simulation replicate per row, while
aggregate rows remain points, bars, MCSE intervals, or table entries.

## Files Changed

- `inst/sim/R/sim_gallery_grain.R`
- `inst/sim/reports/phase18-count-mu-gallery.Rmd`
- `tests/testthat/test-phase18-count-gallery-template.R`
- `inst/sim/README.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/150-phase-18-artifact-grain-closeout.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/R/sim_gallery_grain.R inst/sim/reports/phase18-count-mu-gallery.Rmd tests/testthat/test-phase18-count-gallery-template.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md docs/design/150-phase-18-artifact-grain-closeout.md ROADMAP.md
Rscript --vanilla -e "devtools::test(filter = '^phase18-count-gallery-template$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^phase18-first-wave-(table-bundle|summary-report|summary-render-helper)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^phase18-count-gallery-template$|^phase18-first-wave-(table-bundle|summary-report|summary-render-helper)$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n "phase18_gallery_can_draw_replicate_cloud|sim_gallery_grain|replicate_cloud_gate = 'replicate_clouds_allowed'|Future-gallery grain helper|#461|Slice 1833|1833|fake.*cloud|aggregate-grain|artifact_grain = \"replicate\"" inst/sim README.md ROADMAP.md NEWS.md docs vignettes tests/testthat
git diff --check
```

Results:

- The focused count-gallery template tests passed after the helper migration.
- The focused first-wave table-bundle, summary-report, and summary-render
  helper tests passed.
- The combined focused rerun passed.
- `pkgdown::check_pkgdown()` returned `No problems found`.
- The status scan found the new helper, count-gallery hook, ROADMAP row 1833,
  #461 references, and historical artifact-grain notes.
- `git diff --check` passed.

## Tests Of The Tests

The first focused count-gallery run failed because the template test still
expected the literal `artifact_grain` predicate inside the Rmd. The fix made
the template visibly state the helper-backed gate in its no-cloud subtitle,
then the test passed.

The new helper test covers five paths: no grain marker, replicate grain,
aggregate grain, derived replicate-cloud gate, conflicting gate, and a missing
required plotting column.

## Consistency Audit

The Phase 18 README, simulation-programme design doc, artifact-grain closeout
note, ROADMAP, and rendered-gallery subtitle now describe the reusable helper
as a reporting/data-grain gate. They do not claim new recovery, coverage,
power, runtime, or family support.

## GitHub Issue Maintenance

#461 is the target issue for this helper. #255 remains closed as the current
artifact-grain contract; this task only handles future-gallery reuse.

## What Did Not Go Smoothly

Moving the predicate from the Rmd into a helper removed the visible
`artifact_grain` string from the template. The test caught that loss, and the
subtitle now states both accepted gate forms.

## Team Learning

Future Phase 18 gallery work should add a helper-backed negative aggregate
render smoke at the same time as any cloud, dot-density, empirical-quantile, or
replicate-level failure display.

## Known Limitations

The helper only gates display geometry. It does not validate a full simulation
artifact schema, run simulations, or prove operating characteristics.

## Next Actions

Use this helper in any future Phase 18 gallery that draws cloud-style
replicate geometry.
