# Ayumi all-species joint-OU feasibility receipt

This is a feasibility diagnostic for the admitted G13 joint independent
location-plus-residual-log-scale OU intercept model. It is not a recovery
study, an AIC comparison, or evidence that OU is preferable to Brownian motion.
The source has one body-mass record per species, which gives the scale-side
phylogenetic field little independent within-species information.

Source receipt:

- repository: `/private/tmp/LS_ecogeographical-rules`, commit
  `6c52a46f67d9d86842ae5476dee828684f64a464`;
- data: `data/derived/ecogeo_species_traits_climate_v1.rds`, SHA-256
  `60f2ec750f6c6a16f08232e61000c8debddcb1a43dceeb9d282c97f93ff795d1`;
- tree: `data/derived/ecogeo_tree_main_v1.rds`, SHA-256
  `f5fcc706abf4799bbf942f5649211fa6493216673d03e28efeee2c2d9e5506f8`.

The data and tree had 10,440 matching species. Rows were reordered exactly to
the tree-tip order before fitting. The fit renamed `log_mass_z` to `y`,
`mean_tavg_combined_z` to `temperature`, `mean_prec_combined_z` to
`precipitation`, and `tree_tip` to `species`; its exact ML formula was:

```r
bf(
  y ~ temperature + I(temperature^2) + precipitation + I(precipitation^2) +
    phylo(1 | species, tree = tree, model = "ou"),
  sigma ~ temperature + precipitation +
    phylo(1 | species, tree = tree, model = "ou")
)
```

The all-species fit used `REML = FALSE` with `eval.max = 1000` and
`iter.max = 1000`; it took 383.892 seconds, returned optimizer convergence code
0, maximum gradient `8.05e-09`, no retained warnings, and `pdHess = TRUE`, with
log likelihood -11.36334 and AIC 46.72668. The
location rate was `alpha_mu = 0.00003360`; the residual-log-scale rate was
`alpha_sigma = 1.35097`. The near-zero location rate is a dataset-specific
boundary-like estimate. It must not be interpreted as evidence for an OU
winner, a well-identified rate, or a general property of body mass.

A deterministic 500-tip real-data preflight finished in 16.836 seconds with
convergence code 0 but `pdHess = FALSE`, reinforcing that the fit is a
feasibility/boundary example rather than decision-bearing evidence. The
machine-readable local receipts are intentionally kept outside the package at
`/private/tmp/phylo-ou-sigma-ayumi-receipt/`.
