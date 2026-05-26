# After Task: NB2 q1 Formal Shard Audit, Slice D1

## Goal

Pick up Slice D1 by auditing the already-completed 16-shard
`nbinom2_phylo_q1_formal` GitHub Actions artifact set. The goal was to decide
what the full 500-replicate formal grid says about the ordinary NB2 q=1
phylogenetic `mu` route, not to add new syntax or rerun duplicate compute.

## Implemented

Ada rehydrated the current repository state and found that the 16 successful
formal shard runs already existed on GitHub Actions. The artifacts were
downloaded locally under `/tmp/drmTMB-nb2-q1-formal-shards-20260525` and
audited together. The raw artifacts were not committed.

No spawned subagents were running. Grace checked the Actions and artifact
inventory. Curie checked the shard and combined artifact structure. Fisher
checked recovery, coverage, profile interval status, and promotion boundaries.
Rose caught that local `cell_id` labels repeat inside shards, so the combined
audit used a global key made from `condition_shard` and `cell_id`.

## Evidence Source

The artifact set came from 16 successful `Phase 18 simulation grid` workflow
runs on `main` at commit `2754e536ab27fd4ebc1ed34dfe95cfbd6f8b50b9`. The
artifact names ran from
`phase18-nbinom2_phylo_q1_formal-shard-1-of-16-26374047006` through
`phase18-nbinom2_phylo_q1_formal-shard-16-of-16-26374069987`.

Each shard used:

```text
task = nbinom2_phylo_q1_formal
n_reps = 500
cores = 10
backend = multicore
profile_parameters = log_sd_phylo
condition_shards = 16
```

## Artifact QA

The downloaded set contained all 13 expected CSV artifact families for each
shard:

- formal spec;
- manifest;
- replicate;
- aggregate;
- failure ledger;
- Wald intervals;
- Wald coverage;
- profile targets;
- profile intervals;
- profile coverage;
- interval evidence;
- interval diagnostics;
- interval failures.

The combined formal specification had 288 unique condition combinations, 16
shards, 18 conditions per shard, and `n_rep = 500`. The merged manifest had
144,000 rows, 288 global shard-cell combinations, exactly 500 rows per global
shard-cell, all rows `status = "ok"`, and no skipped rows.

Existing per-shard read-back QA passed for all 16 shard directories with
`expected_n_rep = 500`. The existing per-shard promotion helper returned
`hold_smoke_only` for every shard because each shard-level formal spec has
`coverage_claim_allowed = FALSE`, as intended.

## Recovery Signals

The aggregate tables had 1,728 rows: six parameter summaries for each of 288
global shard-cell combinations. The minimum per-cell convergence rate was
0.968 and the median was 1.000. The minimum per-cell positive-Hessian rate was
0.890 and the median was 1.000.

Fixed-effect Wald coverage was uneven. Across 1,152 Wald coverage rows, 122
were below 0.90 and 27 were below 0.85. `mu:x`, `sigma:(Intercept)`, and
`sigma:z` median coverage was near or above the nominal 0.95 level, but
`mu:(Intercept)` had a lower median coverage of 0.916.

Direct `log_sd_phylo` profile intervals were strongly boundary-sensitive:

| True `sd_phylo` | Median profile success | Median profile coverage |
| ---: | ---: | ---: |
| 0 | 0.058 | 0.000 |
| 0.25 | 0.626 | 0.518 |
| 0.60 | 0.992 | 0.652 |

The profile status table showed 45,205 failed and 2,795 successful profile
rows at true `sd_phylo = 0`, 17,449 failed and 30,551 successful rows at
`sd_phylo = 0.25`, and 2,210 failed and 45,790 successful rows at
`sd_phylo = 0.60`.

The fixed-`sigma` instability from the smaller audit remained visible. The
largest aggregate errors were low-count, low-overdispersion cells; the worst
`sigma:(Intercept)` aggregate row had bias about -3.40 and RMSE about 6.31 on
the modelled log-`sigma` coefficient scale.

## Decision

Do not promote NB2 q1 phylogenetic `mu` beyond formal-admission evidence. The
compute gate is now complete and the artifact set is structurally usable, but
the merged recovery and interval diagnostics are not strong enough for a narrow
promotion claim.

The status is now:

```text
formal shard artifacts complete
combined audit complete
promotion held
route remains hold_smoke_only
```

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md`
- `docs/design/76-phase-18-nbinom2-phylo-q1-sharded-formal-grid.md`
- `docs/design/79-supported-nongaussian-evidence-goal.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-26-nb2-q1-formal-shard-audit-slice-d1.md`

## Checks Run

```sh
gh run list --repo itchyshin/drmTMB --workflow "Phase 18 simulation grid" --limit 30 --json databaseId,displayTitle,event,status,conclusion,createdAt,updatedAt,headBranch,headSha,url
gh api repos/itchyshin/drmTMB/actions/artifacts --paginate -q '.artifacts[] | select(.name | startswith("phase18-nbinom2_phylo_q1_formal-shard-")) | [.id,.name,.size_in_bytes,.expired,.created_at,.expires_at,.workflow_run.id,.workflow_run.head_sha] | @tsv'
du -sh /tmp/drmTMB-nb2-q1-formal-shards-20260525
Rscript --vanilla - <<'RS'
# Combined CSV audit over the downloaded shard directories.
RS
Rscript --vanilla - <<'RS'
# Existing per-shard read-back QA and promotion-decision helper.
RS
rg -n 'next compute (action|step).*full 500|until (all|that) audit lands|formal recovery artifacts still need all 500|formal grid.*not yet run|promotion.*(allowed|promote_narrowly|promoted)|broad.*NB2 q1|NB2 q1.*now (promotes|promoted|supported|formal recovery)' NEWS.md ROADMAP.md docs/design docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-26-nb2-q1-formal-shard-audit-slice-d1.md -g '!*.html'
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

## Known Limitations

The audit did not commit the raw 4.5 GB downloaded artifact tree. The existing
promotion helper is shard-local, so a future follow-up should add a small
merged-shard QA helper that makes the `condition_shard + cell_id` global-key
rule reusable. The route remains blocked for NB2 phylogenetic slopes,
NB2 `sigma` phylogeny, zero-inflated NB2 phylogeny, spatial, animal, and
`relmat()` structured count effects.

## Next Actions

Pick the next Slice D lane only after accepting the hold decision for NB2 q1.
The most useful low-compute next lane is a design gate rather than another
large run: Student-t/skew-normal, zero-one bounded response, Tweedie, or a
later count-family gate such as Conway-Maxwell-Poisson or generalized Poisson.
