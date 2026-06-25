# After Task: Relmat K/Q One-Slope Native Parity Ledger

## 1. Goal

Make the existing relmat K/Q same-target runtime evidence visible as one
generated, mission-control-validated support-cell ledger before any relmat `Q`
bridge payload work.

## 2. Implemented

Added `structured-re-relmat-kq-one-slope-native-parity.tsv` with six native
R/TMB rows: q1 `mu`, q1 `sigma`, matched q1 `mu+sigma`, q2 `mu1+mu2`
slope-only, q4 location one-slope, and the q8-shaped all-four one-slope cell.
The new helper
`phase18_structured_re_relmat_kq_one_slope_native_parity_contract()` generates
the rows, and the new runner writes the dashboard sidecar.

## 3a. Decisions and Rejected Alternatives

Each row is a same-target native R/TMB parity contract for the exact formula
cell named in the sidecar. The `K` path uses a user covariance matrix, the `Q`
path uses a user precision matrix, and both remain point-fit runtime evidence
only.

I did not implement relmat Q bridge marshalling, direct DRM.jl Q export, or
R-via-Julia Q transport in this slice. I also did not promote intervals,
coverage, REML, AI-REML, public support, or broader q8 support. Those require
separate evidence gates.

## 4. Files Touched

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tools/run-structured-re-relmat-kq-one-slope-native-parity.R`
- `docs/dev-log/dashboard/structured-re-relmat-kq-one-slope-native-parity.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-relmat-kq-one-slope-native-parity.R`
  passed and wrote six rows.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported six relmat
  K/Q one-slope native parity rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures', stop_on_failure = TRUE)"`
  passed with 739 assertions, 0 failures, 0 warnings, and 0 skips.
- `git diff --check` passed after the implementation edits.

## 6. Tests of the Tests

The new test checks the exact six row IDs, support-cell IDs, dimension pattern,
input-scale labels, point-fit runtime statuses, unsupported `Q` bridge statuses,
planned interval and coverage statuses, and guard phrases for REML, AI-REML,
coverage, and bridge support. A first attempt to use
`testthat::test_file(..., filter = ...)` failed because this installed
`testthat::test_file()` does not accept `filter`; the package-loaded
`devtools::test()` run is the accepted evidence.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --state open --search "relmat K Q one-slope structured random effect" --limit 10 --json number,title,url,state`
returned no matching open issues. No issue was opened because this slice is a
stacked PR evidence-ledger update, not a new user-facing runtime feature.

## 8. Consistency Audit

The dashboard README now names the generated six-row ledger separately from the
existing one-row q4 location sidecar and the relmat Q payload-marshalling gate.
The q-series completion map records the same distinction in the relmat section
and in the banked-slice list. Mission-control validation links the new sidecar
to both `structured-re-q-series-support-cells.tsv` and
`structured-re-relmat-q-bridge-boundary.tsv`, so drift in cell IDs, endpoint
sets, slope classes, bridge statuses, or claim boundaries will fail validation.

## 9. What Did Not Go Smoothly

Running `air format .` reformatted unrelated R files. Those accidental changes
were reverted before continuing, leaving only the intended slice files changed.
The raw `testthat::test_file()` invocation also failed for harness reasons
before the equivalent package-loaded `devtools::test()` run passed.

## 10. Known Residuals

This slice does not implement relmat Q bridge payload marshalling, direct
DRM.jl Q export, R-via-Julia Q transport, broad R bridge support, interval
reliability, coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared
AI-REML, non-Gaussian REML, public support, broader q8 support, DRAC/Totoro
execution, or SR150 readiness.

## 11. Team Learning

Generated sidecars should be preferred for support-cell ledgers. The relmat Q
bridge-boundary sidecar already carried the right concept, but a generated
native parity companion makes the cross-cell evidence easier to validate and
harder to over-read as bridge support. Use the same pattern for the next
runtime/evidence cell after checking the support-cell ledger and validator
first.
