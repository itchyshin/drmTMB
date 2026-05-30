# After-Task Report: Count Structured q1 Profile-Failure Classes

## Purpose

This slice makes the count structured q1 profile-failure summary readable in
reports. The previous summary preserved exact interval messages, but those
messages can span several lines. A contributor diagnosing the next geometry
problem needs compact failure classes first, with one example message kept for
traceability.

## Changes

`phase18_count_structured_q1_profile_failure_class()` now classifies interval
messages into `nonfinite_interval`, `profile_crossing_failure`,
`missing_interval_message`, or `other_profile_failure`.

`phase18_count_structured_q1_profile_failure_summary()` now groups by
`failure_class` and keeps `example_interval_message` rather than grouping by
the full raw message. The summary still reports `failed_interval`, `n_interval`,
and the condition `failure_rate`.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-failure-classes.md
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
print(audit$profile_gate$failure_summary[, c("cell_id", "failure_class", "failed_interval", "n_interval", "failure_rate")])
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. On artifact
`26669005577`, the classified summary returned 11 rows split between
`nonfinite_interval` and `profile_crossing_failure`; the largest groups were
nonfinite profile intervals in `count_structured_q1_001`,
`count_structured_q1_003`, and `count_structured_q1_006`. `git diff --check`
was clean after formatting. The stale-claim scan found only intended negative
wording and the earlier workflow-plumbing row.

## Scope Boundaries

This slice does not change profile computation, thresholds, interval decisions,
or recovery-grid readiness. It only improves the diagnostic grouping used after
the profile gate has already stopped the lane.

## Review

Ada kept the change to report readability. Fisher kept failure classes tied to
interval messages. Curie kept class output covered in the focused tests. Grace
checked the classified helper against the formal-pilot artifact. Rose kept one
raw example message in the summary so the diagnostic remains auditable.
