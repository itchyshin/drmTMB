## 1. Goal

Record the exact dependency state between drmTMB relmat `Q` payload transport
and the active DRM.jl q2 known-precision provider stack, without promoting
draft upstream evidence into R bridge support.

## 2. Implemented

- Added a generated three-row dashboard sidecar,
  `docs/dev-log/dashboard/structured-re-relmat-q-drmjl-provider-readiness.tsv`.
- Added `phase18_structured_re_relmat_q_drmjl_provider_readiness()` and the
  writer script
  `tools/run-structured-re-relmat-q-drmjl-provider-readiness.R`.
- Wired the new sidecar into `tools/validate-mission-control.py`, including
  exact row IDs, current upstream heads, draft/CLEAN/manual-green statuses, and
  conservative claim-boundary checks.
- Added a dashboard contract test for the new sidecar.
- Updated the q-series completion map, dashboard README, and check log.

## 3a. Decisions and Rejected Alternatives

The sidecar has three rows, not six relmat support-cell rows. DRM.jl #299 and
#300 are q2 known-precision upstream dependencies, so mapping them directly to
all six relmat K/Q one-slope cells would overstate the evidence. I also did not
implement R-side exact `Q` transport in this slice because the upstream provider
API is still draft/stacked.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-26-relmat-q-drmjl-provider-readiness.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-relmat-q-drmjl-provider-readiness.tsv`
- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/run-structured-re-relmat-q-drmjl-provider-readiness.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-relmat-q-drmjl-provider-readiness.R`
  passed and wrote 3 rows.
- `air format inst/sim/R/sim_structured_re_bridge_fixtures.R tools/run-structured-re-relmat-q-drmjl-provider-readiness.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 3 relmat `Q`
  DRM.jl provider-readiness rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  did not run because this app R library has no `devtools`.
- `Rscript --vanilla -e "testthat::test_file('tests/testthat/test-structured-re-conversion-contracts.R', stop_on_failure = TRUE)"`
  did not run because this app R library has no `testthat`.
- A base-R generator/TSV round-trip check passed for row count, names,
  readiness IDs, head OIDs, and draft claim boundaries.
- `git diff --check` passed.
- `Rscript --vanilla -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-26-relmat-q-drmjl-provider-readiness.md')"`
  passed.

## 6. Tests of the Tests

The mission-control validator now fails closed if the readiness sidecar loses a
row, changes a row ID, changes the draft/CLEAN/manual-green state, points to a
nonexistent evidence reference, or drops required boundary wording such as
`not merged`, `not R-via-Julia relmat Q transport`, `not six-cell drmTMB
relmat`, `not implementation`, `broad bridge support`, `coverage`, `REML`, or
`AI-REML`. The new testthat contract mirrors those expectations, but could not
be executed in this local R library because `testthat` is unavailable.

## 7a. Issue Ledger

- Fixed: the dependency between drmTMB relmat `Q` transport and DRM.jl #299/#300
  is now visible as a checked dashboard sidecar.
- Deferred: exact R-side `Q` precision payload transport remains blocked until
  the upstream DRM.jl draft stack is accepted and then matched in R bridge code.
- Deferred: no interval, coverage, REML, AI-REML, public support, DRAC/Totoro,
  or Ayumi-facing action moved in this slice.

## 8. Consistency Audit

I checked the current q-series support-cell map, relmat K/Q native parity
ledger, payload marshalling gate, payload contract review, and live PR state.
The audit confirmed that relmat K/Q native one-slope evidence and sigma
one-slope fixture evidence are already banked, while direct DRM.jl `Q`,
R-via-Julia `Q`, and broad R bridge `Q` support remain unsupported.

## 9. What Did Not Go Smoothly

The local R library in this app session does not include `devtools` or
`testthat`, so package-level targeted tests could not run locally. A first
base-R sanity command also failed because shell expansion stripped `$` from
`x$review_state`; rerunning with single-quoted R code fixed that.

## 10. Known Residuals

The new sidecar is a static dependency snapshot. If DRM.jl #299 or #300 are
rebased, merged, or retargeted, the sidecar must be regenerated from current
evidence. Exact relmat `Q` payload transport is still unimplemented in drmTMB.
No q4 interval reliability, q4 coverage, q4 REML, native-TMB q4 REML, q4
AI-REML, HSquared AI-REML, non-Gaussian REML, broad bridge support, public
support, SR150 readiness, DRAC/Totoro execution, or Ayumi-facing reply is
claimed.

## 11. Team Learning

When an upstream implementation is draft-green but not merged, bank a
dependency-readiness row before coding the downstream bridge. It preserves the
useful evidence while preventing q-neighbour and route-neighbour promotion.
