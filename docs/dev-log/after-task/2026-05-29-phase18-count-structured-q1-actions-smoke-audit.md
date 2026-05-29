# After Task: Phase 18 Count Structured q1 Manual Actions Smoke Audit

Date: 2026-05-29

## Goal

Audit the first manual GitHub Actions `count_structured_q1` smoke artifact run
after PR #368 merged the manual task.

## Actions Run

- URL: `https://github.com/itchyshin/drmTMB/actions/runs/26622840562`
- Task: `count_structured_q1`
- Inputs: `n_reps = 2`, `cores = 2`, `backend = "multicore"`,
  `bootstrap_nsim = 0`, `profile_parameters = ""`,
  `render_report = false`, `condition_shard = 1`, `condition_shards = 1`.
- Result: success. The unselected matrix rows skipped cleanly, and the selected
  `count_structured_q1` row ran checkout, setup, task, summary, and artifact
  upload.

## Artifact Audit

The downloaded artifact
`phase18-count_structured_q1-shard-1-of-1-26622840562` contained:

- `phase18-actions-result.rds`;
- 48 replicate RDS files across 24 condition cells;
- `count-structured-q1-aggregate.csv` with 96 rows;
- `count-structured-q1-replicates.csv` with 192 parameter rows;
- `count-structured-q1-manifest.csv` with 48 rows;
- `count-structured-q1-failures.csv` with 1 warning row;
- `count-structured-q1-wald-intervals.csv` with 192 rows;
- `count-structured-q1-wald-coverage.csv` with 72 rows;
- `count-structured-q1-profile-targets.csv` with 48 rows;
- `count-structured-q1-profile-intervals.csv` with 48 rows;
- `count-structured-q1-profile-coverage.csv` with 0 rows;
- `count-structured-q1-interval-evidence.csv` with 240 rows;
- `count-structured-q1-interval-diagnostics.csv` with 120 rows; and
- `count-structured-q1-interval-failures.csv` with 96 diagnostic rows.

All 48 manifest rows had status `ok`; no replicate was skipped. All 192
parameter rows had `converged = TRUE`. A single NB2 spatial replicate,
`count_structured_q1_020` replicate 2, emitted warning `NaNs produced` and had
`pdHess = FALSE`; this appears as 5 parameter rows with `pdHess = FALSE` and
one warning-ledger row. The other 187 parameter rows had `pdHess = TRUE`.

All 48 structured-SD profile-target rows were `ready`. Profile intervals were
`not_requested` because the workflow input left `profile_parameters` empty. The
Wald interval evidence had 144 `ok` fixed-effect rows and 48 failed
structured-SD rows with missing or invalid standard errors, matching the
intended split between Wald fixed-effect intervals and direct profile targets
for structured SDs.

The result object reported `surface = "count_structured_q1_grid"` with
`backend = "multicore"`, `requested_cores = 2`, and `cores = 2`.

## Boundary

This audit confirms that the manual workflow route can run and upload the
smoke artifact. It does not add a model feature, include the task in
`task = "all"`, add condition sharding, promote formal recovery or coverage,
or expand support to zero-inflated structure, structured count slopes,
labelled q=2/q=4 count covariance, simultaneous structured count types, or
structured NB2 `sigma`.

## Validation

```sh
gh workflow run phase18-simulation-grid.yaml --repo itchyshin/drmTMB --ref main -f task=count_structured_q1 -f n_reps=2 -f cores=2 -f backend=multicore -f bootstrap_nsim=0 -f bootstrap_cores=2 -f bootstrap_backend=none -f profile_parameters='' -f profile_level=0.70 -f condition_shard=1 -f condition_shards=1 -f render_report=false -f require_complete=false -f retention_days=14 -f notes='manual count structured q1 smoke audit after PR #368'
sed -n '1,95p' .github/workflows/phase18-simulation-grid.yaml
gh workflow run phase18-simulation-grid.yaml --repo itchyshin/drmTMB --ref main -f task=count_structured_q1 -f n_reps=2 -f cores=2 -f backend=multicore -f bootstrap_nsim=0 -f bootstrap_cores=2 -f bootstrap_backend=none -f profile_parameters='' -f condition_shard=1 -f condition_shards=1 -f render_report=false -f retention_days=14
gh run watch 26622840562 --repo itchyshin/drmTMB --interval 30 --exit-status
gh run view 26622840562 --repo itchyshin/drmTMB --json conclusion,status,url,createdAt,updatedAt,jobs
gh run download 26622840562 --repo itchyshin/drmTMB --dir /tmp/drmTMB-phase18-count-structured-q1-actions-26622840562
find /tmp/drmTMB-phase18-count-structured-q1-actions-26622840562 -maxdepth 4 -type f | sort
Rscript --vanilla -e 'root <- "/tmp/drmTMB-phase18-count-structured-q1-actions-26622840562/phase18-count_structured_q1-shard-1-of-1-26622840562"; tables <- file.path(root, "tables"); safe_read <- function(name) tryCatch(utils::read.csv(file.path(tables, name), stringsAsFactors = FALSE), error = function(e) data.frame()); csvs <- sort(list.files(tables, pattern = "[.]csv$", full.names = TRUE)); row_count <- function(p) tryCatch(nrow(utils::read.csv(p, stringsAsFactors = FALSE)), error = function(e) 0L); print(data.frame(file = basename(csvs), bytes = as.integer(file.info(csvs)$size), rows = vapply(csvs, row_count, integer(1)), row.names = NULL)); manifest <- safe_read("count-structured-q1-manifest.csv"); replicates <- safe_read("count-structured-q1-replicates.csv"); failures <- safe_read("count-structured-q1-failures.csv"); profile_targets <- safe_read("count-structured-q1-profile-targets.csv"); profile_intervals <- safe_read("count-structured-q1-profile-intervals.csv"); profile_coverage <- safe_read("count-structured-q1-profile-coverage.csv"); interval_evidence <- safe_read("count-structured-q1-interval-evidence.csv"); interval_diagnostics <- safe_read("count-structured-q1-interval-diagnostics.csv"); interval_failures <- safe_read("count-structured-q1-interval-failures.csv"); print(table(manifest$status, useNA = "ifany")); print(data.frame(parameter_rows = nrow(replicates), converged_true = sum(replicates$converged), pdHess_true = sum(replicates$pdHess), pdHess_false = sum(!replicates$pdHess), warning_rows = sum(replicates$warning_count > 0))); print(unique(replicates[replicates$warning_count > 0 | !replicates$pdHess, c("cell_id", "replicate", "family", "structured_type", "n_level", "converged", "pdHess", "warning_count", "warnings")])); print(failures); print(table(profile_targets$profile_target_status, useNA = "ifany")); print(table(profile_intervals$profile.status, useNA = "ifany")); print(nrow(profile_coverage)); print(table(interval_evidence$interval_method, interval_evidence$interval_status, useNA = "ifany")); print(stats::aggregate(cbind(n_interval, n_ok, n_failed, n_not_requested, n_interval_unusable) ~ interval_method, interval_diagnostics, sum)); print(table(interval_failures$interval_method, interval_failures$interval_failure_status, useNA = "ifany")); result <- readRDS(file.path(root, "phase18-actions-result.rds")); print(result$surface); print(result$summary$run$parallel)'
gh issue list --repo itchyshin/drmTMB --state open --search 'count structured q1 smoke audit' --limit 20
air format ROADMAP.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/41-phase-18-simulation-programme.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-actions-smoke-audit.md docs/dev-log/team-improvements.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|count structured q1.*all clean|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
```

The first dispatch command failed with HTTP 422 because `notes`,
`profile_level`, and `require_complete` are runner arguments, not
workflow-dispatch inputs. The corrected dispatch completed successfully. The
issue search returned no open matching issue to update.
`pkgdown::check_pkgdown()` reported no problems. The stale-claim scan returned
the intended NEWS boundary wording and the standing formula-grammar limitation
row, not a claim that the audit was all clean, formal recovery, coverage,
zero-inflated support, structured slopes, or `task = "all"` inclusion.
`git diff --check` was clean.

## Tests Of The Tests

This audit did not add new tests. It tested the operational path by running the
merged workflow on `main`, verifying that unselected matrix rows skipped, and
checking the downloaded artifact rather than relying on the green workflow
status alone.

## Consistency Audit

`ROADMAP.md`, the count structured q=1 design note, the Phase 18 programme,
this check log, and this after-task report now describe the audit as
operational smoke evidence. The wording names the warning and `pdHess = FALSE`
replicate and keeps formal recovery, coverage, `task = "all"` inclusion, and
neighbouring structured count features out of scope.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search 'count structured q1 smoke audit' --limit 20`
returned no open issue to update.

## What Did Not Go Smoothly

The first dispatch attempt used runner options that are not exposed as workflow
inputs. Grace corrected this by reading the workflow input block before
redispatching.

The smoke run was operationally successful but not statistically clean: one
NB2 spatial replicate had warning `NaNs produced` and `pdHess = FALSE`.

## Team Learning

Grace should check `.github/workflows/phase18-simulation-grid.yaml` before
manual dispatches and use only `workflow_dispatch` inputs, not every argument
accepted by `sim_run_actions_cell.R`. Curie and Fisher should treat a green
workflow plus a warning-ledger row as a useful smoke audit, not as a recovery
claim.

## Known Limitations

The audit uses two replicates per cell. It cannot estimate operating
characteristics, final coverage, or recovery. It did not request profile
intervals, did not render a report, and did not diagnose whether the
`count_structured_q1_020` warning is ordinary smoke-run instability or a
condition-specific issue.

## Next Actions

Inspect the NB2 spatial `n_level = 16` warning replicate before any larger
count structured q=1 grid. A separate slice should decide whether to add a
read-back QA helper, a targeted warning diagnostic, or a bounded larger
replication run; do not combine those decisions in one PR.
