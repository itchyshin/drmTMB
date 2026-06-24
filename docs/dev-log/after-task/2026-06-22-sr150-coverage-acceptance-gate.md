# After Task: SR150 Coverage Acceptance Gate

## Goal

Make the interval-coverage blocker executable instead of prose-only, while
leaving SR150 blocked until calibrated q1, q2, and q4 grids exist.

## Implemented

- Added `phase18_structured_re_ademp_calibration_gate()` to turn replicate rows
  and the MCSE policy into a row-level gate decision.
- Added the scaffold output
  `structured-re-ademp-calibration-gate.csv` so future ADEMP grid artifacts
  carry a reusable acceptance decision.
- Added `structured-re-coverage-acceptance-gate.tsv` with q1, q2, q4, and
  integrated SR150 gate rows.

## Mathematical Contract

Coverage remains a binomial proportion with Monte Carlo standard error
`sqrt(p * (1 - p) / n)`. The gate is only eligible for review when the planned
replicate count is met, interval rows have been evaluated, and the MCSE is not
above the target. Failed fits and unavailable intervals stay in the denominator.

## Files Changed

- `inst/sim/R/sim_structured_re_ademp.R`
- `inst/sim/run/sim_write_structured_re_ademp_scaffold.R`
- `docs/dev-log/dashboard/structured-re-coverage-acceptance-gate.tsv`
- `tests/testthat/test-structured-re-ademp-scaffold.R`

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-ademp-scaffold|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
```

Results:

- Focused R tests passed with 464 assertions, 0 failures, 0 warnings, and
  0 skips.
- `python3 tools/validate-mission-control.py` passed with 4
  coverage-acceptance gate rows, 36 closeout-package rows, and 52
  executable-evidence rows.

## Tests Of The Tests

The scaffold test now covers both a blocked undersized pilot and a tiny synthetic
case that becomes `eligible_for_review` only because every interval row is
finite, the planned replicate count is met, and MCSE reaches the requested
threshold.

## Consistency Audit

The gate is deliberately stricter than the diagnostic pilot. It does not
reinterpret the q1 pilot's one finite interval as reliability evidence, and it
keeps q2/q4 blocked when finite intervals or convergence are missing.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is local mission-control evidence, not a
public reply or support announcement.

## What Did Not Go Smoothly

The previous dashboard state already contained several coverage-policy rows, so
the main risk was duplicating the same policy text. The new gate is limited to
the SR150 acceptance decision and uses the existing pilot tables as inputs.

## Team Learning

Curie and Fisher should review coverage work through executable gate rows, not
through narrative summaries alone. Rose should keep the claim boundary on every
coverage row until calibrated grids replace diagnostic pilots.

## Known Limitations

SR150 is still blocked. The gate is ready, but calibrated q1/q2/q4 grids have
not run, q2 bridge parity is still unavailable, and q4 finite-interval behavior
still needs diagnosis.

## Next Actions

Run the focused tests and validator, then use the gate output when scaling the
diagnostic pilots into calibrated grids.
