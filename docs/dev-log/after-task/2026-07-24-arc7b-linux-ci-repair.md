# After Task: Arc 7B Linux CI repair

## 1. Goal

Repair the two Ubuntu R-CMD-check failures on PR #830 without changing the Arc
7B evidence boundary, merging PR #828, or submitting DRAC work.

## 2. Implemented

The Arc 7B runner and DGP tests now source simulation files through the
installed `drmTMB` package. The generic power-table assembler backfills Wald
intervals only for rows whose interval status is `not_requested` (or absent)
and whose endpoints are missing. Explicitly failed or non-finite intervals
remain unchanged. The first-wave smoke test now records that the meta-V grid
intentionally has no legacy Wald-coverage artifact: it contributes 77 legacy
Wald rows rather than the former 86, and publishes its all-attempt and
conditional-finite interval tables separately.

## 3a. Decisions and Rejected Alternatives

This repair does not change the known-`V` likelihood, the L/LS/LSS/LSSS/DH
model contract, or the dense-LSS profile result. It only restores ordinary
Wald-interval handling for fixed-effect power rows while preserving explicit
interval failure evidence.

## 4. Files Touched

Changed `inst/sim/R/sim_power.R`, the Arc 7B runner/DGP and first-wave smoke
tests, and the generic power-engine test. The tests now guard the distinction
between missing, not-requested intervals and explicitly failed intervals, and
between an intentionally absent legacy meta-V artifact and accidental loss.

## 5. Checks Run

The Arc 7B runner/DGP tests and the generic power-engine test passed locally.
The Arc 7B oracle/comparator/DGP test group also passed. The first-wave smoke
test is exercised by the Ubuntu R-CMD-check; its repaired expectation matches
the emitted 77-row legacy bundle and checks the meta-V missing-artifact
receipt. `git diff --check` passed. GitHub's Ubuntu R-CMD-check is pending
after this repair is pushed.

## 6. Tests of the Tests

The new power-engine fixture supplies two valid fixed-effect rows with
`not_requested` intervals and one explicitly failed row. It verifies that only
the first two receive Wald intervals and that the failed row stays unavailable.
The first-wave assertion separately verifies that meta-V no longer enters the
legacy Wald bundle and that the table-bundle receipt labels that omission as
`missing_artifact`.

## 8. Consistency Audit

The repair preserves the local sentinel's `nonfinite_interval` direct-SD
records. No capability tier, reader-facing claim, or DRAC decision changed.

## 7a. Issue Ledger

No issue was changed. This is a focused PR #830 CI repair, not a new feature
or a resolution of the Phase 18 or comparator trackers.

## 9. What Did Not Go Smoothly

The original runner and DGP tests happened to pass locally when their relative
paths were resolved from a source checkout, but failed in Linux package-check
layout. The new package-relative sourcing removes that layout dependency. The
next run also exposed a hard-coded legacy row count that predated the explicit
meta-V interval-artifact split.

## 11. Team Learning

Interval-aware summaries must not make a generic power helper assume every row
already has an interval. Status and endpoints must agree before a row counts
toward power or Type I error.

## 10. Known Residuals

This repair does not make dense LSS direct-SD profiles finite and does not
authorize coverage, DRAC, or capability promotion.

## 12. Cross-Product Coverage

The repair covers Phase 18 simulation plumbing and its power/runner tests. It
does NOT cover likelihood code, formula grammar, reader-facing documentation,
the capability ledger, REML, another engine, missing-data handling, or another
package. Push the repair to PR #830, wait for the Ubuntu R-CMD-check, and merge
only if the full required check succeeds with no review blocker.
