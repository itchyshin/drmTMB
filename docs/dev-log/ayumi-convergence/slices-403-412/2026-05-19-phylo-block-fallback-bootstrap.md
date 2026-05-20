# Slice 403-412: Phylogenetic Block-Diagonal Fallback And Bootstrap Smoke

Reader: `drmTMB` contributors deciding whether the Ayumi Mass + Beak
pre-registration fallback is now runnable, and whether it is interpretable.

## What Changed

`drmTMB` now accepts the labelled phylogenetic q4 fallback:

```r
bf(
  mu1 = Mass_z ~ ... + phylo(1 | pl | species, tree = tree),
  mu2 = Beak_z ~ ... + Mass_cov_z + phylo(1 | pl | species, tree = tree),
  sigma1 = ~ ... + phylo(1 | ps | species, tree = tree),
  sigma2 = ~ ... + Mass_cov_z + phylo(1 | ps | species, tree = tree),
  rho12 = ~ 1
)
```

The fitted latent vector still has four endpoints, but the covariance is
block diagonal: one q2 location block and one q2 scale block. `corpairs()`
therefore reports two phylogenetic rows, not the six rows of the full q4
block.

## Full-Species Mass + Beak Result

The fallback no longer aborts at formula parsing. On the 6,196-species
Passeriformes Mass + Beak data it returned:

| quantity | value |
| --- | ---: |
| elapsed seconds | 678.56 |
| convergence | 1 |
| `pdHess` | `FALSE` |
| logLik | -4220.555 |
| AIC | 8499.111 |
| residual `rho12` | -0.720 |
| phylogenetic `mu1`-`mu2` correlation | -0.750 |
| phylogenetic `sigma1`-`sigma2` correlation | -0.999999 |

`check_drm()` reports false convergence, non-positive-definite Hessian, a
large fixed-gradient component, and a q4 covariance warning driven by the
scale-scale phylogenetic correlation at the boundary. This is a fitted
fallback, but not a clean inferential endpoint.

## 10-Core Bootstrap Smoke

The developer bootstrap prototype was run with `B = 10`, `multicore`, and
`cores = 10`. The script now records `requested_cores` and clamps actual
cores at 10.

All ten refits returned fitted objects, but all ten retained convergence code
1. Mean bootstrap summaries were:

| target | mean | min | max |
| --- | ---: | ---: | ---: |
| residual `rho12` | -0.746 | -0.789 | -0.699 |
| phylogenetic `mu1`-`mu2` | -0.824 | -0.832 | -0.818 |
| phylogenetic `sigma1`-`sigma2` | -0.999993 | -0.999999 | -0.999957 |
| Beak-on-Mass coefficient | 1.807 | 1.790 | 1.828 |

The bootstrap therefore reinforces the diagnostic conclusion: the scale-scale
phylogenetic row is pinned to the boundary under simulated data from this
fallback, so bootstrap intervals would currently describe a weak or
boundary-selected model rather than reliable scientific uncertainty.

## Artifacts

- Fit output: `docs/dev-log/ayumi-convergence/slices-403-412/mass-beak-pv2-block-fallback/`
- Bootstrap output: `docs/dev-log/ayumi-convergence/slices-403-412/mass-beak-pv2-block-fallback-bootstrap/`

## Recommendation

Use `PV2_locphylo` as the clean Mass + Beak demonstration model for now. Keep
the block-diagonal fallback as a developer diagnostic and a protocol-aligned
stress case. Before treating the fallback as interpretable, test a simpler
scale structure, profile the two direct fallback correlations, or add a
regularized/penalized boundary strategy through a separate design decision.
