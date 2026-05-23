# Rendered Figure QA: Slices 71-80

## Scope

Slices 71-80 continue the rendered-figure sweep with the
`simulation-plot-grammar` article. The article is a display contract for future
simulation reports, so the audit focused on whether each plot shows the right
data grain: replicate errors, aggregate MCSE intervals, block-level operating
characteristics, readiness summaries, or failure counts.

No package code, likelihood, formula grammar, simulation engine, or exported
plot helper changed.

## Figure Decisions

| Slice | Article | Figure chunk | Visual data grain | Uncertainty source | Verdict |
| --- | --- | --- | --- | --- | --- |
| 71 | `simulation-plot-grammar` | audit target selected | validation article with five rendered images | mixed MCSE/status/count claims | improve |
| 72 | `simulation-plot-grammar` | `bias-display` | sampled replicate-level signed errors plus aggregate mean bias | 95% mean-bias MCSE | split from RMSE and keep |
| 73 | `simulation-plot-grammar` | `rmse-display` | aggregate root-mean-square error by estimand and surface | 95% RMSE MCSE | split from bias and keep |
| 74 | `simulation-plot-grammar` | `coverage-power-display` | replicate-block proportions plus aggregate operating-characteristic proportions | 95% binomial MCSE | keep |
| 75 | `simulation-plot-grammar` | `fit-status-display` | convergence and positive-definite Hessian proportions | none; readiness summary | split from runtime and keep |
| 76 | `simulation-plot-grammar` | `runtime-display` | median and 90th percentile elapsed seconds | none; runtime summary | split from fit status and keep |
| 77 | `simulation-plot-grammar` | `failure-ledger-display` | replicate counts by status | none; counts are the data | keep |
| 78 | rendered HTML | alt text inventory | six referenced article images | not applicable | 6 images, 0 missing alt text |
| 79 | visualization grammar and checklist | simulation display contract | case-by-case visual rule | not applicable | updated |
| 80 | after-task/check-log | durable evidence | validation commands and limitations | not applicable | recorded |

## Rendered Figures

Rendered images inspected directly:

- `pkgdown-site/articles/simulation-plot-grammar_files/figure-html/bias-display-1.png`
- `pkgdown-site/articles/simulation-plot-grammar_files/figure-html/rmse-display-1.png`
- `pkgdown-site/articles/simulation-plot-grammar_files/figure-html/coverage-power-display-1.png`
- `pkgdown-site/articles/simulation-plot-grammar_files/figure-html/fit-status-display-1.png`
- `pkgdown-site/articles/simulation-plot-grammar_files/figure-html/runtime-display-1.png`
- `pkgdown-site/articles/simulation-plot-grammar_files/figure-html/failure-ledger-display-1.png`

Florence accepted the split accuracy figures because the bias figure now reads
as a replicate-error display and the RMSE figure reads as an aggregate summary,
without sharing one generic alt text. Fisher accepted the uncertainty grammar:
bias, RMSE, coverage, and power name Monte Carlo uncertainty, while fit status,
runtime, and failure counts avoid interval geometry.

Pat accepted the readiness split because fit-status proportions remain on a
0-1 scale and runtime is shown on an elapsed-seconds scale. Rose recorded the
pattern: mixed-unit readiness panels can look compact, but they create a hidden
comparison that the reader should not be asked to make.

## Remaining Limits

The article still uses illustrative fixtures, not Phase 18 production
simulation output. The figures define the display contract until the result
schemas expose stable replicate rows, aggregate summaries, MCSE columns,
manifest fields, and warning/error ledgers.
