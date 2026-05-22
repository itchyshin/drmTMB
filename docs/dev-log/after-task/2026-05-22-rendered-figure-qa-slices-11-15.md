# After Task: Rendered Figure QA Slices 11-15

## Goal

Continue the rendered-figure QA sequence after PR #299 by improving the next
article figures that still looked visually heavier than their statistical
purpose required.

## Implemented

Merged PR #299, started `codex/rendered-figure-qa-11-15` from `main`, and
polished two rendered article surfaces:

- `model-workflow` fitted surfaces now use line-and-ribbon geometry for dense
  continuous prediction grids.
- `model-workflow` habitat contrast now uses a compact horizontal point
  interval with matching caption and alt text.
- `bivariate-coscale` keeps the corrected Confidence Eye row display but drops
  the redundant legend.

No spawned subagents were used. Ada coordinated the slice; Florence checked the
rendered figures; Fisher checked interval provenance; Pat and Darwin checked
reader decoding; Grace checked renderability; Noether checked labels against
estimands; Rose checked repeated figure-pattern drift.

## Mathematical Contract

No likelihood, formula grammar, parameterization, or inferential target
changed. The fitted `mu` and `sigma` surfaces still come from
`predict_parameters(conf.int = TRUE)` and use Wald confidence bands. The
habitat contrast still reports fitted `mu` at temperature zero with 90% Wald
confidence intervals. The bivariate correlation rows still display 95% profile
intervals from the explicit `corpairs()` table.

## Files Changed

- `vignettes/model-workflow.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `docs/dev-log/audits/2026-05-22-rendered-figure-qa-slices-11-15.md`
- `docs/dev-log/after-task/2026-05-22-rendered-figure-qa-slices-11-15.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format vignettes/model-workflow.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = TRUE)"
air format vignettes/bivariate-coscale.Rmd
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('bivariate-coscale', new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::test(filter = 'plot-parameter-surface|plot-corpairs')"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

The targeted plot-helper tests passed with 88 passing expectations and no
failures, warnings, or skips. `pkgdown::check_pkgdown()` found no problems.
`git diff --check` was clean.

Rendered HTML image inventory:

```text
pkgdown-site/articles/model-workflow.html      images=5  missing_alt=0
pkgdown-site/articles/bivariate-coscale.html   images=2  missing_alt=0
pkgdown-site/articles/simulation-plot-grammar.html images=5 missing_alt=0
pkgdown-site/articles/figure-gallery.html      images=21 missing_alt=0
pkgdown-site/articles/phylogenetic-spatial.html images=2 missing_alt=0
pkgdown-site/reference/plot_corpairs.html      images=1  missing_alt=1
pkgdown-site/reference/plot_parameter_surface.html images=1 missing_alt=1
```

## Tests Of The Tests

This slice changes vignette plotting recipes only. It does not change exported
plot-helper mechanics, so the relevant evidence is rendered HTML plus direct
PNG inspection rather than a new unit test.

## Consistency Audit

The caption and alt text for `habitat-contrast-plot` were corrected after the
first render exposed stale "vertical interval" wording. The final rendered
figure uses horizontal intervals and the source now says horizontal intervals.

The case-by-case rule still holds: raw data stay raw, fitted surfaces use
line/ribbon uncertainty, two fitted estimates use point intervals, and fitted
correlation rows use Confidence Eyes only when profile interval rows are
available.

## GitHub Issue Maintenance

Open issue #58 remains the overlapping visualization-layer issue. This slice
should comment on #58 after the PR is opened.

## What Did Not Go Smoothly

The first visual edit changed the habitat contrast orientation but left the old
caption and alt text. The HTML inventory caught that mismatch before closeout.

## Team Learning

Florence's review is sharper when the figure purpose is named first: raw
pattern, fitted surface, fitted contrast, simulation operating characteristic,
or correlation compatibility row. Rose should keep checking captions and alt
text after visual edits, because label drift is easy when a plot changes shape.

## Known Limitations

Reference example images still lack article-style alt text in generated
pkgdown HTML. That remains a separate accessibility slice because the current
reference-page example pipeline does not use vignette `fig.alt` hooks.

## Next Actions

1. Open the PR and update issue #58.
2. After merge, continue with the remaining rendered-reference accessibility
   question or the next figure-heavy article whose rendered image still looks
   inconsistent with its data grain.
