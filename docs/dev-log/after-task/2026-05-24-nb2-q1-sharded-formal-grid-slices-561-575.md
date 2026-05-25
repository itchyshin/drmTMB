# After Task: NB2 q1 Sharded Formal Grid Slices 561-575

## Goal

Merge the completed NB2 smoke/formal-admission PR, attempt the clean
500-replicate formal dispatch, and record the next safe compute shape for the
ordinary NB2 q=1 phylogenetic `mu` route.

## Implemented

PR #320 merged after green R-CMD-check evidence on Ubuntu, macOS, and Windows.
The full NB2 formal grid was then dispatched from `main` as Actions run
`26371083871` with `task = "nbinom2_phylo_q1_formal"`, `n_reps = 500`,
`cores = 10`, `backend = "multicore"`, and
`profile_parameters = "log_sd_phylo"`.

Grace cancelled that singleton run before timeout because the existing
Slices 541-555 manifests imply roughly 27-31 optimistic ten-worker hours for
the 288 x 500 formal condition grid. Waiting for the 360-minute Actions cap
would have produced a compute failure, not a formal audit.

The Phase 18 workflow and Actions runner now accept `condition_shard` and
`condition_shards` for the Poisson/NB2 phylogenetic q1 formal tasks. The runner
applies a stable one-based modulo partition over the formal condition table and
rejects shard inputs for non-formal summary tasks.

Poisson and NB2 formal spec files now record shard metadata:
`condition_shard`, `condition_shards`, `full_condition_count`,
`shard_condition_count`, and `shard_recovery_gate`. They keep
`coverage_claim_allowed = FALSE` whenever `condition_shards > 1`, so a partial
shard cannot be promoted as full formal evidence.

## Mathematical Contract

The fitted model is unchanged:

```r
drmTMB(
  bf(count ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The slice changes only the compute and artifact contract. The NB2 q1
phylogenetic `mu` route remains `hold_smoke_only` until all 288 formal
condition cells have 500 completed replicates and are audited together.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_write_nbinom2_phylo_q1_grid.R`
- `inst/sim/run/sim_write_poisson_phylo_q1_grid.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-nbinom2-phylo-q1.R`
- `docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md`
- `docs/design/76-phase-18-nbinom2-phylo-q1-sharded-formal-grid.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `inst/sim/README.md`
- `vignettes/source-map.Rmd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "files <- c('inst/sim/run/sim_run_actions_cell.R','inst/sim/run/sim_write_nbinom2_phylo_q1_grid.R','inst/sim/run/sim_write_poisson_phylo_q1_grid.R','tests/testthat/test-phase18-nbinom2-phylo-q1.R','tests/testthat/test-phase18-actions-runner.R'); invisible(lapply(files, parse)); cat('parse ok\n')"
Rscript inst/sim/run/sim_run_actions_cell.R --task=nbinom2_phylo_q1_formal --dry-run=true --n-reps=500 --cores=10 --backend=multicore --profile-parameters=log_sd_phylo --condition-shard=2 --condition-shards=16
Rscript -e "devtools::test(filter = 'phase18-actions-runner|phase18-nbinom2-phylo-q1|phase18-poisson-phylo-q1', reporter = 'summary')"
Rscript -e "pkgdown::check_pkgdown()"
gh run cancel 26371083871 --repo itchyshin/drmTMB
gh issue list --repo itchyshin/drmTMB --state open --search "NB2 phylo q1" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "Phase 18 NB2 formal" --limit 20 --json number,title,state,url,labels
rg -n 'NB2.*q1.*formal recovery.*(now|passed|complete)|NB2.*q1.*coverage.*(now|passed|complete)|nbinom2_phylo_q1.*promote_narrowly|broad NB2 structured.*(ready|now)|formal grid.*passed|500-replicate.*(passed|complete)' NEWS.md ROADMAP.md README.md inst/sim/README.md docs/design vignettes tests -g '!*.html'
git diff --check
```

Results:

- Parse smoke printed `parse ok`.
- The Actions dry run printed `n_rep=500`, `backend=multicore`, `cores=10`,
  `profile_parameters=log_sd_phylo`, `condition_shard=2`, and
  `condition_shards=16`.
- Focused tests passed for `phase18-actions-runner`,
  `phase18-nbinom2-phylo-q1`, and `phase18-poisson-phylo-q1`.
- `pkgdown::check_pkgdown()` reported no problems.
- Actions run `26371083871` ended with the NB2 formal job cancelled, no
  artifact upload, and unrelated matrix jobs skipped.
- Direct issue searches returned no open issue that needed mutation.
- The stale-promotion scan returned no current claim that NB2 q1 formal
  recovery or coverage has passed.
- `git diff --check` was clean.

## Tests Of The Tests

The focused tests check dry-run shard parsing, rejection of shard inputs for a
non-formal task, NB2 shard metadata, and the rule that a shard with
`n_rep = 500` still cannot set `coverage_claim_allowed = TRUE`.

## Consistency Audit

Rose checked that the docs say the singleton was cancelled for runtime reasons,
not because the fitted NB2 q1 likelihood failed. The route remains a fitted
smoke/formal-admission surface with no broad NB2 structured-count promotion.

## GitHub Issue Maintenance

Direct issue searches for `NB2 phylo q1` and `Phase 18 NB2 formal` found no
open direct issue that needed mutation. Broader Phase 18 ledgers remain open
for later full-grid evidence.

## What Did Not Go Smoothly

The first plan assumed the 500-replicate grid could be run as one manual
Actions task. The existing manifest timings made that assumption untenable:
the single job was likely to exceed the Actions cap by a wide margin.

## Team Learning

Ada should estimate large formal-grid runtime from existing manifests before
dispatch. Grace should make sharding explicit in workflow inputs before a
formal grid crosses the single-job budget. Fisher should treat shard artifacts
as partial evidence until a combined audit proves full coverage.

## Known Limitations

No 500-replicate NB2 q1 formal artifact exists yet. The sharding infrastructure
is ready, but the actual formal recovery, coverage, warning, Hessian, runtime,
and grouped-comparator audit still requires all shards to be run and combined.

## Next Actions

Run the NB2 q1 formal grid as a sharded manual Actions set, likely
`condition_shards = 16`, then download the artifacts, merge the tables, run
read-back QA, and decide whether the route remains `hold_smoke_only` or can be
promoted narrowly.
