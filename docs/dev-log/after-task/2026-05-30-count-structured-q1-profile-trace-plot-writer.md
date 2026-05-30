# Count Structured q1 Profile Trace Plot Writer

## Task

Save the selected-example profile-trace diagnostic plot as a predictable
artifact under `figures/`.

## What Changed

`phase18_write_count_structured_q1_profile_trace_plot()` now writes
`figures/count-structured-q1-profile-trace.png` from existing trace rows. The
helper returns the ggplot object and the trace summary table, so downstream
reports can keep the visual diagnostic and endpoint-missingness evidence
together.

The focused plot tests now share a synthetic trace fixture. The new writer test
checks that the PNG exists, has non-zero file size, returns the expected summary
rows, and refuses to overwrite an existing plot unless `overwrite = TRUE`.

## Validation

Completed validation:

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-count-structured-q1-profile-trace-plot-writer.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The focused Phase 18 count-structured-q1 suite passed after the test fixture
was made self-contained. The real plot-writer smoke read the previous
selected-example trace CSV from
`/private/tmp/drmtmb-count-structured-q1-profile-trace-summary-writer-20260530/tables/count-structured-q1-profile-trace.csv`
and wrote
`/private/tmp/drmtmb-count-structured-q1-profile-trace-plot-writer-20260530/figures/count-structured-q1-profile-trace.png`.
The rendered PNG was 62,652 bytes and was visually inspected. The smoke summary
had six rows, all with `trace_status = "ok"` and `n_trace_failed = 0`.
`git diff --check` was clean.

## Interpretation

This slice does not change the trace generation, selected examples, profile
settings, or plot recipe. It turns the already-audited likelihood-ratio curve
into a saved local artifact. The summary table remains the evidence for missing
or recovered profile interval endpoints.

## Review Notes

Ada kept the writer internal. Florence treated the rendered PNG as the visual
gate. Fisher checked that the plot remains a curve diagnostic, not an interval
success claim. Pat checked that the `figures/` path is predictable. Curie kept
the tests synthetic and fast. Grace checked local renderability. Rose checked
that the docs still separate curve availability from endpoint availability. No
spawned subagents were running.
