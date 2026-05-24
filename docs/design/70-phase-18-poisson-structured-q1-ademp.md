# Phase 18 Poisson Structured q1 ADEMP Sheet

This sheet records the first structured non-Gaussian simulation gate. It follows
the ADEMP structure of Morris, White, and Crowther (2019) and the transparent
reporting checks of Williams et al. (2024). The fitted route is intentionally
small: one ordinary Poisson response, one `mu` structured intercept, and one
phylogenetic layer.

The sheet does not admit NB2, zero-inflated, hurdle, spatial, animal,
`relmat()`, slope, q2, q4, `sigma`, shape, ordinal, bounded-response, or
mixed-response structured routes. Those remain failure-ledger rows until their
own likelihood, extractor, diagnostic, interval, and recovery evidence exists.

## A - Aims

Primary aim: estimate recovery, convergence, diagnostic behaviour, runtime, and
direct structured-SD interval status for the ordinary Poisson q1 phylogenetic
`mu` intercept route:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree)),
  family = poisson(link = "log"),
  data = dat
)
```

Secondary aims:

- compare the structured route with the nearest ordinary grouped-count
  alternative when the same species labels are treated as independent groups;
- measure sensitivity to tree size, observations per species, expected count,
  true phylogenetic SD, and phylogenetic covariance conditioning;
- verify that neighbouring structured count syntax stays closed before fitting;
- keep the Poisson q1 row separate from ordinary Poisson/NB2 grouped-count
  grids and from Gaussian phylogenetic evidence.

## D - Data-Generating Mechanism

For species `s = 1, ..., S` and observations `i` within species:

```text
a ~ Normal(0, sd_phylo^2 A)
eta_mu_i = offset_i + beta0 + beta1 * x_i + a_species[i]
mu_i = exp(eta_mu_i)
count_i ~ Poisson(mu_i)
```

Here `A` is the phylogenetic covariance implied by the tree, and the fitted
model uses the corresponding sparse precision matrix. The first design should
use trees small enough for local smoke checks and large enough to expose weak
structured-SD recovery.

| Factor | Initial levels | Purpose |
| --- | --- | --- |
| Species count | 20, 40 | Distinguish tiny tutorial fits from a first recovery surface. |
| Observations per species | 4, 8 | Measure replication needed to separate `sd_phylo` from fixed effects. |
| True `sd_phylo` | 0, 0.25, 0.60 | Include boundary, modest signal, and visible signal cases. |
| Mean count | low and moderate intercepts | Check sparse-count failures before biological examples claim stability. |
| Tree/covariance conditioning | balanced and mildly uneven trees | Track when the known structure creates numerical stress. |

Use 20 replicates per cell for local smoke validation. A formal recovery table
should use at least 500 replicates per cell before reporting coverage or
failure rates as stable operating characteristics.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Log-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Log-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Phylogenetic SD in `mu` | `sd_phylo` | `fit$sdpars$mu["phylo(1 | species)"]`, with exact label verified by tests |
| Conditional species effects | generated `a_s` | `ranef(fit, "phylo_mu")`, for diagnostics rather than formal unbiasedness claims |
| Direct SD interval | `sd_phylo` | `profile_targets(fit)` direct `log_sd_phylo` row, then `confint()` when profiling is requested |

No latent correlation is estimated in q1. `corpairs()` should not invent a row
for this model.

## M - Methods

Fit the intended structured model:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree)),
  family = poisson(link = "log"),
  data = dat
)
```

Fit the ordinary grouped comparator only as a diagnostic contrast:

```r
drmTMB(
  bf(count ~ x + (1 | species)),
  family = poisson(link = "log"),
  data = dat
)
```

The comparator does not estimate phylogenetic signal. It answers whether the
structured route behaves differently from treating species as exchangeable
independent groups under the same count design.

The first grid should reject or exclude:

- `phylo(0 + x | species, tree = tree)` and other Poisson structured slopes;
- labelled q2/q4 Poisson phylogenetic covariance;
- NB2 `phylo()` routes;
- zero-inflated or hurdle `phylo()` routes;
- `spatial()`, `animal()`, or `relmat()` inside a Poisson likelihood;
- any structured count effect in `sigma`, `zi`, `hu`, shape, ordinal, or
  bounded-response components.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Rule |
| --- | --- |
| Bias | `mean(estimate - truth)` with MCSE |
| RMSE | `sqrt(mean((estimate - truth)^2))` with MCSE |
| Wald coverage | Fixed `mu` coefficients only, when `sdreport()` is available |
| Direct SD profile status | success, boundary, unavailable, or failed, with profile message |
| Direct SD profile coverage | only for profile rows with valid lower and upper endpoints |
| Convergence rate | `mean(converged & pdHess)` |
| Boundary rate | fraction with fitted `sd_phylo` near zero or `check_drm()` boundary flags |
| Warning/error rate | recorded from fit conditions and warning ledgers |
| Runtime | median and high quantiles of elapsed seconds |

Every report should show failed fits and interval-unavailable rows beside
successful estimates. Do not filter them away before summarising.

## Smoke-Runner Scaffold

The first smoke-runner implementation created this small runner shape:

```text
inst/sim/dgp/sim_dgp_poisson_phylo_q1.R
inst/sim/fit/sim_summarise_poisson_phylo_q1.R
inst/sim/run/sim_run_poisson_phylo_q1_smoke.R
inst/sim/run/sim_summary_poisson_phylo_q1_smoke.R
inst/sim/run/sim_write_poisson_phylo_q1_grid.R
tests/testthat/test-phase18-poisson-phylo-q1.R
```

The current summary helper returns:

- replicate-level fit summaries;
- aggregate bias/RMSE/convergence summaries;
- warning and error ledgers;
- `check_drm()` diagnostic status columns;
- profile-target status rows for `log_sd_phylo`;
- optional direct profile intervals for `log_sd_phylo`, with profile coverage,
  interval-evidence, interval-diagnostics, and interval-failure tables;
- an artifact manifest for saved per-replicate RDS results.

The smoke runner reuses the existing Phase 18 replicate-runner helpers. It
stays opt-in and small enough for local validation, not CRAN-scale tests.
The detailed runner, manifest, warning/error, documentation-sync, and focused
test contracts are recorded in
`docs/design/72-poisson-phylo-q1-runner-contract.md`.

The formal-grid wrapper writes the same artifact family plus
`poisson-phylo-q1-formal-spec.csv`, records whether the 500-replicate formal
recovery gate is met, and can be called by the manual
`poisson_phylo_q1_formal` GitHub Actions task. That task is excluded from
`task = "all"` so routine Phase 18 dispatch does not accidentally launch a
large count-phylogeny grid.

## User-Facing Boundary Examples

| User request | Fit now | Explain as planned |
| --- | --- | --- |
| "Counts vary by phylogeny" | Poisson `phylo(1 | species, tree = tree)` in `mu` | Recovery grids still decide when to advertise this beyond smoke-level evidence. |
| "Overdispersed counts vary by phylogeny" | Ordinary NB2 `mu` random effects if a plain group is enough | NB2 `phylo()` q1 waits for overdispersion-vs-structured-SD recovery. |
| "Counts vary spatially" | Ordinary Poisson/NB2 `mu` random effects when a site group is enough | Poisson/NB2 `spatial()` waits until the phylogenetic q1 recovery gate closes. |
| "Zero inflation varies by phylogeny" | Fixed-effect `zi` where supported, or ordinary count random effects | Structured `zi` random effects are a separate probability-component design. |
| "Count slopes vary by phylogeny" | Ordinary Poisson/NB2 independent numeric `mu` slopes | Structured count slopes wait until q1 intercept recovery is reliable. |

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | Poisson phylogenetic q1 DGP is explicit. |
| 3. Estimands | Fixed `mu`, structured SD, conditional effects, and interval target are named. |
| 4. Methods | Intended `drmTMB` model and ordinary comparator are stated. |
| 5. Performance measures | Bias, RMSE, coverage, convergence, boundary, warning, and runtime measures are defined. |
| 6. Software/settings | Runner metadata remains required. |
| 7. Code availability | The DGP, fitter, smoke runner, summary helper, grid writer, formal-grid wrapper, Actions task, and focused tests live under `inst/sim/`, `.github/workflows/`, and `tests/testthat/`. |
| 8. Replicability | Seeded replicate outputs and artifact manifests are required. |
| 9. Real-data motivation | The biological interpretation is phylogenetic species differences in expected counts. |
| 10. Complete results | Failure ledgers and unavailable interval rows are required outputs. |
| 11. Monte Carlo uncertainty | Formal coverage claims require at least 500 replicates per cell. |
