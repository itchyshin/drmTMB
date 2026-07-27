# After-task report — Arc 6 F4 preregistration review

## 1. Goal

Turn the owner's narrowly approved documentation-only F4 review into a frozen
Bernoulli x ordinary-NB2, intercept-only preregistration without executing F4.

## 2. Implemented

Added `docs/dev-log/2026-07-27-arc6-f4-preregistration-review.md`, which fixes
the 24-cell DGP grid, 24,000-attempt cost, nested denominators, alpha-Wald
candidate interval, calibration targets, MCSE reporting, and DRAC recommendation.

## 3a. Decisions and Rejected Alternatives

F4 evaluates the alpha-scale Godambe Wald interval only. Bootstrap percentile
intervals, association slopes, other pairs, and the stopped 24 x 200 x 399
shards remain excluded. DRAC is recommended as a future job-array host; no host
was contacted.

## 4. Files Touched

- `docs/dev-log/2026-07-27-arc6-f4-preregistration-review.md`
- `docs/dev-log/after-task/2026-07-27-arc6-f4-preregistration-review.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

Confirmed the F3 branch was clean before this edit, read the F3 success receipt
and F0–F2 denominator contract, verified the two pinned blobs at the F3 source
SHA, and passed `git diff --check` after the documentation edit.

## 6. Tests of the Tests

No executable code or harness changed, so no package tests were appropriate.
The review preserves the existing fail-closed source/fixture, status-precedence,
and all-attempt requirements rather than inventing a second contract.

## 7a. Issue Ledger

Resolved: the approved documentation-only F4 preregistration review. Deferred:
any harness, benchmark, host connection, compute approval, F4 execution,
calibration result, public inference, and F5 product decision.

## 8. Consistency Audit

The grid is intercept-only in association while retaining fixed margin slopes;
the 24 cells equal 3 sample sizes x 2 prevalences x 2 dispersions x 2 alpha
values. Its 24,000 cost is 24 x 1,000 outer attempts with no inner refits.

## 9. What Did Not Go Smoothly

The F3 smoke provides no elapsed-time benchmark, so a wall-clock request would
be false precision. The future execution approval must cost concrete DRAC or
Totoro resources from a permitted benchmark/runbook.

## 10. Known Residuals

F4 has not run. No claim about recovery, SE calibration, interval validity,
coverage, availability, or public readiness is supported.

## 11. Team Learning

A finite all-attempt campaign needs the interval method, primary denominator,
availability rule, and source quarantine fixed before any compute authorization.

## 12. Cross-Product Coverage

This documentation covers only fixed-effect, complete-pair Bernoulli x
ordinary-NB2 `association = ~ 1`; it does not transfer to other pair classes,
association slopes, random effects, missingness, weights, offsets, REML, or
direct `rho12` models.
