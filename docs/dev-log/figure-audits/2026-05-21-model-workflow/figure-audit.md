# Figure Audit: Model Workflow Rendered Pass

## Scope

This pass inspected the active rendered figures in
`pkgdown-site/articles/model-workflow.html` after the fast CI workflow update.
The ignored pkgdown figure directory still contained stale `unnamed-chunk-*`
PNGs from earlier renders, so the active inventory came from the HTML image
references, not from the directory listing alone.

Render command:

```sh
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = TRUE)"
```

Active rendered images:

```sh
rg -n "model-workflow_files/figure-html|<img" pkgdown-site/articles/model-workflow.html
```

## Rendered Figure Table

| Figure | Source chunk | Visual data grain | Uncertainty source | Reader risk found | Fix | Verdict |
| --- | --- | --- | --- | --- | --- | --- |
| Temperature surfaces | `temperature-surface-plot` | Fitted `mu` and `sigma` prediction rows from `predict_parameters()` | Wald confidence bands from the prediction table | The old display coloured the `sigma` panel by habitat even though `sigma ~ temperature` has no habitat term, so two identical habitat lines could overlap. | Kept habitat colour for `mu`, filtered `sigma` to one row per temperature, added a neutral grey scale for `sigma`, and added alt text naming the formula boundary. | Pass for this article. |
| Habitat contrast | `habitat-contrast-plot` | Two fitted `mu` rows at temperature zero | Wald 90% confidence intervals from the prediction table | The old two-point panel used a large default grey plotting area. | Added a compact figure size and the article theme. | Pass, with no need for a heavier display in this workflow article. |
| Raw growth pattern | `raw-growth-plot` | Observed response rows | None; raw data only | Default grey panel made the article look unfinished. | Added the article theme, colourblind-safe habitat palette, and explicit alt text. | Pass. |
| Fitted `mu` surface | `mu-temperature-plot` | Fitted `mu` prediction rows | Wald confidence bands from the prediction table | Default styling and unbranded palette weakened comparison with the raw-data panel. | Added the article theme and stable habitat palette. | Pass. |
| Fitted `sigma` surface | `sigma-temperature-plot` | One fitted `sigma` row per temperature after filtering duplicate habitat rows | Wald confidence band from the prediction table | Habitat legend implied a habitat effect on `sigma` that the model did not contain. | Removed habitat colour, added prose explaining the single-line display, and used a neutral line/band. | Pass. |

## Remaining Watch Items

- The article now has figure-level alt text for active rendered figures. Other
  high-risk articles still need the same active-image audit.
- `plot_parameter_surface()` remains intentionally small. This slice only
  changes the article display; it does not add exported theme or plotting
  options.
- Future rendered audits should inventory active HTML image references first,
  because ignored pkgdown image directories can retain stale PNGs from previous
  chunk labels.
