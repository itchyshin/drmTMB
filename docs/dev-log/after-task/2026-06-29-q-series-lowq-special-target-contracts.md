# Q-Series low-q special-target contracts

## 1. Goal

Remove the last two generic Gaussian low-q row-selection holds by banking exact
contracts for `qseries_phylo_direct_sd_univariate` and
`qseries_phylo_interaction_q1_mu`, without promoting either row.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-special-target-contract.tsv`
  with one direct-SD contract and one `phylo_interaction()` provider-boundary
  contract.
- Updated `tools/summarize-structured-re-gaussian-lowq-row-selection.R` so the
  special rows now report `direct_sd_contract_banked_review_pending` and
  `phylo_interaction_contract_banked_review_pending`.
- Regenerated `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
  and the artifact mirror under
  `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/`.
- Updated `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
  so those rows point at the new contract and name their separate blockers.
- Added the special-target contract table to the Q-Series widget and bumped the
  dashboard build to `r144`.
- Updated `tools/validate-mission-control.py` and
  `tests/testthat/test-structured-re-conversion-contracts.R` to make the two
  special contracts validator-owned.

## 3a. Decisions and Rejected Alternatives

- Chose explicit contract statuses rather than leaving both rows on
  `hold_until_row_contract`; the old state hid two different blockers.
- Kept `qseries_phylo_direct_sd_univariate` at
  `point_fit/interval_feasible/planned`. Direct-SD profile feasibility is not
  coverage evidence and does not cover derived correlations.
- Kept `qseries_phylo_interaction_q1_mu` at `point_fit/planned/planned`.
  `phylo_interaction()` is a q1 pair-level provider, not a q2/q4 endpoint
  covariance route.
- Did not launch local, Totoro/FIIA, Nibi, Rorqual, or DRAC compute. Both rows
  need reviewer contract decisions before smoke or denominator work.

## 4. Files Touched

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-lowq-special-target-contracts.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-special-target-contract.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`
  passed and wrote 23 Gaussian low-q row-selection rows.
- Python row-selection audit confirmed 23 rows: 12
  `local_smoke_completed_review_pending`, 4
  `interval_diagnostic_completed_review_pending`, 5
  `ready_for_totoro_fiia_smoke`, 1
  `direct_sd_contract_banked_review_pending`, and 1
  `phylo_interaction_contract_banked_review_pending`.
- `cmp -s docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
  passed.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`
  passed.
- Dashboard JavaScript parse check passed with `dashboard_js_ok`.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
  passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`
  passed with 8502 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## 6. Tests of the Tests

The validator now requires exactly two rows in
`structured-re-gaussian-lowq-special-target-contract.tsv`, exact cell IDs,
review teams, status triples, source evidence, and no-promotion language. The
focused test requires the row-selection statuses, run modes, sidecar evidence
URL, host blocks, and forbidden-claim wording. Reverting either special row to
`hold_until_row_contract`, dropping the sidecar, or accidentally calling either
row `inference_ready` or `supported` would fail.

## 7a. Issue Ledger

- Fixed the final generic Gaussian low-q row-selection holds.
- Fixed stale status-audit prose for the direct-SD and `phylo_interaction()`
  rows.
- Deferred direct-SD denominator design, `phylo_interaction()` interval-route
  design, smoke execution, and any status promotion.

## 8. Consistency Audit

Checked both special rows across the support-cell TSV, Gaussian low-q status
audit, row-selection TSV, new special-target contract TSV, row-selection
artifact mirror, mission-control validator, and focused conversion-contract
test. Support-cell statuses remain unchanged, and the row-selection table now
has zero `hold_until_row_contract` rows.

## 9. What Did Not Go Smoothly

The first dashboard patch attempted to touch a long render block and did not
apply cleanly. I split the dashboard changes into smaller patches: function
argument, summary card, compact table, render call, loader, and version bump.

## 10. Known Residuals

- The two special rows are still not `inference_ready`.
- `qseries_phylo_direct_sd_univariate` needs Fisher/Noether/Rose to define the
  direct-SD interval channel, retained denominator, one-sided miss ledger, and
  derived-correlation exclusion.
- `qseries_phylo_interaction_q1_mu` needs Boole/Fisher/Rose to choose whether it
  gets a row-specific interval route, a rejection contract, or recovery-only
  wording.
- No broad Q-Series support claim changes in this slice.

## 11. Team Learning

Do not leave heterogeneous special targets under one generic hold label. Bank a
small row-level contract with the exact reviewer team and the exact forbidden
claims, then keep support-cell status unchanged until evidence justifies a
promotion.
