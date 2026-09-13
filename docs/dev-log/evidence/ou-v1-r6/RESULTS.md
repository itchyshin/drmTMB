# R6 Ayumi all-species fixed-alpha sensitivity

This empirical receipt reconstructs the local `eco-climatic-rules` source
join, transformations, tree alignment, edge repair, and polytomy resolution.
The pruned source tree's common root-to-tip depth is 66.787. The labelled OU
strengths below are normalized-depth values; the fitted alpha is that value
divided by 66.787.

| model | normalized assumed alpha | AIC |
| --- | ---: | ---: |
| BM | — | 4691.289 |
| OU | 0.1 | 4705.362 |
| OU | 0.3 | 4727.658 |
| OU | 0.7 | 4784.493 |
| OU | 1.3 | 4898.863 |
| OU | 2.5 | 5234.478 |

All fits converged with positive-definite Hessians and no retained warnings.
For this exact source-compatible data/tree preparation and fixed climate
formula, BM has the smallest AIC and fit worsens monotonically over this
assumed-alpha grid. This is an empirical sensitivity result, not evidence
that alpha was estimated or that BM is generally preferable.
