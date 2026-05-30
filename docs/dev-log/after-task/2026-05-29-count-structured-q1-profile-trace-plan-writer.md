# After-Task Report: Count Structured q1 Profile Trace Plan Writer

## Purpose

This slice makes the selected-example trace plan a stable table artifact. The
next rerun helper can read one CSV instead of reconstructing examples, seeds,
and profile-control labels from prose.

## Changes

Added `phase18_write_count_structured_q1_profile_trace_plan()`. The helper
creates the normal `tables/` directory, writes
`count-structured-q1-profile-trace-plan.csv`, returns the written path and plan,
and refuses to overwrite an existing table unless `overwrite = TRUE`.

Updated the focused Phase 18 test, `ROADMAP.md`,
`docs/design/41-phase-18-simulation-programme.md`,
`docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`,
and
`docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md`.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-trace-plan-writer.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
Rscript --vanilla - <<'EOF'
source("inst/sim/R/sim_registry.R")
source("inst/sim/R/sim_utils.R")
source("inst/sim/dgp/sim_dgp_count_structured_q1.R")
source("inst/sim/R/sim_runner.R")
source("inst/sim/R/sim_aggregate.R")
source("inst/sim/R/sim_uncertainty.R")
source("inst/sim/fit/sim_summarise_count_structured_q1.R")
source("inst/sim/run/sim_run_count_structured_q1_smoke.R")
source("inst/sim/run/sim_summary_count_structured_q1_smoke.R")
source("inst/sim/run/sim_write_count_structured_q1_grid.R")
out <- phase18_write_count_structured_q1_profile_trace_plan(tempfile("trace-plan-"))
print(out$path)
print(utils::read.csv(out$path))
unlink(out$output_dir, recursive = TRUE)
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. The smoke check wrote
the CSV under `tables/`, read back all six planned rows, and preserved the exact
artifact seeds. `git diff --check` was clean after formatting.

## Scope Boundaries

This slice does not rerun profiles, add likelihood-ratio traces, dispatch a
simulation, change profile settings, or alter the main grid artifact manifest.
It only writes the selected-example plan table.

## Review

Ada kept the writer separate from the grid output bundle. Fisher kept the CSV
as an input artifact, not evidence about profile behavior. Curie covered
overwrite protection and seed round-tripping. Grace checked the smoke writer.
Rose kept the scope boundary explicit.
