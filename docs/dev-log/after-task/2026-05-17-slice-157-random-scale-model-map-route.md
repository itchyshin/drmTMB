# After Task: Slice 157 random-effect scale model-map route

## Goal

Make the model-map article route fitted random-effect SD surfaces through the
same grid and table helpers shown in the model-workflow example.

## Implemented

`vignettes/model-map.Rmd` now has an explicit Phase 17 display row for fitted
random-effect SD surfaces. The row points users to `prediction_grid()` followed
by `predict_parameters(..., dpar = "sd(group)")`, optionally reduced with
`marginal_parameters()`. The grouped-Gaussian output-contract table now points
`sd(id) ~ x_group` users to the same helpers.

NEWS, the Phase 17 roadmap, and
`docs/design/39-visualization-grammar.md` now record the model-map route.

## Mathematical Contract

This slice does not change any model. It only records the post-fit routing
contract:

```text
sd(group) ~ x_group
prediction_grid() -> predict_parameters(dpar = "sd(group)")
prediction rows have component random-effect-sd-model
```

The model-map wording keeps fitted random-effect SD surfaces separate from
residual `sigma`, raw responses, `emmeans`, and plotting-helper support.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-157-random-scale-model-map-route.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-040912-codex-checkpoint.md`
- `vignettes/model-map.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-map.Rmd`:
  passed.
- `git diff --check`: passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-map.Rmd", output_dir = tempfile("model-map-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `articles/model-map.html`, `ROADMAP.html`, and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- Positive source/rendered scan for the Slice 157 random-effect SD map route
  found the expected source and rendered entries.
- Stale-claim scan for direct-SD confidence intervals, direct-SD `emmeans`,
  raw-response confusion, and plotting-helper overclaim found only intended
  boundary wording.
- `Rscript -e "devtools::test(filter = 'prediction-grid|predict-parameters|marginal-parameters', reporter = 'summary')"`:
  passed.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-040912-codex-checkpoint.md`.

## Tests Of The Documentation

The model-map article renders, the pkgdown site renders, and the focused table
helper tests still pass. This is enough for a route-map slice because no
runtime behavior changed.

## Consistency Audit

The slice is documentation-only. It does not add a plotting helper, direct-SD
intervals, `emmeans` support, formula grammar, likelihood code, object
structure, or random-effect scale model family.

## What Did Not Go Smoothly

Nothing material.

## Team Learning

Pat should keep the model map and worked tutorials synchronized: the map tells
users which route to start from, while the worked article shows the concrete
fit-grid-table sequence. Rose should keep map rows from advertising planned
plotting or interval support before tests exist.

## Known Limitations

- The map now points to current point-estimate table helpers only.
- Direct-SD uncertainty intervals, direct-SD `emmeans`, and a dedicated
  random-effect SD plotting helper remain planned or unsupported.

## Next Actions

Do not start a larger feature before the 5am report. Let CI finish for this
small documentation route, merge if green, then prepare the overnight summary.
