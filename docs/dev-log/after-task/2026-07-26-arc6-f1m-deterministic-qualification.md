# After-task report — Arc 6 F1M deterministic qualification

## 1. Goal

Complete the private F1 deterministic matrix for the fixed-effect complete-pair Bernoulli × ordinary-NB2 staged-alpha candidate and, only if it passed, prepare an F3 approval packet without running F3.

## 2. Implemented

F1E had independently qualified the interior and two `|a|=4` tail controls.  F1M added the eta-zero, moderate-sign, response-order, and positive near-boundary fixtures.  The focused staged-sandwich harness gained an independent bounded-CDF-scale zero-count oracle, coordinate-level ladder checks, and explicit retained F1 aggregation taxonomy.  A private F1 receipt and a draft-only F3 packet were added.

## 3a. Decisions and Rejected Alternatives

For NB2 zero, the oracle preserves the true `-Inf` latent lower endpoint and integrates on the bounded CDF scale.  A finite-endpoint proxy, production finite-difference reuse, tolerance relaxation, and production-status mutation were rejected.  Finite cases require two adjacent analytic-node ladder comparisons before frozen production-versus-oracle derivative tolerances are considered.

## 4. Files Touched

- `tests/testthat/test-associate-pairs-staged-sandwich.R`
- `docs/dev-log/2026-07-26-arc6-association-f0-f2-preparation-receipt.md`
- `docs/dev-log/2026-07-26-arc6-f1m-deterministic-qualification-receipt.md`
- `docs/dev-log/2026-07-26-arc6-f3-approval-packet.md`
- `docs/dev-log/after-task/2026-07-26-arc6-f1m-deterministic-qualification.md`
- `docs/dev-log/plan-actual/2026-07-26-arc6-f1m-deterministic-qualification.md`

## 5. Checks Run

The focused Bernoulli-NB2 and staged-sandwich tests passed, as did `git diff --check` and the canonical after-task structure check.  The `a=-4` fixture retained its pinned Genz point agreement, while `a=-7` retained a valid fail-closed unavailable outcome.

## 6. Tests of the Tests

The fixture aggregation test exercises every retained failure-taxonomy branch with synthetic failing evidence, while the live matrix exercises finite qualification, response-order transformation, the `-7` unavailable control, invalid endpoint, and forced quadrature-error propagation.  This separates a passing production row from a qualified independent derivative result.

## 7a. Issue Ledger

F1D remains retained negative evidence.  The zero-count oracle endpoint issue is resolved test-only by the bounded-CDF integration formulation.  F3 remains deferred pending a fresh written owner approval.

## 8. Consistency Audit

Noether, Fisher, and Rose each returned `F1_PASS`.  A fresh three-reviewer D-43-style panel also returned three `F1_PASS` verdicts, limited to the deterministic private gate.  The source-neighbourhood sweep found no production-kernel or public-surface change.

## 9. What Did Not Go Smoothly

The repository-local path for the after-task checker was absent; the canonical validator resides in the Shinichi repository and was used instead.  This was a tooling-path correction, not a package failure.

## 10. Known Residuals

The deterministic pass does not validate a full-refit provenance route, sandwich uncertainty, or intervals.  The F3 packet deliberately contains no runner and no authorization.

## 11. Team Learning

For discrete zero-count latent rectangles, a bounded CDF-scale integral can retain the mathematically correct infinite latent endpoint while supporting an independent moving-endpoint derivative check.  Preserve runtime failure semantics and classify test-only evidence separately.

## 12. Cross-Product Coverage

This work covers ✓ only the private fixed-effect, complete-pair Bernoulli × ordinary-NB2 intercept-only staged-alpha deterministic kernel/derivative matrix.  It does NOT cover ✗ sandwich-SE validity, intervals, recovery, coverage, public readiness, F3 provenance, F4 calibration, or any route outside that exact candidate.
