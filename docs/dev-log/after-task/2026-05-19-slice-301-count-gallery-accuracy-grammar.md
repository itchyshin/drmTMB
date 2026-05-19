# After Task: Slice 301 Count Gallery Accuracy Grammar

## Goal

Apply the Slice 300 accuracy-display contract to the actual Phase 18 paired
count-pilot gallery template, while keeping the boundary clear: aggregate CSVs
can show mean bias, RMSE, and MCSE intervals, but they cannot support
replicate-error rainclouds until replicate-level errors are available.

## Implemented

- Replaced the old generic count-gallery accuracy plotter with separate bias
  and RMSE plotters in `inst/sim/reports/phase18-count-mu-gallery.Rmd`.
- Bias and RMSE now use fixed family facets, readable parameter-class labels,
  and horizontal MCSE bars when `bias_mcse` or `rmse_mcse` are present.
- The bias panel states that replicate-error clouds require replicate-level
  output, and the RMSE panel states that RMSE is an aggregate root-mean-square
  summary rather than the center of an absolute-error cloud.
- Updated count-gallery template and render-helper tests so fixture CSVs carry
  `bias_mcse` and `rmse_mcse`.
- Updated NEWS, ROADMAP, the visualization grammar note, and the Phase 18
  simulation-programme note to record the aggregate-versus-replicate boundary.

## Mathematical Contract

No simulation DGP, runner, aggregation helper, result schema, exported plotting
helper, likelihood, extractor, formula grammar, or package API changed. This
slice changes the reader-facing count-pilot report template only. The existing
aggregate rows are not enough for a raincloud; the report therefore shows
aggregate bias/RMSE and MCSE intervals and leaves replicate-error clouds for a
future replicate-level result schema.

## Files Changed

- `inst/sim/reports/phase18-count-mu-gallery.Rmd`
- `tests/testthat/test-phase18-count-gallery-template.R`
- `tests/testthat/test-phase18-count-gallery-render-helper.R`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-19-slice-301-count-gallery-accuracy-grammar.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format inst/sim/reports/phase18-count-mu-gallery.Rmd tests/testthat/test-phase18-count-gallery-template.R tests/testthat/test-phase18-count-gallery-render-helper.R`:
  passed.
- `Rscript -e "devtools::test(filter = '^phase18-count-gallery')"`: passed
  with 41 tests, 0 failures, 0 warnings, and 0 skips.
- Rendered a real count-gallery smoke artifact to
  `/tmp/drmtmb-s301-count-gallery/gallery/phase18-count-mu-gallery.html` and
  extracted three embedded PNGs for visual inspection.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 301 count gallery accuracy grammar" --next "stage, commit, push, and open a draft PR"`:
  wrote
  `docs/dev-log/recovery-checkpoints/2026-05-19-071653-codex-checkpoint.md`.

## Tests Of The Tests

The focused tests now check that the template source contains the separate
bias/RMSE plotters and MCSE-aware language, and the render fixtures include
`bias_mcse` and `rmse_mcse` columns. The smoke render exercises the real
Poisson/NB2 pilot path rather than only hand-written CSV fixtures.

## Consistency Audit

The count-pilot gallery, NEWS, ROADMAP, visualization grammar note, and Phase
18 simulation-programme note now describe the same rule: aggregate-only reports
show aggregate bias/RMSE with MCSE intervals; rainclouds require
replicate-level error rows.

## Team Learning

Ada kept the slice scoped to the report template. Florence rejected the first
render because the caption was clipped and the facet labels were raw internal
values. Fisher kept RMSE on its aggregate scale. Pat's Slice 300 concern about
moving lanes carried forward into fixed family facets. Grace kept validation
focused on the count-gallery tests and a real smoke render. Rose recorded that
no new API or result schema was added. No spawned subagents were running for
this slice.

## Known Limitations

- The report still cannot draw real rainclouds because the current count-pilot
  gallery inputs do not contain replicate-level error rows.
- The smoke render uses a tiny pilot and is a visual plumbing check, not
  simulation evidence.
- No exported `plot_simulation_summary()` helper was added.

## Next Actions

When Phase 18 writes replicate-level error rows for an admitted surface, add a
result-report slice that draws bias rainclouds from the real replicate output
and keeps RMSE as an aggregate point/MCSE display.
