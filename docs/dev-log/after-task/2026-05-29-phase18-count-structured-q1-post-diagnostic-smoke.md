# After Task: Phase 18 Count Structured q1 Post-Diagnostic Smoke Audit

Date: 2026-05-29

## Goal

Run the manual `count_structured_q1` smoke task after PR #370 merged the
fit-level diagnostic columns, then verify that the GitHub Actions artifact
records the new boundary and Hessian status columns.

## Implemented

GitHub Actions run `26626333581` completed on `main` with
`task = count_structured_q1`, `n_reps = 2`, `cores = 2`,
`backend = "multicore"`, `profile_parameters = ""`, and
`render_report = false`. The selected `count_structured_q1` job succeeded in
3m33s. All unselected matrix jobs skipped.

The downloaded artifact
`phase18-count_structured_q1-shard-1-of-1-26626333581` contained 48 replicate
RDS files and the expected 12 table CSVs. The replicate table included
`fit_diagnostic_status`, `fit_diagnostic_message`, `hessian_status`,
`hessian_message`, `sd_boundary_status`, and `sd_boundary_message`.

## Artifact Findings

All 48 manifest rows had status `ok`; no replicate was skipped. All 192
parameter rows had `converged = TRUE`. The original warning case,
`count_structured_q1_020` replicate 2, remained the only failure-ledger row:
it emitted `NaNs produced`, had `pdHess = FALSE`, and carried
`hessian_status = "warning"` plus `sd_boundary_status = "warning"` across its
five parameter rows.

The new diagnostic columns exposed additional boundary cases that were not
warning-ledger rows:

```text
fit_diagnostic_status: 169 ok, 23 warning
hessian_status:        187 ok, 5 warning
sd_boundary_status:    169 ok, 23 warning
```

The 23 boundary-warning parameter rows collapse to five replicate fits:
`count_structured_q1_007` replicate 2, `count_structured_q1_008` replicate 2,
`count_structured_q1_010` replicate 2, `count_structured_q1_012` replicate 1,
and `count_structured_q1_020` replicate 2. Only the last of those had a Hessian
warning and an R warning.

## Mathematical Contract

No model, likelihood, formula grammar, or interval target changed. The smoke
task still audits ordinary Poisson/NB2 q=1 structured `mu` intercept fits for
`spatial()`, `animal()`, and `relmat()`.

## Files Changed

- `ROADMAP.md`
- `docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-post-diagnostic-smoke.md`

## Checks Run

```sh
gh workflow run phase18-simulation-grid.yaml --repo itchyshin/drmTMB --ref main -f task=count_structured_q1 -f n_reps=2 -f cores=2 -f backend=multicore -f bootstrap_nsim=0 -f bootstrap_cores=2 -f bootstrap_backend=none -f profile_parameters='' -f condition_shard=1 -f condition_shards=1 -f render_report=false -f retention_days=14
gh run watch 26626333581 --repo itchyshin/drmTMB --interval 30 --exit-status
gh run download 26626333581 --repo itchyshin/drmTMB --dir /tmp/drmTMB-phase18-count-structured-q1-diagnostic-smoke-26626333581
find /tmp/drmTMB-phase18-count-structured-q1-diagnostic-smoke-26626333581 -maxdepth 4 -type f | sort
Rscript --vanilla -e 'root <- "/tmp/drmTMB-phase18-count-structured-q1-diagnostic-smoke-26626333581/phase18-count_structured_q1-shard-1-of-1-26626333581"; tables <- file.path(root, "tables"); safe_read <- function(name) tryCatch(utils::read.csv(file.path(tables, name), stringsAsFactors = FALSE), error = function(e) data.frame()); csvs <- sort(list.files(tables, pattern = "[.]csv$", full.names = TRUE)); row_count <- function(p) tryCatch(nrow(utils::read.csv(p, stringsAsFactors = FALSE)), error = function(e) 0L); print(data.frame(file = basename(csvs), bytes = as.integer(file.info(csvs)$size), rows = vapply(csvs, row_count, integer(1)), row.names = NULL)); manifest <- safe_read("count-structured-q1-manifest.csv"); replicates <- safe_read("count-structured-q1-replicates.csv"); failures <- safe_read("count-structured-q1-failures.csv"); profile_targets <- safe_read("count-structured-q1-profile-targets.csv"); profile_intervals <- safe_read("count-structured-q1-profile-intervals.csv"); profile_coverage <- safe_read("count-structured-q1-profile-coverage.csv"); interval_evidence <- safe_read("count-structured-q1-interval-evidence.csv"); interval_diagnostics <- safe_read("count-structured-q1-interval-diagnostics.csv"); interval_failures <- safe_read("count-structured-q1-interval-failures.csv"); print(table(manifest$status, useNA = "ifany")); print(data.frame(parameter_rows = nrow(replicates), converged_true = sum(replicates$converged), pdHess_true = sum(replicates$pdHess), pdHess_false = sum(!replicates$pdHess), warning_rows = sum(replicates$warning_count > 0))); print(setdiff(c("fit_diagnostic_status", "fit_diagnostic_message", "hessian_status", "hessian_message", "sd_boundary_status", "sd_boundary_message"), names(replicates))); print(table(replicates$fit_diagnostic_status, useNA = "ifany")); print(table(replicates$hessian_status, useNA = "ifany")); print(table(replicates$sd_boundary_status, useNA = "ifany")); print(unique(replicates[replicates$warning_count > 0 | !replicates$pdHess | replicates$fit_diagnostic_status != "ok", c("cell_id", "replicate", "family", "structured_type", "n_level", "converged", "pdHess", "warning_count", "warnings", "fit_diagnostic_status", "hessian_status", "sd_boundary_status", "sd_boundary_message")])); print(failures); print(table(profile_targets$profile_target_status, useNA = "ifany")); print(table(profile_intervals$profile.status, useNA = "ifany")); print(nrow(profile_coverage)); print(table(interval_evidence$interval_method, interval_evidence$interval_status, useNA = "ifany")); print(stats::aggregate(cbind(n_interval, n_ok, n_failed, n_not_requested, n_interval_unusable) ~ interval_method, interval_diagnostics, sum)); print(table(interval_failures$interval_method, interval_failures$interval_failure_status, useNA = "ifany")); result <- readRDS(file.path(root, "phase18-actions-result.rds")); print(result$surface); print(result$summary$run$parallel)'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
gh issue list --repo itchyshin/drmTMB --state open --search 'count_structured_q1 boundary OR count structured q1 boundary OR count structured q1 diagnostic' --limit 20 --json number,title,state,url,labels
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|count structured q1.*all clean|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
```

`pkgdown::check_pkgdown()` reported no problems. The open-issue search returned
no matching open issues. The stale-claim scan returned only the intended NEWS
boundary wording and standing formula-grammar planned-neighbour row.
`git diff --check` was clean.

## Tests Of The Tests

This was an operational artifact audit rather than a code-test slice. The test
of the diagnostic hardening is the downloaded Actions artifact: it proves that
the merged `main` branch writes the new diagnostic columns and that those
columns reveal boundary-sensitive replicates beyond the warning ledger.

## Consistency Audit

`ROADMAP.md`, the count structured q=1 design note, this check log, and this
after-task report now agree that the post-diagnostic smoke is operational
evidence. They keep recovery, coverage, zero-inflated structure, structured
count slopes, and `task = "all"` inclusion out of scope.

## GitHub Issue Maintenance

No GitHub issue was opened during this audit. The previous diagnostic slice
searched for overlapping count structured q1 warning issues and found none.

## What Did Not Go Smoothly

The diagnostic columns did their job: they showed that a green manifest and a
single warning-ledger row understate the boundary behaviour. Five replicate
fits touched the random-effect-SD boundary in this two-replicate smoke run.

## Team Learning

Curie and Fisher should review boundary rates at the replicate-fit level, not
only warning-ledger rows. Grace should keep the manual task out of
`task = "all"` until the team has an explicit acceptance threshold for
`sd_boundary_status = "warning"` and `hessian_status != "ok"`.

## Known Limitations

This run used only two replicates per cell. It is not a recovery,
coverage, or operating-characteristic estimate.

## Next Actions

Before a larger count structured q=1 pilot, choose an explicit boundary-rate
review rule and decide whether low-count/high-structured-SD cells should remain
in the ordinary smoke grid or move to a diagnostic stress lane.
