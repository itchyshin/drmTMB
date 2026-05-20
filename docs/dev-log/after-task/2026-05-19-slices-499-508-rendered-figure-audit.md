# After-Task Report: Slices 499-508 Rendered Figure Audit

## Active Perspectives

Ada rebuilt the rendered pkgdown site and coordinated the audit. Florence
reviewed the generated figure contact sheets. Pat watched whether figure
subtitles matched what the reader could actually see. Grace checked pkgdown
structure after the edit. Rose recorded the visual issue so it does not get
lost behind the green test suite.

## Goal

Inspect the rendered pkgdown article figures after the reference and
simulation-plot cleanup, with special attention to the uncertainty displays
that had previously looked inconsistent.

## Findings

- The rendered pkgdown site rebuilt successfully.
- The stale-status scan found intended planned-boundary wording rather than a
  new implemented-versus-planned contradiction.
- The rendered simulation RMSE panel still had a visual mismatch: the subtitle
  said points and bars showed RMSE and MCSE intervals, but the bars were nearly
  invisible because the x-axis range was too wide for the fixture values.

## Changes Made

- Updated `vignettes/simulation-plot-grammar.Rmd` so the RMSE display uses
  capped horizontal MCSE intervals through `geom_errorbarh()`.
- Tightened the RMSE x-axis and moved the RMSE facets to a two-by-two layout,
  making both the points and MCSE intervals legible.
- Saved rendered contact sheets for the figure-gallery and simulation-plot
  grammar figures under
  `docs/dev-log/figure-audits/2026-05-19-rendered-pkgdown/`.

## Checks Run

```sh
Rscript -e "pkgdown::build_site()"
Rscript -e "pkgdown::build_article('simulation-plot-grammar')"
Rscript -e "pkgdown::check_pkgdown()"
rg -n "first fitted bivariate phylogenetic|q=4 correlations are derived-only|q4.*derived-only|bootstrap confidence intervals.*implemented|public bootstrap|animal models are implemented|animal\\(\\).*fitted|spatial.*corpair.*implemented|phylogenetic scale terms planned|not yet fitted|planned but not implemented|remain planned" pkgdown-site README.md NEWS.md ROADMAP.md docs/design vignettes --glob '!pkgdown-site/search.json'
```

## Visual Evidence

- `docs/dev-log/figure-audits/2026-05-19-rendered-pkgdown/figure-gallery-contact-sheet.png`
- `docs/dev-log/figure-audits/2026-05-19-rendered-pkgdown/simulation-plot-grammar-contact-sheet.png`

## Known Limitations

This pass visually inspected the rendered contact sheets and the RMSE
before/after PNGs. It was not a full accessibility or editorial review of every
figure caption and alt-text string.

## Next Actions

Continue the next implementation or documentation slice from the green
full-test baseline, using the regenerated contact sheets as the rendered figure
evidence for this pass.
