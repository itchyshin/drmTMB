# Rendered Figure QA: Slices 21-25

Date: 2026-05-22

## Scope

This note records the next rendered-figure pass after PR #301 merged. The slice
set covered:

21. merge PR #301 and start a fresh branch from `main`;
22. re-inventory the rendered gallery, model-workflow, bivariate-coscale,
    structural-correlation, and generated-reference images;
23. polish the gallery `parameter-surface` figure so fitted surfaces use
    lines and Wald ribbons without dense grid-point clutter;
24. make no-interval figures explicit, especially conditional random-slope
    modes and the direct `sd(site)` surface whose table reports
    `conf.status = "wald_unavailable"`;
25. synchronize the gallery source map with the visible figure grammar.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace,
Noether, Curie, and Rose. They are review perspectives, not spawned agents.

## Rendered Inventory

The following rendered outputs were checked during this pass:

| Page | Rendered state | Notes |
| --- | --- | --- |
| `figure-gallery` | 21 article images | Main target for this slice. Confidence Eye targets retained their dotted zero lines and hollow points. The changed fitted-surface and no-interval figures were rebuilt and inspected. |
| `model-workflow` | 5 referenced article images | Referenced figures remained consistent with the previous slice. Older `unnamed-chunk-*` PNGs in the ignored `pkgdown-site` directory were stale generated artifacts, not images referenced by the rendered article. |
| `bivariate-coscale` | 2 article images | The residual-versus-individual correlation display retained uncertainty through the Confidence Eye geometry. |
| `phylogenetic-spatial` | 2 article images | The q=2 correlation Confidence Eyes still used the intended row-wise grammar. |
| Generated plotting references | 2 reference images | Previous post-build alt-text treatment remains the current route for generated reference example images. |

## Visual Decisions

The gallery `parameter-surface` figure is an estimate-surface display, not a
raw-data figure and not a Confidence Eye target. It now calls
`plot_parameter_surface(..., point = FALSE)` so the reader sees fitted lines and
95% Wald confidence bands from `predict_parameters()` without a field of dense
grid points. The caption and subtitle name the Wald provenance, and the `sigma`
surface stays separate from raw response data.

The conditional random-slope figure shows site-level conditional modes. Those
lines are useful model output, but they are not interval uncertainty. The
subtitle now says so directly.

The direct `sd(site)` surface is also an estimate-surface display rather than a
Confidence Eye target. It stays line-only because the derived random-effect SD
surface does not yet provide finite Wald bands. The caption, alt text, subtitle,
and source map now point to profile or bootstrap intervals as the appropriate
future route instead of implying uncertainty was silently omitted.

## Visual Inspection

Florence inspected the changed rendered PNGs after rebuilding
`figure-gallery`:

- `figure-gallery_files/figure-html/parameter-surface-1.png`: improved from a
  line, ribbon, and dense-grid-point display to a cleaner line-and-ribbon
  surface. The title/subtitle/caption now connect the visible ribbons to
  `predict_parameters()` Wald bands.
- `figure-gallery_files/figure-html/random-slope-modes-1.png`: retained as a
  raw-observation plus conditional-mode display, with the subtitle clarifying
  that the lines are modes rather than interval uncertainty.
- `figure-gallery_files/figure-html/random-effect-sd-surface-1.png`: retained
  as a fitted direct-SD surface with rug support and no band. The rendered
  subtitle now tells the reader that profile or bootstrap intervals are needed.
- `figure-gallery_files/figure-html/coefficient-intervals-1.png`,
  `correlation-display-1.png`, and
  `random-effect-variance-components-1.png`: retained as row-wise Confidence
  Eye displays with dotted zero lines where zero is meaningful and hollow
  point-estimate circles.

## Remaining Work

The next slice can move beyond the broad gallery into either reference pages or
article pages whose rendered image directories contain stale generated PNGs.
Those stale artifacts are not user-facing when the HTML does not reference them,
but they make audits harder and should be cleaned or documented when a future
slice touches the relevant article build.
