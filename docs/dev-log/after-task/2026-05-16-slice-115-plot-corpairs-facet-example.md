# After Task: Slice 115 Plot Corpairs Facet Example

## Goal

Make the new `facet = "level"` display option discoverable in the
`plot_corpairs()` Reference example while keeping the example table explicit.
This is not yet the full biological workflow example; that should wait until a
fitted correlation model, table, plot, and interpretation can be shown together.

## Implemented

- Added `plot_corpairs(pairs, facet = "level")` to the roxygen example.
- Regenerated `man/plot_corpairs.Rd`.
- Recorded Slice 115 in ROADMAP.
- Updated `docs/design/39-visualization-grammar.md` to distinguish this
  Reference example from a later fitted biological workflow.

## Mathematical Contract

No statistical model, likelihood, parameter transform, or interval method
changed. The example uses the same explicit table as the existing
`plot_corpairs()` example and only demonstrates how a supplied table column can
separate panels.

## Files Changed

- `R/plot-corpairs.R`
- `man/plot_corpairs.Rd`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-115-plot-corpairs-facet-example.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-173204-codex-checkpoint.md`

## Checks Run

- `air format R/plot-corpairs.R ROADMAP.md docs/design/39-visualization-grammar.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/plot_corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'plot-corpairs|plot-parameter-surface', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered the
  updated `plot_corpairs()` Reference page and ROADMAP.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n 'plot_corpairs\\(pairs, facet = "level"\\)|Slice 115|biological `plot_corpairs` workflow|faceted Reference example' R/plot-corpairs.R man/plot_corpairs.Rd ROADMAP.md docs/design/39-visualization-grammar.md pkgdown-site/reference/plot_corpairs.html pkgdown-site/ROADMAP.html`:
  confirmed source and rendered pages include the faceted example and Slice 115
  notes.
- `rg -n 'future `plot_corpairs`|future plot_corpairs|only exported plotting helper|currently `plot_parameter_surface`|facet.*computes|facet.*profile|plot_corpairs\\(\\).*model refit|ggplot2.*Imports|posterior draw|credible interval' R/plot-corpairs.R tests/testthat/test-plot-corpairs.R NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md DESCRIPTION pkgdown-site/reference/plot_corpairs.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  found only intended confidence-not-credible-interval and design-source
  guardrails.
- `Rscript tools/codex-checkpoint.R --goal "Slice 115 plot_corpairs facet example" --next "stage, commit, push stacked branch, and open PR after Slice 114"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-173204-codex-checkpoint.md`.

## Tests Of The Tests

No new test was needed because Slice 114 already tests the `facet = "level"`
behaviour directly by checking the plotted facet column and built panel count.
This slice only exposes that tested option in the Reference example.

## Consistency Audit

The roxygen example, generated Rd page, rendered pkgdown Reference page, ROADMAP,
and visualization grammar now agree that the faceted example exists. The design
note still reserves a fitted biological workflow for a later slice, avoiding the
claim that the current explicit data-frame example is a scientific worked
example.

## What Did Not Go Smoothly

Nothing blocked the slice. The main judgement call was to keep this as a
Reference example rather than forcing a bivariate fitted example into the
univariate model-workflow article.

## Team Learning

- Ada: Reference-page discoverability can be improved without expanding the
  plotting API.
- Boole: examples should use public arguments plainly, without helper shortcuts.
- Pat: readers should see `facet = "level"` where they first read the function.
- Grace: regenerating roxygen and pkgdown is enough for this docs-only user
  surface.
- Rose: keep the distinction between "API example" and "biological workflow"
  visible so the tutorial does not overclaim.

## Known Limitations

- No fitted biological `plot_corpairs()` workflow was added.
- No new plotting option, likelihood, formula grammar, TMB code, interval
  computation, EMM, contrast, slope, or diagnostics plot changed.

## Next Actions

1. Add a fitted biological `plot_corpairs()` workflow when the example can show
   model, `corpairs()` table, plot, and interpretation together.
