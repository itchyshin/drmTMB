# Phase 18 NB2 Phylogenetic q1 ADEMP Sheet

> **Status supersession (2026-07-14).** This sheet preserves the first
> intercept-only evidence lane. Current 0.6.0 also fits the unlabelled NB2
> phylogenetic `mu` intercept-plus-one-slope route and the exact q1 NB2
> phylogenetic `sigma` intercept-plus-one-slope route at recovery grade.
> Pure, labelled, or multiple slopes, richer structured sigma blocks,
> structured-sigma intervals/coverage, and zero-inflated NB2 phylogenetic
> effects remain planned.

This sheet records the focused Phase 18 evidence lane for an ordinary NB2
phylogenetic `mu` intercept:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The route is one response, one count family, one q=1 phylogenetic species
effect in the log-mean predictor, and fixed-effect `sigma` overdispersion. It
does not open NB2 phylogenetic slopes, NB2 `sigma` phylogeny, zero-inflated NB2
phylogeny, spatial/animal/`relmat()` count structure, or count-side
cross-parameter covariance.

## A - Aims

Primary aim: estimate bias, RMSE, convergence, Hessian status, warning/error
rate, fixed-effect Wald coverage, direct `log_sd_phylo` profile-target status,
and optional profile interval status for the fitted NB2 q=1 phylogenetic
`mu` gate.

Secondary aim: make the overdispersion confounding explicit. This lane varies
species count, observations per species, mean count, baseline NB2
overdispersion `sigma`, true phylogenetic SD, and tree shape. Each replicate
also fits an ordinary grouped NB2 random-intercept comparator,
`count ~ x + (1 | species), sigma ~ z`, so summaries can show when an
unstructured grouped SD is absorbing the same between-species variation.

## D - Data-Generating Mechanism

For species `s = 1, ..., S` and observations `k = 1, ..., m`, use balanced
within-species predictors `x_sk` and `z_sk` and a standardized phylogenetic tip
correlation matrix `C`:

```text
a ~ Normal(0, sd_phylo^2 * C)
eta_mu_sk = beta0 + beta1 * x_sk + a_s
mu_sk = exp(eta_mu_sk)
eta_sigma_sk = gamma0 + gamma1 * z_sk
sigma_sk = exp(eta_sigma_sk)
count_sk ~ NB2(mu_sk, size = 1 / sigma_sk^2)
```

The helper `phase18_dgp_nbinom2_phylo_q1()` implements this DGP. Its condition
helper `phase18_nbinom2_phylo_q1_conditions()` names the first smoke factors:

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n_species` | 20, 40 | Enough species for a structured SD row without making smoke tests benchmark-sized. |
| `n_per_species` | 4, 8 | Low and moderate repeated counts per species. |
| `sd_phylo` | 0, 0.25, 0.60 | Boundary, small, and clearer phylogenetic signal. |
| `mean_count` | 1.5, 4.0 | Low and moderate count means where NB2 variance changes are visible. |
| `sigma_baseline` | 0.45, 0.80 | Moderate and high overdispersion on the public `sigma` scale. |
| `tree_shape` | balanced, mildly uneven | Tree-shape variation without adding large-tree benchmark complexity. |
| `beta_mu_x`, `beta_sigma_z` | -0.20, 0.15 | Fixed slopes keep the model realistic without becoming the main estimand. |

Use one replicate per cell for routine package smoke tests, 20 replicates per
cell for local opt-in grid checks, and 500 replicates per cell before writing
formal recovery or coverage claims.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Log-mean intercept and slope | `beta_mu` | `coef(fit, dpar = "mu")` |
| Log-`sigma` intercept and slope | `beta_sigma` | `coef(fit, dpar = "sigma")` |
| Phylogenetic log-mean SD | `sd_phylo` | `fit$sdpars$mu["phylo(1 | species)"]` |
| Ordinary grouped comparator SD | marginal `sd_phylo` | comparator `fit$sdpars$mu["(1 | species)"]` |
| Direct profile target | `log_sd_phylo` | `profile_targets(fit)` row `sd:mu:phylo(1 | species)` |
| Replication diagnostic | species count and repeated rows | `check_drm()` phylogenetic diagnostic rows |

The comparator is not a second fitted feature claim. It is an evidence row for
how much ordinary unstructured species heterogeneity can resemble structured
phylogenetic SD in the same NB2 data.

## M - Methods

Fit the intended ordinary non-zero-inflated NB2 model:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

Fit the ordinary grouped comparator only inside the simulation runner:

```r
drmTMB(
  bf(count ~ x + (1 | species), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The smoke runner `phase18_run_nbinom2_phylo_q1_smoke()` wires the DGP, target
fit, grouped comparator, summariser, registry, and bounded replicate runner.
The grid writer `phase18_write_nbinom2_phylo_q1_grid_outputs()` saves
aggregate, replicate, manifest, failure-ledger, Wald interval, Wald coverage,
direct profile-target, optional profile-interval, interval-evidence,
interval-diagnostics, and interval-failure CSVs beside resumable replicate RDS
files. The formal wrapper adds `nbinom2-phylo-q1-formal-spec.csv`, read-back QA,
a comparator-row check, and a promotion-decision helper.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Fixed-effect Wald coverage | `mu` and fixed `sigma` rows with usable standard errors |
| Profile-target status | `sd:mu:phylo(1 | species)` maps to direct `log_sd_phylo` and is marked ready or not ready |
| Optional profile coverage | Direct phylogenetic SD row when `profile_parameters` requests `log_sd_phylo` |
| Comparator behaviour | ordinary grouped comparator SD bias/RMSE against the same marginal species SD |
| Convergence and Hessian rate | `mean(converged)` and `mean(pdHess)` for target and comparator rows |
| Warning/error rate | manifest and failure-ledger rows, not dropped from summaries |
| Runtime | replicate elapsed seconds, summarized beside the operating metrics |

Failed fits, failed profiles, and unavailable intervals are part of the result.
Do not compute coverage after silently removing them.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Bias, RMSE, coverage, diagnostics, overdispersion, and comparator behaviour are named. |
| 2. DGP | The NB2 log-mean phylogenetic effect and fixed log-`sigma` overdispersion are explicit. |
| 3. Estimands | Fixed `mu`, fixed `sigma`, phylogenetic SD, grouped comparator SD, profile target, and diagnostic rows are named. |
| 4. Methods | The exact target and comparator `drmTMB()` models are stated. |
| 5. Performance measures | Bias, RMSE, intervals, convergence, warnings, runtime, and comparator behaviour are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | The implemented helpers live under `inst/sim/`. |
| 8. Replicability | Seeded cells and replicate seeds are handled by the Phase 18 runner registry. |
| 9. Real-data motivation | The count tutorial supplies the applied count-model motivation. |
| 10. Complete results | Manifests, failure ledgers, interval-status tables, and comparator rows keep failed or competing explanations visible. |
| 11. Monte Carlo uncertainty | Formal coverage claims require a 500-replicate gate with MCSEs. |

Slices 541-555 add the local formal-audit note
`docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md`. That audit checks
the all-cell formal-condition sentinel and a representative 5-replicate subset,
but it keeps formal recovery and coverage claims blocked until the 500-replicate
grid is actually run and reviewed.
