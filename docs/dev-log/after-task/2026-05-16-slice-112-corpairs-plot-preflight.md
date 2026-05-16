# After Task: Slice 112 Corpairs Plotting Preflight

## Goal

Record the minimum data and testing contract for a future `plot_corpairs()`
helper before adding another exported plotting function. Correlation displays
need more care than ordinary fitted-parameter surfaces because residual,
ordinary group-level, phylogenetic, spatial, and future study-level
correlations are different layers.

## Implemented

- Added a `corpairs()` plotting preflight section to
  `docs/design/39-visualization-grammar.md`.
- Recorded that a future helper should consume an explicit `corpairs()` table.
- Required visible `level`, `class`, `parameter`, `estimate`, `modelled`, and
  interval-status columns where applicable.
- Recorded that point estimates can be drawn for all rows, but interval
  segments should be drawn only from finite `conf.low` and `conf.high` bounds.
- Required labels or facets that keep correlation `level` visible.
- Required tests for residual, ordinary group-level, phylogenetic,
  derived-unavailable, empty-table, and missing-`ggplot2` cases before export.
- Updated NEWS and ROADMAP with the Slice 112 preflight contract.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-112-corpairs-plot-preflight.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-165401-codex-checkpoint.md`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered the
  updated ROADMAP and NEWS.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n 'Slice 112|corpairs\\(\\) plotting preflight|plot_corpairs\\(\\).*helper|conf\\.status|derived-unavailable|empty-table|missing-`ggplot2`|finite confidence' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed source and rendered pages carry the preflight contract.
- `rg -n "plot_corpairs\\(\\).*implemented|plot_corpairs\\(\\).*exported|autoplot\\.drmTMB|ggplot2.*Imports|tidybayes.*dependency|ggdist.*dependency|posterior draw|credible interval" NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md DESCRIPTION pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  found only intended planned-name, design-inspiration, and
  confidence-not-credible-interval guardrails.
- `Rscript tools/codex-checkpoint.R --goal "Slice 112 corpairs plotting preflight" --next "stage, commit, push stacked branch, and open/retarget PR after Slice 109 through 111 settle"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-165401-codex-checkpoint.md`.

## What Did Not Change

- `plot_corpairs()` is still planned and unexported.
- No R API, dependency, likelihood, formula grammar, TMB code, or tests changed.
- No correlation plot, interval layer, diagnostics plot, EMM, contrast, slope,
  or simulation display was added.

## Team Learning

- Ada: preflight design is the right move before adding a plotting helper whose
  rows mix several correlation layers.
- Fisher: interval segments need finite bounds and explicit status, not only a
  row-level point estimate.
- Boole: `corpairs()` tables are the right primary input; a plot helper should
  not rediscover correlation rows internally.
- Jason: the landscape lesson is to separate data extraction from display, even
  for the tempting `corpairs()` plot.
- Grace: future helper tests need the empty-table and missing-`ggplot2` paths
  before Reference-page export.
- Rose: this slice prevents a likely future overclaim: plotting correlations is
  not the same as proving every correlation layer has interval support.

## Known Limitations

- No user-facing function was added.
- The design note does not choose final aesthetics for `plot_corpairs()`.
- The helper remains blocked until implementation, tests, documentation, and
  Reference-index updates are present.

## Next Actions

1. Implement `plot_corpairs()` only after the preflight test set is ready.
2. Keep residual, group-level, phylogenetic, spatial, and future study-level
   correlation layers visibly separate.
3. Do not draw correlation intervals unless `corpairs()` supplies finite bounds.
