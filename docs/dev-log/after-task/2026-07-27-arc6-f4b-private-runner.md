# After-task report — Arc 6 F4b private runner

## 1. Goal

Prepare the private, fail-closed F4 runner on the owner-approved base
`095f51b3b`, with focused contract tests and without a host connection,
simulation campaign, or public inference work.

## 2. Implemented

`tools/run-arc6-bernoulli-nbinom2-f4-private.R` now freezes the 24-cell,
24,000-attempt seed schedule; validates the source and two private-engine
blobs; retains one status row per scheduled attempt; applies the frozen
terminal-stage precedence; and extracts only `alpha` plus the private
Godambe alpha covariance/SE.  The sourceable per-attempt function uses fresh
margin fits and the private sandwich, but the only CLI mode is `prepare`:
there is no execution or scheduler mode in this F4b receipt.

## 3a. Decisions and Rejected Alternatives

The runner rejects `--mode=execute`.  It does not call `vcov()` or
`confint()`, use conditional association curvature, or treat a near-boundary
coefficient as a point estimate.  A later DRAC receipt must pin this runner's
post-commit source SHA, name its output root and scheduler runbook, and
authorize the fixed campaign before `f4_run_attempt()` may be invoked.

## 4. Files Touched

- `tools/run-arc6-bernoulli-nbinom2-f4-private.R`
- `tests/testthat/test-arc6-f4-private-runner.R`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

`git diff --check` passed.  The focused F4 runner suite passed 31
expectations, including deterministic seed replay, source/blob mismatch,
terminal-stage precedence, boundary retention, delta-stage routing, and the
private-alpha-versus-conditional-curvature guard.  The untouched F3 runner
suite also passed 57 expectations.

## 6. Tests of the Tests

The F4 tests source the runner rather than invoking its CLI.  The runner
accepts only `--mode=prepare`, so the suite cannot launch a fit, scheduler,
Totoro, or DRAC operation.  The conditional-curvature test supplies an
incompatible stage-two Hessian and a distinct private alpha SE, proving the
extraction route selects the latter.

## 7a. Issue Ledger

Resolved: F4b private-runner preparation.  Deferred: exact campaign SHA,
DRAC runbook, preflight, all 24,000 outer refits, calibration summaries,
F4 review panel, public S3 methods, and F5.

## 8. Consistency Audit

The code reproduces the preregistration's lexicographic cells, seed formula,
all-attempt record, unavailable-point rule, alpha-Godambe rule, and primary
stage ordering.  F4b does not amend targets, denominators, or scope.

## 9. What Did Not Go Smoothly

The first pure test run exposed a duplicate protocol-stage check that converted
an early margin failure into a malformed `dgp_harness` record.  The runner now
treats protocol validity as the sole `dgp_harness` status and begins ordinary
stage precedence at the Bernoulli margin; the regression test is retained.

## 10. Known Residuals

No F4 attempt has been generated or fitted.  The `prepare` CLI has not been
invoked, no DRAC account or host was contacted, and no source SHA is yet
approved for compute.  The public `vcov()` and `confint()` methods remain
deliberately unavailable.

## 11. Team Learning

For a staged inferential campaign, terminal precedence is part of the evidence
definition: a status table is not valid merely because it has one row per seed.
The protocol quarantine must be distinct from the first numerical failure.

## 12. Cross-Product Coverage

This F4b harness covers only fixed-effect, complete-pair Bernoulli x
ordinary-NB2 `association = ~ 1` alpha evidence.  It does not cover other
pairs, slopes, eta intervals, random/structured effects, missingness,
weights, offsets, REML, `rho12`, Arc D, public inference, or release claims.
