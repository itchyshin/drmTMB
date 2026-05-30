# Count Structured q1 Profile Trace Summary

## Task

Add a stable summary table for the selected-example profile trace artifact so
the next visual diagnostic can work from one row per example and profile pass.

## What Changed

`phase18_count_structured_q1_profile_trace_summary()` now groups trace rows by
`cell_id`, `replicate`, and `profile_pass`. It reports trace-row counts, failed
trace rows, endpoint missingness, response-scale profile-value ranges, maximum
`delta_deviance`, elapsed time, and interval status.

The helper keeps two questions separate: whether the profile curve was
generated, and whether the profile interval endpoints are usable. That matters
for the selected examples because the corrected target labels produce trace
rows, but the interval endpoint failures are still visible in `conf.low`,
`conf.high`, and `conf.status`.

## Validation

Validation completed:

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-count-structured-q1-profile-trace-summary.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. The real trace-artifact
smoke returned a six-row summary from
`/private/tmp/drmtmb-count-structured-q1-profile-trace-targets-20260530`: three
selected examples crossed with `current` and `smaller_ystep` passes. All six
rows had `trace_status = "ok"` and `n_trace_failed = 0`, while endpoint fields
preserved the interval diagnostic. `git diff --check` was clean after
formatting the slice files.

## Interpretation

This slice does not add new simulation evidence or change profile settings. It
turns the existing selected-example trace rows into a stable audit table for
the next plotting and interpretation slice.

## Review Notes

Ada kept the helper as a bridge from trace rows to diagnostics. Fisher checked
that interval endpoint fields remain separate from trace status. Florence
requested a stable table before judging plots. Curie covered mixed success and
failure rows. Grace kept validation local and fast. Rose checked for stale
claim drift. No spawned subagents were running.
