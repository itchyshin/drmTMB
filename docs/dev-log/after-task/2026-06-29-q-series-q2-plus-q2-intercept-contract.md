# After Task: Q-Series q2-plus-q2 intercept contract

## 1. Goal

Close the row-level contract for `qseries_phylo_q2_plus_q2_intercept` without
promoting the row or spending cluster compute. The row combines one labelled
phylo q2 block in `mu1`/`mu2` and one labelled phylo q2 block in
`sigma1`/`sigma2`, so the contract must separate admissible within-block
targets from unavailable mean-scale cross-block correlations.

## 2. Implemented

This promotes exactly no Q-Series row. The sidecar
`structured-re-q2-plus-q2-intercept-contract.tsv` names six admissible
within-block targets and four blocked cross-block correlations:

- direct SD targets for `mu1`, `mu2`, `sigma1`, and `sigma2`;
- direct correlation targets for `cor(mu1, mu2)` and `cor(sigma1, sigma2)`;
- blocked cross-block correlations for `cor(mu1, sigma1)`,
  `cor(mu1, sigma2)`, `cor(mu2, sigma1)`, and `cor(mu2, sigma2)`.

The linked support cell remains `fit_status = point_fit`,
`interval_status = planned`, and `coverage_status = planned`. The low-q audit
row now says the row has point/fixture evidence only plus a contract, not
interval or coverage evidence.

## 3a. Decisions and Rejected Alternatives

The q2-plus-q2 route is block diagonal at this stage. The location block has
two structured location coefficients and can define location-block SD and
location-block correlation targets. The scale block has two structured scale
coefficients and can define scale-block SD and scale-block correlation targets.
There is no current target for cross-block `mu`-to-`sigma` correlations under
this block-diagonal route; those require a true q4 route before any interval,
coverage, `inference_ready`, `supported`, or public claim.

The location-axis small-sample bias+t default is relevant only for the location
SD targets. Sigma-side targets explicitly do not inherit that default.

Rejected alternative: do not treat this row as all-four q4 evidence. The
available q2-plus-q2 route is two labelled q2 blocks, not a single four-axis
covariance with cross-block correlations.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-plus-q2-intercept-contract.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 structured RE q-series cells,
  35 Gaussian low-q status-audit rows, 23 Gaussian low-q row-selection rows, 12
  q2 intercept interval-contract rows, 10 q2-plus-q2 intercept-contract rows,
  and 12 q2 intercept local-smoke rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8070 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `/opt/homebrew/bin/air format tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.

## 6. Tests of the Tests

The focused test now reads the q2-plus-q2 contract directly. It checks the
10-row shape, the exact linked support cell, the six direct targets, the four
blocked cross-block targets, the direct target denominator ladder, the sigma
no-bias+t boundary, and the linked support-cell statuses. A missing after-task
link, a cross-block target promoted as if it were measurable, or a support-cell
status promotion should fail either the test or mission-control validator.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is an internal
Q-Series evidence-board contract slice under the active widget/mission-control
PR stack.

## 8. Consistency Audit

The support-cell row, Gaussian low-q audit row, row-selection ledgers,
mission-control validator, and focused test all now describe the same boundary:
q2-plus-q2 intercept is contract-ready with no compute and no promotion. The
contract does not alter q2-only location inference, sigma readiness, q4/q8,
non-Gaussian rows, REML, AI-REML, bridge support, or public support.

## 9. What Did Not Go Smoothly

The first validator run failed because the sidecar pointed at this report before
the report existed, and because the Gaussian low-q audit wording said
"point/fixture evidence plus a contract" instead of the stricter
"point/fixture evidence only" phrase required by the gate. That was a useful
Rose-style catch: the row must read as evidence-bound, not nearly promoted.

## 10. Known Residuals

This contract is not runtime evidence. It does not run a q2-plus-q2 smoke, does
not provide a denominator, does not provide MCSE, and does not create any
interval or coverage claim. Totoro/FIIA, Nibi/Rorqual, DRAC, TSV promotion, and
public wording remain blocked until same-target fixture/extractor parity,
local smoke, and Fisher/Rose review pass.

## 11. Team Learning

For mixed location-and-scale structured rows, the contract should name
unavailable targets as explicitly as available ones. Otherwise a future coverage
runner may accidentally treat block-diagonal q2-plus-q2 evidence as q4
cross-block covariance evidence.

Next action: add same-target fixture/extractor checks before any q2-plus-q2
smoke or denominator work. Keep DRAC compute behind the local validator and
Fisher/Rose gates.
