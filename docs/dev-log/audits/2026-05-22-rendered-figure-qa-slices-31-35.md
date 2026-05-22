# Rendered Figure QA: Slices 31-35

Date: 2026-05-22

## Scope

This note records the next rendered-figure pass after PR #303 merged. The slice
set covered:

31. merge PR #303, start a fresh branch from `main`, and inventory referenced
    `model-workflow` and `bivariate-coscale` figures;
32. improve the `model-workflow` raw growth panel as a raw-data figure with no
    implied model uncertainty;
33. improve the `model-workflow` `mu` and `sigma` temperature panels so fitted
    means, residual SDs, and Wald bands are visible in the plot;
34. improve the combined `model-workflow` surface and habitat-contrast figures
    so fitted summaries, confidence levels, and response scales are explicit;
35. re-check the `bivariate-coscale` residual-correlation curve and
    correlation Confidence Eye for zero-reference and uncertainty consistency.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, Curie, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

The following referenced rendered outputs were checked during this pass:

| Page | Rendered state | Notes |
| --- | --- | --- |
| `model-workflow` | 5 referenced article images | Changed all five referenced images. Stale ignored `unnamed-chunk-*` PNGs remained outside the rendered HTML reference set. |
| `bivariate-coscale` | 2 referenced article images | Changed the residual `rho12` curve wording and the two-row correlation Confidence Eye labels/subtitle. |

The referenced-image inventory found:

- `model-workflow_files/figure-html/temperature-surface-plot-1.png`
- `model-workflow_files/figure-html/habitat-contrast-plot-1.png`
- `model-workflow_files/figure-html/raw-growth-plot-1.png`
- `model-workflow_files/figure-html/mu-temperature-plot-1.png`
- `model-workflow_files/figure-html/sigma-temperature-plot-1.png`
- `bivariate-coscale_files/figure-html/bivariate-coscale-rho12-curve-1.png`
- `bivariate-coscale_files/figure-html/bivariate-coscale-group-corpairs-plot-1.png`

## Visual Decisions

The raw growth panel is a raw-data figure. It now has a title and subtitle that
say the points are observed response values and no model interval is shown. No
smooth line or fake interval was added.

The fitted `mu` panel is a fitted mean surface. It now names `mu`, the habitat
comparison, and the 95% Wald bands from `predict_parameters()` in visible plot
text, caption, and alt text.

The fitted `sigma` panel is a residual-SD surface, not a response plot. It now
names `sigma` as the fitted residual SD, says the ribbon is a 95% Wald band, and
explains that one band is drawn because habitat is not in the `sigma` formula.
Raw growth points stay out of this panel.

The combined `mu`/`sigma` surface is a distributional-parameter display. It now
has a visible title and subtitle, an explicit response-scale y-axis, and a
caption/alt text that name the 95% Wald bands and the fact that `sigma` is
shared across habitats.

The habitat contrast is a discrete fitted-`mu` summary. It now uses the same
habitat palette as the other workflow figures and states that points are fitted
`mu` estimates while bars are 90% Wald intervals.

The bivariate residual `rho12` curve remains a line-and-ribbon display because
the correlation changes over a continuous disturbance predictor. It is not a
Confidence Eye target. Its caption, alt text, and subtitle now name the dotted
zero line in addition to the 95% Wald ribbon.

The two-row bivariate `corpairs()` plot remains a Confidence Eye target because
it is a row-wise fitted-correlation display with profile intervals. Multi-line
row labels and the subtitle now make the dotted zero line explicit.

## Visual Inspection

Florence inspected the regenerated PNGs after rebuilding both articles:

- `raw-growth-plot-1.png`: raw points remain the evidence; no model interval is
  implied.
- `mu-temperature-plot-1.png`: the fitted `mu` comparison and 95% Wald bands are
  visible and labelled.
- `sigma-temperature-plot-1.png`: the residual-SD estimand is explicit, and raw
  response data are not plotted on the `sigma` axis.
- `temperature-surface-plot-1.png`: both facets now tell the reader that the
  ribbons are Wald bands and that `sigma` is shared across habitats.
- `habitat-contrast-plot-1.png`: habitat colours now match the workflow palette,
  and the 90% Wald bars are visible.
- `bivariate-coscale-rho12-curve-1.png`: the line/ribbon display remains
  appropriate for a continuous fitted residual-correlation curve; the dotted
  zero reference is now named.
- `bivariate-coscale-group-corpairs-plot-1.png`: the Confidence Eye display
  keeps the residual and individual-level correlation rows separate, with
  readable multi-line labels and a named zero reference line.

## Remaining Work

The next slice can continue into other article pages rather than revisiting
these two immediately. Good candidates are `location-scale`, `which-scale`, and
`phylogenetic-spatial`, with the same rule: inspect rendered images first, then
decide whether the figure needs raw data, fitted surfaces, row-wise
compatibility displays, or explicit no-interval wording.
