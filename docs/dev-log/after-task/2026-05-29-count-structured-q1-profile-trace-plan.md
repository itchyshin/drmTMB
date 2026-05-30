# After-Task Report: Count Structured q1 Profile Trace Plan

## Purpose

This slice turns the profile-geometry diagnostic note into an executable plan
table. It fixes the selected examples, artifact seeds, profile target, and two
`ystep` passes before any helper reruns profiles.

## Changes

Added `phase18_count_structured_q1_profile_trace_examples()` and
`phase18_count_structured_q1_profile_trace_plan()`. The plan contains three
formal-pilot examples from artifact `26669005577` crossed with two passes:
`current` (`ystep = 0.50`) and `smaller_ystep` (`ystep = 0.25`). The selected
examples use exact artifact seeds: `count_structured_q1_006` replicate 45 seed
932584520, `count_structured_q1_003` replicate 33 seed 461195966, and
`count_structured_q1_001` replicate 25 seed 32713190.

Updated the focused Phase 18 test, `ROADMAP.md`,
`docs/design/41-phase-18-simulation-programme.md`,
`docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`,
and
`docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md`.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-trace-plan.md
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
print(phase18_count_structured_q1_profile_trace_plan())
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. The plan has six rows:
three selected examples crossed with `current` and `smaller_ystep` passes. The
printed plan used the exact artifact seeds listed above. `git diff --check` was
clean after formatting.

## Scope Boundaries

This slice does not rerun profiles, save likelihood-ratio points, change the
formal-pilot profile settings, or relax `hold_interval_diagnostic`. It only
creates the plan table for the next rerun helper.

## Review

Ada kept the scaffold small and auditable. Fisher checked that the plan
compares settings without treating one as preferred. Curie covered the plan
shape and seed values in the focused test. Grace checked the printed plan.
Rose caught that registry-derived seeds did not match the artifact and kept the
exact artifact seeds in the default examples.
