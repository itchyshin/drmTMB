# Article Figure QA: Slices 3-5

Date: 2026-05-22

## Scope

This note records the article-specific follow-up after the Confidence Eye and
figure-gallery repair. PR #297 was merged first, `main` was refreshed, and the
new branch `codex/article-figure-qa` carries slices 3-5:

1. polish `model-workflow` figure captions;
2. polish `bivariate-coscale` figure captions and no-effect references;
3. polish `simulation-plot-grammar` figure captions and target references.

The active review roles were Ada, Florence, Fisher, Pat, Darwin, Grace, and
Rose. They are review perspectives, not spawned agents.

## Visual Decisions

`model-workflow` keeps a mixed grammar because the article shows a workflow,
not one inferential object. Raw observations remain raw points, fitted
response-scale parameter surfaces get Wald-band captions, and the habitat
contrast names its 90% Wald interval source.

`bivariate-coscale` keeps the fitted `rho12` curve as a line-and-ribbon display
because the target is a continuous residual-correlation function over
disturbance. The no-effect reference is dotted in both the ggplot and base
fallback paths. The `corpairs()` example now uses Confidence Eyes because both
rows are fitted correlation estimates: the residual row uses
`corpairs(conf.int = TRUE)`, and the intercept-only modelled `corpair()` row
uses `confint(..., newdata = ...)` for a response-scale profile interval.

`simulation-plot-grammar` stays simulation-first. Bias, RMSE, coverage, and
power show replicate/block grain plus aggregate Monte Carlo uncertainty. The
convergence/runtime and failure-ledger figures intentionally show operating
status and replicate counts rather than model-estimate intervals.

## Rendered Pages Checked

The following pages were rebuilt with `pkgdown::build_article()`:

| Article | Rendered path |
| --- | --- |
| `model-workflow` | `pkgdown-site/articles/model-workflow.html` |
| `bivariate-coscale` | `pkgdown-site/articles/bivariate-coscale.html` |
| `simulation-plot-grammar` | `pkgdown-site/articles/simulation-plot-grammar.html` |

Browser QA used a local static server at `http://127.0.0.1:8473/`.

| Article | Content images | Missing alt text | Captions |
| --- | ---: | ---: | ---: |
| `model-workflow` | 5 | 0 | 5 |
| `bivariate-coscale` | 2 | 0 | 2 |
| `simulation-plot-grammar` | 5 | 0 | 5 |

## Visual Inspection

Florence inspected the rendered PNGs, with Pat and Fisher checking what the
reader can infer from each display:

- `temperature-surface-plot-1.png`: readable two-panel `mu`/`sigma` fitted
  surface; caption names the response-scale parameters and why `sigma` has one
  line.
- `habitat-contrast-plot-1.png`: sparse but honest two-estimate interval plot;
  caption names the 90% Wald interval.
- `raw-growth-plot-1.png`: raw response-scale pattern remains visible before
  fitted surfaces.
- `mu-temperature-plot-1.png`: fitted `mu` ribbons are readable and tied to
  prediction-table uncertainty.
- `sigma-temperature-plot-1.png`: single fitted `sigma` band is readable and
  avoids duplicate habitat lines.
- `bivariate-coscale-rho12-curve-1.png`: fitted residual-correlation curve has
  a dotted zero reference and 95% Wald ribbon.
- `bivariate-coscale-group-corpairs-plot-1.png`: Confidence Eye display keeps
  residual and individual-level correlations visually separate while showing
  95% profile intervals on the correlation scale.
- `bias-rmse-display-1.png`: bias display shows replicate grain, aggregate
  summaries, MCSE bars, and a dotted zero reference.
- `bias-rmse-display-2.png`: RMSE display is readable without a no-effect zero
  reference.
- `coverage-power-display-1.png`: coverage/power targets use dotted reference
  lines.
- `convergence-runtime-display-1.png`: fit-status proportions and runtimes sit
  beside accuracy, as intended.
- `failure-ledger-display-1.png`: warnings, boundary cases, errors, and skipped
  cells remain visible as replicate counts.

## Issue Check

`gh issue list --search "figure caption pkgdown visualization" --limit 20`
returned no matching open issues, so no issue comment or new issue was needed
for this caption and rendered-QA slice.

## Remaining Work

This slice closes the agreed first five steps. The next figure work should keep
the same case-by-case rule and move through the remaining rendered articles or
reference pages only when their purpose, data grain, and uncertainty source are
clear.
