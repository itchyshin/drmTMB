# Q-Series Support-Cell Map

## 1. Goal

Make the exact q-series support cell the planning and evidence unit for
structured random-effect completion before adding new runtime model cells.

## 2. Implemented

- Added `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` with
  69 exact cells across ordinary comparators, `phylo()`, `spatial()`,
  `animal()`, `relmat()`, `phylo_interaction()`, count q1 routes, q2 fixtures,
  q4 point rows, planned q6/q8 rows, explicit residual-scale slope gaps, and
  direct-SD targets.
- Added `docs/design/218-structured-q-series-completion-map.md` to define the
  schema, evidence ladder, authority rule, current support boundary, why the
  previous approach drifted, and the recommended implementation order.
- Wired the table into the mission-control validator and dashboard README.
- Added a focused R contract test so the package-side conversion checks also
  require the q-series support-cell schema and guardrails.
- Corrected drift around q4 point evidence in
  `docs/design/216-structured-random-effect-finish-100-slices.md` and the
  SR132 next-gate text in `structured-re-finish-100-slices.tsv`.
- Tightened one stale q8 residual-scale error hint and the NEWS wording for the
  route-specific experimental q4 Julia-bridge REML diagnostic.

## 3a. Decisions and Rejected Alternatives

This slice deliberately avoided coding new runtime q-cells. The team decision
was that new runtime support should come after exact rows, neutral endpoint
metadata, provider contracts, and row-specific tests are in place.

The support map separates `q1+q1` from labelled q2, q2 fixtures from broad
bridge support, q4 point parity from intervals or coverage, ordinary q8
diagnostics from structured q8, and direct SD profiles from derived-correlation
interval reliability.

## 4. Files Touched

- `NEWS.md`
- `R/drmTMB.R`
- `docs/design/216-structured-random-effect-finish-100-slices.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-finish-100-slices.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

This after-task report sits on top of the still-dirty q2 helper correction
files from the same local review stack:

- `inst/sim/R/sim_structured_re_bridge_fixtures.R`
- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `docs/dev-log/after-task/2026-06-23-q2-helper-dashboard-drift-correction.md`

## 5. Checks Run

- `air format R/drmTMB.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed; removed
  `tools/__pycache__`.
- `python3 tools/validate-mission-control.py` passed and reported 69
  structured RE q-series cells.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1470 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"`
  passed with 254 assertions.
- `git diff --check` passed.

## 6. Tests of the Tests

The first run of the new R contract test failed because `anyDuplicated()`
returns integer `0`, not logical `FALSE`. The expectation was corrected to
`expect_equal(anyDuplicated(qseries$cell_id), 0L)`, and the focused test then
passed. The mission-control validator accepted the new TSV on its first run,
including required rows, status vocabulary, evidence paths, q4 coverage guards,
and structured q8 planned-status guards.

## 7a. Issue Ledger

No GitHub issue, PR body, PR comment, or Ayumi-facing reply was created or
updated. PR #638 remains draft. No files were staged or committed.

## 8. Consistency Audit

The new q-series table is now the exact-cell authority for completion planning.
The older `structured-re-balance-matrix.tsv` remains the coarse support matrix.
Design 216 now agrees with the q4 point-parity sidecars: SR131, SR133, and
SR140 are banked for point evidence only, while q4 interval reliability,
coverage, q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML,
non-Gaussian AI-REML, and broad bridge support remain unpromoted.

## 9. What Did Not Go Smoothly

The table itself validated cleanly, but the R-side duplicate-ID assertion used
the wrong return type on the first run. That was fixed before recording the
passing checks.

## 10. Known Residuals

The new map is not a runtime implementation. The next code slice should start
with neutral structured metadata wrappers and provider contract tests before
adding residual-scale slope, structured q4 slope, structured q6, or structured
q8 support.

The dirty DRM.jl worktree for PR #297 remains unreconciled and should not be
treated as banked.

## 11. Team Learning

Future structured random-effect work should begin with one support-cell row and
finish by updating code, tests, dashboard, docs, check-log, and PR wording
against that row. That prevents high-value evidence from spreading across the
repo faster than the public truth can track it.
