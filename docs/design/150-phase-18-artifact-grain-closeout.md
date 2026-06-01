# Phase 18 Artifact-Grain Closeout

## Purpose

Issue #255 asked the simulation layer to stop drawing distributional clouds
from aggregate-only summaries. The current Phase 18 contract is now explicit:
replicate-level simulation artifacts carry `artifact_grain = "replicate"`,
aggregate summaries carry `artifact_grain = "aggregate"`, and report code may
draw replicate-error clouds only from replicate-ready inputs.

## Current Guarantee

The guarantee applies to current first-wave report staging and the first
figure-producing count gallery.

| Surface | First-wave surface | Replicate artifact | Aggregate artifact | Current display rule |
| --- | --- | --- | --- | --- |
| Gaussian location-scale | `gaussian_ls_grid` | `replicate_csv` rows are classified as `replicate_ready` | `aggregate_csv` rows are classified as `aggregate_only` | First-wave reports allow clouds only from replicate-ready rows. |
| Gaussian `meta_V(V = V)` | `meta_v_grid` | `replicate_csv` rows are classified as `replicate_ready` | `aggregate_csv` rows are classified as `aggregate_only` | Known sampling variance remains input data; aggregate summaries stay as points, bars, and MCSE ranges. |
| Count `mu` random effects | `count_mu_random_effect_grid` | `replicate_csv` rows are classified as `replicate_ready` | `aggregate_csv` rows are classified as `aggregate_only` | The count gallery draws replicate-error points only when `artifact_grain = "replicate"`. |
| Fixed-effect proportions | `proportion_fixed_effect_grid` | `replicate_csv` rows are classified as `replicate_ready` | `aggregate_csv` rows are classified as `aggregate_only` | First-wave reports keep aggregate summaries out of clouds until a replicate-ready artifact is present. |
| Bivariate residual `rho12` | `biv_rho12_grid` | `replicate_csv` rows are classified as `replicate_ready` | `aggregate_csv` rows are classified as `aggregate_only` | First-wave reports separate residual-correlation evidence from aggregate Monte Carlo uncertainty. |

## Evidence

The table-bundle test now covers these five current report surfaces with
synthetic first-wave outputs. For each surface, `aggregate_csv` must return
`grain_status = "aggregate_only"` and
`plot_geometry = "aggregate_points_bars_mcse_only"`, while `replicate_csv`
must return `grain_status = "replicate_ready"` and
`plot_geometry = "replicate_clouds_allowed"`.

The rendered count-gallery test covers the figure-facing failure mode directly:
an input with `error`, `term`, `family`, and `parameter_class` columns is still
not cloud-ready when it carries `artifact_grain = "aggregate"`.

## Boundary

This closeout does not dispatch a new grid, claim recovery or coverage, or
promote any planned model surface. It closes the current artifact-grain
reporting contract for #255. Future simulation galleries should use #461 to
apply the same gate whenever they add cloud-style, dot-density, empirical
quantile, or replicate-level failure displays.
