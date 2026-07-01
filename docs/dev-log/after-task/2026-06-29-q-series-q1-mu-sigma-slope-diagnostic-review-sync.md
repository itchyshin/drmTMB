# Q-Series q1 mu+sigma one-slope diagnostic-review sync

## 1. Goal

Move the four Gaussian low-q q1 `mu+sigma` one-slope rows out of generic
row-contract hold now that readiness, interval-diagnostic, and stability
sidecars exist, without promoting any row to `inference_ready` or `supported`.

## 2. Implemented

- Updated `tools/summarize-structured-re-gaussian-lowq-row-selection.R` so the
  phylo, spatial, animal, and relmat q1 `mu+sigma` one-slope rows now use
  `interval_diagnostic_completed_review_pending`.
- Kept those four rows in `matched_mu_sigma_design_hold`, with
  `first_smoke_n_rep=0` and host escalation blocked until Fisher/Noether/Rose
  accept target-specific denominators.
- Regenerated `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
  and the artifact mirror under
  `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/`.
- Updated the four matching rows in
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv` so the
  widget names the diagnostic sidecars instead of saying only parity-fixture
  evidence exists.
- Updated `tools/validate-mission-control.py` and
  `tests/testthat/test-structured-re-conversion-contracts.R` to require the new
  diagnostic-review state and the no-promotion wording.
- Bumped the dashboard build from `r142` to `r143`.

## 3a. Decisions and Rejected Alternatives

- Chose `interval_diagnostic_completed_review_pending` rather than
  `local_smoke_completed_review_pending` because the one-slope rows have
  diagnostic sidecars, not a new replicated smoke for this slice.
- Kept support cells at `point_fit/planned/planned`. The diagnostic sidecars
  expose interval shape and failure modes, but they are not coverage evidence.
- Did not run Totoro/FIIA, Nibi, Rorqual, or DRAC work. The row contract still
  requires Fisher/Noether/Rose to split direct `sd_mu`, direct `sd_sigma`, and
  `mu-sigma` correlation denominators first.
- Did not apply q1 `mu`, q1 `sigma`, q2, q4/q8, non-Gaussian, REML, or
  AI-REML evidence to these rows.

## 4. Files Touched

- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-mu-sigma-slope-diagnostic-review-sync.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`
  passed and wrote 23 Gaussian low-q row-selection rows.
- A Python row-selection audit confirmed 23 rows: 12
  `local_smoke_completed_review_pending`, 4
  `interval_diagnostic_completed_review_pending`, 5
  `ready_for_totoro_fiia_smoke`, and 2 `hold_until_row_contract`.
- `cmp -s docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
  passed.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`
  passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`
  passed with 8462 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- Dashboard JavaScript parse check passed with `dashboard_js_ok`.

## 6. Tests of the Tests

The validator and focused test now require the four exact q1 `mu+sigma`
one-slope cell IDs, `interval_diagnostic_completed_review_pending`,
`fisher_noether_rose_review_before_calibration_or_smoke`, `first_smoke_n_rep=0`,
the diagnostic-status evidence URL, the three named sidecars, and explicit
no-promotion phrases. A stale `hold_until_row_contract` row, missing diagnostic
sidecar reference, or accidental `inference_ready`/`supported` wording would
fail both `tools/validate-mission-control.py` and the focused test.

## 7a. Issue Ledger

- Fixed stale low-q row-selection state for the four q1 `mu+sigma` one-slope
  rows.
- Fixed stale audit prose that implied only point/fixture evidence existed even
  though diagnostic sidecars were already present.
- Deferred target-specific denominator design, local replicated smoke, coverage,
  and status promotion.

## 8. Consistency Audit

Checked the q1 `mu+sigma` one-slope rows across the support-cell TSV,
Gaussian low-q status audit, row-selection TSV, readiness sidecar,
interval-diagnostic sidecar, and interval-stability sidecar. The support cells
remain `point_fit/planned/planned`; the row-selection table now records a
diagnostic-review state; the validator confirms dashboard and artifact copies
match.

## 9. What Did Not Go Smoothly

The worktree is already broad and dirty from the Q-Series campaign, so full
`git diff --stat` includes large pre-existing validator, dashboard, and test
changes. This slice therefore relied on focused regeneration, mission-control
validation, and focused test output rather than interpreting the whole branch
diff as new work.

## 10. Known Residuals

- The four q1 `mu+sigma` one-slope rows are not `inference_ready`.
- They still need Fisher/Noether/Rose target splitting for direct `sd_mu`,
  direct `sd_sigma`, and `mu-sigma` correlation denominators.
- Totoro/FIIA, Nibi, Rorqual, and DRAC compute remain blocked for these rows.
- Two low-q rows remain on generic `hold_until_row_contract`: the phylo direct
  SD univariate row and the phylo-interaction q1 `mu` row.

## 11. Team Learning

When a row has diagnostic sidecars, the board should not leave it in a generic
contract hold. Record the intermediate evidence state explicitly, keep the
support-cell statuses unchanged, and make the next reviewer decision
target-specific.
