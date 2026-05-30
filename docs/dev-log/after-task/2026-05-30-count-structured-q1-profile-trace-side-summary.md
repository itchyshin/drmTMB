# Count Structured q1 Profile Trace Side Summary

## Task

Add the side-specific trace support summary requested by the selected-example
profile-trace interpretation note.

## What Changed

`phase18_count_structured_q1_profile_trace_side_summary()` now splits each
selected example and profile pass into lower-side and upper-side support around
the fitted estimate. For each side it reports the trace-row count,
profile-value range, link-scale profile-value range, maximum likelihood-ratio
distance, whether the side reaches the profile cutoff, and whether the matching
interval endpoint is present.

The focused test uses synthetic trace rows to check endpoint presence and cutoff
reach without rerunning selected formal-pilot profiles.

## Validation

Completed validation:

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/design/142-phase-18-count-structured-q1-profile-trace-interpretation.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-count-structured-q1-profile-trace-side-summary.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The focused Phase 18 count-structured-q1 suite passed. The real side-summary
smoke read the selected trace CSV from
`/private/tmp/drmtmb-count-structured-q1-profile-trace-summary-writer-20260530/tables/count-structured-q1-profile-trace.csv`
and returned 12 rows: every lower side had `side_reaches_cutoff = FALSE`, every
upper side had `side_reaches_cutoff = TRUE`, and only the nonfinite example had
finite upper endpoints. `git diff --check` was clean.

## Interpretation

The real selected trace artifact shows that all lower sides fail to reach the
70% cutoff, while all upper sides reach it. Only the nonfinite example has a
finite upper endpoint. The next profile-setting experiment should therefore
target lower-side boundary support, not merely generate denser profile rows.

## Review Notes

Ada kept the helper internal. Fisher checked cutoff reach separately from
endpoint extraction. Noether checked the link-scale side split. Florence kept
the helper tied to the existing diagnostic plot. Curie covered side behavior
with a focused test. Grace checked focused tests and local smoke evidence. Rose
checked that the formal-pilot gate remains closed. No spawned subagents were
running.
