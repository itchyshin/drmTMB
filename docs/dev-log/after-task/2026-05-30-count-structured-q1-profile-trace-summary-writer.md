# Count Structured q1 Profile Trace Summary Writer

## Task

Make the selected-example trace-run artifact self-contained by writing the
summary table beside the plan and raw trace rows.

## What Changed

`phase18_write_count_structured_q1_profile_trace_run()` now writes three CSVs
under `tables/`: the selected trace plan, the raw trace rows, and
`count-structured-q1-profile-trace-summary.csv`. The function also returns the
summary table in its result object.

The focused writer test now checks that the summary CSV is created and that
overwrite protection covers all trace-run tables.

## Validation

Completed validation:

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-count-structured-q1-profile-trace-summary-writer.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The focused test suite passed. The real writer smoke wrote the plan, trace, and
summary CSVs under
`/private/tmp/drmtmb-count-structured-q1-profile-trace-summary-writer-20260530/tables/`.
The saved summary had six rows, all with `trace_status = "ok"` and
`n_trace_failed = 0`. The endpoint-missingness columns still showed the
intended diagnostic result: the two crossing examples missed both endpoints,
and the non-finite example kept its finite upper endpoint while missing the
lower endpoint. `git diff --check` was clean.

## Interpretation

This slice does not change trace generation, profile settings, or the
formal-pilot gate. It makes future trace artifacts easier to audit because the
endpoint-missingness summary is saved with the raw trace rows.

## Review Notes

Ada kept the writer self-contained. Fisher checked that the summary remains
descriptive endpoint evidence. Florence kept the plot support table beside the
trace data. Curie covered the CSV in the focused writer test. Grace checked a
real local writer smoke. Rose checked that downstream reports no longer rely on
ad hoc summary aggregation. No spawned subagents were running.
