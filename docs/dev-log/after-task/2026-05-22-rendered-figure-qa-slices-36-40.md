# After Task: Rendered Figure QA Slices 36-40

## Goal

Continue the rendered-figure QA sequence after PR #304 by improving
`location-scale`, `which-scale`, and `phylogenetic-spatial` article figures
without changing model behaviour, formula grammar, or interval methods.

## Implemented

Merged PR #304, started `codex/rendered-figure-qa-36-40` from `main`, and made
three article-level figure changes:

- Added two figures to `location-scale`: a raw response-scale growth panel with
  fitted `mu` lines and 95% Wald bands, and a separate fitted residual-`sigma`
  habitat contrast with 95% Wald intervals.
- Added two figures to `which-scale`: a fitted residual-`sigma` curve with a
  95% Wald band, and a fitted `sd(population)` display that intentionally shows
  no interval because the prediction table marks that random-effect-SD surface
  as interval-unavailable.
- Updated both `phylogenetic-spatial` q=2 Confidence Eyes so titles,
  subtitles, captions, colour, and alt text identify the latent-correlation
  estimand, 95% profile interval, and dotted zero line.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
rendered figures; Fisher checked uncertainty provenance and data grain; Pat and
Darwin checked reader decoding; Grace checked rendered article output, alt
text, tests, and pkgdown; Noether checked axes against estimands; Curie checked
prediction-table provenance; Rose caught and fixed an observation-row versus
population-row habitat mapping error in the new `which-scale` SD plot.

## Mathematical Contract

No likelihood, formula grammar, extractor, fitted model, plotting helper, or
interval method changed. The edits only affect article plotting recipes,
captions, alt text, and plot labels. Raw observations remain response-scale
evidence. Fitted `mu`, `sigma`, `sd(population)`, and latent-correlation rows
remain model summaries with their displayed uncertainty source named where an
interval is supported.

## Files Changed

- `vignettes/location-scale.Rmd`
- `vignettes/which-scale.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `docs/dev-log/audits/2026-05-22-rendered-figure-qa-slices-36-40.md`
- `docs/dev-log/after-task/2026-05-22-rendered-figure-qa-slices-36-40.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
gh pr merge 304 --squash --delete-branch --subject "Polish workflow figure QA slices (#304)"
git checkout -b codex/rendered-figure-qa-36-40
air format vignettes/location-scale.Rmd vignettes/which-scale.Rmd vignettes/phylogenetic-spatial.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); for (article in c('location-scale','which-scale','phylogenetic-spatial')) pkgdown::build_article(article, new_process = FALSE, quiet = TRUE)"
Rscript tools/fix-pkgdown-reference-alt.R pkgdown-site
Rscript -e "devtools::test(filter = 'prediction-grid|predict-parameters|plot-parameter-surface|plot-corpairs', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
```

The three target articles rebuilt successfully. Article-image alt-text
inspection found two referenced images in each target article and 0 missing alt
attributes. Targeted prediction and plot tests passed. `git diff --check` was
clean. `pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

This slice changes article plotting recipes and captions. The primary
validation is rendered-output inspection after rebuilding the three articles.
The targeted tests cover the helpers and tables used by the changed figures:
`prediction_grid()`, `predict_parameters()`, `plot_parameter_surface()`, and
`plot_corpairs()`.

## Consistency Audit

The case-by-case visual rule still holds:

- raw response points appear only on the response-scale growth plot;
- fitted `mu` and `sigma` displays use Wald intervals only where the prediction
  table supplies finite supported bounds;
- fitted `sd(population)` is shown without intervals because the prediction
  table reports `interval_source = "not_available"`;
- animal and `relmat()` q=2 latent correlations use Confidence Eyes because
  they are row-wise correlation summaries with profile intervals and a
  meaningful zero reference.

## GitHub Issue Maintenance

Open issue #58 remains the overlapping visualization-layer issue. This slice
should comment on #58 after the PR is opened.

## What Did Not Go Smoothly

The first `which-scale` random-effect-SD figure joined habitat from the
observation-level `fish` rows. `predict_parameters(dpar = "sd(population)")`
returns population-level rows for this model, so the plot initially collapsed
the forest and grassland estimates toward the same value. The rendered PNG
inspection caught the error. The fix joins habitat from `population_info`
instead.

## Team Learning

Rendered figure QA should treat row provenance as part of visual correctness.
When a prediction table reports group-level SDs, Fisher and Rose should check
whether row indices refer to observations, groups, or newdata rows before
aggregating for display.

## Known Limitations

This slice does not add profile or bootstrap uncertainty for modelled
random-effect SD surfaces. It preserves the current prediction-table boundary:
show point estimates and say when no supported interval is available.

## Next Actions

1. Open a PR and update issue #58 with the slice summary.
2. Continue the rendered-figure sweep with another article group after this PR
   is green or deliberately queued.
