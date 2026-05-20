# Figure Audit: Slices 1280-1364 Structural Parity And Current Gallery Gate

## Scope

Ada reran the figure gate after the animal/`relmat()` first-slice work and the
latest simulation-display repairs. Florence, Fisher, Pat, Grace, and Rose were
used as role perspectives, not spawned agents.

This audit supersedes the earlier full-gallery note where the simulation bias
panel was still described as using pseudo-replicate grain. The current rendered
articles use explicit fixture replicate-error rows for bias examples, block
proportions for coverage/power examples, and named Wald or binomial MCSE
intervals.

## Rendered Pages Checked

- `pkgdown-site/articles/figure-gallery.html`
- `pkgdown-site/articles/simulation-plot-grammar.html`
- `pkgdown-site/articles/model-map.html`
- `pkgdown-site/articles/formula-grammar.html`
- `pkgdown-site/articles/phylogenetic-spatial.html`

Grace rebuilt those articles from the source tree with `devtools::load_all()`
and `pkgdown::build_article(..., new_process = FALSE)`, because a clean
new-process render can otherwise use the installed package and miss the local
`predict_parameters()` code.

## Scans

```sh
rg -n "Warning|deprecated|geom_errorbarh|height.*translated|Error in|could not find function|pseudo-replicate|pseudo replicate|pseudo" \
  pkgdown-site/articles/figure-gallery.html \
  pkgdown-site/articles/simulation-plot-grammar.html \
  pkgdown-site/articles/model-map.html \
  pkgdown-site/articles/formula-grammar.html \
  pkgdown-site/articles/phylogenetic-spatial.html \
  vignettes/figure-gallery.Rmd \
  vignettes/simulation-plot-grammar.Rmd

rg -n "no fitted likelihood|future lower-level|Planned, not fitted yet|animal.*planned-only|relmat.*future lower-level|markers only until pedigree or known-matrix likelihoods|reserved structured-effect markers until the likelihood" \
  pkgdown-site/articles/model-map.html \
  pkgdown-site/articles/phylogenetic-spatial.html \
  pkgdown-site/articles/formula-grammar.html \
  pkgdown-site/articles/figure-gallery.html \
  --glob "!pkgdown-site/search.json"
```

The only warning-like hit in the rendered pages is the deliberate section title
"Warnings and failures stay visible" in the simulation grammar article. The
only planned-status hits are current limitations: one-slope animal/`relmat()`
grammar, phylo+spatial combinations, bivariate animal examples, and
`corpair()` parity remain planned.

## Figure Inventory

| Rendered figure | Source object | Visual data grain | Uncertainty source | Missing-cell display | Reader risk | Verdict | Fix or watch item |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `location-scale-fit-1.png` | fitted location-scale example | raw observations plus fitted rows | Wald prediction bands | not applicable | low | pass | Shows data and fitted `mu`/`sigma` story together. |
| `parameter-surface-1.png` | fitted `mu` and `sigma` surfaces | fitted-row summaries | Wald bands where available | not applicable | low | pass | Panels keep response mean and residual scale separate. |
| `residual-scale-observed-check-1.png` | residual magnitude check | row residual magnitudes | no interval claim; green curve is derived expected absolute residual | not applicable | low | pass | Subtitle and axis now name absolute residuals and sigma conversion. |
| `confidence-distribution-slopes-1.png` | coefficient examples | confidence-distribution approximation | Wald compatibility density and interval cutoff | not applicable | medium | pass with note | Shared-axis slope displays require standardized or otherwise comparable predictors; this caveat stays in nearby prose. |
| `shape-inflation-rho12-panels-1.png` | distributional-parameter panels | fitted parameter summaries | named Wald intervals | unsupported targets are separated by panel/status prose | low | pass | Different dpars remain on their own response scales. |
| `random-effect-variance-components-1.png` | variance component summary | fitted component estimates | no interval claim | not applicable | low | pass | Didactic component display only. |
| `coefficient-intervals-1.png` | coefficient table fixture | Wald confidence distribution per coefficient | central 66% and 95% Wald intervals plus raindrop density | not applicable | low | pass | Raindrop display makes compatibility decrease toward interval edges. |
| `random-slope-modes-1.png` | conditional site trajectories | raw repeated site observations plus fitted conditional lines | no interval claim | not applicable | low | pass | Shows repeated site behaviour rather than only a variance number. |
| `random-effect-sd-surface-1.png` | direct SD surface | fitted SD surface only | intervals explicitly unavailable | not applicable | medium | pass with note | Honest sparse surface; profile/bootstrap route still needed before drawing bands. |
| `discrete-comparison-1.png` | categorical contrast | fitted means by level | Wald intervals | not applicable | low | pass | Horizontal display avoids sparse floating points. |
| `cat-cat-interaction-1.png` | categorical interaction | raw observations plus fitted cell means | Wald intervals | not applicable | low | pass | Intervals align with cell means after removing `geom_pointrange()` fatten path. |
| `emmeans-display-1.png` | emmeans bridge | marginal means | Wald intervals from `emmeans` | unsupported targets discussed below figure | low | pass | Horizontal layout keeps intervals and labels on one scale. |
| `emmeans-factor-grid-1.png` | conditioned emmeans grid | marginal means by season | Wald intervals | not applicable | low | pass | Dodged horizontal lanes stay aligned. |
| `emmeans-interaction-grid-1.png` | interaction emmeans grid | fitted cell means | Wald intervals | not applicable | low | pass | Acceptable teaching figure. |
| `empirical-marginal-summary-1.png` | fitted-row `mu` summary | fitted-row predictions and averaged row-wise limits | row-wise Wald prediction limits averaged over fitted rows | not applicable | medium | pass with note | It is not raw data; subtitle and prose name the fitted-row grain. |
| `emmeans-boundary-strip-1.png` | support boundary strip | status rows | no interval claim | explicit support boundary | medium | watch | Honest but dense; revisit when emmeans material is split. |
| `cont-cont-interaction-1.png` | continuous interaction | raw observations plus fitted lines | Wald bands | not applicable | low | pass | Shows interaction on the model-output scale. |
| `correlation-display-1.png` | residual, group, phylo correlation rows | confidence distribution on Fisher-z scale back-transformed | Wald compatibility density and central intervals | not applicable | low | pass | Layers stay separate; no posterior wording. |
| `correlation-layer-boundaries-1.png` | correlation support strip | fitted/planned status rows | interval only where finite | planned rows visible | medium | pass with note | Still a boundary display, not a fitted animal/relmat correlation claim. |
| `simulation-operating-characteristics-1.png` | simulation bias fixture | explicit fixture replicate-error rows plus aggregate mean | 95% MCSE intervals for mean bias | undefined cells absent by design | low | pass | Repaired: no pseudo-replicate language remains. |
| `simulation-operating-characteristics-2.png` | simulation coverage fixture | replicate-block proportions plus aggregate coverage | 95% binomial MCSE intervals | blank/not-targeted cells visible | low | pass | Geometry matches the simulation grain. |
| `bias-rmse-display-1.png` | simulation grammar bias display | explicit fixture replicate-error rows plus aggregate mean | 95% MCSE intervals for mean bias | unsupported cells blank | low | pass | Tiny MCSE bars now use visible end caps. |
| `bias-rmse-display-2.png` | simulation grammar RMSE display | aggregate RMSE by surface/estimand | 95% RMSE MCSE intervals | missing rows remain blank | low | pass | RMSE is kept as aggregate, not a fake cloud. |
| `coverage-power-display-1.png` | simulation grammar coverage/power display | replicate-block proportions plus aggregate proportion | 95% binomial MCSE intervals | `not targeted` cells visible | low | pass | Uses block dots instead of inline `n=` clutter. |
| `convergence-runtime-display-1.png` | simulation diagnostics | aggregate status proportions and runtime | no interval claim | failure classes visible | medium | watch | Useful but still more diagnostic than elegant. |
| `failure-ledger-display-1.png` | simulation diagnostics | failure/status ledger | no interval claim | failure classes visible | medium | watch | Honest ledger; future report can improve hierarchy. |

## Cross-Figure Patterns

- Florence: the weakest remaining figures are status or diagnostics displays,
  not the main model-output figures. They are acceptable as honest teaching
  figures but should not become the final publication style.
- Fisher: every interval or band now names its source in the title, subtitle,
  caption, or nearby prose: Wald interval, Wald compatibility display, binomial
  MCSE, RMSE MCSE, or unavailable.
- Pat and Darwin: the gallery is moving toward "what does the model say?"
  displays rather than table-only examples. The next worked animal, phylo,
  spatial, and `relmat()` examples should each carry a model-output figure.
- Grace: article renders are clean of accidental lifecycle warnings after the
  `geom_errorbarh()` and `geom_pointrange(fatten = ...)` replacements.
- Rose: the process failure was assuming a corrected source recipe was enough.
  The rendered PNG remains the truth.

## Remaining Watch Items

1. The `emmeans` support strip, convergence/runtime summary, and failure
   ledger need a future reader-first redesign when their articles split.
2. Direct SD surfaces still need profile or bootstrap intervals before shaded
   uncertainty bands are honest.
3. Coefficient raindrop displays should be used only when coefficients share a
   meaningful scale, or the display must facet/label units explicitly.
4. Simulation displays should continue to choose geometry from artifact grain:
   replicate rows get dots/clouds, aggregate rows get aggregate points and
   named MCSE intervals.
