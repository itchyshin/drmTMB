# Spatial-models mesh and uncertainty figure audit

Date: 2026-08-02

## Scope

Florence reviewed the rendered `spatial-models` article after the fixed-kappa
mesh slice. The audit covered the coordinate-site field map, the spatial
intercept/slope SD display, and the bivariate spatial correlation display.

| Surface | Data grain | Uncertainty source | Reader risk | Disposition |
| --- | --- | --- | --- | --- |
| Site-field map | conditional site-level fitted location effects from `ranef()` | none validated for this display | readers could mistake conditional effects for raw responses or infer asymmetric colour magnitudes | caption now says simulated example and uncertainty not shown; colour limits are symmetric about zero |
| Intercept/slope SD summary | two fitted variance-component point estimates | intervals for these exact rows are not validated | a shared x axis compared response units with response-units-per-depth | replaced the chart with a compact table that gives each estimate, unit, and uncertainty status; the near-zero slope boundary is explicit |
| q2 spatial correlation | one fitted latent location-location correlation | profile mechanics exist, but calibration and coverage remain planned | an unused fill scale emitted a visible warning and the chunk name implied a Confidence Eye | `interval = FALSE` is explicit; the unused scales are removed; the point is directly labelled; the panel is shorter and named as a point estimate |

## Render evidence

`pkgdown::build_article("spatial-models", new_process = FALSE)` completed after
the repairs. The rendered HTML contains no emitted warning output, including
no manual-scale warning, `NaNs produced`, or unknown-parameter warning.
Original-resolution inspection confirmed that the site-field title and
subtitle are not clipped and that the compact q2 plot retains the full
`[-1, 1]` correlation axis.

## Claim boundary

No confidence interval or Confidence Eye was added. The current spatial SD
and q2 correlation rows remain point-only because their interval calibration
and coverage are not validated. The figure repair does not promote issue #881,
change the dense `coords =` route, estimate mesh range, or widen the mesh model.
