# After-Task Report: Count Structured q1 Profile-Failure Diagnostics

## Purpose

This slice adds a compact failure diagnostic to the count structured q1 profile
gate. The reader is a contributor deciding what to inspect after a profile gate
returns `hold_interval_diagnostic`. The useful question is not only how many
intervals failed, but which cells and interval messages account for the failures.

## Changes

`phase18_count_structured_q1_profile_failure_summary()` now groups failed
requested profile intervals by condition, `interval_status`, and
`interval_message`. The output carries `failed_interval`, the condition
denominator `n_interval`, and the condition `failure_rate`.

`phase18_count_structured_q1_profile_gate_summary()` includes that table as
`failure_summary`, so both table-level and artifact-level audits can report the
failed interval groups without another hand-written CSV pass.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-failure-diagnostics.md
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
print(audit$profile_gate$decision)
print(head(audit$profile_gate$failure_summary, 5))
EOF
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. The formal-pilot
artifact still returned `hold_interval_diagnostic`. The largest failed groups
were nonfinite profile intervals in `count_structured_q1_001`,
`count_structured_q1_003`, and `count_structured_q1_006`; the next groups were
interpolation-crossing failures in `count_structured_q1_001` and
`count_structured_q1_003`. `git diff --check` was clean after formatting. The
stale-claim scan found only intended negative wording and the earlier
workflow-plumbing row.

## Scope Boundaries

This slice does not change profile computation, thresholds, dispatch settings,
or recovery-grid readiness. It only turns the existing failed interval rows into
a reusable diagnostic summary. The stable count structured q1 lane still stops
at `hold_interval_diagnostic` for run `26669005577`.

## Review

Ada kept the diagnostic attached to the existing gate. Fisher kept the summary
focused on failed requested profile intervals. Curie covered message grouping
and denominator attachment. Grace ran the helper on the formal-pilot artifact.
Rose kept the report clear that this is diagnostic evidence, not a geometry fix
or recovery-grid design.
