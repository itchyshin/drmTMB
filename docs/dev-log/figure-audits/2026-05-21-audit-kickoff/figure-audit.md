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

The second render happened after editing the correlation-display wording.

## Directly Inspected Figures

| Page | Chunk | Rendered file | Visual data grain | Uncertainty source | Verdict |
| --- | --- | --- | --- | --- | --- |
| `figure-gallery` | `random-effect-sd-surface` | `pkgdown-site/articles/figure-gallery_files/figure-html/random-effect-sd-surface-1.png` | Fitted `sd(site)` surface on a reef-cover grid | None drawn; table reports unavailable Wald surface intervals | Correct boundary, but sparse and visually plain. Keep for now; improve in a later polish pass. |
| `figure-gallery` | `coefficient-intervals` | `pkgdown-site/articles/figure-gallery_files/figure-html/coefficient-intervals-1.png` | Wald compatibility display for fixed effects, SDs, and a correlation row | 66% and 95% Wald intervals | Mostly readable. The bottom legend is large and the correlation row dominates the x-range; later polish should reduce visual weight. |
| `figure-gallery` | `correlation-display` | `pkgdown-site/articles/figure-gallery_files/figure-html/correlation-display-1.png` | Illustrative `corpairs()`-like correlation rows | Illustrative Wald/profile intervals transformed through a guarded correlation-link scale | Fixed during this pass: replaced Fisher-z wording with guarded correlation-link wording. Visual structure is usable but should be revisited for legend density. |
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
5. Re-rendered `figure-gallery` and confirmed the rendered correlation figure
   now says "guarded correlation-link scale".

## Florence-Led Next Fixes

These should be handled after the initial inventory, not squeezed into this
kickoff slice:

1. Reduce legend weight in the coefficient and correlation raindrop figures.
2. Make the random-effect SD surface less visually empty, while still avoiding
   raw-response points on an SD axis.
3. Review all gallery figures one by one, not just the five high-risk figures
   inspected here.
4. For public-facing pages, avoid over-centering storage or stacked-vector
   mechanics. Those details belong in mechanics notes, not headline visual
   narratives.

## Boundary

This pass starts Step 3. It does not complete Step 3. The full figure audit
still needs a complete rendered-image table across `figure-gallery`,
`model-workflow`, `model-map`, `implementation-map`,
`simulation-plot-grammar`, and `phylogenetic-spatial`.
