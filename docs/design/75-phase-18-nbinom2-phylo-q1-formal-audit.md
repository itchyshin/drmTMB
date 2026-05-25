# Phase 18 NB2 Phylogenetic q1 Formal Audit

This note records Slices 541-555 for the ordinary NB2 q=1 phylogenetic `mu`
route:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The audit uses the formal-grid machinery from
`docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md`. It does not change the
likelihood, formula grammar, or admitted model surface. Its job is to test the
formal artifact path, inspect the grouped comparator row, and decide whether
the route can move beyond formal-admission evidence.

## Formal Gate

The default formal specification contains 288 condition cells. With
`n_rep = 500`, that is 144,000 target/comparator replicate fits before the
direct `log_sd_phylo` profile requests are counted. That full run was not
launched from the dirty local branch. The formal recovery gate therefore
remains closed:

| Run | Conditions | Replicates | Target replicate fits | Formal gate |
| --- | ---: | ---: | ---: | --- |
| Default formal spec | 288 | 500 | 144,000 | not run locally |
| Local sentinel | 288 | 1 | 288 | not met |
| Representative replicate audit | 24 | 5 | 120 | not met |

The correct promotion-decision status after this audit is `hold_smoke_only`.
The artifacts pass local QA, but the formal recovery replicate gate is not met.

## Slices 561-575 Runtime Gate

After PR #320 merged, the full single-job Actions run was dispatched from
`main` as run `26371083871` with `task = "nbinom2_phylo_q1_formal"`,
`n_reps = 500`, `backend = "multicore"`, `cores = 10`, and
`profile_parameters = "log_sd_phylo"`. Grace cancelled that singleton before
it spent the full six-hour job budget because the existing Slices 541-555
manifests already showed that the run shape is too large for one Actions job.

The sentinel manifest averaged 6.80 seconds per replicate fit, and the
representative 5-replicate audit averaged 7.83 seconds. Even under an optimistic
ten-effective-worker calculation, the 288 x 500 formal grid would take roughly
27-31 hours before GitHub setup overhead. The next formal-compute route is
therefore sharded manual dispatch, not another singleton run.

The sharded runner contract is:

- dispatch `condition_shard = 1, ..., condition_shards`;
- keep `n_reps = 500`, `profile_parameters = "log_sd_phylo"`, and the grouped
  comparator row in every shard;
- treat each shard as partial evidence: shard formal specs record
  `coverage_claim_allowed = FALSE` whenever `condition_shards > 1`;
- promote only after all 288 formal condition cells have 500 replicates, read
  back cleanly, and are audited together.

## Local Artifacts

The artifact directories are ignored package results under `inst/sim/results/`:

- `inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555_sentinel`
- `inst/sim/results/actions/nbinom2_phylo_q1_formal_541_555_replicate_audit`

The sentinel used all 288 formal condition cells once with
`profile_parameters = "log_sd_phylo"`, `backend = "multicore"`, and
`cores = 10`. It wrote all expected CSV artifacts:

| Check | Result |
| --- | ---: |
| Manifest rows | 288 |
| Replicate rows | 1,728 |
| Result failure rows | 55 warning rows |
| Manifest status | 288 `ok` |
| Target convergence | all `TRUE` |
| Target `pdHess` | all `TRUE` |
| Profile intervals | 159 `ok`, 129 `failed` |

The 55 warning rows all report `collapsing to unique 'x' values`. They are
warning-ledger evidence, not failed fits. The profile failures concentrate at
the boundary: the sentinel produced 91 failed and 5 successful profile
intervals when the true phylogenetic SD was 0, 31 failed and 65 successful
intervals when the true SD was 0.25, and 7 failed and 89 successful intervals
when the true SD was 0.60.

The representative replicate audit used 24 formal-shaped cells and
5 replicates per cell, again with `profile_parameters = "log_sd_phylo"`,
`backend = "multicore"`, and `cores = 10`:

| Check | Result |
| --- | ---: |
| Manifest rows | 120 |
| Replicate rows | 720 |
| Result failure rows | 29 warning rows |
| Manifest status | 120 `ok` |
| Convergence | all parameter rows `TRUE` |
| Target `pdHess` | 119 of 120 target fits `TRUE` |
| Grouped-comparator `pdHess` | 120 of 120 comparator fits `TRUE` |
| Profile intervals | 74 `ok`, 46 `failed` |

The profile interval pattern again shows the boundary. All 40 true-zero
phylogenetic SD rows failed to produce usable two-sided profile intervals,
whereas the positive-SD rows produced 36 of 40 usable intervals at true
`sd_phylo = 0.25` and 38 of 40 usable intervals at true `sd_phylo = 0.60`.

## Recovery Signals

The 5-replicate audit is too small for formal recovery or coverage claims, but
it gives useful stress signals:

| Target | Mean error | RMSE | Maximum absolute error |
| --- | ---: | ---: | ---: |
| `mu:(Intercept)` | 0.0118 | 0.1661 | 0.7751 |
| `mu:x` | 0.0042 | 0.0722 | 0.2270 |
| `sigma:(Intercept)` | -0.8945 | 3.6630 | 26.2270 |
| `sigma:z` | 0.2398 | 4.7051 | 33.4698 |
| `sd:mu:phylo(1 | species)` | -0.0354 | 0.1127 | 0.5702 |
| grouped comparator SD | -0.0313 | 0.1235 | 0.3929 |

The extreme fixed-`sigma` errors occur in low-mean, low-overdispersion cells
with small species counts. They are a boundary-identifiability signal for
Fisher and Grace to inspect before a larger run is interpreted. They do not
invalidate the fitted route, but they block any broad recovery wording.

The grouped comparator remains useful. Its SD error scale is close to the
phylogenetic SD error scale in this small audit, which means ordinary
unstructured species heterogeneity can still explain similar between-species
variation in some cells. Keep the comparator row in every NB2 q1 artifact
schema until the formal 500-replicate grid is reviewed.

## Decision

Do not promote NB2 q1 phylogenetic `mu` beyond formal-admission evidence yet.
The local Slices 541-555 artifacts show that the runner, read-back QA, direct
profile target, warning ledger, and grouped comparator schema work across the
formal condition grid. They also show that two-sided profile intervals at
`sd_phylo = 0` are usually boundary failures and that fixed `sigma` can be
weakly identified in low-count, low-overdispersion cells.

The next compute step is the full 500-replicate formal grid, preferably from a
clean pushed branch or manual Actions dispatch. Its audit should preserve the
profile failures, warning rows, Hessian rows, and grouped comparator summaries
instead of filtering them out before computing coverage.
