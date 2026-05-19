# After Task: Slice 300 Simulation Raincloud Grammar

## Goal

Carry the Slice 299 raincloud lesson into the Simulation & Comparison article
so future Phase 18 reports show replicate-level simulation variation beside the
mean and Monte Carlo uncertainty, rather than showing only aggregate means.

## Implemented

- Updated `vignettes/simulation-plot-grammar.Rmd` so the bias display uses
  replicate-level error clouds, faint replicate points, mean bias points, and
  95% MCSE intervals in fixed surface facets.
- Split RMSE into its own point-and-interval display because RMSE is a
  root mean-square aggregate, not signed bias or the center of an
  absolute-error cloud.
- Kept missing surface-estimand cells visible by leaving unsupported or
  not-yet-targeted rows blank instead of filling them with zeros.
- Updated NEWS, ROADMAP, and `docs/design/39-visualization-grammar.md` so the
  simulation-display contract says real bias reports should use actual
  replicate-level outputs plus MCSE intervals, while RMSE should stay in a
  separate aggregate point/MCSE display.

## Mathematical Contract

No simulation DGP, runner, result schema, plotting helper API, likelihood,
extractor, formula grammar, or test fixture changed. This slice changes the
reader-facing simulation plot grammar only. The article still uses
illustrative fixtures; real Phase 18 reports must use actual replicate outputs,
aggregate summaries, MCSE columns, manifests, and warning/error ledgers. The
RMSE panel is deliberately aggregate-only because RMSE is not the mean of
absolute replicate errors.

## Files Changed

- `vignettes/simulation-plot-grammar.Rmd`
- `docs/design/39-visualization-grammar.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-19-slice-300-simulation-raincloud-grammar.md`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format vignettes/simulation-plot-grammar.Rmd`:
  passed during the first render pass.
- `Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/simulation-plot-grammar.Rmd', output_dir = '/tmp/drmtmb-simulation-raincloud-s300', quiet = FALSE)"`:
  passed.
- Extracted 5 embedded PNGs from the rendered HTML and visually checked the
  revised bias raincloud and RMSE point/MCSE panels under
  `/tmp/drmtmb-simulation-raincloud-s300/embedded-pngs/`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "devtools::test()"`: passed with 4,952 tests, 0 failures,
  0 warnings, and 0 skips.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 300 simulation raincloud grammar" --next "stage, commit, push, and open a draft PR"`:
  wrote
  `docs/dev-log/recovery-checkpoints/2026-05-19-065413-codex-checkpoint.md`.

## Tests Of The Tests

No executable tests changed. The validation target is the rendered article:
the render runs the edited simulation-plot chunks, and visual inspection checks
that bias and RMSE now show separate uncertainty displays.

## Consistency Audit

The article, NEWS, ROADMAP, and visualization grammar design note all describe
the same boundary: replicate-level bias displays and aggregate RMSE displays
are now the expected simulation-report grammar, but exported simulation plot
helpers remain deferred until Phase 18 result schemas stabilize.

## What Did Not Go Smoothly

The first RMSE interval version used dodged segments under flipped coordinates,
which made whiskers slant. A later absolute-error cloud version aligned the
geometry but risked teaching that RMSE is the center of an absolute-error
distribution. The final version facets by surface, keeps fixed estimand rows,
and draws RMSE as an aggregate point with a horizontal MCSE bar.

## Team Learning

Ada kept the slice as documentation and visual grammar. Florence rejected the
slanted RMSE whiskers as a visual QA failure and required a second render.
Fisher kept the bias/RMSE distinction explicit: signed bias can use
replicate-error clouds, while RMSE needs a separate aggregate uncertainty
display. Pat flagged that dodged surfaces with missing cells made mean points
look inconsistently located. Grace kept the validation path tied to rendered
HTML and PNG inspection. Rose caught stale wording and the RMSE-versus-absolute
error ambiguity. Pat and Rose ran as bounded review subagents.

## Known Limitations

- The bias clouds in the article are illustrative fixture rows, not formal Phase
  18 simulation results.
- No real simulation runner or aggregate table was changed.
- No exported `plot_simulation_summary()` helper was added.

## Next Actions

When a Phase 18 surface writes real replicate-level outputs, add a focused
result-report slice that uses this grammar with actual replicate bias errors,
aggregate RMSE summaries, MCSE intervals, manifests, and warning/error ledgers.
