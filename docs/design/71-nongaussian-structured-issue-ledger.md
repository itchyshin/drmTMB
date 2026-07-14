# Non-Gaussian Structured Issue Ledger

This ledger turns the Slice 406-420 stretch queue into issue-ready text. It is
not implementation permission. It gives future PRs a route-specific starting
point after the Slice 389-405 gate closed the broad planning rows.

The simulation sections follow the ADEMP structure of Morris, White, and
Crowther (2019) and the transparent reporting checklist of Williams et al.
(2024). Any future runner should report Monte Carlo standard errors beside
operating-characteristic summaries.

## Slice 406: Route-Specific Issue Ledger

Future issues should use one route per issue. The minimum route key is:

| Field | Rule |
| --- | --- |
| Family | One likelihood family, such as `poisson(link = "log")` or `nbinom2()`. |
| Component | One distributional parameter, starting with `mu`. |
| Layer | One structured marker, starting with `phylo()`. |
| q | One latent endpoint count, starting with q=1. |
| Comparator | One fitted alternative, usually an ordinary grouped count random effect. |
| Boundary rows | Explicit unsupported neighbours with expected error text. |
| Evidence | Extractors, diagnostics, interval status, simulations, docs, and stale scans. |

Do not open an implementation issue named "non-Gaussian structured effects" or
"count structured parity." Those labels are too broad to review.

## Slice 407: Poisson q1 Implementation Issue Draft

Suggested title: Implement Poisson phylogenetic q1 `mu` intercept evidence gate.

Issue body:

```md
## Route

- Family: `poisson(link = "log")`
- Component: `mu`
- Layer: `phylo(tree = tree)`
- q: 1
- Syntax: `bf(count ~ x + phylo(1 | species, tree = tree))`
- Comparator: ordinary Poisson `bf(count ~ x + (1 | species))`

## Required implementation evidence

- Confirm the log-mean likelihood contract and structured prior contribution.
- Confirm `sdpars$mu` label for the phylogenetic SD.
- Confirm `ranef(fit, "phylo_mu")` conditional effects on the link scale.
- Confirm `profile_targets(fit)` direct `log_sd_phylo` row.
- Confirm `check_drm()` replication, boundary, Hessian, and SD-ratio rows.
- Confirm `corpairs()` returns no q1 latent-correlation row.
- Add malformed-neighbour tests for slopes, q2/q4, `zi`, `hu`, NB2,
  `spatial()`, `animal()`, `relmat()`, `sigma`, shape, and cross-parameter
  structured requests.
- Update implementation-map, model-map, formula grammar, family docs, NEWS,
  check-log, and after-task report.

## Not in scope

- NB2 structured effects beyond the ordinary q=1 `mu` phylogenetic intercept.
- Zero-inflated or hurdle structured effects.
- Structured count slopes.
- q2/q4 count covariance.
- Spatial, animal, or `relmat()` count effects.
- Structured scale, shape, ordinal, bounded-response, or mixed-response routes.
```

## Slice 408: Poisson q1 Smoke-Runner Issue Draft

Suggested title: Add Poisson phylogenetic q1 smoke recovery runner.

Issue body:

```md
## Purpose

Build the first opt-in recovery runner for
`bf(count ~ x + phylo(1 | species, tree = tree))`.

## Required files

- `inst/sim/dgp/sim_dgp_poisson_phylo_q1.R`
- `inst/sim/run/sim_run_poisson_phylo_q1_smoke.R`
- `inst/sim/run/sim_summary_poisson_phylo_q1_smoke.R`
- `tests/testthat/test-phase18-poisson-phylo-q1.R`

## Required artifacts

- replicate-level fit summaries;
- aggregate bias/RMSE/convergence summaries;
- warning and error ledgers;
- `check_drm()` diagnostic rows;
- profile-target status rows for `log_sd_phylo`;
- manifest with file paths, row counts, seeds, worker settings, and session
  metadata.

## Initial smoke grid

- species count: 20, 40;
- observations per species: 4, 8;
- true `sd_phylo`: 0, 0.25, 0.60;
- mean count: low, moderate;
- tree conditioning: balanced, mildly uneven;
- local smoke replicates: 20 per cell;
- formal coverage claim: at least 500 replicates per cell.
```

## Slice 409: Malformed-Neighbour Test Issue Draft

Suggested title: Guard unsupported structured count neighbours for Poisson q1.

Issue body:

```md
Add tests that unsupported neighbours fail before TMB with messages naming the
family, component, layer, and nearest fitted alternative.

Required unsupported requests:

- `phylo(0 + x | species, tree = tree)` in Poisson `mu`;
- labelled Poisson q2 or q4 phylogenetic blocks;
- Poisson `phylo()` in `zi`;
- Poisson `spatial()`, `animal()`, or `relmat()`;
- NB2 `phylo()` beyond the ordinary q=1 `mu` intercept;
- structured effects in `sigma`, shape, ordinal, bounded-response, or
  mixed-response components;
- cross-parameter count covariance.
```

## Slice 410: User-Documentation Sync Issue Draft

Suggested title: Document Poisson phylogenetic q1 as a first-slice count route.

Issue body:

```md
Update user-facing docs only after implementation, extractor, diagnostic,
interval-status, and smoke-runner evidence exists.

Required pages:

- `vignettes/implementation-map.Rmd`;
- `vignettes/model-map.Rmd`;
- `vignettes/formula-grammar.Rmd`;
- `vignettes/count-nbinom2.Rmd` or a focused count-dependence page;
- `docs/design/01-formula-grammar.md`;
- `docs/design/03-likelihoods.md`;
- `README.md` only if the route is visible enough for top-level status;
- `NEWS.md`;
- `docs/dev-log/check-log.md`;
- after-task report.

The docs must say that Poisson q1 phylogenetic `mu` is separate from NB2 q1
phylogenetic `mu`; neither route is `zi`, `hu`, q2/q4, a labelled count
covariance route, or a pure or multiple structured count slope route.
```

## Slice 411-414: NB2 q1 ADEMP Skeleton

This section began as a skeleton. The ordinary non-zero-inflated NB2 q=1
phylogenetic `mu` intercept is now fitted as a first code slice, but this
section still defines the larger overdispersion-aware recovery grid needed
before the route should be promoted beyond smoke evidence.

### A - Aims

Primary aim: evaluate whether the q=1 phylogenetic NB2 `mu` structured
intercept can recover fixed log-mean coefficients and the structured SD when
overdispersion is also estimated through fixed-effect `sigma`.

Secondary aims:

- measure confounding between NB2 overdispersion and the structured SD;
- compare against ordinary NB2 `mu` random intercepts;
- identify mean-count and overdispersion regions where the structured SD becomes
  boundary-dominated;
- keep zero-inflated, hurdle, slope, q2/q4, spatial, animal, `relmat()`, and
  scale-structured routes out.

### D - Data-Generating Mechanism

For species `s = 1, ..., S` and observations `i` within species:

```text
a ~ Normal(0, sd_phylo^2 A)
eta_mu_i = offset_i + beta0 + beta1 * x_i + a_species[i]
mu_i = exp(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
count_i ~ NB2(mu_i, size_i = 1 / sigma_i^2)
```

Initial factors:

| Factor | Initial levels |
| --- | --- |
| Species count | 20, 40 |
| Observations per species | 4, 8 |
| True `sd_phylo` | 0, 0.25, 0.60 |
| Mean count | low, moderate |
| NB2 `sigma` | low, moderate, high |
| Tree conditioning | balanced, mildly uneven |

### E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Log-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Log-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-overdispersion coefficients | `gamma` | `coef(fit, dpar = "sigma")` |
| Phylogenetic SD in `mu` | `sd_phylo` | future `sdpars$mu` row |
| Direct SD interval | `sd_phylo` | future direct `log_sd_phylo` profile row |

### M - Methods

Intended future structured fit:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

Comparator:

```r
drmTMB(
  bf(count ~ x + (1 | species), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

### P - Performance Measures

Report bias, RMSE, fixed-effect Wald coverage, direct SD profile status,
convergence rate, Hessian rate, boundary rate, warning/error rate, and runtime
with Monte Carlo standard errors. Do not report coverage after filtering out
failed fits.

## Slice 415-420: Component And Public-Name Contracts

| Slice | Contract |
| --- | --- |
| 415 | `zi` and `hu` structured effects need probability-component use cases, prediction semantics, diagnostics, and recovery before syntax. |
| 416 | Non-Gaussian scale structured effects need family-specific scale interpretation and separation from latent structured SD. |
| 417 | Historical planning boundary, superseded in part: shape and ordinal random effects outside the exact fitted gates need family-specific comparator and boundary evidence before broader mixed-model syntax. |
| 418 | Known sampling covariance and latent relatedness must stay separate in issue titles, formulas, diagnostics, and examples. |
| 419 | Structured count q1 extractor names should reserve route-specific labels before code: `sdpars$mu`, `ranef("<level>_mu")`, direct `log_sd_*`, and no `corpairs()` row for q1. |
| 420 | Structured count q1 diagnostics should reserve route-specific rows for replication, SD-ratio/boundary, Hessian, fixed-gradient, family-specific warnings, and unsupported-neighbour errors. |

The next implementation PR should copy one of these issue drafts rather than
reopening the full design discussion.
