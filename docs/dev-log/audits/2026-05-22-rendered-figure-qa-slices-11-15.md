# Rendered Figure QA: Slices 11-15

Date: 2026-05-22

## Scope

This note records the next small rendered-figure pass after PR #299 merged.
The slice set covered:

11. merge PR #299 and start a fresh branch from `main`;
12. re-inventory the active rendered article and reference images;
13. polish `model-workflow` fitted-surface displays so continuous prediction
    grids render as line-and-ribbon surfaces rather than dense point strings;
14. polish the `model-workflow` habitat contrast into a compact horizontal
    point-interval display with matching caption and alt text;
15. remove the redundant legend from the `bivariate-coscale` Confidence Eye
    plot because the row labels already name the correlation layers.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

The following pages were checked after the branch started:

| Page | Rendered images | Missing alt text | Notes |
| --- | ---: | ---: | --- |
| `model-workflow` | 5 | 0 | Main target for this slice. |
| `bivariate-coscale` | 2 | 0 | One Confidence Eye display polished. |
| `simulation-plot-grammar` | 5 | 0 | Re-inventoried; no source change in this slice. |
| `figure-gallery` | 21 | 0 | Re-inventoried; prior gallery pass still holds. |
| `phylogenetic-spatial` | 2 | 0 | Re-inventoried after PR #299. |
| `plot_corpairs()` reference | 1 | 1 | Reference example image still lacks article-style alt text. |
| `plot_parameter_surface()` reference | 1 | 1 | Reference example image still lacks article-style alt text. |

## Visual Decisions

`model-workflow` is a workflow article, so it keeps mixed visual grammars. Raw
response observations remain raw points. Fitted `mu` and `sigma` surfaces are
model-estimate surfaces with Wald confidence bands, so continuous grids should
read as smooth line-and-ribbon displays. Removing dense points makes the
surface and interval source easier to see without changing the underlying
prediction table.

The fitted habitat comparison is a two-row estimate display, not raw data and
not a correlation compatibility row. A compact horizontal point interval is the
right grammar: the point is the fitted `mu` estimate, and the horizontal bar is
the 90% Wald confidence interval requested from `predict_parameters()`.

The `bivariate-coscale` row display already uses Confidence Eyes because both
rows are fitted correlation estimates with profile intervals. The legend was
redundant after the row labels were made explicit, so this slice removed it to
bring the plot closer to the clean reference-style correlation display.

## Visual Inspection

Florence inspected the changed rendered PNGs:

- `model-workflow_files/figure-html/temperature-surface-plot-1.png`: the
  combined `mu` and `sigma` surface now has clean line-and-ribbon geometry and
  a shorter legend.
- `model-workflow_files/figure-html/habitat-contrast-plot-1.png`: the discrete
  fitted `mu` comparison now uses a compact horizontal point interval; the
  caption and alt text correctly say horizontal intervals.
- `model-workflow_files/figure-html/mu-temperature-plot-1.png`: the `mu`
  surface now shows lines plus Wald bands without dense grid points.
- `model-workflow_files/figure-html/sigma-temperature-plot-1.png`: the
  `sigma` surface now shows one line plus one Wald band, matching the scale
  formula.
- `bivariate-coscale_files/figure-html/bivariate-coscale-group-corpairs-plot-1.png`:
  the residual and individual-level correlation Confidence Eyes keep the
  dotted zero line and profile intervals, with no redundant legend.

## Remaining Work

The reference example images still lack article-style alt text in generated
pkgdown HTML. That limitation remains separate from article figures because
the current roxygen examples do not expose the same `fig.cap` and `fig.alt`
hooks as vignettes.
