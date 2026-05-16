# After Task: Slice 113 Plot Corpairs Helper

## Goal

Implement the first narrow `plot_corpairs()` helper after the Slice 112
preflight. The implemented claim is deliberately small: `plot_corpairs()` turns
an explicit `corpairs()`-style table into a composable `ggplot` object without
refitting a model, computing correlation pairs, or inventing intervals.

## Implemented

- Added exported `plot_corpairs(data, colour = "level", interval = TRUE, ...)`.
- Required `data` to be a data frame with `level`, `class`, `parameter`,
  `estimate`, and `modelled`.
- Drew one point per correlation row and added interval segments only for rows
  where both `conf.low` and `conf.high` are finite.
- Preserved interval display status through `.drmTMB_conf_status`, using
  `conf.status` when present and `not_requested` for plain point-only tables.
- Built the y-axis labels from `level`, `class`, and `parameter` so residual,
  ordinary group-level, phylogenetic, spatial, and future study-level rows do
  not collapse into unnamed estimates.
- Kept `ggplot2` as an optional dependency by checking it at call time.
- Added the helper to `NAMESPACE`, `_pkgdown.yml`, NEWS, ROADMAP, the model-map
  article, and the visualization grammar design note.

## Mathematical Contract

No likelihood, parameter transform, symbolic equation, or formula grammar
changed. The display contract is:

- x-position is the response-scale correlation `estimate` supplied by the table;
- y-position is the explicit row identity `level | class | parameter`;
- interval segments are descriptive displays of supplied finite `conf.low` and
  `conf.high` values, not newly computed profile intervals;
- rows without finite bounds remain visible as point estimates.

## Files Changed

- `NAMESPACE`
- `NEWS.md`
- `ROADMAP.md`
- `_pkgdown.yml`
- `R/plot-corpairs.R`
- `man/plot_corpairs.Rd`
- `tests/testthat/test-plot-corpairs.R`
- `vignettes/model-map.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-113-plot-corpairs-helper.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-171333-codex-checkpoint.md`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md R/plot-corpairs.R tests/testthat/test-plot-corpairs.R _pkgdown.yml vignettes/model-map.Rmd`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated `NAMESPACE` and
  `man/plot_corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'plot-corpairs|plot-parameter-surface', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered the
  new Reference page, Reference index, ROADMAP, NEWS, and model-map article.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n 'future `plot_corpairs`|future plot_corpairs|only exported plotting helper|currently `plot_parameter_surface`' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-map.Rmd pkgdown-site/ROADMAP.html pkgdown-site/news/index.html pkgdown-site/articles/model-map.html`:
  returned no matches after the Slice 113 wording update.
- `rg -n 'plot_corpairs|Plot fitted correlation-pair summaries|Correlation estimate|Slice 113|Visualization|finite `conf.low`|finite confidence|level.*class' R/plot-corpairs.R tests/testthat/test-plot-corpairs.R man/plot_corpairs.Rd NAMESPACE _pkgdown.yml NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-map.Rmd pkgdown-site/reference/index.html pkgdown-site/reference/plot_corpairs.html pkgdown-site/articles/model-map.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed source and rendered pages include the new helper, Reference entry,
  axis label, finite-bound rule, and Slice 113 roadmap/news text.
- `Rscript tools/codex-checkpoint.R --goal "Slice 113 plot_corpairs helper" --next "stage and commit Slice 113, push stacked branch, open PR, then merge and rebase the Slice 110-113 visualization stack"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-171333-codex-checkpoint.md`.

## Tests Of The Tests

The focused test file checks the normal display path, point-only tables, empty
tables, and malformed inputs. The malformed-input cases cover non-data-frame
input, missing required columns, nonnumeric estimates, half-supplied interval
columns, missing colour columns, invalid `interval`, reserved `...`, and the
missing-`ggplot2` failure path through a mocked helper.

## Consistency Audit

The stale-wording scan removed the confusing "future `plot_corpairs()`" phrasing
from current NEWS, ROADMAP, the visualization grammar, the model-map article,
and rendered pkgdown pages. `_pkgdown.yml` now lists both exported plotting
helpers under `Visualization`, while extraction and post-fit tables remain under
`Model fitting and post-fit tools`.

## What Did Not Go Smoothly

The first empty-table implementation assigned a scalar `not_requested` status,
which failed for zero-row tables. The helper now uses
`rep("not_requested", nrow(data))`, and the empty-table test protects that path.
The first stale-wording scan also caught Slice 112 text that still described the
helper as future-facing after Slice 113 exported it.

## Team Learning

- Ada: keep plotting slices table-first until the data contract is stable.
- Boole: the small API is enough for now; `colour` and `interval` are the only
  options that have earned their way into the interface.
- Fisher: finite confidence bounds are a display precondition, not evidence
  that an interval method was run inside the plot helper.
- Curie: empty tables and missing optional dependencies need first-class tests
  for every plotting helper.
- Pat: the model-map row now gives readers a plain route from `corpairs()` to
  `plot_corpairs()` without implying automatic diagnostics.
- Grace: pkgdown caught the new Reference page and the navigation update.
- Rose: stale "planned" wording becomes risky quickly once stacked plotting
  slices move from preflight to implementation.

## Known Limitations

- `plot_corpairs()` consumes an explicit table only. It does not call
  `corpairs()` internally, fit models, compute correlation pairs, or run profile
  intervals.
- The helper does not choose final publication aesthetics, faceting, or
  biological example text.
- Spatial correlation rows remain supported only insofar as they are explicit
  rows in the supplied table; this slice does not implement new spatial models.
- No likelihood, formula grammar, TMB code, interval computation, EMM, contrast,
  slope, or diagnostics plot changed.

## Next Actions

1. Rebase or retarget the stacked visualization PRs after Slice 110 lands.
2. Consider a reader-facing example once real fitted `corpairs()` examples are
   ready and stable.
3. Keep future plotting helpers on the same path: explicit data table first,
   optional display second, and no hidden inference.
