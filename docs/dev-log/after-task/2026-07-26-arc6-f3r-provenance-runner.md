# After-task report — Arc 6 F3R provenance runner

## 1. Goal

Prepare and test, without invoking, a private immutable runner for the one future F3 Bernoulli × ordinary-NB2 provenance smoke.

## 2. Implemented

F3R corrected F1M provenance, separated F3 provenance from F4 calibration, froze the execution packet, and added a developer-only runner with pure preflight and status-contract tests.

## 3a. Decisions and Rejected Alternatives

The runner uses a dedicated tool rather than extending the old Arc 6.1/6.2 smoke runner.  SHA-256 uses a required external `shasum` or `sha256sum` command rather than adding a package dependency.  The runner is committed before a future approval can pin its exact source.  Executing the runner, a local fit, a retry, and any public inference route were rejected as out of scope.

## 4. Files Touched

- `docs/dev-log/2026-07-26-arc6-association-f0-f2-preparation-receipt.md`
- `docs/dev-log/2026-07-26-arc6-f1m-deterministic-qualification-receipt.md`
- `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md`
- `tools/run-arc6-bernoulli-nbinom2-f3-provenance-smoke.R`
- `tests/testthat/test-arc6-f3-provenance-smoke-runner.R`
- this report, the F3R preflight receipt, and plan-vs-actual record.

## 5. Checks Run

The F3R runner test passed 47 expectations.  Focused `associate-pairs-staged-sandwich` and `associate-pairs-bernoulli-nb2` tests passed.  `git diff --check` passed.

## 6. Tests of the Tests

The focused test rejects split-form CLI arguments, stage/status combinations not in the frozen allowlist, an existing output directory, a preflight SHA failure, and non-ok rectangle rows.  It also verifies that sourcing the runner does not execute its main function and that the frozen RNG helper restores the caller state.

## 7a. Issue Ledger

Resolved: F1M receipt SHA ambiguity; F3/F4 comparator ambiguity; missing F3 status/artifact contract; lack of a SHA-pinnable runner.  Deferred: the actual one-attempt F3 smoke, F4 calibration, F5 product decision, and all public exposure.

## 8. Consistency Audit

The runner is private, uses existing private helper names only, and is isolated from the legacy generic Arc 6 smoke tool.  No exported R function, NAMESPACE entry, capability ledger, public documentation, Arc D/F5 surface, or direct `rho12` route changed.

## 9. What Did Not Go Smoothly

The initial runner draft accepted a non-frozen CLI form, had an unreliable direct-execution guard, and did not fully reflect the receipt layout.  Independent review caught these before any invocation; the runner and tests were corrected.

## 10. Known Residuals

The runner has not been executed.  Its real fit/provenance path, artifact writing under a live attempt, and private sandwich availability remain unverified until separate owner approval.

## 11. Team Learning

For a one-attempt provenance smoke, the runner itself must be committed before the owner can approve a SHA-pinned execution.  A status contract needs stage-specific allowed outcomes, not merely a generic success/failure column.

## 12. Cross-Product Coverage

This work covers ✓ only a private fixed-effect complete-pair Bernoulli × ordinary-NB2 F3 provenance runner.  It does NOT cover ✗ any uncertainty-validity, interval, recovery, coverage, F4 compute, F5/public API, association slope, other pair, random-effect, missingness, weight, offset, REML, or direct `biv_lognormal()` `rho12` surface.
