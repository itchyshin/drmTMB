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

## Directly Inspected Figures

| Page | Chunk | Rendered file | Visual data grain | Uncertainty source | Verdict |
| --- | --- | --- | --- | --- | --- |
| `figure-gallery` | `random-effect-sd-surface` | `pkgdown-site/articles/figure-gallery_files/figure-html/random-effect-sd-surface-1.png` | Fitted `sd(site)` surface on a reef-cover grid plus site-level predictor rug | None drawn; table reports unavailable Wald surface intervals | Improved during this pass: the rug shows design support without placing raw response points on an SD axis. Still needs a future interval route. |
| `figure-gallery` | `coefficient-intervals` | `pkgdown-site/articles/figure-gallery_files/figure-html/coefficient-intervals-1.png` | Wald compatibility display for fixed effects, SDs, and a correlation row | 66% and 95% Wald intervals | Improved during this pass: the redundant bottom legend is removed and row labels carry the parameter-class meaning. |
| `figure-gallery` | `correlation-display` | `pkgdown-site/articles/figure-gallery_files/figure-html/correlation-display-1.png` | Illustrative `corpairs()`-like correlation rows | Illustrative Wald/profile intervals transformed through a guarded correlation-link scale | Improved during this pass: replaced Fisher-z wording with guarded correlation-link wording and removed the redundant layer legend because each row names the layer. |
| `figure-gallery` | `simulation-operating-characteristics` figure 1 | `pkgdown-site/articles/figure-gallery_files/figure-html/simulation-operating-characteristics-1.png` | Fixture replicate errors plus aggregate bias points | Mean bias with 95% MCSE intervals | Fixed during this pass: unsupported cells now say "not targeted" instead of appearing as silent blanks. |
| `figure-gallery` | `simulation-operating-characteristics` figure 2 | `pkgdown-site/articles/figure-gallery_files/figure-html/simulation-operating-characteristics-2.png` | Coverage block dots plus aggregate coverage points | 95% binomial MCSE intervals | Fixed during this pass: subtitle now explains that faint block dots sample replicate-block coverage. |

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
8. Re-rendered `figure-gallery` and confirmed the rendered correlation figure
   now says "guarded correlation-link scale".

## Florence-Led Next Fixes

These should be handled after the initial inventory, not squeezed into this
kickoff slice:

1. Review all gallery figures one by one, not just the five high-risk figures
   inspected here.
2. For public-facing pages, avoid over-centering storage or stacked-vector
   mechanics. Those details belong in mechanics notes, not headline visual
   narratives.
3. Design an interval route for modelled `sd(group) ~ x` surfaces before
   drawing ribbons or whiskers around those fitted curves.

## Boundary

This pass starts Step 3. It does not complete Step 3. The full figure audit
still needs a complete rendered-image table across `figure-gallery`,
`model-workflow`, `model-map`, `implementation-map`,
`simulation-plot-grammar`, and `phylogenetic-spatial`.
