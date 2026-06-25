# After Task: Relmat Q1 Scale Fixture Parity

## 1. Goal

Close the smaller relmat q1 gap by moving the Gaussian `sigma` and matched
`mu+sigma` intercept cells from point-fit-only status to deterministic
fixture-parity status, without promoting Q precision bridge marshalling,
intervals, coverage, REML, AI-REML, or broad bridge support.

## 2. Implemented

Added a focused deterministic fixture test for q1 Gaussian `relmat()` scale-side
payloads in `tests/testthat/test-structured-re-bridge-fixtures.R`. The test
checks `sigma` and matched `mu_sigma` endpoints across `native_tmb`,
`direct_drmjl`, and `r_via_julia` fixture routes, with a K-matrix payload and
exact agreement in coefficient and log-likelihood fixture values.

Added two rows to
`docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`:

- `q1_sigma_relmat_gaussian_fixture`
- `q1_mu_sigma_relmat_gaussian_fixture`

Updated the q-series authority rows for `qseries_relmat_q1_sigma_intercept` and
`qseries_relmat_q1_mu_sigma_intercept` so `bridge_status = fixture_parity`,
`route = native_direct_bridge_fixture`, and `denominator_policy =
fixture_not_coverage`. Both rows still keep intervals and coverage planned.

## 3a. Decisions and Rejected Alternatives

I kept the new fixture rows K-matrix scoped. The native runtime tests already
exercise K/Q point-fit and extractor behavior, but this slice does not add live
Q precision bridge marshalling. That distinction matters because the broader Q
bridge route remains a separate design and validation problem.

I did not change runtime code. The gap was in evidence accounting: runtime
support was already covered by the relmat Gaussian tests, while the q-series
map and q1 fixture sidecar still treated the scale-side relmat intercept cells
as planned bridge evidence.

## 4. Files Touched

- `tests/testthat/test-structured-re-bridge-fixtures.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q1-parity-fixture-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-relmat-q1-scale-fixture-parity.md`

## 5. Checks Run

```sh
air format tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts|animal-relmat-gaussian', stop_on_failure = TRUE)"
python3 tools/validate-mission-control.py
git diff --check
Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-25-relmat-q1-scale-fixture-parity.md
```

The first focused test run caught one wording mismatch: the matched relmat
`mu+sigma` parity row did not literally keep unsupported routes as "remain
separate". After correcting that claim-boundary text, the same focused test
command passed with 4,481 assertions, 0 failures, 0 warnings, and 0 skips.

`python3 tools/validate-mission-control.py` passed and reported 9 q1
parity-fixture rows. `git diff --check` passed. The after-task checker passed
for this report.

## 6. Tests of the Tests

The new fixture test would fail if the q1 relmat `sigma` or `mu_sigma` payloads
lost the relmat target metadata, stopped using the K-matrix fixture ID, changed
the estimator away from ML, omitted the scale fixed coefficient, or failed the
deterministic native/direct/R-via-Julia parity status.

The dashboard contract test would fail if the two new relmat scale-side rows
lost `covered`/`experimental` status, stopped naming the K-matrix boundary,
stopped naming Q bridge marshalling as separate, or disappeared from the q1
acceptance inventory.

## 7a. Issue Ledger

No GitHub issue or Ayumi-facing reply was created. This is local q-series
evidence hygiene for the stacked drmTMB PR lane.

## 8. Consistency Audit

The q1 parity sidecar, q-series support-cell table, dashboard README, design
map, and tests now agree that relmat q1 `sigma` and matched `mu+sigma` have
fixture-parity evidence only. This is not public support wording and does not
change q2, q4, q8, REML, interval, or coverage status.

## 9. What Did Not Go Smoothly

The first contract-test run found one stale phrase in the matched relmat
`mu+sigma` row. That was useful: it confirmed the guard catches boundary drift
before the sidecar can become the new source of ambiguity.

## 10. Known Residuals

Live bridge parity for these relmat scale-side q1 cells remains unbanked.
Q precision bridge marshalling, calibrated interval diagnostics, coverage
denominators, REML, AI-REML, structured q6/q8, and broader public support all
remain outside this slice.

## 11. Team Learning

Rose/Emmy: support-cell status should move only when the exact evidence tier is
named. Gauss/Fisher: native K/Q point fits are useful runtime evidence, but they
are not the same as Q bridge marshalling or interval reliability. Grace: the
dashboard tests should continue checking literal boundary phrases because they
catch drift early.
