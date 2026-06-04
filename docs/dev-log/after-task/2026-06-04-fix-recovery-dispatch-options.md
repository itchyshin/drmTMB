# After Task: Fix Undispatchable Recovery Lanes in the Workflow

## Problem

The six `*_recovery` Actions tasks added this session
(`biv_gaussian_mu_slope_recovery`, `biv_gaussian_q4_location_recovery`,
`biv_gaussian_q6_location_recovery`, `biv_gaussian_q2_scale_recovery`,
`poisson_mu_re_recovery`, `nbinom2_mu_re_recovery`) were wired into the runner
choices, the dispatcher, the registry, and the workflow **matrix**, but were
never added to the `workflow_dispatch` `task` choice **`options:`** list. Since
they are `include_in_all: false` and the job gates each matrix entry on
`inputs.task == matrix.task || (inputs.task == 'all' && include_in_all)`, the
recovery lanes were **not dispatchable by any route**. No test compared the
options list to the runner task choices, so this passed CI unnoticed.

## Fix

- Added the six recovery tasks to the `task` choice `options:` list in
  `.github/workflows/phase18-simulation-grid.yaml`.
- Added a regression test asserting the dispatch options (minus `all`) are
  set-equal to `phase18_actions_task_choices()`, following the established
  `skip_if_not(file.exists(workflow))` pattern.

## Validation

Run in base R against the edited workflow (no package deps): 30 options parsed,
all six recovery tasks present, options-minus-`all` set-equal to the runner
choices. Test file parses.

## Correction To Earlier Framing

This corrects a claim made earlier in the session that running the recovery
lanes (Phase B evidence) needs local R. It does not: the GitHub Actions runners
build the package and run R, so the recovery lanes can be dispatched and run
**in the cloud** via `workflow_dispatch` once this fix is merged. The local-R
requirement still holds for the TMB capability implementation (Phase A),
comparator fits, and CRAN checks.
