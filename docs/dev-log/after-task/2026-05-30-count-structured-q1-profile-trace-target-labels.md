# Count Structured q1 Profile Trace Target Labels

## Task

Fix the selected-example profile trace plan so the real trace writer calls
`profile()` with public direct target labels rather than the internal TMB
parameter name.

## What Changed

`phase18_count_structured_q1_profile_trace_examples()` now records
per-example `profile_parameters`: `sd:mu:spatial(1 | site)` for the two spatial
examples and `sd:mu:animal(1 | id)` for the animal example. These are the
labels returned by `profile_targets()` and accepted by `profile()`.

`phase18_count_structured_q1_profile_trace_plan()` now uses those example-level
labels by default. A scalar `profile_parameters` override is still allowed for
tests or future diagnostics that deliberately target the same profile label for
all selected rows.

## Validation

Validation completed:

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/141-phase-18-count-structured-q1-profile-geometry-diagnostic-slices-1792-1799.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-count-structured-q1-profile-trace-target-labels.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The real selected-example trace smoke was written to
`/private/tmp/drmtmb-count-structured-q1-profile-trace-targets-20260530`.
It produced 116 `current` rows and 125 `smaller_ystep` rows, all with
`trace_status = "ok"`. Endpoint inspection showed the nonfinite-interval
example still has missing lower endpoints and finite upper endpoints, while
both profile-crossing examples still have missing lower and upper endpoints.
`git diff --check` was clean after formatting the slice files.

## Interpretation

The corrected labels make the profile curves inspectable. That is
profile-curve evidence, not interval-success evidence. The nonfinite-interval
example still lacks lower endpoints, and the two profile-crossing examples
still lack both interval endpoints in the trace rows.

## Review Notes

Ada kept the fix scoped to target labels. Boole checked the public profile
target namespace. Fisher kept curve availability separate from confidence
interval availability. Curie updated the focused test. Grace kept the real
trace run bounded and local. Rose checked that the profile-gate failure remains
visible. No spawned subagents were running.
