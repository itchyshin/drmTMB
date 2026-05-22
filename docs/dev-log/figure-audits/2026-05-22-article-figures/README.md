# Figure Audit: Article Figures First Triage

Date: 2026-05-22

## Scope

This is the first figure-heavy triage after the article navigation sweep. It
checks the rendered figure surfaces that the rendered article checklist flagged
for immediate attention:

- `model-workflow`
- `bivariate-coscale`
- `figure-gallery`
- `simulation-plot-grammar`

This pass does not certify every gallery figure as final publication artwork.
It records rendered evidence, fixes the blocking `bivariate-coscale` display
defects, and gives the finite-interval compatibility figures their public
`Confidence Eye` name while leaving the deeper per-figure polish pass queued.

## Evidence Files

Contact sheets:

- `model-workflow-contact.png`
- `bivariate-coscale-contact.png`
- `figure-gallery-contact-1.png`
- `figure-gallery-contact-2.png`
- `simulation-plot-grammar-contact.png`

The contact sheets were generated from rendered `pkgdown-site/articles/*`
figure PNGs. The two changed `bivariate-coscale` figures were also inspected
individually after rerendering.

## Rejected Draft

The first Confidence Eye edit in this slice was rejected after rendered review.
It renamed existing raindrop/error-bar style panels before returning to the
visual idea itself. That produced cluttered figures with extra bars or outlines
and did not satisfy the user-facing design: finite confidence/compatibility
region plus hollow estimate circle, with no invented uncertainty.

Rose records this as a process failure: do not retrofit an old uncertainty
panel and call it a Confidence Eye. Start from the visual grammar, then render
and inspect the figure before recording it as fixed.

## Findings

| Article | Rendered figures | Alt text after pass | Visual verdict | Action |
| --- | ---: | --- | --- | --- |
| `model-workflow` | 5 | complete | Readable first-pass workflow figures; no obvious clipping or empty interval bands in rendered triage. | No source edit in this pass. |
| `bivariate-coscale` | 2 | fixed | The residual `rho12` curve had no alt text, no uncertainty display, and a transparent/base-plot rendering that failed on dark backgrounds. The group-level `corpairs()` plot had no alt text and unreadable long row labels. | Added `fig.alt`, changed the residual curve to a white-background ggplot with a 95% Wald ribbon from `predict_parameters()`, and gave `plot_corpairs()` compact labels plus a title/subtitle that states intervals are not drawn. |
| `figure-gallery` | 21 | partial | Contact-sheet triage found the gallery broadly readable, but the first Confidence Eye attempt was rejected. The repaired correlation-row figure now uses pale finite Fisher-z/atanh confidence regions plus hollow estimate circles for residual, group, phylogenetic, spatial, animal, and `relmat()` rows. | Named the finite-interval compatibility display `Confidence Eye`, removed default CI bars and filled estimate dots from the correlation-row display, and clarified that CI-line overlays are optional variants rather than the default. |
| `simulation-plot-grammar` | 5 | complete | Rendered panels are readable and keep replicate dots, aggregate points, MCSE intervals, and failure ledgers visible. | No source edit in this pass; future pass should check MCSE/provenance wording figure by figure. |

## Repaired Figures

`bivariate-coscale-rho12-curve`

- Data grain: fitted residual correlation on a `newdata` disturbance grid.
- Uncertainty source: 95% Wald interval from `predict_parameters()`.
- Problem: empty alt text and transparent base-plot rendering were fragile
  outside a white pkgdown page. The point-only line also underused available
  uncertainty.
- Fix: added alt text and a white-background ggplot display with a 95% Wald
  ribbon.

`bivariate-coscale-group-corpairs-plot`

- Data grain: two fitted correlation rows from `corpairs(fit_group)`, one
  residual row and one group-level `mu1`/`mu2` random-intercept row.
- Uncertainty source: none drawn in this example.
- Problem: empty alt text and default long
  `level | class | parameter` labels made the row labels unreadable.
- Fix: added alt text, compact display labels, and a title/subtitle that name
  the residual and individual-level layers while saying intervals are not
  drawn.

`figure-gallery` correlation-row Confidence Eye

- Data grain: compact `corpairs()`-style fitted correlation-row table for
  residual `rho12`, group, phylogenetic, spatial, animal, and `relmat()`
  layers.
- Uncertainty source: illustrative finite 95% intervals transformed on
  Fisher's `z`/atanh scale.
- Problem: the first edit relabelled a cluttered existing display instead of
  designing from the Confidence Eye grammar. A later draft still showed black
  interval bars and filled points, which contradicted the default design.
- Fix: repaired the six-row correlation display itself: pale finite confidence
  regions, hollow point-estimate circles, no outer outline, no default CI bar,
  and row labels that name the correlation layer.

## Remaining Figure Work

The next figure pass should inspect the `figure-gallery` images one by one and
decide which additional uncertainty figures should graduate to the Confidence
Eye style. The default style is intentionally sparse: pale finite
confidence/compatibility region, hollow point-estimate circle, no outer outline,
and no CI bar. Optional outlines or interval bars should be treated as print or
diagnostic variants, not the default. That pass should record, for every
figure, the plotted data grain, interval source, support boundary, missing-cell
handling, and whether the image is final artwork or a temporary teaching
scaffold.
