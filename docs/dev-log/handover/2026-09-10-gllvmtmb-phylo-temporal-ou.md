# Ready-to-post handoff — additive phylogenetic stable effect plus temporal OU

## Purpose

This is a portability note for the gllvmTMB/GLLVM phylogenetic-model team. It describes a tested **additive** composition: an existing tree-correlated stable intercept plus an independent, within-series temporal OU deviation. It is not a request to implement a separable phylogeny-by-time random field.

## Model contract

For series/species `i` at elapsed time `t`, use

\[y_{it}=x_{it}^{T}\beta+b_i+a_{it}+\epsilon_{it},\]

with `b ~ N(0, s_b^2 A)` for a tree correlation matrix `A`, independent OU deviations
`Cov(a_it, a_js) = 1(i=j) s_a^2 exp(-lambda |t-s|)`, and independent residuals `epsilon_it ~ N(0, sigma^2)`. Thus each observation-level covariance is

\[V_{rq}=s_b^2 A_{i_r i_q}+1(i_r=i_q)s_a^2e^{-\lambda|t_r-t_q|}+1(r=q)\sigma^2.\]

The temporal component is the main new structure: it supports genuinely irregular elapsed time and a positive continuous decay `lambda`. The phylogenetic term only explains stable species differences.

## Parser and data requirements

- Use one shared species/series ID for both components.
- The formula-facing tree must be a named object: `phylo(1 | species, tree = tree)`. A nested expression such as `tree = generated$tree` should be rejected or normalized before formula parsing.
- Validate finite numeric time and duplicate raw species--time keys before response omission. Preserve elapsed-time gaps; do not rank or compress them.
- Require at least three species, two distinct times per species, and three distinct positive lags for this development slice.

## TMB implementation and tests

Build the marginal covariance from the sum above and evaluate it with a dense Cholesky reference before optimizing. Keep stationary OU normalization. Test shuffled rows, irregular gaps, independent-series separation, zero temporal/phylogenetic reductions, and parser rejection of mismatched IDs or non-symbol tree expressions. Public labels should keep `sd_phylo_stable`, `sd_temporal`, `decay_temporal`, and `sigma` distinct.

## Retained drmTMB evidence

The G9b recovery study used 24 contrast fixtures plus 300 independent trees (100 at each phylogenetic SD). It passed contrast MAE and variance/decay thresholds; ensemble standardized signed intercept bias was 0.032, 0.072, and 0.063 at phylogenetic SD 0.3, 0.6, and 1.0. This is point-recovery evidence only. It does not establish interval coverage, forecast performance, `newdata` prediction, or portability to a separable field.

## Suggested issue title

`Design: additive phylogenetic stable intercept plus independent irregular-time OU deviations`

## Next action

Create a fresh GLLVM/gllvmTMB child plan with its own likelihood oracle, data-layout contract, recovery evidence, and reader example. Do not copy drmTMB implementation code without recording provenance and revalidating the native likelihood.
