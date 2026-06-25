# After Task: Count Slope Native Fixture Status

## 1. Goal

Bank native-only deterministic fixture status for ordinary Poisson/NB2 q1
structured `mu` intercept-plus-one-slope cells in `phylo()`, fixed-covariance
`spatial()`, `animal()`, and `relmat()`.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-count-slope-native-fixture-status.tsv`
  with eight exact native fixture rows.
- Updated
  `docs/dev-log/dashboard/structured-re-count-slope-fixture-recovery-contract.tsv`
  so `fixture_contract_status` is now `native_fixture_banked` and
  `recovery_contract_status` remains `designed_not_run`.
- Added mission-control validation for the new sidecar, including row count,
  schema, family/provider identity, matrix slot, coefficient order, evidence
  URLs, conservative claim boundaries, and links to the fixture/recovery
  contract plus q-series support-cell rows.
- Added a focused R dashboard contract test that keeps native fixture status
  separate from bridge parity, calibrated recovery, intervals, coverage, q2/q4,
  REML, AI-REML, public support, labelled/multiple count slopes, structured
  count scale routes, and zero-inflated structured effects.
- Updated the dashboard README, q-series completion map, and check log.

## 3a. Decisions and Rejected Alternatives

- Treated the existing deterministic seeded native TMB tests in
  `tests/testthat/test-count-structured-mu.R` as native fixture evidence, but
  did not rename that evidence as bridge parity. Count bridge support is still
  unsupported.
- Rejected moving the q-series support-cell `bridge_status` or
  `interval_status`. This slice adds no R-to-Julia payload, no direct DRM.jl
  parity, no intervals, and no coverage denominator.
- Kept calibrated recovery as `designed_not_run`. The next real inference
  slice should run a reviewed recovery grid, potentially on Totoro or DRAC
  after race-safety review.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-fixture-recovery-contract.tsv`
- `docs/dev-log/dashboard/structured-re-count-slope-native-fixture-status.tsv`
- `docs/dev-log/after-task/2026-06-25-count-slope-native-fixture-status.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `air format tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed with 86 structured RE
  q-series cells, 8 structured RE count-slope fixture/recovery contract rows,
  and 8 structured RE count-slope native-fixture rows.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-25-count-slope-native-fixture-status.md')"`
  passed.
- `gh issue list --repo itchyshin/drmTMB --search "count structured mu native fixture" --limit 20 --json number,title,state,url,labels`
  returned `[]`.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  could not run because `devtools` is absent from the clean local R library.
  Non-vanilla startup points arm64 R 4.6 at an old
  `x86_64-pc-linux-gnu-library/4.4` library.

## 6. Tests of the Tests

The new R dashboard contract reads
`structured-re-count-slope-native-fixture-status.tsv`, verifies the exact
eight provider/family rows, checks `native_fixture_banked` status, and then
joins the rows back to both
`structured-re-count-slope-fixture-recovery-contract.tsv` and
`structured-re-q-series-support-cells.tsv`. It asserts that q-series fit and
extractor status remain point-fit/extractor-ready, while bridge and interval
status stay unsupported and coverage remains planned.

The Python validator independently checks the same fields and requires claim
boundaries to name native fixture evidence, bridge parity, calibrated recovery,
coverage, q2, q4, REML, AI-REML, public support, and broad bridge support.
That means a future status promotion must change the exact row and its
evidence gate deliberately.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --search "count structured mu native fixture" --limit 20 --json number,title,state,url,labels`
returned no matching issues. No issue was opened because this is a narrow
stacked-PR evidence-status slice tied to the q-series ledger.

## 8. Consistency Audit

- Checked the existing count one-slope runtime tests in
  `tests/testthat/test-count-structured-mu.R`; they provide deterministic
  seeded native point-fit/extractor evidence for the eight ordinary count
  one-slope cells.
- Updated the fixture/recovery contract and added a native fixture status
  sidecar instead of changing the q-series rows to bridge parity.
- Updated `docs/dev-log/dashboard/README.md` and
  `docs/design/218-structured-q-series-completion-map.md` so native fixture
  status is visible but bounded.
- Kept NEWS, roxygen, examples, and formula grammar unchanged because no
  runtime behavior or user-facing API changed.

## 9. What Did Not Go Smoothly

The main subtlety was terminology. Existing Gaussian fixture sidecars often
mean native/direct/R-via-Julia bridge parity; this count slice cannot borrow
that meaning because count bridge support is unsupported. The sidecar therefore
uses `native_fixture_banked` and keeps bridge parity separate.

## 10. Known Residuals

- Calibrated recovery diagnostics remain `designed_not_run`.
- Bridge parity, intervals, coverage, q2/q4 count covariance, REML, AI-REML,
  public support, labelled or multiple count slopes, structured count scale
  routes, zero-inflated structured effects, and broad bridge support remain
  unsupported or planned.
- Totoro/DRAC execution remains unsubmitted pending a later race-safety and
  recovery-design review.

## 11. Team Learning

Do not reuse "fixture parity" as a vague status label. For non-Gaussian count
cells, native deterministic fixture evidence and bridge parity are different
rungs, and the dashboard should name them separately before any recovery or
coverage work starts.
