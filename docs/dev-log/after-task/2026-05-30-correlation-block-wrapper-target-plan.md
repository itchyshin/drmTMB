# After Task: Correlation-Block Wrapper Target Plan

## Goal

Add a small helper that reports the current Phase 18
correlation-block wrapper targets without running models, writing artifacts, or
dispatching GitHub Actions.

## Implemented

Added `phase18_correlation_block_wrapper_target_plan()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The helper reuses
`phase18_correlation_block_workflow_plan()`, keeps only rows where
`workflow_helper = "correlation_block_wrapper"`, and returns a status table for
the future wrapper slice. Current q=2 structured rows are labelled
`q2_interval_provenance_needed`; current q=4 rows are labelled
`q4_diagnostic_only`; every returned row carries
`dispatch_mode = "read_only_no_models_or_actions"`.

## Mathematical Contract

No likelihood, formula grammar, or parameterization changed. The helper only
reports registry status for residual and structured correlation-block rows. It
keeps residual `rho12`, q=2 `corpairs()`, and q=4 diagnostic rows separated by
the existing `interval_policy` values.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-correlation-block-wrapper-target-plan.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R
Rscript --vanilla -e "files <- c('inst/sim/run/sim_phase18_structured_workflow_registry.R', 'tests/testthat/test-phase18-structured-workflow-registry.R'); invisible(lapply(files, parse)); cat('ok parse\n')"
Rscript --vanilla -e "testthat::test_file('tests/testthat/test-phase18-structured-workflow-registry.R', reporter = 'summary')"
Rscript --vanilla -e 'e <- new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local = e); r <- e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv"); p <- e$phase18_correlation_block_wrapper_target_plan(r); print(p[, c("lane_id", "target_status", "interval_policy", "dispatch_mode")], row.names = FALSE)'
gh issue list --state open --limit 30 --search "phase18 correlation block wrapper"
git diff --check
```

All checks passed. No models were run and no Actions jobs were dispatched.

## Tests Of The Tests

The focused tests assert the three current wrapper-target rows, q=2 versus q=4
status labels, `include_diagnostic = FALSE`, and the empty-table shape expected
after a future slice wires all wrapper targets to existing tasks.

## Consistency Audit

The helper is internal to the Phase 18 simulation registry and does not change
exported API, formula grammar, likelihood parameterization, pkgdown navigation,
or family support. The direct helper call returned:

- `structured_gaussian_q2`: `q2_interval_provenance_needed`
- `bivariate_gaussian_group_q4`: `q4_diagnostic_only`
- `structured_gaussian_q4`: `q4_diagnostic_only`

## GitHub Issue Maintenance

`gh issue list --state open --limit 30 --search
"phase18 correlation block wrapper"` returned no open issues, so no issue was
opened or updated for this status helper.

## What Did Not Go Smoothly

The same implementation and test files also contained concurrent
family-surface status-table edits. I left those edits intact and kept this
patch scoped to the correlation-block target helper.

## Team Learning

Ada kept the implementation as a read-only view over the existing registry
plan. Curie added tests that cover the present target inventory and future
empty state. Fisher kept q=4 rows diagnostic-only. Rose checked that concurrent
same-file edits were not reverted or folded into this task.

## Known Limitations

The helper does not create a wrapper runner, model smoke, artifact writer,
interval method, or Actions task. q=4 derived intervals remain unavailable.

## Next Actions

Use this status helper to plan the future correlation-block wrapper slice:
first audit q=2 layer-specific interval provenance, then decide whether q=4
rows stay diagnostic-only or get a separately designed derived-interval method.
