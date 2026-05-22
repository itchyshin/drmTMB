# Figure Audit Kickoff

## Scope

This is the first rendered-figure pass in the comprehensive audit. It does not
certify the full gallery. It records which figures were rendered and inspected
directly, what was fixed immediately, and which issues should move into the
next Florence-led polish slice.

Rendered with:

```sh
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = FALSE); pkgdown::build_article('model-workflow', new_process = FALSE, quiet = FALSE)"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = FALSE)"
```

The second render happened after editing the correlation-display wording. The
third render happened after applying the first `gllvmTMB`-informed visual
polish pass: lighter raindrop legends and a site-support rug for the
modelled `sd(site)` surface.
The fourth render happened after the full gallery pass compacted sparse
point-interval panels.
The fifth render happened on 2026-05-22 after the two status-boundary
watchlist panels were redesigned as lighter status matrices. Durable evidence
for that pass lives under
`docs/dev-log/figure-audits/2026-05-22-status-matrix-reference-pass/`.

## Directly Inspected Figures

| Page | Chunk | Rendered file | Visual data grain | Uncertainty source | Verdict |
| --- | --- | --- | --- | --- | --- |
| `figure-gallery` | `random-effect-sd-surface` | `pkgdown-site/articles/figure-gallery_files/figure-html/random-effect-sd-surface-1.png` | Fitted `sd(site)` surface on a reef-cover grid plus site-level predictor rug | None drawn; table reports unavailable Wald surface intervals | Improved during this pass: the rug shows design support without placing raw response points on an SD axis. Still needs a future interval route. |
| `figure-gallery` | `coefficient-intervals` | `pkgdown-site/articles/figure-gallery_files/figure-html/coefficient-intervals-1.png` | Wald compatibility display for fixed effects, SDs, and a correlation row | 66% and 95% Wald intervals | Improved during this pass: the redundant bottom legend is removed and row labels carry the parameter-class meaning. |
| `figure-gallery` | `correlation-display` | `pkgdown-site/articles/figure-gallery_files/figure-html/correlation-display-1.png` | Illustrative `corpairs()`-like correlation rows | Illustrative Wald/profile intervals transformed through a guarded correlation-link scale | Improved during this pass: replaced Fisher-z wording with guarded correlation-link wording and removed the redundant layer legend because each row names the layer. |
| `figure-gallery` | `simulation-operating-characteristics` figure 1 | `pkgdown-site/articles/figure-gallery_files/figure-html/simulation-operating-characteristics-1.png` | Fixture replicate errors plus aggregate bias points | Mean bias with 95% MCSE intervals | Fixed during this pass: unsupported cells now say "not targeted" instead of appearing as silent blanks. |
| `figure-gallery` | `simulation-operating-characteristics` figure 2 | `pkgdown-site/articles/figure-gallery_files/figure-html/simulation-operating-characteristics-2.png` | Coverage block dots plus aggregate coverage points | 95% binomial MCSE intervals | Fixed during this pass: subtitle now explains that faint block dots sample replicate-block coverage. |

## Full Gallery Rendered Pass

All 21 rendered PNGs in
`pkgdown-site/articles/figure-gallery_files/figure-html/` were inspected
directly during the next pass. The additional findings were:

| Chunk | Verdict |
| --- | --- |
| `location-scale-fit` | Pass. Raw observations, fitted mean, and interval band are visually clear. |
| `parameter-surface` | Pass for now. The `mu` and `sigma` panels tell the right story; later polish should revisit whether the shared `sigma` panel needs a clearer no-habitat cue. |
| `residual-scale-observed-check` | Pass. It correctly shows residual magnitudes rather than raw responses on a scale axis. |
| `confidence-distribution-slopes` | Pass. The two-row raindrop display is readable and not overburdened by a legend. |
| `shape-inflation-rho12-panels` | Pass. Each panel names a different response-scale distributional parameter. |
| `random-effect-variance-components` | Fixed during this pass: reduced the rendered height so three SD rows do not float in a large blank panel. |
| `random-slope-modes` | Pass. Raw repeated observations and fitted site trajectories are distinguishable. |
| `discrete-comparison` | Fixed during this pass: reduced height and removed the redundant habitat legend because row labels already name `reef` and `kelp`. |
| `cat-cat-interaction` | Pass. Raw observations and fitted cell intervals are visible, with season dodging readable. |
| `emmeans-display` | Fixed during this pass: matched the compact discrete-comparison treatment and removed the redundant habitat legend. |
| `emmeans-factor-grid` | Improved during this pass: reduced height while retaining the season legend because the row labels do not encode season. |
| `emmeans-interaction-grid` | Pass. The temperature slices and habitat colours are readable. |
| `empirical-marginal-summary` | Pass. The subtitle names fitted-row predictions and averaged row-wise Wald limits, not raw responses. |
| `emmeans-boundary-strip` | Improved on 2026-05-22: redesigned as a lighter status matrix with a status marker and current route. |
| `cont-cont-interaction` | Pass. Raw observations, fitted slices, and confidence bands are readable. |
| `correlation-layer-boundaries` | Improved on 2026-05-22: redesigned as a lighter status matrix and corrected stale animal/`relmat()` partial-support colouring. |

## Immediate Fixes

1. Changed `sd(site)` surface wording from "direct random-effect SD surface" to
   "modelled random-effect SD surface" in `vignettes/model-workflow.Rmd`,
   `vignettes/figure-gallery.Rmd`, and
   `docs/design/39-visualization-grammar.md`.
2. Changed the correlation-display subtitle and prose from Fisher-z wording to
   guarded correlation-link wording in `vignettes/figure-gallery.Rmd`.
3. Added "not targeted" labels to the simulation bias panel so unsupported
   surface-estimand cells are visible rather than blank.
4. Reworded the coverage-panel subtitle so faint block dots are explicitly
   replicate-block coverage values.
5. Read the local `gllvmTMB` covariance/correlation plotting helper branch and
   recorded transferable visual lessons in
   `docs/dev-log/audits/2026-05-21-gllvmtmb-visual-lessons.md`.
6. Removed redundant legends from the coefficient and correlation raindrop
   displays, following the sister-package pattern that row labels should name
   the layer when the labels are already visible.
7. Added a site-level predictor rug to the modelled `sd(site)` surface so the
   design support is visible without putting raw response points on an SD
   axis.
8. Reduced the rendered height of sparse point-interval panels and removed
   redundant habitat legends from the two-row `predict_parameters()` and
   `emmeans` displays.
9. Re-rendered `figure-gallery` and confirmed the rendered correlation figure
   now says "guarded correlation-link scale".

## Florence-Led Next Fixes

These remain after the 2026-05-22 status-matrix repair:

1. For public-facing pages, avoid over-centering storage or stacked-vector
   mechanics. Those details belong in mechanics notes, not headline visual
   narratives.
2. Design an interval route for modelled `sd(group) ~ x` surfaces before
   drawing ribbons or whiskers around those fitted curves.
3. Move the rendered audit from `figure-gallery` to `model-workflow`, then the
   capability-map pages.

## Boundary

This pass starts Step 3 and completes the first full rendered `figure-gallery`
pass. It does not complete Step 3. The figure audit still needs rendered-image
and rendered-page tables across `model-workflow`, `model-map`,
`implementation-map`, `simulation-plot-grammar`, and `phylogenetic-spatial`.
