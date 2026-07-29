# After-task: Arc 6 F4R completion review

## 1. Goal

Close the authorized F4R private validation campaign by checking every retained
receipt and deciding the predeclared high-information alpha interval screen.

## 2. Implemented

The closeout preserves a complete, auditable review of the authorized F4R
retained-attempt campaign; it does not change package behavior or expose a
public association-inference interface.

## 3a. Decisions and Rejected Alternatives

Accepted the predeclared private alpha interval-feasibility screen because all
16 frozen high-information cells meet its retained-attempt gates. Rejected a
public promotion, generic `rho12` claim, eta claim, or F5 implementation: each
needs a separately approved product and validation arc.

## 4. Files Touched

- `docs/dev-log/2026-07-29-arc6-f4r-completion-review.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- Read-only Rorqual ControlMaster inspection found 16 `RUN-COMPLETE.txt` and 16
  `all-attempts.tsv` files under the authorized durable results root.
- The completion review records 16,000 retained attempts, 15,978 alpha point /
  Godambe / interval-available attempts, and 22 retained boundary-unresolved
  attempts.
- All 16 frozen F4R cells pass the alpha bias, availability, SE/SD, and coverage
  gates. The result is a narrow private PASS.
- `git diff --check` passed for the closeout documentation.

## 6. Tests of the Tests

No package test was added. This task audits retained simulation output rather
than introducing a new implementation. The all-attempt denominator and the
explicit unavailable records are recorded to prevent a success-only summary.

## 7a. Issue Ledger

No issue was opened or closed: F4R is a completed private evidence screen, while
F5 is still an unapproved separate product decision.

## 8. Consistency Audit

The new review explicitly distinguishes F4R from the failed lower-information
F4 campaign and from future F5 public API work. No package source, formula
grammar, capability ledger, user-facing vignette, or pkgdown artifact changed.

## 9. What Did Not Go Smoothly

F4R alpha records can retain ancillary `eta_delta_unavailable` metadata. The
review uses alpha availability fields, as preregistered, rather than treating
that ancillary eta status as an alpha inference failure.

## 10. Known Residuals

F4R covers only the frozen high-information intercept grid. A separately
approved F5 may define and test an alpha-only public surface; broader family,
design, and eta inference questions remain separate arcs.

## 11. Team Learning

Future completion packets should retain a machine-readable summary,
post-processing/bootstrap seed, and source/library-build manifest alongside
per-shard receipts.

## 12. Cross-Product Coverage

The review links the F4R design and preserves the F5 boundary. No public docs
are changed because none may imply public association inference yet.

This arc does NOT cover eta intervals, lower-information designs, slopes,
random effects, other family pairs, generic `rho12` inference, public API
eligibility, or public documentation. It also does NOT alter ML/REML routing,
missing-data behavior, aggregation, formula grammar, capability-ledger counts,
or any provider-specific implementation.
