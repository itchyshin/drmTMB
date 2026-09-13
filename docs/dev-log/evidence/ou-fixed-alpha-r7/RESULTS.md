# R7 fixed-alpha OU application sweep

This is a bounded robustness check, not an alpha-recovery, interval, or model-
selection campaign. Every comparison holds rows, tree, fixed-effect formulae,
and optimizer settings fixed while changing only the declared location-side OU
decay assumption. AIC values are conditional on that grid.

| dataset | BM AIC | best qualified fixed-OU AIC | best fixed alpha | result |
| --- | ---: | ---: | ---: | --- |
| Ayumi passerine body mass (R6 receipt) | 4691.289 | 4705.362 | 0.1 | BM lowest |
| AVONET mass--morphology, deterministic 128-species subset | 70.510 | 73.476 | 0.3 | BM lowest |
| Simulated OU draw: 64 species, 6 rows/species, alpha truth 0.7, moderate signal | 368.586 | 369.842 | 0.7 | BM lowest |
| Simulated OU draw: same tree/design/truth, stronger phylogenetic signal | -104.980 | -103.079 | 0.3 | BM lowest |

All 15 small retained cells converged with positive-definite Hessians and no
warnings. The separate full 657-species AVONET batch is retained in
`summary.csv` and `coefficients.csv`: its BM fit ended with false convergence
(code 1), and two fixed-OU fits used the optimizer's careful preset. It is
therefore a feasibility/boundary receipt, not an AIC comparison, and its
failure is retained rather than omitted.
The AVONET subset used a fixed seed (20260913) only to keep the local usability
demonstration small; it is not a representative AVONET analysis. Its pruned
published tree contained zero/non-positive edges, repaired to the positive-edge
median times `1e-8`, matching the documented Ayumi preparation rule.

## Interpretation

The new fixed-alpha workflow is useful: it provides a transparent way to ask
whether a biological conclusion changes under prespecified phylogenetic-decay
assumptions. But this four-case panel gives no basis to promote free-alpha OU,
conditional AIC selection, or a full OU-v1 expansion. The simulated results
are particularly important: even a fixed-seed draw generated from the native
stationary OU covariance did not make the true-grid OU member lowest-AIC in
this finite design. That is negative evidence about the current decision route,
not a claim that OU is generally inferior to BM.

The appropriate decision is to keep BM as the default, retain
`ou_sensitivity()` as experimental fixed-assumption sensitivity, and park
free-rate/correlated OU behind a fresh evidence-first programme.
