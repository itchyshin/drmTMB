# After-Task Report: Count Structured q1 Profile-Failure Example Replicates

## Purpose

This slice makes the profile-failure summary immediately actionable. A
failure-class row now points to one concrete replicate, so the next diagnostic
note can inspect a real failed case without re-reading the interval table.

## Changes

`phase18_count_structured_q1_profile_failure_summary()` now reports
`example_replicate` beside `failure_class`, `example_interval_message`,
`failed_interval`, `n_interval`, and `failure_rate`.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-failure-examples.md
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
print(audit$profile_gate$failure_summary[, c("cell_id", "failure_class", "example_replicate", "failed_interval", "n_interval", "failure_rate")])
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. On artifact
`26669005577`, all 11 failure-class rows carried an example replicate. For
`count_structured_q1_001`, the example nonfinite replicate was 14 and the
example profile-crossing replicate was 25. `git diff --check` was clean after
formatting. The stale-claim scan found only intended negative wording and the
earlier workflow-plumbing row.

## Scope Boundaries

This slice does not inspect profile curves, change profile computation, change
thresholds, or revise the formal-pilot decision. It only gives the next
diagnostic a concrete replicate pointer.

## Review

Ada kept the change to diagnostic routing. Fisher kept the field tied to failed
requested profile intervals. Curie covered the new field in the focused test.
Grace checked the helper on the formal-pilot artifact. Rose kept the report from
overstating this as a geometry diagnosis.
