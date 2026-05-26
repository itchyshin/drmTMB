# Phase 18 NB2 Phylogenetic q1 Sharded Formal Grid

This note records Slices 561-575 for the ordinary NB2 q=1 phylogenetic `mu`
route:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The model surface is unchanged. The slice only changes how the formal Phase 18
grid is dispatched and interpreted.

## Why The Single Job Was Cancelled

After PR #320 merged, run `26371083871` dispatched the full
`nbinom2_phylo_q1_formal` task from `main` with `n_reps = 500`,
`profile_parameters = "log_sd_phylo"`, `backend = "multicore"`, and
`cores = 10`. That shape asks for 288 condition cells x 500 replicates, or
144,000 target/comparator replicate fits before direct profile intervals are
counted.

The Slices 541-555 local manifests give a safer runtime estimate than waiting
for GitHub to time out:

| Prior run | Manifest rows | Mean elapsed seconds | Optimistic 10-worker full-grid estimate |
| --- | ---: | ---: | ---: |
| All-cell sentinel, `n_rep = 1` | 288 | 6.80 | 27.2 hours |
| Representative audit, `n_rep = 5` | 120 | 7.83 | 31.3 hours |

Because the workflow job has a 360-minute timeout, Grace cancelled the
single-job dispatch before treating timeout as evidence. The formal recovery
gate remains closed.

## Shard Contract

The manual Phase 18 workflow now accepts `condition_shard` and
`condition_shards`. The Actions runner applies a stable one-based modulo
partition over the formal condition table. Each shard keeps the same model,
truth grid, grouped comparator row, direct `log_sd_phylo` profile request, and
replicate count.

A shard is not a full formal grid. Formal spec files now record
`condition_shard`, `condition_shards`, `full_condition_count`,
`shard_condition_count`, and `shard_recovery_gate`. They also set
`coverage_claim_allowed = FALSE` whenever `condition_shards > 1`, even if the
shard itself used `n_rep = 500`. This prevents a single shard from returning a
promotion decision for the whole NB2 q1 route.

The practical dispatch shape should use enough shards that each job fits inside
the Actions cap. Sixteen shards is the first recommended shape:

```sh
for shard in $(seq 1 16); do
  gh workflow run phase18-simulation-grid.yaml \
    --repo itchyshin/drmTMB \
    --ref main \
    -f task=nbinom2_phylo_q1_formal \
    -f n_reps=500 \
    -f cores=10 \
    -f backend=multicore \
    -f profile_parameters=log_sd_phylo \
    -f condition_shard="$shard" \
    -f condition_shards=16 \
    -f render_report=false \
    -f retention_days=14
done
```

The workflow concurrency group includes `condition_shard` and
`condition_shards`. That is intentional: GitHub Actions keeps at most one
pending run per concurrency group, so shard-level concurrency prevents a rapid
16-run dispatch from replacing earlier pending shards. This does not change the
statistical grid; it only makes the operational queue match the shard contract.

## Audit Rule

Fisher should not interpret shard artifacts one at a time. Promotion can only
be reconsidered after the downloaded shard set proves all of these conditions:

- every one of the 288 formal condition cells appears;
- every cell has 500 completed replicate fits;
- profile failures, warning rows, Hessian rows, runtime rows, and grouped
  comparator rows remain in the merged tables;
- the combined read-back QA passes without missing artifact classes;
- bias, RMSE, convergence, `pdHess`, boundary, warning/error, runtime, Wald
  coverage, and direct-profile interval summaries are computed from the merged
  table set.

Until that combined audit exists, the NB2 q1 phylogenetic `mu` route remains
`hold_smoke_only`.

## Full Shard Audit Result

The 16-shard manual dispatch from `main` at commit `2754e536` completed
successfully on GitHub Actions on 2026-05-25. The downloaded artifact set
contains all 16 `phase18-nbinom2_phylo_q1_formal-shard-*` archives, each with
the 13 expected CSV tables. The combined formal specification has 288 unique
condition combinations, 16 shards, 18 conditions per shard, and `n_rep = 500`.
Each shard-level formal spec still records `coverage_claim_allowed = FALSE`,
which is correct because no single shard may promote the whole route.

The merged manifest has 144,000 rows, 288 global shard-cell combinations, and
exactly 500 manifest rows per global shard-cell. All manifest rows have
`status = "ok"` and `skipped = FALSE`. The audit used a global key made from
`condition_shard` and local `cell_id`, because each shard preserves local
`cell_id` labels from `nbinom2_phylo_q1_001` through
`nbinom2_phylo_q1_018`.

The compute gate is now complete, but the promotion gate remains closed.
Fixed-effect Wald coverage includes weak cells, with 122 of 1,152 coverage rows
below 0.90 and 27 below 0.85. Direct `log_sd_phylo` profile intervals remain
boundary-sensitive: median profile success is 0.058 when the true phylogenetic
SD is 0, 0.626 when it is 0.25, and 0.992 when it is 0.60. Low-count,
low-overdispersion cells still show large fixed-`sigma` errors. Treat the full
shard set as a completed formal audit with caution flags, not as a narrow
promotion.
