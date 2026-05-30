# Count Structured q1 Profile Trace Run Writer

## Task

Add the small writer that saves the selected-example profile trace plan and the
bound trace rows as a stable artifact before running the real selected
formal-pilot examples.

## What Changed

`phase18_write_count_structured_q1_profile_trace_run()` now writes two CSVs
under `tables/`: `count-structured-q1-profile-trace-plan.csv` and
`count-structured-q1-profile-trace.csv`. It uses
`phase18_count_structured_q1_profile_trace_run_plan()` to build the trace rows,
then returns the output directory, table directory, paths, plan, and trace data.

`phase18_count_structured_q1_profile_trace_run_paths()` centralizes the two
trace-run paths. The existing plan writer now uses the same plan path.

## Validation

Validation completed:

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-count-structured-q1-profile-trace-run-writer.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. A fake-run writer smoke
created both trace-run CSVs and read back four trace rows from
`count-structured-q1-profile-trace.csv`. `git diff --check` was clean after
formatting the slice files.

## Interpretation

This slice records the artifact contract for the selected-example trace rerun.
It does not run the three selected formal-pilot examples, change `ystep`, or
relax the profile gate. The next slice can use this writer to produce a real
trace artifact for the current and smaller-`ystep` passes.

## Review Notes

Ada kept the writer separate from the main simulation grid bundle. Fisher kept
the saved rows descriptive until real profile traces exist. Curie covered the
writer with fake DGP, fit, and profile functions. Grace kept expensive profiles
out of CI. Rose checked that the docs still mark this as artifact plumbing, not
new evidence. No spawned subagents were running.
