# Slice 413-422: Fallback Profile, Bootstrap Diagnostics, And Scale Simplification

Reader: `drmTMB` contributors deciding whether the Ayumi Mass + Beak
phylogenetic fallback can be used for uncertainty, or whether it should stay in
the diagnostic ledger.

## Question

After slices 403-412 made the block-diagonal phylogenetic fallback fit, the
open question was whether its two direct fallback correlation targets could
support uncertainty. Ada tested three routes:

- a bounded profile-likelihood diagnostic for the fallback phylogenetic
  mean-mean correlation;
- a 10-core parametric bootstrap smoke with per-replicate optimizer messages
  and gradients;
- a first simplification that kept the two q2 phylogenetic blocks but made the
  `sigma1` and `sigma2` formulas intercept-only.

## Bounded Profile Diagnostic

The fallback `profile_targets()` table lists the two phylogenetic correlations
as direct tanh targets. That means a profile can be attempted. It does not
guarantee that the likelihood crosses the confidence threshold on both sides.

The full-species bounded profile for
`cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | pl | species)` used
`ystep = 1`, `ytol = 0.5`, `maxit = 2`, and a narrow link-scale range. It took
511.6 seconds and failed to extract a 95% interval. The profile machinery
therefore behaved honestly: the target is mechanically direct, but the Ayumi
fallback is not profile-proven.

Artifacts:

- `docs/dev-log/ayumi-convergence/slices-413-422/mass-beak-pv2-block-fallback-profile-bounded/`

## Bootstrap Diagnostics

The 10-core bootstrap rerun (`B = 10`) refitted all replicates and now records
optimizer message, objective, maximum absolute gradient, and the largest
gradient component. All ten refits again returned false convergence.

| quantity | value |
| --- | ---: |
| refits returned | 10 |
| convergence code 0 | 0 |
| convergence code 1 | 10 |
| median max gradient | 37.45 |
| max gradient | 75.30 |
| mean residual `rho12` | -0.746 |
| mean phylogenetic `mu1`-`mu2` | -0.824 |
| mean phylogenetic `sigma1`-`sigma2` | -0.999993 |
| mean Beak-on-Mass coefficient | 1.807 |

This is useful bootstrap infrastructure, but it is not yet usable scientific
uncertainty for the fallback. It describes a boundary and false-convergence
model selection pattern.

Artifacts:

- `docs/dev-log/ayumi-convergence/slices-413-422/mass-beak-pv2-block-fallback-bootstrap-diagnostics/`

## Scale-Formula Simplification

The first simplification removed climate predictors from `sigma1` and
`sigma2`, while keeping the `pl` location block and `ps` scale block:

```r
bf(
  mu1 = Mass_z ~ ... + phylo(1 | pl | species, tree = tree),
  mu2 = Beak_z ~ ... + Mass_cov_z + phylo(1 | pl | species, tree = tree),
  sigma1 = ~ 1 + phylo(1 | ps | species, tree = tree),
  sigma2 = ~ 1 + phylo(1 | ps | species, tree = tree),
  rho12 = ~ 1
)
```

It fit in 538.0 seconds but still returned convergence 1 and `pdHess = FALSE`.
The AIC worsened from 8499.1 to 8610.5. Residual `rho12` collapsed to nearly
zero, the location phylogenetic correlation flipped to `+0.538`, and the
scale-scale phylogenetic correlation remained near the boundary at `-0.99996`.
The largest gradient was on `log_sd_phylo[1]`.

This says the scale-phylogenetic boundary is not solved by removing climate
terms from the scale formulas.

Artifacts:

- `docs/dev-log/ayumi-convergence/slices-413-422/mass-beak-pv2-block-fallback-sigma-intercept/`

## Interpretation

The clean Mass + Beak demonstration remains the q2 location-only phylogenetic
model (`PV2_locphylo`). The block-diagonal fallback is implemented and valuable
as a protocol-aligned stress test, but for this dataset it remains
diagnostic-only. The next technical route should be either:

- keep phylogeny in the location block and remove the scale phylogenetic block
  for the tutorial model;
- profile or bootstrap only models that have acceptable convergence and
  gradient diagnostics;
- design an explicit penalized/MAP covariance option rather than using jittered
  starts or bootstrap as a hidden regularizer.
