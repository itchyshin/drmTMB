# C7 NB2 sigma phylo-interaction local point-recovery receipt

This is the corrected retained local receipt for exactly ordinary univariate
`nbinom2()` with

```r
bf(count ~ x,
   sigma ~ phylo_interaction(1 | plant:pollinator,
                             tree1 = plant_tree,
                             tree2 = pollinator_tree))
```

The fixed ultrametric balanced trees have eight plant and eight pollinator
tips; the full 8 x 8 interaction grid has 18 observations per pair. The
within-pair-centred predictor has fixed-effect truths `(1.40, 0.30)`. The
log-sigma intercept and latent interaction SD truths are `(-0.20, 0.60)`.
`raw-attempts.tsv` retains all four planned seeds (`2026072901:2026072904`);
the IID fitted control is separate from the structured estimator attempts. PASS requires
every fit to converge with `pdHess = TRUE`, finite non-boundary estimates, mean
fixed-effect errors <= 0.20, mean log-sigma-intercept error <= 0.25, and mean
latent-SD relative error <= 40%. The repaired fixture passed.

This is technical point-fit recovery only. It supplies no profile, interval,
coverage, calibration, or inference-ready claim. The sibling non-repaired
directory retains the preceding DGP-stage runner error and is intentionally
not overwritten. The `-run-1` successor retains the re-run tied to the runner
which also records the fitted IID control.
