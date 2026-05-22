# Rendered Figure QA: Slices 26-30

Date: 2026-05-22

## Scope

This note records the next rendered-figure pass after PR #302 merged. The slice
set covered:

26. merge PR #302 and start a fresh branch from `main`;
27. clarify the categorical-by-categorical gallery figure so fitted means and
    Wald intervals are not conflated;
28. clarify the empirical marginal summary as plug-in means with averaged
    row-wise Wald limits, not a full marginal-mean uncertainty calculation;
29. clarify the continuous-by-continuous interaction ribbon provenance in the
    rendered subtitle;
30. polish generated reference examples for `plot_corpairs()` and
    `plot_parameter_surface()`.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, Curie, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

The following rendered outputs were checked during this pass:

| Page | Rendered state | Notes |
| --- | --- | --- |
| `figure-gallery` | 21 article images | Main gallery targets were the categorical-cell summary, empirical marginal summary, and continuous-interaction ribbon plot. |
| Generated plotting references | 2 reference images | Both example images were rebuilt after `devtools::document()` so roxygen examples and pkgdown output stayed synchronized. |
| `model-workflow` | 5 referenced article images | Inspected as audit context only. The figures remain acceptable for their current article purpose, and stale ignored `unnamed-chunk-*` files were not treated as referenced output. |

## Visual Decisions

The categorical-by-categorical plot is a raw-data plus fitted-cell summary. It
should show both grains because the raw observations help readers see cell-level
support, while the large points and bars carry the fitted `mu` means and 95%
Wald intervals. The caption, alt text, and subtitle now say this directly.

The empirical marginal plot is more limited. The large points are plug-in
marginal means, and the bars average row-wise Wald limits from fitted-row
predictions. That display is useful, but it is not a full uncertainty interval
for an empirical marginal mean. The caption, alt text, subtitle, y-axis label,
and source map now preserve that distinction.

The continuous-by-continuous interaction figure already had the right visual
grammar: raw points, fitted lines, and ribbons. The rendered subtitle now names
the ribbons as 95% Wald bands at three moisture slices so readers do not have
to infer the uncertainty source from the code chunk.

The `plot_corpairs()` reference example is a Confidence Eye target. It now uses
multi-line row labels, a manual colour/fill palette, no redundant legend, hollow
point-estimate circles, and the dotted zero reference line already supplied by
the helper.

The `plot_parameter_surface()` reference example is an estimate-surface display,
not a raw-data figure. It now suppresses grid points and uses fitted lines with
Wald ribbons plus a title and subtitle that name the interval provenance.

## Visual Inspection

Florence inspected these regenerated PNGs after rebuilding the reference topics
and `figure-gallery`:

- `reference/plot_corpairs-1.png`: now follows the target Confidence Eye
  grammar with readable row labels, pale finite regions, hollow estimates, and
  a visible dotted zero line.
- `reference/plot_parameter_surface-1.png`: now shows two uncluttered parameter
  surfaces with lines and ribbons only.
- `figure-gallery_files/figure-html/cat-cat-interaction-1.png`: raw points,
  fitted points, and bars remain visible, and the subtitle no longer implies
  intervals are the fitted means.
- `figure-gallery_files/figure-html/empirical-marginal-summary-1.png`: the
  large points and bars are readable, and the subtitle names the plug-in and
  averaged-rowwise nature of the display.
- `figure-gallery_files/figure-html/cont-cont-interaction-1.png`: the raw
  points, fitted slices, and ribbons remain visually balanced; the subtitle now
  names the Wald bands.

## Remaining Work

The next slice can continue through article pages that are visually adequate
but still have weaker reader contracts than the gallery: model-workflow figures
with plain base plotting, bivariate-coscale correlation displays, or generated
examples whose rendered reference output is still more useful than beautiful.
The current slice leaves those as audit targets rather than changing them
without a specific figure purpose.
