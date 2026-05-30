# After-Task Report: Count Structured q1 Profile-Gate Artifact Audit

## Purpose

This slice connects the profile-gate helper to downloaded count structured q1
artifacts. The reader is a package contributor auditing a future GitHub Actions
run. They should be able to point at the artifact directory and get the same
`hold_interval_diagnostic` or `propose_next_pilot` decision used by the table
helper.

## Changes

`phase18_audit_count_structured_q1_profile_gate()` now reads a count structured
q1 artifact directory, loads `count-structured-q1-profile-intervals.csv`, and
passes the rows to `phase18_count_structured_q1_profile_gate_summary()`. The
return value records the output directory, table directory, artifact paths,
missing-artifact names, and profile-gate result.

The focused test builds a synthetic artifact with one requested `ok` profile
interval row, verifies that the wrapper returns
`count_structured_q1_profile_gate_audit`, and confirms the decision is
`propose_next_pilot`.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-gate-artifact-audit.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. `git diff --check` was
clean after formatting the slice files. The stale-claim scan found only
intended negative wording and the earlier workflow-plumbing row.

## Scope Boundaries

This slice does not add new profile interval computation, change profile
thresholds, dispatch a simulation, or reinterpret the formal-pilot result. It
only adds artifact plumbing around the profile-gate helper. The stable count
structured q1 lane still stops at `hold_interval_diagnostic` for run
`26669005577`.

## Review

Ada kept the wrapper aligned with the existing boundary-gate audit shape.
Curie tested the wrapper with a synthetic requested interval artifact. Fisher
kept the gate tied to requested profile intervals. Grace preserved
missing-artifact metadata for downloaded Actions outputs. Rose kept recovery,
bootstrap, and broad coverage claims out of the report.
