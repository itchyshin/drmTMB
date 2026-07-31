# AOI-3R6 plan-only additive long-tail profile

## 1. Goal

Profile the retained AOI-3 additive long-tail records and write a revised,
fail-closed local-smoke design without running seeds, submitting DRAC work, or
changing public uncertainty.

## 2. Implemented

Added the R6 plan-only record.  It distinguishes retained completed private
sandwich paths from R5's process timeout, identifies the unmeasured phase
boundary, and specifies a future outer-only timing/provenance smoke.

## 3a. Decisions and Rejected Alternatives

The 180-second timeout is not treated as an optimizer failure, a sandwich
failure, or evidence for public uncertainty.  R6 rejects silently widening a
run, reusing old seeds, reducing the formula set, or beginning full-refit/DRAC
calibration.  The proposed 300-second cap is operational and awaits a separate
authorization.

## 4. Files Touched

- `docs/dev-log/2026-07-31-aoi3r6-additive-long-tail-profile-and-revised-smoke-design.md`
- `docs/dev-log/after-task/2026-07-31-aoi3r6-plan-only-profile.md`

No retained simulation artifacts were edited or staged.

## 5. Checks Run

- Read R4/R5 retained attempt and supervisor-event records.
- Read the private association-fit and sandwich call path.
- Markdown closeout checker — PASS.
- `git diff --check` — PASS.

## 6. Tests of the Tests

No executable behavior changed.  The proposed R7A contract explicitly makes
phase event presence and provenance independently checkable before it can be
considered complete.

## 7a. Issue Ledger

- AOI-2 point-recovery HOLD — unchanged.
- AOI-3 uncertainty calibration — not started.
- R5 execution/completeness — retained invalid result.
- R7A timing/provenance smoke — proposed only; awaits authorization.

## 8. Consistency Audit

The plan preserves the Bernoulli x ordinary-NB2-only private diagnostic scope.
It makes no change to public APIs, documentation, capability ledgers, Lane B,
Arc D, or foreign Association work.

## 9. What Did Not Go Smoothly

R5's process supervisor correctly retained the timeout but did not identify the
child phase in which it occurred.  R6 records that observability gap rather
than guessing its cause.

## 10. Known Residuals

The long-tail mechanism remains unmeasured until a separately approved,
instrumented fresh-seed R7A run.  Neither an operationally complete R7A nor a
private sandwich `ok` result establishes uncertainty calibration.

## 11. Team Learning

Memory receipt: a hard cap is useful only when the retained payload identifies
what work the child completed before the cap.  Phase observability must precede
interpretation of a timeout.  No durable brain-memory update is warranted.

Golden Set: not in scope; this is an internal execution-design record.

## 12. Cross-Product Coverage

This work covers a private plan for AOI-3 execution observability only.  It
does NOT cover point recovery, sandwich validity, covariance/SE or interval
calibration, DRAC, `vcov()`, `confint()`, public uncertainty, other family
pairs, random/structured association effects, missingness, weights, offsets,
REML, capability promotion, or public inference.
