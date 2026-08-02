# After Task: Arc 6 F3 F1 deterministic-tail stop

## Goal

Implement the locked F1 deterministic matrix, then begin a one-cell local F3
provenance smoke only if the entire matrix passed.

## Implemented

Added validated zero, sign, positive-tail, and positive-near-boundary oracle
controls plus explicit negative-tail blocked controls to the staged-sandwich
test file. The full F1 gate failed at the negative tail, so the arc stopped
before the smoke.

## Mathematical Contract

The target remains staged link-scale `alpha`; `eta` is derived only. The
negative `alpha = -4` row had a finite production result but a disagreeing
numerical oracle and non-finite oracle Hessian, so it meets neither permitted
F1 outcome. At `alpha = -7`, production was fail-closed unavailable.

## Files Changed

- `tests/testthat/test-associate-pairs-staged-sandwich.R`
- `docs/dev-log/2026-07-26-arc6-f3-f1-tail-stop-receipt.md`
- this report and the linked F0–F2 receipt update

## Checks Run

- Baseline focused staged-sandwich test through `devtools::load_all()` — PASS.
- Expanded focused staged-sandwich test — PASS.
- Direct tail diagnosis at `alpha = -4, -7` — recorded in the stop receipt.
- `git diff --check` — required before closeout.

## Tests Of The Tests

The positive cases still compare probability, gradient, and Hessian with the
independent numerical oracle at frozen tolerances. Negative-tail controls assert
the observed mismatch/unavailability so a later edit cannot relabel them as
validated cases.

## Consistency Audit

Noether, Fisher, and Rose all returned STOP/NOT READY for F3 smoke. The private
engine, public aborts, Arc D boundary, ledger, and direct `rho12` separation
remain unchanged.

## GitHub Issue Maintenance

No issue or PR action. This is retained negative evidence in a bounded private
development lane.

## What Did Not Go Smoothly

The first direct `test_file()` call lacked `devtools::load_all()` and failed as
a harness invocation, not as a model test. The corrected local invocation
passed the baseline and exposed the real negative-tail stop.

## Team Learning

A passing focused suite is not a passing F1 matrix when it includes an explicit
blocked control. The independent numerical oracle must itself be stable in the
target regime before it can certify a finite production calculation.

## Known Limitations

F1 is incomplete; F3 smoke, all refits, uncertainty calibration, intervals,
and public inference remain unperformed and unavailable.

## Next Actions

Start a fresh, plan-only negative-tail oracle adjudication lane. Do not retry
the F3 smoke until its revised F1 contract is independently reviewed and
explicitly approved.
