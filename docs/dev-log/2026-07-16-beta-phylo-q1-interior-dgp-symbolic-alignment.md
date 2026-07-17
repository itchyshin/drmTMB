# Beta phylogenetic direct-SD interior-DGP symbolic alignment

## Purpose

This successor is a new finite-precision recovery-DGP lineage for the bounded
Beta phylogenetic direct-SD route. It does not rerun, alter, filter, or rescore
the stopped PR2 campaign. Its claim ceiling remains `point_fit_recovery`.

## Model

For observation `i` in species `s(i)`,

```text
logit(mu_i) = beta_0 + beta_1 x_mu,i + a_s(i)
log(sigma_i) = gamma_0 + gamma_1 x_sigma,i
phi_i = sigma_i^(-2)
log(tau_s) = alpha_0 + alpha_1 x_tau,s
a ~ N(0, D_tau A D_tau)
```

The Beta family `sigma` determines precision `phi`; the direct-SD formula
models latent phylogenetic SD `tau`. Neither quantity is a conditional-response
standard deviation.

| Symbol | Formula/DGP term | Implementation target | Recovery target |
| --- | --- | --- | --- |
| `beta` | `mu ~ x_mu + phylo(1 | spp_id)` | existing Beta q1 phylo location path | `fit$par$mu` |
| `gamma` | `sigma ~ x_sigma`, `phi = sigma^(-2)` | existing fixed Beta `sigma` path | `fit$par$sigma` |
| `alpha` | `sd(spp_id, level = "phylogenetic") ~ x_tau` | existing direct latent-SD path | `fit$par[["sd_phylo(spp_id)"]]` |
| `a` | `D_tau A D_tau` | unit phylogenetic field scaled at observed tips | latent nuisance field |
| `y` | machine-strict conditional Beta draw | successor-only response generator | strict-interior telemetry |

## Machine-strict conditional-Beta response generator

After the frozen tree, predictors, and unit phylogenetic field are drawn, each
row receives up to 1,000 `rbeta()` draws in data-row order. The first finite
draw strictly inside `(0, 1)` is retained. A non-finite, zero, or one draw is
redrawn for that response only; it never restarts an attempt or changes a seed.
The runner records initial invalid draws, total redraws, the largest row-level
redraw count, cap exhaustion, and the final strict-interior assertion.

The resulting finite-precision DGP is Beta conditional on representable
interior output. This is a newly frozen DGP, not an estimator diagnosis and not
a replacement for the stopped shared-arm attempt.

## Recovery contract

The 12 cells are `{distinct, shared} x {256, 512, 1024} x {2, 4}` with 400
retained certification attempts each. The two `g = 1024, m = 4` cells must pass
independently. Any cap exhaustion, non-interior final response, seed/design
drift, failed authentication, or failed existing recovery gate produces
`HOLD_NO_SUCCESSOR_PROMOTION`.

The arc excludes random RHS terms in `sd()`, family-`sigma` phylogeny, q>1,
labels, slopes, REML, missingness, intervals, coverage, and all other family
expansion.
