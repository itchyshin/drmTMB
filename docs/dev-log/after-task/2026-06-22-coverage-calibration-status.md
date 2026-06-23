# After Task: SR142-SR149 Coverage Calibration Status

Date: 2026-06-22

## Goal

Bank the coverage-calibration infrastructure rows after SR141 without claiming
that any q1, q2, or q4 coverage grid has passed.

## Changes

- Added `structured-re-coverage-calibration-status.tsv` for SR142-SR149.
- The rows now bank q1/q2/q4 diagnostic-pilot status, interval-method
  separation, bootstrap refit accounting fields, MCSE target policy, failure
  taxonomy, and a coverage-report template.
- The diagnostic pilot artifact is
  `docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/`.
  It reports q1 with three fit-target rows and one finite Wald interval, q2
  with six fit-target rows and zero finite intervals, and q4 with eight
  fit-target rows, zero converged rows, and zero finite intervals.
- The artifact points back to the existing ADEMP scaffold code and tests:
  `inst/sim/R/sim_structured_re_ademp.R`,
  `inst/sim/run/sim_write_structured_re_ademp_scaffold.R`, and
  `tests/testthat/test-structured-re-ademp-scaffold.R`.

## Evidence

Checks run:

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-ademp-scaffold|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/structured-re-coverage-calibration-status.tsv >/dev/null
```

Results:

- After the diagnostic-pilot status refresh,
  `structured-re-ademp-scaffold` and `structured-re-conversion-contracts`
  passed with 433 assertions, 0 failures, 0 warnings, and 0 skips.
- The conversion-contract tests now assert the pilot artifact totals:
  q1 has 3 target rows and 1 finite Wald interval, q2 has 6 target rows and
  0 finite intervals, and q4 has 8 target rows, 0 converged rows, and
  0 finite intervals.
- `tools/validate-mission-control.py` passed with 8 coverage-calibration rows,
  35 closeout-package rows, and 51 executable-evidence rows after the q4 audit
  closeout/evidence rows were added.
- `status.json` and `sweep.json` parsed as JSON, `tools/start-mission-control.sh`
  passed shell syntax validation, and `git diff --check` was clean.
- The live widget served build `r14`; direct fetches passed for
  `structured-re-coverage-calibration-status.tsv`,
  `structured-re-finish-100-slices.tsv`, `structured-re-closeout-package.tsv`,
  and `structured-re-executable-evidence.tsv`.
- One parallel fetch of the new TSV raced the `/tmp/drm-dashboard` copy and
  returned 404 before the refresh completed; the serial retry after the start
  script finished passed.

## Boundary

This banks diagnostic pilot, scaffold, policy, accounting, taxonomy, and
report-template evidence only. It does not run a calibrated coverage grid,
estimate reliable interval coverage, promote q2 bridge support, promote q4
parity, promote q4 REML, claim AI-REML, or change public bridge-support wording.

## Next Gate

Replace mock scaffold rows with row-specific q1, q2, and q4 DGP/fitter outputs
that report failed-fit denominators, finite-interval accounting, and MCSE.
