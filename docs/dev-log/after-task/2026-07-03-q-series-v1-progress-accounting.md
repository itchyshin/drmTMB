# After Task: Q-Series v1 progress accounting

## 1. Goal

Make the Q-Series v1.0 progress answer reproducible from the 104-row support
board, while keeping row-accounting percentages separate from package-release
completion and support claims.

## 2. Implemented

Extended `tools/qseries_v1_release_ledger.py` so the generated release-status
file now includes a `Progress Accounting` section. The section reports the
practical v1.0 row surface, Gaussian v1.0 core, basic-distribution recovery,
exact `inference_ready` anchors, `supported` authority, and post-v1.0
validation/design rows as row counts and one-decimal percentages.

Updated the Mission Control validator and the focused
`structured-re-conversion-contracts` test so the new percentages are checked
from current support-cell counts. Updated the dashboard README to state that
these are row-accounting summaries, not package-release completion claims.

## 3a. Decisions and Rejected Alternatives

I kept the percentage accounting inside the generated release-status file
rather than adding another hand-maintained sidecar. That keeps the 104-row
support-cell table and generated v1 ledger as the source of truth.

I did not use the progress percentages to promote rows, authorize compute,
change public APIs, change formula grammar, or change coverage/support status.

## 4. Files Touched

- `docs/dev-log/after-task/2026-07-03-q-series-v1-progress-accounting.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/release-audits/q-series-v1-release-status.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/qseries_v1_release_ledger.py`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/validate-mission-control.py tools/qseries-tranche-scaffold.py tools/qseries_v1_release_ledger.py`: passed.
- `python3 tools/qseries_v1_release_ledger.py --check --check-status --summary`: passed with the expected five-track split and progress accounting.
- Dashboard JS extraction plus bundled Node `--check /tmp/drmtmb-mission-control-index-r324.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e 'Sys.setenv(NOT_CRAN="true", OMP_NUM_THREADS="1", OPENBLAS_NUM_THREADS="1", MKL_NUM_THREADS="1"); devtools::test(filter = "structured-re-conversion-contracts", reporter = "summary")'`: passed with `DONE`.

## 6. Tests of the Tests

The Python validator computes the row percentages from the support-cell and
release-ledger counts, then checks the generated status text. The focused R
test independently checks the visible percentage rows in the generated status
file, so a stale or missing progress table fails even when the TSV ledger still
exists.

## 7a. Issue Ledger

No GitHub issue or PR action was taken. This was a local status-tooling
improvement for the active Q-Series v1.0 readiness campaign.

## 8. Consistency Audit

The generated status now reports practical v1.0 row surface 74/104 (71.2%),
Gaussian v1.0 core 56/67 (83.6%), basic-distribution recovery 18/37 (48.6%),
exact `inference_ready` anchors 8/104 (7.7%), `supported` authority 0/104
(0.0%), and post-v1.0 validation/design 30/104 (28.8%).

The status text explicitly says these are row-accounting summaries, not
package-release completion claims. No support-cell status, q4/q8 coverage,
REML, AI-REML, broad bridge support, or public-support wording was promoted.

## 9. What Did Not Go Smoothly

The main risk was conflating the previously discussed rough 80% campaign
estimate with row-level evidence. The generated status avoids that by reporting
row fractions directly and leaving release-completion judgment outside the
table.

## 10. Known Residuals

The progress table does not prove drmTMB v1.0 is complete. It proves only the
current row-accounting split for the Q-Series v1.0 release boundary. Final v1.0
readiness still needs ordinary release checks and review of package-facing
claims.

## 11. Team Learning

When a status number will be discussed repeatedly, generate it from the ledger
and test the displayed wording. That is faster than redoing arithmetic in chat
and safer than letting a rough percentage become a statistical claim.
