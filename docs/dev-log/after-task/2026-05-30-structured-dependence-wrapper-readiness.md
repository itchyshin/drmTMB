# After Task: Structured-Dependence Wrapper Target Readiness

## Goal

Add a small, disjoint next-slice patch after Slice 1825 that summarizes
structured-dependence wrapper-target readiness without editing the workflow,
Actions runner, registry CSV, or Slice 1825 helper/test files.

## Implemented

Added `phase18_structured_dependence_wrapper_target_readiness()` in
`inst/sim/run/sim_phase18_structured_dependence_wrapper_readiness.R`.
The helper reads the existing structured-dependence workflow plan and returns
only rows whose `workflow_helper` is `structured_dependence_wrapper`.

The current table has four Gaussian wrapper targets: `phylo()`, `spatial()`,
`animal()`, and `relmat()` one-slope or intercept/slope rows. The spatial row
is labelled `grid_writer_available` because
`phase18_write_spatial_mu_slope_grid_outputs()` already exists. The other
three rows are labelled `source_test_ready` and keep their required artifacts
as `needed:*` values. Every returned row uses
`dispatch_mode = "wrapper_target_not_actions"` and has no `actions_task`.

## Mathematical Contract

This patch does not change any model, likelihood, formula grammar, covariance
parameterization, simulation DGP, or Actions dispatch path. It is a registry
status view only. The fitted structured-dependence claims remain those already
recorded in the existing registry and design notes.

## Files Changed

- `inst/sim/run/sim_phase18_structured_dependence_wrapper_readiness.R`
- `tests/testthat/test-phase18-structured-dependence-wrapper-readiness.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-structured-dependence-wrapper-readiness.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_dependence_wrapper_readiness.R tests/testthat/test-phase18-structured-dependence-wrapper-readiness.R
Rscript --vanilla -e "devtools::test(filter = '^phase18-structured-dependence-wrapper-readiness$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^phase18-(structured-workflow-registry|structured-dependence-wrapper-readiness)$', reporter = 'summary')"
gh issue list --repo itchyshin/drmTMB --state open --search "structured dependence wrapper target readiness" --limit 20
```

Results:

- `air format` completed on the new helper and test files.
- The focused wrapper-readiness test passed.
- The adjacent registry plus wrapper-readiness test filters passed together.
- `gh issue list --repo itchyshin/drmTMB --state open --search
  "structured dependence wrapper target readiness" --limit 20` returned no
  open issues.

## Tests Of The Tests

The new tests check the four current Gaussian wrapper targets, verify that
spatial is the only row with a concrete artifact writer, require source-test
evidence for the other rows, and add a fail-closed check for an unknown future
wrapper target.

## Consistency Audit

The helper reads the existing registry plan and returns a status table. It does
not edit `.github/workflows/phase18-simulation-grid.yaml`,
`inst/sim/run/sim_run_actions_cell.R`,
`inst/sim/registry/phase18_structured_workflow_registry.csv`, or the Slice
1825 registry helper/test files.

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search "structured dependence wrapper target readiness" --limit 20`
returned no open issue to update.

## What Did Not Go Smoothly

The first focused test used `expect_gt(..., info = ...)`, but the local
testthat version does not support `info` on that expectation. I switched the
locator checks to the existing `expect_true(..., info = ...)` style and the
test passed.

Concurrent edits appeared in `ROADMAP.md`,
`docs/design/143-phase-18-structured-workflow-registry.md`,
`docs/design/41-phase-18-simulation-programme.md`,
`docs/dev-log/check-log.md`,
`inst/sim/run/sim_phase18_structured_workflow_registry.R`, and
`tests/testthat/test-phase18-structured-workflow-registry.R` while this patch
was being prepared. I treated those as other-agent edits, did not revert them,
and kept this slice in new helper/test files plus an appended check-log entry.

## Team Learning

When a wrapper-target lane is already in flux, a separate read-only readiness
helper lets Ada and Grace see what is still local-only without touching the
registry plumbing or manual Actions runner.

## Known Limitations

This helper does not add the missing phylo, animal, or relmat artifact writers.
It does not promote source-test readiness to recovery, coverage, or Actions
readiness.

## Next Actions

Use the readiness table to choose one structured-dependence wrapper target at a
time. The smallest next implementation target is likely the missing
phylogenetic Gaussian `mu` one-slope artifact writer, because it has focused
source tests but no dedicated Phase 18 artifact row yet.
