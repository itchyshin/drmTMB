# After Task: Correlation-Block Status Actions Task

## Goal

Make the current Phase 18 correlation-block plan runnable as a manual,
read-only Actions status task. The task should write artifacts for the existing
registry state while keeping q=4 derived correlations out of interval-ready
claims.

## Implemented

Added `phase18_write_correlation_block_status_outputs()`. It writes four CSV
tables: the full correlation-block plan, the dispatched rows, the current
wrapper-target table, and the correlation-block registry summary. It also
returns the standard artifact manifest.

The Phase 18 Actions runner now accepts `correlation_block_status`, sources the
registry and writer helpers, and dispatches the writer. The manual workflow
matrix exposes the task with seed `20260608` and keeps it out of `task = "all"`.
The structured workflow registry now routes the structured q=2 and q=4
correlation-block rows to this status task instead of a future wrapper target.

The registry path helper now prefers the current checkout's
`inst/sim/registry/phase18_structured_workflow_registry.csv` before an installed
package copy when no explicit path is supplied. That keeps local Actions task
smokes from reading a stale installed registry.

## Mathematical Contract

No likelihood, formula grammar, parameter transform, model fit, profile method,
or extractor semantics changed. This is routing and status evidence only.
Residual `rho12`, q=2 direct or layer-specific correlation rows, q=4
diagnostic rows, and structured status rows stay separate.

q=4 derived correlations remain `q4_derived_interval_unavailable`. The task
does not add bootstrap intervals, profile intervals, structured `rho12`,
predictor-dependent q=4 `corpair()` regressions, or recovery/coverage/power
evidence.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `inst/sim/run/sim_write_correlation_block_status.R`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `tests/testthat/test-phase18-correlation-block-status.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/dev-log/after-task/2026-05-31-correlation-block-status-actions-task.md`

This reviewable extraction intentionally leaves mixed global status files
(`NEWS.md`, `ROADMAP.md`, `docs/design/46-pre-simulation-readiness-matrix.md`,
and `docs/dev-log/check-log.md`) unstaged for a later split.

## Checks Run

```sh
Rscript --vanilla -e "files <- c('inst/sim/run/sim_run_actions_cell.R','inst/sim/run/sim_phase18_structured_workflow_registry.R','inst/sim/run/sim_write_correlation_block_status.R','tests/testthat/test-phase18-correlation-block-status.R','tests/testthat/test-phase18-structured-workflow-registry.R','tests/testthat/test-phase18-actions-runner.R'); invisible(lapply(files, parse)); cat('correlation block status parse ok\n')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-correlation-block-status|phase18-structured-workflow-registry|phase18-actions-runner)$', reporter = 'summary')"
rm -rf /tmp/drmTMB-correlation-block-status-smoke && Rscript --vanilla inst/sim/run/sim_run_actions_cell.R --task=correlation_block_status --output-dir=/tmp/drmTMB-correlation-block-status-smoke --overwrite=true --dry-run=false
Rscript --vanilla -e "x <- read.csv('/tmp/drmTMB-correlation-block-status-smoke/tables/correlation-block-plan.csv'); print(x[, c('lane_id','admission_status','dispatch_status','actions_task','interval_policy')], row.names = FALSE); y <- read.csv('/tmp/drmTMB-correlation-block-status-smoke/tables/correlation-block-wrapper-targets.csv'); cat('wrapper rows:', nrow(y), '\n')"
git diff --check
```

All checks passed for this focused extraction. The local status artifact
reported six routed correlation-block rows and zero wrapper-target rows. The
q=4 rows still report `q4_derived_interval_unavailable`.

## Tests Of The Tests

The writer tests assert the artifact files, six-row plan, six-row dispatch
table, zero wrapper targets, registry-summary shape, overwrite guard, and input
validation. The Actions-runner tests cover dry-run acceptance, dependency path
lookup, and a stubbed real dispatch through `phase18_actions_main()`, so the
manual workflow route is not tested only as static YAML text.

## Consistency Audit

Boole audited the fitted-versus-planned capability rows. This extraction keeps
routing evidence separate from recovery or coverage evidence and does not
include mixed global status-file cleanup.

## GitHub Issue Maintenance

The overlapping open issues are #446, the Phase 6c random-slope simulation
power, accuracy, and coverage plan, and #436, the four-week Phase 6c sprint. I
left both open and did not comment because this task adds read-only routing and
status artifacts; it does not close simulation recovery, coverage, or sprint
scope.

## What Did Not Go Smoothly

The first local task smoke read the installed registry before the current
checkout registry, which made the new task look absent even though the local CSV
was updated. The registry path helper now prefers the current checkout when it
is available.

## Team Learning

Ada kept this as a status-routing slice. Boole pushed the fitted, planned, and
missing capability rows apart. Grace caught the need for direct runner tests.
Rose's durable rule for the next status helper is to keep fitted syntax,
artifact routing, and recovery or coverage evidence in separate columns.

## Known Limitations And Next Actions

This task does not make any new model surface fitted. It does not add q=4
intervals, structured `rho12`, structured slope correlations, residual-scale
structured slopes, or broad structured non-Gaussian recovery. The next useful
step is to use the status artifact as a gate before any q=2 layer-specific
profile evidence or q=4 derived-interval design work.
