# After-Task Report: Q8 Optimizer-Budget Pilot

## Task

Run the next q8 usability gate as a paired high-sample optimizer-budget audit,
keeping q8 status sample-size conditional and avoiding a binary "works" or
"does not work" conclusion.

## Implementation

- Added optimizer metadata to
  `inst/sim/run/sim_run_biv_gaussian_q8_usability_pilot.R`, including
  `optimizer_label`, `eval_max`, and `iter_max` columns in fit-summary,
  profile-target, failure, and start-mapping rows.
- Added `phase18_biv_gaussian_q8_optimizer_budgets()` and
  `phase18_run_biv_gaussian_q8_optimizer_budget_pilot()` so the high
  sample-size q8 row can be rerun under named `nlminb()` budgets.
- Added focused tests that pin the optimizer-budget metadata contract without
  fitting another q8 model.

## Evidence

The pilot wrote
`docs/dev-log/simulation-artifacts/2026-06-09-q8-optimizer-budget-pilot/`.
It reran `q8_size_003` with 96 groups x 12 repeats, seed `20260687`, `se =
TRUE`, cold / q4 SD-staged / q4 theta-staged starts, and 800 versus 1600
evaluations/iterations.

The result is diagnostic. Cold and q4 SD-staged fits reported `pdHess = TRUE`
under both budgets but still returned optimizer convergence code 1. The printed
q8 correlation diagnostics did not change with the larger budget: cold q8 had
minimum eigenvalue 2.05e-6 and condition number 1.27e6, while SD-staged q8 had
minimum eigenvalue 4.26e-6 and condition number 6.11e5. Q4 theta-staged q8
reported `pdHess = FALSE` under both budgets and one `NaNs produced` warning.

This confirms the sample-size lesson without promoting q8: high replication
can improve Hessian and conditioning behaviour, but increasing the single
`nlminb()` budget from 800 to 1600 did not turn this high sample-size row into
optimizer convergence code 0.

## Status Sync

Updated README, NEWS, ROADMAP, the capability worklist, the pre-simulation
readiness matrix, the q8 Hessian/start-rescue note, the q8 start-hook preflight
note, the simulation README, and known limitations. These files now say that
q8 remains fitted and diagnostic-artifact ready, with sample-size-dependent
usability evidence, but not coverage-ready, power-ready, or
derived-correlation-interval ready.

## Checks

```sh
/usr/local/bin/Rscript --vanilla -e 'devtools::test(filter = "phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
/usr/local/bin/Rscript --vanilla -e 'styler::style_file(c("inst/sim/run/sim_run_biv_gaussian_q8_usability_pilot.R", "tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R"))'
/usr/local/bin/Rscript --vanilla -e 'phase18_run_biv_gaussian_q8_optimizer_budget_pilot(...)'
rg -n "larger-sample, larger[- ]optimizer|larger optimizer-budget|optimizer-budget audit passes|needs optimizer-budget follow-up|next q8 gate is a larger|larger optimizer budget paired audit" README.md NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md inst/sim/README.md --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**'
git diff --check -- inst/sim/run/sim_run_biv_gaussian_q8_usability_pilot.R tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R README.md NEWS.md ROADMAP.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/design/163-phase-18-q8-hessian-start-rescue.md docs/design/165-phase-18-q8-start-hook-preflight.md docs/dev-log/known-limitations.md inst/sim/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-09-q8-optimizer-budget-pilot.md docs/dev-log/simulation-artifacts/2026-06-09-q8-optimizer-budget-pilot/fit-summary.csv docs/dev-log/simulation-artifacts/2026-06-09-q8-optimizer-budget-pilot/profile-targets.csv docs/dev-log/simulation-artifacts/2026-06-09-q8-optimizer-budget-pilot/start-mapping.csv docs/dev-log/simulation-artifacts/2026-06-09-q8-optimizer-budget-pilot/manifest.csv
```

The focused q8 endpoint test suite passed after documentation closeout. The
stale-wording scan returned no rows outside historical logs and after-task
reports, and `git diff --check` was clean for the touched files and new
artifacts.

## Follow-Up

Do not spend more q8 time on `nlminb()` budget alone for this high-replication
row. The next q8 diagnostic slice should compare alternative optimizer/start
routes or deliberately larger information content, then decide whether any
surface is stable enough for a small formal recovery grid.
