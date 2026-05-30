# Count Structured q1 Profile Trace Plot

## Task

Add an internal visual diagnostic for the selected-example profile trace curves.
The figure should help the team inspect the likelihood-ratio geometry before
changing profile settings or proposing a larger recovery grid.

## What Changed

`phase18_plot_count_structured_q1_profile_trace()` now plots `delta_deviance`
against the log structured-SD profile value. The plot facets by selected
example, colours and linetypes the current and smaller-`ystep` passes, marks
the fitted estimate, and draws the 70% likelihood-ratio cutoff. The y-axis uses
a sqrt scale so the cutoff region and high-tail spikes remain visible in the
same panel.

The helper is internal diagnostic plumbing. It is not a user-facing plotting
function and does not change the profile interval gate.

## Validation

Validation completed:

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-count-structured-q1-profile-trace-plot.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The rendered figure, summary CSV, and figure-audit note were saved under
`docs/dev-log/figure-audits/2026-05-30-count-structured-q1-profile-trace/`.
The focused `phase18-count-structured-q1` suite passed. The first render was
rejected because response-scale scientific-notation x-axis labels and high-tail
spikes made the cutoff region hard to inspect; the final render uses log
structured-SD values on x and a sqrt y-axis. `git diff --check` was clean after
formatting the slice files.

## Interpretation

The plot shows curve geometry, not interval success. A curve can render cleanly
while the corresponding interval endpoints remain missing. The trace summary
table remains the source for endpoint availability.

## Review Notes

Ada kept this as internal diagnostic plumbing. Florence inspected the rendered
PNG before closure. Fisher checked the plotted grain as likelihood-ratio trace
rows. Pat checked axis and facet readability. Grace checked that the plot
renders from the saved trace artifact. Rose checked that the prose does not
turn curve availability into interval availability. No spawned subagents were
running.
