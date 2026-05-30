# After-Task Report: Count Structured q1 Profile Example Geometry Summary

## Purpose

This slice gives the profile failure audit a compact descriptive view of the
example-detail rows. The goal is to show endpoint missingness and estimate
ranges by failure class without turning those summaries into a new pass/fail
rule.

## Changes

`phase18_audit_count_structured_q1_profile_gate()` now returns
`profile_gate$example_geometry_summary`. The table groups failure-summary rows
by `failure_class` and records failed-interval totals, the number of readable
example details, missing lower and upper endpoint counts, public structured-SD
estimate ranges, estimate/truth ranges, and the minimum-estimate example cell
and replicate.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-example-geometry-summary.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
Rscript --vanilla - <<'EOF'
out <- "/tmp/drmtmb-count-structured-formal-lJ18lP/phase18-count_structured_q1-shard-1-of-1-26669005577"
source("inst/sim/R/sim_registry.R")
source("inst/sim/R/sim_utils.R")
source("inst/sim/R/sim_runner.R")
source("inst/sim/R/sim_uncertainty.R")
source("inst/sim/fit/sim_summarise_count_structured_q1.R")
source("inst/sim/run/sim_write_count_structured_q1_grid.R")
audit <- phase18_audit_count_structured_q1_profile_gate(
  out,
  require_complete = TRUE,
  watch_cells = c("count_structured_q1_003", "count_structured_q1_005")
)
print(audit$profile_gate$example_geometry_summary)
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. On artifact
`26669005577`, `nonfinite_interval` had 22 failed intervals across seven
failure-summary rows, all seven example rows missing lower endpoints, no
example rows missing upper endpoints, and a minimum example estimate
`1.906516e-05` in `count_structured_q1_006` replicate 45.
`profile_crossing_failure` had five failed intervals across four rows, all four
example rows missing both lower and upper endpoints, and a minimum example
estimate `2.168574e-05` in `count_structured_q1_003` replicate 33.
`git diff --check` was clean after formatting.

## Scope Boundaries

This slice does not introduce a near-zero threshold, change profile
construction, alter likelihood code, or claim profile coverage. It is a
descriptive artifact summary for the next interval-geometry review.

## Review

Ada kept the summary attached to the profile-gate audit. Fisher kept the table
descriptive rather than inferential. Curie covered the single-row synthetic
summary in the focused test. Grace checked the formal-pilot artifact. Rose kept
endpoint missingness separate from a profile-failure cause claim.
