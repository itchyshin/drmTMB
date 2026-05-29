# After Task: Phase 18 Count Structured q1 Pilot Audit

## Goal

Audit the 24-cell x 10-replicate `count_structured_q1` diagnostic pilot before
deciding whether the lane can move toward formal recovery evidence.

## Implemented

GitHub Actions run `26631771105` dispatched `task=count_structured_q1` from
`main` at commit `12e0c789e9f74afb0fd8d104561571332d42e3c6`, with
`n_reps = 10`, `cores = 2`, `backend = multicore`,
`profile_parameters = ''`, one condition shard, and `render_report = false`.
The selected job succeeded in 3m51s, while the unselected matrix jobs skipped.

The downloaded artifact had 24 condition directories, 240 replicate RDS files,
240 `ok` manifest rows, 960 replicate parameter rows, 96 aggregate rows, 240
profile-target rows, 240 not-requested profile-interval rows, 960 Wald
interval rows, 72 Wald coverage rows, and one warning-ledger row.

The boundary-gate helper collapsed the replicate table to 240 fitted
replicates and returned `hold_diagnostic`. The overall SD-boundary warning rate
was 40/240 = 0.167, which fails the pre-declared 15% gate. Six condition cells
also failed the condition-level SD-boundary gate:
`count_structured_q1_002`, `count_structured_q1_005`,
`count_structured_q1_006`, `count_structured_q1_008`,
`count_structured_q1_010`, and `count_structured_q1_012`.

## Mathematical Contract

No likelihood, formula grammar, parameterization, or fitted model surface
changed. The audited model remains an ordinary non-zero-inflated Poisson or
NB2 count model with one q=1 structured `mu` intercept on the log-mean scale.

## Files Changed

- `docs/design/136-phase-18-count-structured-q1-pilot-audit-slices-1751-1752.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `inst/sim/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`
- `docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-pilot-audit.md`

## Checks Run

```sh
gh run watch 26631771105 --repo itchyshin/drmTMB --interval 30 --exit-status
gh run download 26631771105 --repo itchyshin/drmTMB --dir /tmp/drmTMB-phase18-count-structured-q1-pilot-26631771105
Rscript --vanilla -e 'devtools::load_all(quiet = TRUE); source("inst/sim/R/sim_registry.R"); source("inst/sim/R/sim_utils.R"); source("inst/sim/R/sim_runner.R"); source("inst/sim/R/sim_uncertainty.R"); source("inst/sim/fit/sim_summarise_count_structured_q1.R"); source("inst/sim/run/sim_write_count_structured_q1_grid.R"); root <- "/tmp/drmTMB-phase18-count-structured-q1-pilot-26631771105/phase18-count_structured_q1-shard-1-of-1-26631771105"; audit <- phase18_audit_count_structured_q1_boundary_gate(root, require_complete = TRUE); print(audit$boundary_gate$overall); print(audit$boundary_gate$conditions[audit$boundary_gate$conditions$fit_diagnostic_warning > 0 | audit$boundary_gate$conditions$sd_boundary_warning > 0 | audit$boundary_gate$conditions$hessian_warning > 0, c("cell_id", "family", "structured_type", "n_level", "sd_structured", "mean_count", "sigma_baseline", "n_fit", "fit_diagnostic_warning", "sd_boundary_warning", "hessian_warning")]); print(audit$boundary_gate$checks); print(audit$boundary_gate$decision)'
Rscript --vanilla -e 'root <- "/tmp/drmTMB-phase18-count-structured-q1-pilot-26631771105/phase18-count_structured_q1-shard-1-of-1-26631771105"; tables <- file.path(root, "tables"); safe_read <- function(name) tryCatch(utils::read.csv(file.path(tables, name), stringsAsFactors = FALSE), error = function(e) data.frame()); manifest <- safe_read("count-structured-q1-manifest.csv"); replicates <- safe_read("count-structured-q1-replicates.csv"); failures <- safe_read("count-structured-q1-failures.csv"); profile_targets <- safe_read("count-structured-q1-profile-targets.csv"); profile_intervals <- safe_read("count-structured-q1-profile-intervals.csv"); interval_evidence <- safe_read("count-structured-q1-interval-evidence.csv"); interval_diagnostics <- safe_read("count-structured-q1-interval-diagnostics.csv"); interval_failures <- safe_read("count-structured-q1-interval-failures.csv"); print(table(manifest$status, useNA = "ifany")); print(data.frame(parameter_rows = nrow(replicates), converged_true = sum(replicates$converged), pdHess_true = sum(replicates$pdHess), pdHess_false = sum(!replicates$pdHess), warning_rows = sum(replicates$warning_count > 0))); print(table(replicates$fit_diagnostic_status, useNA = "ifany")); print(table(replicates$hessian_status, useNA = "ifany")); print(table(replicates$sd_boundary_status, useNA = "ifany")); print(failures); print(table(profile_targets$profile_target_status, useNA = "ifany")); print(table(profile_intervals$profile.status, useNA = "ifany")); print(table(interval_evidence$interval_method, interval_evidence$interval_status, useNA = "ifany")); print(stats::aggregate(cbind(n_interval, n_ok, n_failed, n_not_requested, n_interval_unusable) ~ interval_method, interval_diagnostics, sum)); print(table(interval_failures$interval_method, interval_failures$interval_failure_status, useNA = "ifany")); result <- readRDS(file.path(root, "phase18-actions-result.rds")); print(result$surface); print(result$summary$run$parallel)'
gh issue list --repo itchyshin/drmTMB --state open --search 'count_structured_q1 diagnostic OR count structured q1 diagnostic OR count structured q1 boundary OR count structured q1 pilot' --limit 20 --json number,title,state,url,labels
```

Final validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

No package tests changed. The executable gate was tested against a real
GitHub Actions artifact and produced the pre-declared negative path:
`hold_diagnostic` from `sd_boundary_rate` and
`sd_boundary_condition_rate`.

## Consistency Audit

The roadmap, Phase 18 simulation programme, simulation README, check log, and
this after-task report now all state the same decision: the 10-replicate pilot
is diagnostic evidence and stops before formal recovery or coverage claims.

## GitHub Issue Maintenance

`gh issue list` found no overlapping open issue for the count structured q1
pilot or boundary diagnostics. I did not open a new issue because the ROADMAP,
design note, check log, and after-task report record the hold decision and the
next design action.

## What Did Not Go Smoothly

The first combined R audit printed the boundary-gate output, then exited when
a naive `read.csv()` row counter hit the 3-byte
`count-structured-q1-profile-coverage.csv` placeholder. The artifact summary
was rerun with a safe reader, and a team-improvement note now says placeholder
CSV files should be treated as zero-row artifacts during row-count audits.

## Team Learning

Ada kept the lane from advancing after the helper returned `hold_diagnostic`.
Curie checked that fitted replicates, not parameter rows, were the gate unit.
Fisher kept profile and recovery claims out because profile intervals were not
requested and the boundary gate failed. Grace verified the run, artifact, and
issue search. Rose recorded the hold decision and the row-counting failure
mode. No spawned subagents were running.

## Known Limitations

The pilot does not estimate structured-SD coverage, does not make recovery
claims, and does not support a formal grid dispatch. Low-`sd_structured`
boundary cells need a separate design decision before this lane can advance.

## Next Actions

Design a follow-up that separates low-`sd_structured` boundary-stress cells
from stable cells, or revises the condition table before another
recovery-oriented pilot is dispatched.
