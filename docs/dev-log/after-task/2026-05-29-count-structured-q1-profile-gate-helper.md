# After-Task Report: Count Structured q1 Profile-Gate Helper

## Purpose

This slice turns the manual profile-interval decision from the stable-set
formal pilot into executable audit logic. The immediate reader is a package
contributor checking whether a future `count_structured_q1` artifact can move
past interval diagnostics. The answer should come from the same stop rules each
time, not from a hand-written table scan.

## Changes

`phase18_count_structured_q1_profile_gate_summary()` now summarises requested
profile interval rows for the count structured q1 lane. It ignores
`not_requested` intervals, computes overall and condition-level profile failure
rates, applies optional watch-cell profile-failure checks, and returns a
decision table with either `hold_interval_diagnostic` or `propose_next_pilot`.

Focused tests in `tests/testthat/test-phase18-count-structured-q1.R` cover a
stopped pilot with a condition crossing the 10% profile failure rule and a
clean pilot that stays below all gates.

## Validation

```sh
air format inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/140-phase-18-count-structured-q1-formal-pilot-audit-slices-1774-1782.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-count-structured-q1-profile-gate-helper.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-count-structured-q1', reporter = 'summary')"
git diff --check
```

The focused `phase18-count-structured-q1` suite passed. `git diff --check` was
clean after formatting the final slice files. The stale-claim scan found only
intended negative wording and the earlier workflow-plumbing row.

## Scope Boundaries

This slice does not change the likelihood, formula grammar, DGP, fitted model,
profile interval computation, bootstrap interval path, or GitHub Actions
workflow. It only makes the formal-pilot profile gate auditable in code. The
stable count structured q1 lane still stops at `hold_interval_diagnostic`
because `count_structured_q1_001` crossed the condition-level profile interval
failure rule in run `26669005577`.

## Review

Ada kept the work on the next audit helper rather than opening a recovery-grid
design. Fisher checked that the stop rules match the formal-pilot design and
audit. Curie covered both held and clean outcomes. Grace kept the helper
internal to the simulation audit path. Rose kept the report clear that this is
not recovery, bootstrap, or broad coverage evidence.
