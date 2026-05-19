# After Task: Slice 265 simulation plot grammar

## Task

Create the first Simulation & Comparison article for operating-characteristic
plot grammar before broad Phase 18 result articles are advertised.

## What Changed

- Added `vignettes/simulation-plot-grammar.Rmd`.
- Added the article to the Simulation & Comparison pkgdown navbar and article
  index.
- Added illustrative fixture tables and plots for bias, RMSE, coverage, power,
  convergence, runtime, and warning/error ledgers.
- Covered continuous, proportion, count, and meta-analysis example surfaces
  without presenting the fixtures as final simulation evidence.
- Updated the roadmap, visualization grammar note, Phase 18 simulation
  programme note, NEWS, check log, and recovery checkpoint.

## Files Changed

- `_pkgdown.yml`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/after-task/2026-05-18-slice-265-simulation-plot-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-181824-codex-checkpoint.md`
- `vignettes/simulation-plot-grammar.Rmd`

## Checks

- `air format vignettes/simulation-plot-grammar.Rmd _pkgdown.yml NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/41-phase-18-simulation-programme.md docs/dev-log/recovery-checkpoints/2026-05-18-181824-codex-checkpoint.md`
- `Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/simulation-plot-grammar.Rmd', output_dir = '/tmp/drmtmb-simulation-plot-grammar-s265b', quiet = FALSE)"`
- Extracted embedded PNGs from `/tmp/drmtmb-simulation-plot-grammar-s265b/simulation-plot-grammar.html` and visually checked the bias/RMSE, coverage/power, convergence/runtime, and warning/error ledger displays.
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept the slice focused on a new article and pkgdown route rather than
  simulation-engine work.
- Pat checked that the article names the reader questions before showing the
  plots.
- Fisher kept Monte Carlo uncertainty, missing unsupported estimands, and
  failure-ledger visibility central to the grammar.
- Grace checked the render, pkgdown, and diff hygiene before treating the slice
  as closed.
- Rose checked that the fixtures are described as display examples, not final
  evidence.
- Florence reviewed the plots for scanability and for honest separation of
  accuracy, interval behaviour, diagnostics, runtime, and failures.

## Known Limits

- The article uses illustrative fixtures; it does not report real Phase 18
  operating-characteristic results.
- This slice does not add new simulation helpers or runners.
- Real result articles still need generated tables with fitted-surface
  admission checks, interval status, diagnostics, and failure ledgers.
