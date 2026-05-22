# After Task: Confidence Eye Gallery Cleanup

## Purpose

Repair the remaining figure-gallery Confidence Eye examples after the rejected
filled-point and CI-line versions kept resurfacing from stale rendered
artifacts, then complete a one-by-one case-by-case triage of the remaining
gallery figures.

## Team Review

- Ada kept the target fixed to rendered `figure-gallery` PNGs rather than
  contact sheets or prose claims. After the case-by-case review, Ada kept
  Confidence Eyes only for row-wise interval summaries rather than applying one
  visual grammar to every figure.
- Florence enforced the default visual contract: pale finite confidence region,
  hollow point-estimate circle, vertical scale grid, dotted zero line where zero
  is meaningful, no filled dots, no CI bars, no outlines, and no in-plot
  title/subtitle. The Confidence Eye row displays keep the bottom axis as a
  common scale anchor.
- Fisher checked the interval scales: fixed effects use the fitted coefficient
  scale, SD rows are shaped on log-SD and displayed as SDs, and correlations are
  shaped on Fisher's `z`/atanh scale.
- Pat and Darwin checked whether raw data should remain visible in other figure
  classes when they carry sample grain, spread, outliers, repeated-measures
  structure, or biological pattern.
- Grace rebuilt the figure-gallery article and refreshed the stale
  `pkgdown-site/dev` mirror from the current render. She also ran the broader
  `devtools::test()` pass before commit.
- Rose recorded the failure mode: stale local-site and audit PNGs can become
  misleading project evidence if they are shown without refresh or rejected
  labels. She also recorded that one good Confidence Eye figure must not become
  a universal rule for raw-data, line, simulation, or support-boundary figures.

## Changes

- Replaced the mixed fixed-effect, SD, and correlation panel with a single
  clean Confidence Eye display.
- Standardized the Confidence Eye row displays on the same visual family:
  slim lens geometry, hollow estimates, dotted zero reference where meaningful,
  vertical scale grid, and bottom axis.
- Kept the variance-component display in the default Confidence Eye grammar,
  with SD intervals shaped on the log-SD scale.
- Kept the correlation-row display in the approved default grammar, with
  Fisher-z/atanh eyes and hollow point estimates.
- Refreshed the stale `pkgdown-site/dev/articles/figure-gallery_files/` copy
  from the current article render.
- Saved fresh inspected evidence PNGs under
  `docs/dev-log/figure-audits/2026-05-22-article-figures/`.
- Refreshed older tracked audit PNGs that had been showing the rejected
  filled-point/CI-line design as current evidence.
- Completed a one-by-one `figure-gallery` triage table for all 21 rendered
  article figures, recording data grain, uncertainty source, and visual
  verdict.
- Polished the point-interval summary family after rendered review: direct
  prediction summaries, categorical cell summaries, and `emmeans` summaries now
  use a compact point-interval grammar, clearer titles, and a connected
  temperature-slice EMM display.
- Polished broader gallery figures after the user flagged additional weak
  panels: the base gallery theme is quieter, the parameter-surface figure names
  the shared `sigma ~ temperature` curve, support rugs and support-boundary
  strips are tighter, subtitles are shorter, and simulation target/reference
  lines use dotted styling.

## Validation

```sh
air format R/plot-corpairs.R vignettes/figure-gallery.Rmd docs/design/39-visualization-grammar.md docs/dev-log/figure-audits/2026-05-22-article-figures/README.md docs/dev-log/team-improvements.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-22-confidence-eye-gallery-cleanup.md man/plot_corpairs.Rd NEWS.md
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::test(filter = 'plot-corpairs', reporter = 'summary')"
Rscript -e "devtools::test(reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
```

The focused `plot-corpairs` test and full `devtools::test()` suite passed.
`git diff --check` was clean and `pkgdown::check_pkgdown()` reported no
problems after the final broader gallery polish.

Rendered PNGs inspected directly:

- `pkgdown-site/articles/figure-gallery_files/figure-html/confidence-distribution-slopes-1.png`
- `pkgdown-site/articles/figure-gallery_files/figure-html/random-effect-variance-components-1.png`
- `pkgdown-site/articles/figure-gallery_files/figure-html/coefficient-intervals-1.png`
- `pkgdown-site/articles/figure-gallery_files/figure-html/correlation-display-1.png`
- all remaining `pkgdown-site/articles/figure-gallery_files/figure-html/*.png`
  during the case-by-case triage, with polished evidence PNGs saved for the
  compact point-interval family and the broader surface, support-boundary, and
  simulation polish.

## Remaining Work

This cleanup fixes the Confidence Eye examples and completes a first
case-by-case triage of the full `figure-gallery` article. Future work should
treat this as a coherent teaching gallery, not a final manuscript plate: polish
individual panels only when a specific article, paper, or tutorial needs a
tighter layout.
