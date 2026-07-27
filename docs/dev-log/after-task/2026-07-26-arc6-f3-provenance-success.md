# After-task report — Arc 6 F3 Bernoulli x ordinary-NB2 provenance success

## 1. Goal

Execute exactly one approved, SHA-pinned F3 provenance smoke and audit its
immutable receipt, without entering F4 or public inference.

## 2. Implemented

Created a clean detached worktree at `2418d847b45891b09f719932e75985101be50116`,
verified the source and F1M blobs, and made the one literal approved invocation.
The retained receipt records a complete successful staged provenance smoke.

## 3a. Decisions and Rejected Alternatives

Did not retry, alter the CLI, seed, start values, tolerances, source SHA, or
output path. Did not run F4, a simulation, calibration, profile, bootstrap, or
public inference route.

## 4. Files Touched

- `docs/dev-log/smoke/2026-07-26-arc6-f3-2418d847b458/attempt-001/`
- `docs/dev-log/2026-07-26-arc6-f3-provenance-success-receipt.md`
- this report and its plan-versus-actual record

No package source, API, capability ledger, public documentation, or Arc D/F5
file changed during the execution and closeout.

## 5. Checks Run

The detached SHA and two F1M blobs matched before invocation. The receipt has
`complete/success`, all eight pre-interval stages `ok`, and interval
`not_attempted`. All artifact hashes were independently recomputed and matched.
The focused runner suite passed with 57 expectations.

## 6. Tests of the Tests

Three fresh read-only reviewers independently inspected provenance, inference
limits, and contract compliance. All accepted only the narrow F3 provenance
claim after the exact owner authorization was durably recorded.

## 7a. Issue Ledger

Resolved: one complete F3 provenance receipt now exists. Deferred: F4
preregistration, harness design, compute approval, calibration, intervals,
recovery, coverage, public inference, API exposure, and Arc D/F5.

## 8. Consistency Audit

The receipt source SHA, literal CLI, requested output path, F1M SHA, blobs,
dataset hash, terminal status, and artifact manifest agree. The output is a
single immutable `attempt-001` directory and includes no interval result.

## 9. What Did Not Go Smoothly

Two earlier one-shot attempts revealed and repaired output-path, local-helper,
and nested-layout preflight defects. Those authorizations remained consumed;
this later SHA received its own exact written approval and was invoked once.

## 10. Known Residuals

F3 proves only this one staged provenance smoke. It is not uncertainty
calibration or evidence for public inference. F4 has not started and remains
separately approval-gated.

## 11. Team Learning

An approval-gated smoke needs a durable receipt chain: exact owner approval,
clean source/blob checks, one literal CLI, hash-verified artifacts, and an
explicitly narrow claim boundary.

## 12. Cross-Product Coverage

This covers only the fixed-effect, complete-pair Bernoulli x ordinary-NB2 F3
provenance smoke. It does NOT cover F4, empirical-SD calibration, SE or
interval validity, recovery, coverage, public inference, other pair classes,
random effects, missingness, or Arc D/F5.
