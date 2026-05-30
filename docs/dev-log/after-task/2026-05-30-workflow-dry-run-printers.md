# After Task: Workflow Dry-Run Printers

## Goal

Add read-only dry-run printers for the structured workflow bundle so the
current random-slope, structured-dependence, correlation-block, and
family-surface workflow status can be printed from live registry-derived
objects.

## Implemented

Added `phase18_format_structured_workflow_bundle_dry_run()` and
`phase18_print_structured_workflow_bundle_dry_run()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The bundle printer
renders the plan count table and one table per workflow plan. Added matching
single-plan helpers,
`phase18_format_structured_workflow_plan_dry_run()` and
`phase18_print_structured_workflow_plan_dry_run()`.

## Mathematical Contract

No likelihood, parser, formula grammar, family support, interval target, or
simulation result changed. The dry-run helpers only print existing plan state.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-workflow-dry-run-printers.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-workflow-dry-run-printers.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e 'e<-new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local=e); b<-e$phase18_structured_workflow_plan_bundle(e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv")); e$phase18_print_structured_workflow_bundle_dry_run(b)'
rg -n "dry-run printer|phase18_format_structured_workflow_bundle_dry_run|phase18_print_structured_workflow_bundle_dry_run|phase18_format_structured_workflow_plan_dry_run|phase18_print_structured_workflow_plan_dry_run|Slice 1821" inst/sim/run tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-workflow-dry-run-printers.md
git diff --check
```

The focused tests passed, the live dry-run print showed the bundle count table
and all four plan sections, the reference scan found the intended Slice 1821
entries, and `git diff --check` passed.

## Tests Of The Tests

The new tests check that the bundle dry-run text includes the no-dispatch
header, the workflow plan names, a wrapper target row, and a blocked-design
row. The single-plan test captures console output and checks the plan header,
wrapper target status, and `phase18_actions_main` rows.

## Consistency Audit

The dry-run bundle formatter consumes the same object returned by
`phase18_structured_workflow_plan_bundle()`. It does not re-read or reinterpret
the registry independently.

## What Did Not Go Smoothly

The first table output used base R's default console width and wrapped wide
tables into column blocks. The formatter now temporarily widens the local
print width while preserving the caller's option afterward.

## Team Learning

Ada gets a live status view for choosing the next slice. Grace can inspect
which rows would dispatch through existing Actions tasks versus wrapper
targets before any job is launched. Rose gets blocked and design-only rows in
the same printout as admitted rows, reducing the chance of accidental
promotion.

## Known Limitations

The dry-run output is a plain text table, not a rendered report, GitHub
Actions dispatcher, artifact downloader, or pkgdown page.

## Next Actions

1. Add wrapper targets for random slopes, structured dependence, and
   correlation blocks.
2. Use the dry-run printer in future status reports before dispatching pilots.
3. Add a small command-line entry point only if repeated manual sourcing
   becomes cumbersome.
