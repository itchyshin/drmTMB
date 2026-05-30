# Count Structured q1 Profile Trace Runner

## Task

Add the next small runner slice for the count structured q1 profile-geometry
diagnostic. The goal was to connect the selected-example trace plan to the DGP,
fit, and profile steps while keeping CI tests on injected fake functions.

## What Changed

`phase18_count_structured_q1_profile_trace_run_plan()` now takes the trace
plan, selects each matching stable condition by `cell_index`, regenerates the
replicate with the recorded artifact seed, fits the model, and delegates
successful fits to `phase18_count_structured_q1_profile_trace_result()`.

DGP and fit errors return failed trace rows with the same plan metadata shape
as profile failures. `phase18_count_structured_q1_profile_trace_bind_rows()`
aligns columns before binding, so a one-row failure can sit beside successful
likelihood-ratio trace rows without dropping profile columns.

## Validation

Validation completed:

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-count-structured-q1-profile-trace-runner.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. A fake-run smoke check
returned four trace rows for two planned examples with `trace_status = "ok"`.
`git diff --check` was clean after formatting the slice files.

## Interpretation

This slice is runner plumbing. It does not rerun the three selected
formal-pilot examples, change `ystep`, change the profile confidence level, or
relax the formal-pilot profile gate. It makes the real selected-example trace
rerun executable as a bounded follow-up slice.

## Review Notes

Ada kept the change scoped to the trace runner. Fisher kept the output
descriptive until real likelihood-ratio traces exist. Curie covered the runner
with fake DGP, fit, and profile functions. Grace kept expensive selected-example
profiles out of CI. Rose checked that the roadmap and diagnostic note do not
promote the helper as new simulation evidence. No spawned subagents were
running.
