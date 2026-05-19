# After Task: Slice 264 emmeans and marginal-effects figures

## Task

Extend the public figure gallery so the supported fixed-effect univariate `mu`
`emmeans` route, factor-conditioned grids, interaction grids, empirical
marginal summaries, and unsupported `emmeans` boundaries are visible in one
reader-facing path.

## What Changed

- Expanded the estimated-marginal-means section into a broader `emmeans` and
  marginal-summary section.
- Kept the advertised `emmeans` route limited to fixed-effect univariate `mu`.
- Added a simple habitat EMM, a factor-conditioned habitat-by-season grid, and
  an explicit habitat-by-temperature interaction grid.
- Added an empirical `marginal_parameters()` display that averages over the
  fitted-row covariate distribution without interval bars.
- Added an `emmeans` support-boundary strip for `sigma`, bivariate responses,
  zero-inflated or hurdle response means, ordinal expected scores, and
  random-effect targets.
- Updated the roadmap, visualization grammar note, `emmeans` interface
  contract, NEWS, check log, and recovery checkpoint.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/after-task/2026-05-18-slice-264-emmeans-marginal-figures.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-181035-codex-checkpoint.md`
- `vignettes/figure-gallery.Rmd`

## Checks

- `air format vignettes/figure-gallery.Rmd NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md docs/dev-log/after-task/2026-05-18-slice-264-emmeans-marginal-figures.md docs/dev-log/recovery-checkpoints/2026-05-18-181035-codex-checkpoint.md`
- `Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = '/tmp/drmtmb-figure-gallery-s264b', quiet = FALSE)"`
- Extracted embedded PNGs from `/tmp/drmtmb-figure-gallery-s264b/figure-gallery.html` and visually checked the EMM, factor-conditioned, interaction-grid, empirical marginal, and support-boundary displays.
- `Rscript -e "devtools::test(filter = 'emmeans-methods|marginal-parameters|plot-parameter-surface', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept the slice inside the public figure-gallery lane and avoided new API
  work.
- Pat checked that the reader can see the target, conditioning rule, and
  unsupported boundary before trying to generalize `emmeans()`.
- Fisher kept empirical `marginal_parameters()` summaries separate from
  `emmeans` reference-grid intervals.
- Grace checked the focused tests, pkgdown, and diff hygiene before treating
  the slice as closed.
- Rose checked that blocked targets stay blocked in prose, roadmap, NEWS, and
  the interface contract.
- Florence reviewed the new plots for readable labels and separation of
  supported EMMs from unsupported targets.

## Known Limits

- This slice does not extend the `emmeans` bridge beyond fixed-effect
  univariate `mu`.
- The empirical marginal summary is a plug-in average and does not display
  interval bars.
- Unsupported `sigma`, bivariate, zero-inflated, hurdle, ordinal, and
  random-effect targets need separate design and validation before they can be
  plotted as `emmeans` results.
