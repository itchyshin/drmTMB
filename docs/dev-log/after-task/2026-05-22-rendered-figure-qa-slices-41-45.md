# After Task: Rendered Figure QA Slices 41-45

## Goal

Continue the rendered-figure QA sequence after PR #305 by improving
`spatial-models` and `phylogenetic-models` with case-specific figures that
separate fitted fields, fitted SDs, and latent correlation rows.

## Implemented

Merged PR #305, started `codex/rendered-figure-qa-41-45` from `main`, and made
two focused article-level changes:

- Added three figures to `spatial-models`: a coordinate map of fitted
  conditional spatial location deviations, a spatial-SD display with finite
  Wald interval where available and a labelled boundary row where the interval
  is not finite, and a q=2 spatial mean-mean Confidence Eye with a 95% profile
  interval.
- Added two figures to `phylogenetic-models`: a fitted residual-`sigma` versus
  phylogenetic-location-SD display with 95% Wald intervals, and a q=2
  phylogenetic mean-mean Confidence Eye with a 95% profile interval.

No spawned subagents were used. Ada coordinated the slice; Florence inspected
rendered figures; Fisher checked uncertainty provenance and data grain; Pat
and Darwin checked reader decoding; Grace checked rendered article output, alt
text, tests, and pkgdown; Noether checked axes against estimands; Curie checked
that fitted examples were small and deterministic; Rose caught one
title-clipping issue and checked for repeated one-rule-fits-all drift.

## Mathematical Contract

No likelihood, formula grammar, extractor, fitted model, plotting helper, or
interval method changed. The edits only affect article plotting recipes,
captions, alt text, and plot labels. Spatial and phylogenetic SD displays use
existing `confint(..., parm = "variance_components")` Wald intervals. Spatial
and phylogenetic q=2 latent correlations use existing `corpairs(...,
conf.int = TRUE)` profile intervals. The near-boundary spatial depth-slope SD
is point-only because the current Wald interval has an infinite upper bound.

## Files Changed

- `vignettes/spatial-models.Rmd`
- `vignettes/phylogenetic-models.Rmd`
- `docs/dev-log/audits/2026-05-22-rendered-figure-qa-slices-41-45.md`
- `docs/dev-log/after-task/2026-05-22-rendered-figure-qa-slices-41-45.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
gh pr merge 305 --squash --delete-branch --subject "Polish scale figure QA slices (#305)"
git checkout -b codex/rendered-figure-qa-41-45
air format vignettes/spatial-models.Rmd vignettes/phylogenetic-models.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); for (article in c('spatial-models','phylogenetic-models')) pkgdown::build_article(article, new_process = FALSE, quiet = TRUE)"
Rscript tools/fix-pkgdown-reference-alt.R pkgdown-site
Rscript -e "devtools::test(filter = 'spatial-gaussian|phylo|plot-corpairs', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
```

The two target articles rebuilt successfully. Article-image alt-text
inspection found three referenced images in `spatial-models`, two referenced
images in `phylogenetic-models`, and 0 missing alt attributes. Targeted
phylogenetic, spatial, and `plot_corpairs()` tests passed. `git diff --check`
was clean. `pkgdown::check_pkgdown()` reported no problems.

## Tests Of The Tests

This slice changes article plotting recipes and captions. The primary
validation is rendered-output inspection after rebuilding the two articles.
The targeted tests cover the fitted routes and plotting helper used by the new
figures: phylogenetic Gaussian models, spatial Gaussian models, and
`plot_corpairs()`.

## Consistency Audit

The case-by-case visual rule still holds:

- the spatial map is a fitted conditional-effects field, not a raw response or
  uncertainty panel;
- spatial and phylogenetic SD figures use Wald intervals only when the current
  interval table gives finite supported bounds;
- the near-boundary spatial slope SD is shown without a misleading infinite
  bar;
- spatial and phylogenetic q=2 latent correlations use Confidence Eyes because
  they are row-wise correlation summaries with profile intervals and a
  meaningful zero reference;
- raw observations do not appear on SD or correlation axes.

## GitHub Issue Maintenance

Open issue #58 remains the overlapping visualization-layer issue. This slice
should comment on #58 after the PR is opened.

## What Did Not Go Smoothly

The first render failed because `confint(..., parm = "variance_components")`
returns bounds but not an `estimate` column. The SD figures now attach point
estimates explicitly from the fitted objects before plotting.

The first spatial map render clipped the title/subtitle. The visible title and
subtitle were shortened, then the article was rebuilt and the PNG reinspected.

## Team Learning

Rendered figure QA should treat finite versus infinite interval bounds as a
visual data-grain problem, not as a formatting nuisance. If a current interval
is boundary-limited or infinite, the figure should label that fact instead of
silently clipping the interval.

## Known Limitations

This slice does not add profile or bootstrap uncertainty for spatial slope SDs.
It preserves the current interval boundary: finite Wald intervals are shown,
and the near-boundary depth-slope SD is point-only.

## Next Actions

1. Open a PR and update issue #58 with the slice summary.
2. Continue the rendered-figure sweep with `animal-models`,
   `relmat-known-matrices`, and remaining map/status articles after this PR is
   green or deliberately queued.
