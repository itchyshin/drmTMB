# Lane C Z7 — zero-one-beta sigma phylo-interaction q1 recovery

```r
bf(y ~ x,
   sigma ~ phylo_interaction(1 | plant:pollinator,
                             tree1 = plant_tree, tree2 = pollinator_tree),
   zoi ~ 1, coi ~ 1)
```

The sole estimand is \(\tau_\sigma=\exp(\ell_\sigma)\) on the log-sigma
predictor, with the latent field ordered as `plant` within `pollinator` and
precision \(Q_2\otimes Q_1\). At source
`75f150948c2b9898205ed9afde875c02c5de45c2`, all four retained local attempts
pass (mean SD relative error 0.18954; gradients <=0.00428; `pdHess = TRUE`;
mode correlations 0.952--0.962). The independent test oracle checks the same
Kronecker ordering, determinant normalization, and full atom/interior mixture.

This receipt does NOT cover slopes, labels, other providers/dpars, profiles,
intervals, bootstrap, coverage, or inference readiness.
