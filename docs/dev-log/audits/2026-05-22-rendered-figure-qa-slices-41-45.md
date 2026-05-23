# Rendered Figure QA: Slices 41-45

Date: 2026-05-22

## Scope

This note records the next rendered-figure pass after PR #305 merged. The slice
set covered:

41. merge PR #305, start a fresh branch from `main`, and inventory focused
    spatial and phylogenetic guide articles;
42. add a rendered coordinate-site fitted spatial-location field to
    `spatial-models`;
43. add fitted spatial-SD and q=2 spatial-correlation uncertainty displays to
    `spatial-models`;
44. add fitted residual-`sigma` versus phylogenetic-location-SD uncertainty to
    `phylogenetic-models`;
45. add a phylogenetic q=2 mean-mean Confidence Eye, rebuild, inspect, and
    validate the changed article figures.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, Curie, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

Before editing, neither focused guide article had referenced rendered article
images. After editing and rebuilding, the target pages contained five
referenced article images:

- `spatial-models_files/figure-html/spatial-site-field-figure-1.png`
- `spatial-models_files/figure-html/spatial-sd-figure-1.png`
- `spatial-models_files/figure-html/spatial-q2-confidence-eye-1.png`
- `phylogenetic-models_files/figure-html/phylo-sd-figure-1.png`
- `phylogenetic-models_files/figure-html/phylo-q2-confidence-eye-1.png`

## Visual Decisions

The spatial site-field map is a fitted conditional-effects figure. It shows
site coordinates coloured by fitted spatial location deviations from
`ranef(fit_spatial, "spatial_mu")`. It does not draw intervals because the
purpose is to show the fitted site-level field, not a confidence interval.

The spatial-SD display is a model-summary figure. The intercept spatial field
has a finite 95% Wald interval from `confint(..., parm = "variance_components")`.
The depth-slope spatial SD is near the zero boundary and has an infinite upper
Wald bound, so the row is point-only and labelled as a boundary interval. This
avoids drawing an artificial or clipped uncertainty bar.

The spatial q=2 correlation display is a Confidence Eye because
`corpairs(level = "spatial", conf.int = TRUE)` supplies a profile interval for
the latent mean-mean correlation row. The dotted vertical line marks zero.
Raw paired responses do not appear on the correlation axis.

The phylogenetic SD display compares residual `sigma` with the
phylogenetic-location SD from a univariate Gaussian `phylo()` model. Both rows
use response-scale point estimates and 95% Wald intervals.

The phylogenetic q=2 correlation display is a Confidence Eye because
`corpairs(level = "phylogenetic", conf.int = TRUE)` supplies a profile
interval for the latent mean-mean correlation row. The figure distinguishes the
phylogenetic layer from residual `rho12`.

## Visual Inspection

Florence inspected the regenerated PNGs after rebuilding:

- `spatial-site-field-figure-1.png`: the map reads as a fitted site-level
  location field. The first render had clipped title text; the title and
  subtitle were shortened and the article was rebuilt.
- `spatial-sd-figure-1.png`: finite and boundary SD rows are visually distinct,
  with the zero SD boundary shown and no fake infinite interval.
- `spatial-q2-confidence-eye-1.png`: the Confidence Eye is broad but readable,
  with a hollow point estimate and dotted zero line.
- `phylo-sd-figure-1.png`: residual `sigma` and phylogenetic location SD are
  separated with finite 95% Wald intervals.
- `phylo-q2-confidence-eye-1.png`: the Confidence Eye uses a visible 95%
  profile region, hollow estimate, and dotted zero line.

## Remaining Work

The next slice can move to `animal-models`, `relmat-known-matrices`, and
remaining map/status articles that are still table-only. The same rule should
hold: raw response panels only when the response scale is the evidence;
structured SDs and latent correlations should use fitted summaries with named
uncertainty, or point-only rows when intervals are unsupported.
