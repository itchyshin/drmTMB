# After Task: q2-plus-q2 sigma rejection contract

## 1. Goal

Bank exact rejection evidence for the scale-only structured `sigma1+sigma2`
q2-plus-q2 sibling cells in fixed-covariance `spatial()`, A-matrix `animal()`,
and `relmat()`.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-plus-q2-sigma-rejection-contract.tsv`
with one row per rejected provider. Each row records the support-cell id,
formula cell, provider, q-dimension, endpoint, expected pre-optimization error
pattern, status fields, evidence file, claim boundary, and next gate.

Updated the three corresponding rows in
`docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` to point at
the new rejection contract. The rows remain `unsupported` for fit, extractor,
bridge, interval, and coverage status.

Mission-control validation now checks the sidecar schema, provider set, linked
support-cell statuses, expected error messages, and forbidden-claim boundary.
The structured RE conversion-contract tests now check the same dashboard
contract from R.

## 3a. Decisions and Rejected Alternatives

I did not add parser support or runtime support for these cells. The existing
behavior is a deliberate pre-optimization rejection:

- `spatial()` rejects with `Partial spatial location-scale blocks`.
- `animal()` rejects with `Partial animal-model location-scale blocks`.
- `relmat()` rejects with `Partial relmat location-scale blocks`.

The useful slice was to make that rejection the authoritative cell evidence, not
to infer support from q2 location fixtures, q4 all-four rows, or relmat K/Q
runtime parity.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-plus-q2-sigma-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-q2-plus-q2-sigma-rejection-contract.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported three
  structured RE q2-plus-q2 sigma rejection rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-q2-rejections|structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,579 assertions, 0 failures, 0 warnings, and 0 skips.

## 6. Tests of the Tests

Changing any provider id, support-cell id, expected error message, unsupported
status, evidence path, or claim-boundary phrase should fail both
`tools/validate-mission-control.py` and
`tests/testthat/test-structured-re-conversion-contracts.R`.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This is a narrow support-cell evidence
slice inside the existing q-series completion lane.

## 8. Consistency Audit

The support-cell table, dashboard README, design note, validator, and focused
test now agree: the three scale-only q2-plus-q2 rows are exact rejection cells.
They are not parser-ready, point-fit, bridge, interval, coverage, REML,
AI-REML, public-support, q4, or q8 evidence.

## 9. What Did Not Go Smoothly

Mission-control initially failed on a capitalization mismatch in the validator
phrase check for the spatial claim boundary. The dashboard wording was correct,
so the validator was updated to expect the exact phrase.

## 10. Known Residuals

A supported scale-side structured route still needs a separate design,
implementation, and tests before any of these rows can move beyond
`unsupported`.

## 11. Team Learning

Unsupported cells need their own evidence rows. Otherwise adjacent q2/q4
successes make it too easy to forget that a half-cell is still deliberately
rejected.
