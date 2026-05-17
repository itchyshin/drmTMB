# After Task: Slice 156 random-effect scale workflow example

## Goal

Add the first reader-facing model-workflow example for predicting a fitted
random-effect SD surface.

## Implemented

The model-workflow article now includes a concrete `sd(site) ~ reef_cover`
example. It simulates site-level reef cover, fits a Gaussian location model
with a site random intercept and direct-SD formula, builds an explicit
`prediction_grid()` over reef cover, reports
`predict_parameters(..., dpar = "sd(site)")`, and reduces the same grid with
`marginal_parameters(..., by = "reef_cover")`.

NEWS, the Phase 17 roadmap, and
`docs/design/39-visualization-grammar.md` now describe the same reader-facing
contract.

## Mathematical Contract

This slice does not change the random-effect scale model:

```text
growth_ij ~ Normal(mu_ij, sigma^2)
mu_ij = beta_0 + beta_1 temperature_ij + b_site[j]
b_site[j] = sd_site[j] u_j
u_j ~ Normal(0, 1)
log(sd_site[j]) = alpha_0 + alpha_1 reef_cover_j
```

The article explains that the predicted `sd(site)` rows are random-intercept
SDs, not residual `sigma` and not raw responses.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-156-random-scale-workflow-example.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-035330-codex-checkpoint.md`
- `vignettes/model-workflow.Rmd`

## Checks Run

- Dry-run scout for the proposed vignette model code: passed.
- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd`:
  passed.
- `git diff --check`: passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`:
  passed and rendered the new section.
- `Rscript -e "devtools::test(filter = 'prediction-grid|predict-parameters|marginal-parameters', reporter = 'summary')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `articles/model-workflow.html`, `ROADMAP.html`, and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- Positive source/rendered scan for the Slice 156 `sd(site) ~ reef_cover`
  workflow found the expected source and rendered entries.
- Stale-claim scan for direct-SD confidence intervals, direct-SD `emmeans`,
  and raw-response confusion found only intended boundary wording.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-035330-codex-checkpoint.md`.

## Tests Of The Example

The rendered article executes the full example path: fit, grid construction,
`predict_parameters()`, and `marginal_parameters()`. The focused helper tests
also passed after the article render.

## Consistency Audit

The slice is documentation-only. It introduces no formula grammar,
likelihood, object structure, S3 method, or interval changes. The wording keeps
direct-SD point estimates separate from residual `sigma`, raw responses,
`emmeans`, and confidence intervals.

## What Did Not Go Smoothly

Nothing material. A dry-run scout checked that the small model fit and table
outputs were suitable before the article was edited.

## Team Learning

Pat should put direct-SD workflows after the general prediction-table section
so applied readers see the grid before interpretation. Fisher should keep
interval absence visible for direct-SD point surfaces. Rose should keep
random-effect SD prose separate from residual `sigma` and raw-response plots.

## Known Limitations

- This slice adds a reader-facing point-estimate example only.
- It does not add direct-SD uncertainty intervals, `emmeans` support,
  bivariate random-effect scale surfaces, empirical weighting beyond the
  existing helper, or a plotting helper for random-effect SDs.

## Next Actions

If time remains before the 5am report, continue with one more small
documentation or validation slice rather than widening the random-effect scale
model family.
