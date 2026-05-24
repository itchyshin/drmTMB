# Poisson Phylogenetic q1 Runner Contract

This contract turns the fitted ordinary Poisson `phylo(1 | species, tree =
tree)` q=1 `mu` route into testable simulation-runner requirements. It does
not add a new likelihood route. It records what the first recovery runner,
malformed-neighbour tests, extractor checks, diagnostic checks, and artifact
checks must prove before the route can move beyond smoke-level evidence.

The route remains one response, one family, one distributional parameter, one
structured layer, and one latent endpoint:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree)),
  family = poisson(link = "log"),
  data = dat
)
```

NB2, zero-inflated, hurdle, spatial, animal, `relmat()`, slope, q2, q4,
structured `sigma`, shape, ordinal, bounded-response, and mixed-response
neighbours stay planned or unsupported here.

## Implementation Status

Slices 451-465 implemented the first opt-in smoke surface:

```text
inst/sim/dgp/sim_dgp_poisson_phylo_q1.R
inst/sim/fit/sim_summarise_poisson_phylo_q1.R
inst/sim/run/sim_run_poisson_phylo_q1_smoke.R
inst/sim/run/sim_summary_poisson_phylo_q1_smoke.R
tests/testthat/test-phase18-poisson-phylo-q1.R
```

The implemented helper returns aggregate, replicate, manifest, failure-ledger,
fixed-effect Wald interval, Wald coverage, and direct profile-target status
tables. Formal recovery grids, CSV grid writers, and coverage claims remain
future work.

## Slices 421-422: Target And Extractor Rows

The runner and focused tests should assert the exact public rows before any
simulation report interprets the route.

| Surface | Required row contract |
| --- | --- |
| Structured SD | `sdpars$mu` contains one phylogenetic q1 SD row for `phylo(1 | species)`. |
| Conditional effects | `ranef(fit, "phylo_mu")` returns species-level conditional effects on the log-mean scale. |
| Direct profile target | `profile_targets(fit)` contains one direct `log_sd_phylo` target for the Poisson `mu` phylogenetic SD. |
| Correlations | `corpairs()` returns no q1 latent-correlation row for this model. |
| Fixed effects | `coef(fit, dpar = "mu")` returns log-mean coefficients, with offset handling unchanged from ordinary Poisson. |

Tests should check row names and component names directly, not only row counts.
If labels change, documentation and simulation summaries should move in the
same PR.

## Slices 423-424: Artifact Schemas

The smoke runner should save an artifact manifest and warning/error ledger with
stable columns. Extra columns are allowed, but these columns are required.

| Manifest column | Meaning |
| --- | --- |
| `surface` | Constant route name, for example `poisson_phylo_q1`. |
| `cell_id` | Condition-cell identifier. |
| `replicate` | Replicate number within cell. |
| `seed` | Seed used to simulate the replicate. |
| `artifact` | Artifact class, such as `replicate`, `aggregate`, `diagnostic`, `profile_target`, or `failure_ledger`. |
| `path` | Relative output path. |
| `exists` | Whether the artifact exists after the run. |
| `n_rows` | Row count for CSV artifacts; `NA` for non-tabular artifacts. |
| `requested_workers` | Worker count requested by the caller. |
| `actual_workers` | Worker count actually used by the runner. |
| `session_info` | Session metadata path or compact session identifier. |

| Warning/error column | Meaning |
| --- | --- |
| `surface` | Constant route name. |
| `cell_id` | Condition-cell identifier. |
| `replicate` | Replicate number within cell. |
| `stage` | `simulate`, `fit`, `extract`, `diagnose`, `profile`, or `write`. |
| `status` | `ok`, `warning`, `error`, `skipped`, or `unavailable`. |
| `message` | Warning, error, or unavailable-status text. |
| `converged` | Optimizer convergence flag when a fit object exists. |
| `pdHess` | Hessian flag when available. |
| `elapsed_sec` | Elapsed wall time for the stage. |

Do not summarize operating characteristics after dropping failed or
interval-unavailable replicates. Failure rows are part of the result.

## Slices 425-426: Smoke And Formal Grid Gates

The first smoke grid should stay small enough for local opt-in validation:

| Factor | Smoke levels |
| --- | --- |
| Species count | 20, 40 |
| Observations per species | 4, 8 |
| True `sd_phylo` | 0, 0.25, 0.60 |
| Mean count | low, moderate |
| Tree conditioning | balanced, mildly uneven |
| Replicates | 20 per cell for local smoke |

Formal coverage or recovery claims need a separate admission decision:

| Gate | Required evidence before promotion |
| --- | --- |
| Fixed effects | Bias, RMSE, convergence, and Wald coverage with Monte Carlo standard errors. |
| Structured SD | Bias, RMSE, boundary rate, direct profile-target status, and valid interval rows where profiles succeed. |
| Diagnostics | `check_drm()` rows for replication, boundary, SD-ratio, Hessian, fixed-gradient, and family warning status. |
| Failure ledger | Warning, error, boundary, unavailable-interval, and elapsed-time rows reported beside successful fits. |
| Replicates | At least 500 replicates per cell before coverage is described as an operating characteristic. |

The ordinary grouped Poisson comparator should be reported as a diagnostic
contrast, not as a phylogenetic-signal estimator.

## Slices 427-430: Documentation Sync

After runner evidence exists, user-facing docs should keep three statements
together:

1. Poisson q1 phylogenetic `mu` is fitted on the log-mean scale.
2. The route is still smoke/artifact level, not broad count structured parity.
3. NB2, zero inflation, hurdle probability, slopes, q2/q4 count covariance,
   spatial, animal, and `relmat()` count structure remain planned.

The count tutorial should separate the fitted ordinary Poisson q1 phylogenetic
`mu` route from the remaining planned phylogenetic count neighbours.

## Slice 431: Unsupported Syntax Error Table

Future malformed-input tests should verify early, specific failures for these
requests:

| Unsupported request | Expected guidance |
| --- | --- |
| `phylo(0 + x | species, tree = tree)` in Poisson `mu` | Structured count slopes are planned; use ordinary independent count slopes or q1 phylogenetic intercept. |
| labelled Poisson q2/q4 `phylo()` blocks | Count covariance blocks are planned; q1 has no latent correlation row. |
| Poisson `phylo()` in `zi` | `zi` remains fixed-effect probability modelling. |
| NB2 `phylo()` | NB2 structured q1 waits for overdispersion-versus-structured-SD recovery. |
| Poisson `spatial()`, `animal()`, or `relmat()` | Only the Poisson phylogenetic q1 route is fitted. |
| structured count `sigma`, shape, ordinal, bounded, or mixed-response routes | These are separate family/component gates, not Poisson q1 extensions. |

Messages should name the family, component, structured layer, and nearest
fitted alternative.

## Slices 432-435: Focused Test Plan

| Slice | Test target |
| --- | --- |
| 432 | Malformed syntax rejects the unsupported neighbours in Slice 431 before TMB fitting. |
| 433 | Extractor names match `sdpars$mu`, `ranef("phylo_mu")`, direct `log_sd_phylo`, and absent q1 `corpairs()` rows. |
| 434 | Diagnostic rows include replication, SD-ratio or boundary, Hessian, fixed-gradient, and family-warning status. |
| 435 | Simulation artifacts include aggregate, replicate, manifest, failure-ledger, diagnostic, and profile-target files with row-count checks. |

These tests should be focused and skip-aware. CRAN-scale simulations should stay
outside routine package checks; routine tests should exercise tiny fixtures,
schema validation, and malformed-input guards.
