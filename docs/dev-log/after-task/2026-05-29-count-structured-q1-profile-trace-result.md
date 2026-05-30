# After-Task Report: Count Structured q1 Profile Trace Result

## Purpose

This slice defines the per-row result contract for the selected-example profile
rerun. It lets the next helper attach likelihood-ratio trace rows to the exact
plan metadata and record profile failures as ordinary diagnostic rows.

## Changes

Added `phase18_count_structured_q1_profile_trace_result()` and
`phase18_count_structured_q1_profile_trace_metadata()`. The wrapper takes a
`drmTMB` fit, one trace-plan row, and a profile function. Successful profile
calls return profile rows with cell id, replicate, seed, example role, profile
pass, profile target, confidence level, `ystep`, status, message, and elapsed
time attached. Failed profile calls return one metadata row with
`trace_status = "failed"` and the profile error message.

Updated the focused Phase 18 test, `ROADMAP.md`,
`docs/design/41-phase-18-simulation-programme.md`,
`docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`,
and
`docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md`.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-trace-result.md
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
row <- phase18_count_structured_q1_profile_trace_plan()[1, , drop = FALSE]
fake_profile <- function(object, parm, level, ystep) {
  data.frame(profile_value = c(0.1, 0.2), delta_deviance = c(1, 0))
}
print(phase18_count_structured_q1_profile_trace_result(
  structure(list(), class = "drmTMB"),
  row,
  fake_profile
))
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. The smoke check returned
two fake profile rows with plan metadata attached and `trace_status = "ok"`.
`git diff --check` was clean after formatting.

## Scope Boundaries

This slice does not rerun the formal-pilot examples, save real likelihood-ratio
points, change profile settings, or relax the interval diagnostic hold. It only
defines the result shape for the next rerun helper.

## Review

Ada kept the helper at one plan row. Fisher kept success and failure traces in a
single diagnostic shape. Curie covered success and error behavior with injected
profile functions. Grace avoided expensive profiles in tests. Rose kept the
result contract separate from evidence about real examples.
