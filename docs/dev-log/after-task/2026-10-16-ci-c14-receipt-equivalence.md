# 2026-10-16: CI now runs the C14/C17 receipt-equivalence check (#1538)

Reader: the maintainer reviewing the PR that refs #1538.

## Problem

The "Validate generated capability ledger" step in
`.github/workflows/R-CMD-check.yaml` ran `capability_ledger.py --check` but not
`--check-c14-receipt-equivalence`. `--check` does not compare C14/C17 receipts
with current source, so a stale receipt of the #1513 kind could merge green.

## Change

- Added `python3 tools/capability_ledger.py --check-c14-receipt-equivalence` to
  that step, directly after `--check`.
- Added `tools/tests/test_ci_wires_c14_receipt_equivalence.py`, a stdlib-only
  forcing test that reads the workflow and fails when the command is absent
  from the step (a comment does not count). It is itself run by the step.

No change to `src/drmTMB.cpp`, `R/drmTMB.R`, `R/methods.R`,
`R/mi-weights.R`, or the C17 capability ledger. The check passes on current
main (3 eligible, 7 source-different retained receipts; C17 PASS), so no
receipt refresh was needed.

## Evidence

- The forcing test fails on the base commit `ca3ddefa5` (run alone via a
  throwaway branch) and passes with the workflow change.
- The Python tools tests wired into the step pass locally.

## Not run locally

`devtools::document()` and the R test suite could not run in the authoring
container: CRAN was unreachable and roxygen2, TMB and testthat were not
installed. The change touches no roxygen or R code, so `document()` has no
output to commit; the R suite is left to the PR's CI.
