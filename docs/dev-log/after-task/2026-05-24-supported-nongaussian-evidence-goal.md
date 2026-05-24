# After Task: Supported Non-Gaussian Evidence Goal

## Goal

Implement the goal "Finish supported non-Gaussian distribution evidence" as a
bounded evidence closeout. The claim is that supported fixed-effect
non-Gaussian families and first count mixed-model lanes have a synchronized
evidence ledger, not that `drmTMB` has broad non-Gaussian random-effect parity.

## Implemented

- Added shard-aware concurrency to the Phase 18 simulation workflow so rapid
  16-shard NB2 q1 formal dispatches do not replace earlier pending shards.
- Added a focused workflow-concurrency regression test.
- Added `docs/design/79-supported-nongaussian-evidence-goal.md` as the
  supported non-Gaussian evidence ledger.
- Synced the Phase 18 simulation programme, readiness matrix, validation-debt
  register, simulation README, source map, distribution-family tutorial,
  ROADMAP, NEWS, and check log.

## Mathematical Contract

No likelihood, link, formula grammar, or TMB parameterization changed. The
supported claim remains fixed-effect non-Gaussian families plus narrow first
count mixed-model slices: ordinary Poisson/NB2 `mu` random effects, ordinary
NB2 log-`sigma` random intercepts, and Poisson/NB2 q=1 phylogenetic `mu`
intercepts. The NB2 q1 phylogenetic route remains `hold_smoke_only` until the
full 500-replicate shard set is merged and audited.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `tests/testthat/test-phase18-actions-runner.R`
- `docs/design/79-supported-nongaussian-evidence-goal.md`
- Phase 18, readiness, validation-debt, source-map, NEWS, ROADMAP, simulation
  README, and tutorial ledgers.

## Checks Run

```sh
Rscript -e "files <- c('tests/testthat/test-phase18-actions-runner.R'); invisible(lapply(files, parse)); cat('parse ok\n')"
air format tests/testthat/test-phase18-actions-runner.R
Rscript -e "devtools::test(filter = 'phase18-actions-runner|phase18-nbinom2-phylo-q1|phase18-poisson-phylo-q1', reporter = 'summary')"
Rscript inst/sim/run/sim_run_actions_cell.R --task=nbinom2_phylo_q1_formal --dry-run=true --n-reps=500 --cores=10 --backend=multicore --profile-parameters=log_sd_phylo --condition-shard=16 --condition-shards=16
Rscript -e "pkgdown::check_pkgdown()"
rg -n 'non-Gaussian.*(parity|all routes|all random effects|now supports broad|fully supports)|NB2.*q1.*formal recovery.*(passed|complete)|NB2.*q1.*coverage.*(passed|complete)|zi.*random effects.*(fitted|implemented)|hu.*random effects.*(fitted|implemented)|mixed-response.*(fitted|implemented)|structured non-Gaussian.*(broad|parity|all)' README.md ROADMAP.md NEWS.md docs/design vignettes inst/sim tests -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "non-Gaussian evidence" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "NB2 formal" --limit 20 --json number,title,state,url,labels
git diff --check
```

## Tests Of The Tests

The new test reads the workflow file and fails if shard inputs drop out of the
workflow text. The existing Actions runner tests still validate formal shard
arguments and reject shard arguments for non-formal tasks.

## Consistency Audit

The stale scan found only boundary or historical guardrail wording. It did not
find a current claim that broad non-Gaussian parity, mixed-response families,
or inflation/hurdle random effects are fitted. The distribution-family tutorial
now states that the supported evidence goal is narrower than "everything
non-Gaussian."

## GitHub Issue Maintenance

The "NB2 formal" search found no direct open issue to update. The broader
"non-Gaussian evidence" search returned unrelated large-data, tutorial,
comparator, random-slope, relatedness, and visualization issues, so no issue
was mutated.

## What Did Not Go Smoothly

The concurrency problem appeared only when translating the sharded plan into a
real Actions dispatch. The workflow had shard inputs, but its concurrency group
was still task-level, which could replace pending shards during a rapid
multi-run dispatch.

## Team Learning

Grace should check Actions concurrency whenever a simulation plan shifts from
one workflow run to many manual shards. Curie should add a small workflow-text
test when operational queueing is part of the evidence contract.

## Known Limitations

The full NB2 q1 500-replicate formal evidence is not yet audited in this
commit. The shard-safe workflow must be pushed before the 16 formal shards are
dispatched. A promotion decision still requires downloading, merging, and
auditing all shard artifacts together.

## Next Actions

1. Push the branch and dispatch all 16 `nbinom2_phylo_q1_formal` shards with
   `n_reps = 500`, `cores = 10`, `backend = "multicore"`, and
   `profile_parameters = "log_sd_phylo"`.
2. Download the shard artifacts after completion.
3. Merge the artifacts and rerun the NB2 q1 formal QA and promotion helper.
