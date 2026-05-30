# After Task: Family-Surface Registry Status Tables

## Goal

Add a small helper for future family-surface report slices. The
helper should summarize the existing registry without running models,
dispatching GitHub Actions jobs, or implying coverage or recovery evidence.

## Implemented

Added `phase18_family_surface_status_tables()` in
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. It consumes the
existing family-surface workflow plan and returns three tables:

- `row_summary`: one row per family-surface registry row, with lane,
  distribution route, distributional parameters, status, dispatch state, next
  action, supervision boundary, and `status_scope = "registry_status_only"`.
- `category_summary`: counts by admission category, admission status, and
  dispatch status.
- `distribution_summary`: counts by family group, family route, admission
  category, and admission status.

`include_blocked = FALSE` passes through to the existing plan helper so future
report slices can either show the failure-ledger rows or limit the table to
dispatchable/readiness rows.

## Mathematical Contract

No likelihood, formula grammar, family implementation, simulation design,
model run, GitHub Actions dispatch, recovery claim, or coverage claim changed.
This slice only summarizes registry rows that already existed.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-family-surface-status-tables.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-family-surface-status-tables.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
git diff --check
```

The focused registry test passed, and `git diff --check` was clean.

## Tests Of The Tests

The focused tests require the live family-surface status tables to preserve the
eleven registry rows, six admitted rows, one smoke-only row, three blocked
rows, and one design-only row. They also check that category and distribution
counts sum back to the row summary, that count and ordinal distribution rows
remain visible, and that `include_blocked = FALSE` removes blocked and
design-only rows.

## Consistency Audit

The helper calls `phase18_family_surface_workflow_plan()` instead of
reclassifying status from scratch. The added `status_scope` column is
deliberately narrow: it marks registry status only, not fitted support,
recovery, interval coverage, or simulation readiness.

## GitHub Issue Maintenance

No issue was opened or updated for this status helper. The helper summarizes
the existing Phase 18 registry state and does not introduce a new family,
model route, Actions task, or user-facing API that needs a separate issue.

## What Did Not Go Smoothly

While checking the diff, concurrent correlation-block wrapper target edits
appeared in the same implementation and test files. I left those changes intact
and kept this after-task report scoped to the family-surface status-table
helper.

## Team Learning

Ada gets a compact future-reporting surface that stays tied to the registry.
Curie has focused tests around table shape and blocked-row filtering. Fisher
and Rose get an explicit status-scope marker that keeps reporting language from
drifting into unsupported evidence claims.

## Known Limitations

The helper is a registry summarizer only. It does not render a report, write a
CSV, promote any family-surface row, or validate model behavior.

## Next Actions

Use the status tables as input for a later family-surface report or dashboard
slice. Any future promotion from registry status to model evidence must add the
appropriate DGP, smoke/grid writer, tests, and artifact audit for the specific
family route.
