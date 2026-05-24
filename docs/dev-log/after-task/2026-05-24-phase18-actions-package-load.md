# After Task: Phase 18 Actions Package Load

## Goal

Recover the NB2 phylogenetic q1 formal shard dispatch after all 16 manual
`main` runs from merged PR #322 failed before uploading artifacts.

## Implemented

- Added an explicit installed-package load to the Phase 18 Actions runner before
  non-dry-run tasks source and execute simulation helpers.
- Left dry-run parsing unchanged so subprocess dry-runs remain lightweight.
- Added a focused runner test that checks the package load happens before
  helper sourcing.

## Files Changed

- `inst/sim/run/sim_run_actions_cell.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-24-phase18-actions-package-load.md`

## Checks Run

```sh
gh run list --repo itchyshin/drmTMB --branch main --limit 40 --json databaseId,workflowName,displayTitle,event,status,conclusion,createdAt,updatedAt,headSha,url
gh run view 26372989242 --repo itchyshin/drmTMB --log-failed
Rscript --vanilla inst/sim/run/sim_run_actions_cell.R --task=nbinom2_phylo_q1_formal --output-dir=/tmp/drmTMB-nb2-repro-shard1 --n-reps=1 --cores=1 --backend=none --master-seed=20260602 --overwrite=true --render=false --require-complete=false --profile-parameters=log_sd_phylo --condition-shard=1 --condition-shards=16 --bootstrap-nsim=0 --bootstrap-cores=1 --bootstrap-backend=none
Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); source("inst/sim/run/sim_run_actions_cell.R"); phase18_actions_main(c("--task=nbinom2_phylo_q1_formal", "--output-dir=/tmp/drmTMB-nb2-repro-patched-onecell", "--n-reps=1", "--cores=1", "--backend=none", "--master-seed=20260602", "--overwrite=true", "--render=false", "--require-complete=false", "--profile-parameters=log_sd_phylo", "--condition-shard=1", "--condition-shards=288", "--bootstrap-nsim=0", "--bootstrap-cores=1", "--bootstrap-backend=none"))'
Rscript --vanilla -e "files <- c('inst/sim/run/sim_run_actions_cell.R', 'tests/testthat/test-phase18-actions-runner.R'); invisible(lapply(files, parse)); cat('parse ok\n')"
air format inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-actions-runner.R
Rscript --vanilla -e "devtools::test(filter = 'phase18-actions-runner', reporter = 'summary')"
Rscript --vanilla inst/sim/run/sim_run_actions_cell.R --task=nbinom2_phylo_q1_formal --dry-run=true --n-reps=500 --cores=10 --backend=multicore --profile-parameters=log_sd_phylo --condition-shard=16 --condition-shards=16
git diff --check
```

## Outcomes

The 16 remote shard runs were dispatch failures, not evidence failures. Run
`26372989242` reached the selected NB2 q1 formal job and stopped with `The NB2
phylogenetic q1 smoke run produced no summaries.` A clean detached worktree at
merge commit `3e68109d` reproduced the failure with `n_reps = 1`; the saved
replicate RDS files contained `there is no package called 'drmTMB'`.

The patched one-condition control run under `devtools::load_all()` wrote a
formal-grid result with one condition, six replicate rows, and
`manifest_status = ok`. The focused `phase18-actions-runner` tests passed with
24 assertions.

## Consistency Audit

No formula grammar, likelihood parameterization, family support, or promotion
status changed. The NB2 q1 phylogenetic route remains `hold_smoke_only` until
all fixed shard artifacts are downloaded, merged, and audited together.

## Tests Of The Tests

The new test reads the runner script and checks that
`phase18_actions_load_package()` appears before
`phase18_actions_source_dependencies(task)`. Existing dry-run tests still
exercise argument parsing, core capping, formal shard validation, shard-aware
workflow concurrency, and nested-parallel rejection.

## What Did Not Go Smoothly

The GitHub log showed only the aggregate no-summary stop. The saved local
replicate RDS files were needed to reveal that the standalone runner lacked a
package attachment before executing helper code.

## Team Learning

Grace should treat a simulation runner as a standalone executable, not as if it
inherits the testthat package namespace. Curie should keep one test around the
runner boundary whenever Actions dispatch is part of the validation evidence.

## GitHub Issue Maintenance

No issue was updated. This was a direct follow-up to merged PR #322 and the
failed manual shard dispatches, so the immediate next public artifact should be
the small fix PR and then a fresh 16-shard dispatch.

## Known Limitations And Next Actions

This fix only restores the runner boundary. It does not itself provide NB2 q1
formal recovery evidence. After this PR merges, rerun the 16
`nbinom2_phylo_q1_formal` shards from `main`, then download, merge, and audit
all shard artifacts before changing any support claim.
