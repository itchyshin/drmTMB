# After Task: Slice 114 Plot Corpairs Facets

## Goal

Add an optional faceting control to `plot_corpairs()` so readers can separate
explicit correlation rows by `level` or another supplied table column without
changing the table-first extraction contract.

## Implemented

- Added `facet = NULL` to `plot_corpairs()`.
- Validated `facet` as an optional single column name.
- Added `.drmTMB_plot_facet` to the plotted data when a facet column is
  supplied.
- Added `ggplot2::facet_wrap(~.drmTMB_plot_facet, scales = "free_y")` when
  faceting is requested.
- Kept the default single-panel plot unchanged.
- Updated NEWS, ROADMAP, roxygen documentation, the generated Rd file, tests,
  and the visualization grammar design note.

## Mathematical Contract

No likelihood, formula grammar, parameter transform, or interval method changed.
Faceting is only a display grouping for rows already present in the supplied
table. The helper still plots supplied `estimate` values, draws interval
segments only from finite supplied `conf.low` and `conf.high` values, and keeps
rows without finite intervals visible as point estimates.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/plot-corpairs.R`
- `man/plot_corpairs.Rd`
- `tests/testthat/test-plot-corpairs.R`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-114-plot-corpairs-facets.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-172339-codex-checkpoint.md`

## Checks Run

- `air format R/plot-corpairs.R tests/testthat/test-plot-corpairs.R NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/plot_corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'plot-corpairs|plot-parameter-surface', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered the
  updated `plot_corpairs()` Reference page, ROADMAP, and NEWS.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n 'facet|plot_corpairs|Slice 114|visually separate correlation layers|implemented in Slice 113|reader-facing `plot_corpairs` examples' R/plot-corpairs.R tests/testthat/test-plot-corpairs.R man/plot_corpairs.Rd NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md pkgdown-site/reference/plot_corpairs.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed source and rendered pages include the facet argument and Slice 114
  docs.
- `rg -n 'future `plot_corpairs`|future plot_corpairs|only exported plotting helper|currently `plot_parameter_surface`|facet.*computes|facet.*profile|plot_corpairs\\(\\).*model refit|ggplot2.*Imports|posterior draw|credible interval' R/plot-corpairs.R tests/testthat/test-plot-corpairs.R NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md DESCRIPTION pkgdown-site/reference/plot_corpairs.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  found only intended confidence-not-credible-interval and design-source
  guardrails.
- `Rscript tools/codex-checkpoint.R --goal "Slice 114 plot_corpairs faceting" --next "stage, commit, push stacked branch, and open PR after Slice 113"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-172339-codex-checkpoint.md`.

## Tests Of The Tests

The new facet test calls `plot_corpairs(pairs, facet = "level")`, checks that
the facet column is attached to the plotted data, and verifies that the built
plot has three panels for the three example levels. The validation test also
checks that an unknown facet column fails through the same explicit column-name
path used by `colour`.

## Consistency Audit

The public helper signature, roxygen, generated Rd page, NEWS, ROADMAP, design
note, and rendered pkgdown Reference page all include `facet`. The near-term
slice order in `docs/design/39-visualization-grammar.md` now treats
reader-facing examples as the next `plot_corpairs()` step rather than still
asking to add the helper itself.

## What Did Not Go Smoothly

Nothing blocked the slice. The only extra cleanup was recognizing that the
near-term slice order had become stale once Slice 113 exported
`plot_corpairs()`.

## Team Learning

- Ada: small display controls are safest when they reuse explicit table columns.
- Boole: `facet` should mirror `colour`: a validated column name or `NULL`.
- Fisher: visual separation must not imply new interval support.
- Curie: testing the built panel count makes the facet test behavioural rather
  than only checking object class.
- Pat: `facet = "level"` gives applied readers a plain way to separate residual,
  group-level, phylogenetic, spatial, or future study-level rows.
- Grace: roxygen plus pkgdown is enough for this public-argument update.
- Rose: stale near-term-order text should be cleaned immediately after a planned
  helper becomes implemented.

## Known Limitations

- `facet` only separates rows already present in `data`.
- No fitted biological `plot_corpairs()` example was added.
- No likelihood, formula grammar, TMB code, interval computation, EMM, contrast,
  slope, or diagnostics plot changed.

## Next Actions

1. Add a reader-facing `plot_corpairs()` example when a fitted correlation
   workflow is stable enough for the article.
2. Keep any future plotting options tied to explicit table columns.
