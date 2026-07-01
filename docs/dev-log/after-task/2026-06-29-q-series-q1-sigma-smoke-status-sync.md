# Q-Series q1 Sigma Smoke Status Sync

## 1. Goal

Sync the Gaussian low-q q1 `sigma` intercept row-selection and status-audit
ledgers to the executed local n=5 smoke without promoting any Q-Series support
cell.

## 2. Implemented

- Updated `tools/summarize-structured-re-gaussian-lowq-row-selection.R` so the
  four q1 `sigma` intercept rows now report
  `local_smoke_completed_review_pending` and
  `fisher_gauss_rose_review_before_host_escalation`.
- Regenerated
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv` and
  its artifact mirror.
- Updated the four q1 `sigma` intercept rows in
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv` to
  point at the local smoke sidecar.
- Updated mission-control validation and the focused conversion-contract test
  so the executed-smoke state is guarded.
- Bumped the dashboard widget build to `r140`.

## 3a. Decisions and Rejected Alternatives

- I treated the local smoke as route evidence only. It changes the host/review
  gate wording but not `fit_status`, `interval_status`, `coverage_status`,
  `authority_status`, `inference_ready`, or `supported`.
- I kept the route contract visible in the generated row-selection text because
  the smoke is interpretable only under that contract.
- I rejected a status promotion for animal and relmat despite 5/5 usable
  raw-Wald intervals; five local replicates are not a calibrated denominator.
- I rejected deleting phylo/spatial boundary evidence. Those retained boundary
  rows are the reason the next gate is review and denominator design, not
  cluster escalation.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-sigma-smoke-status-sync.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/summarize-structured-re-gaussian-lowq-row-selection.R
  --overwrite=true`: passed and wrote 23 row-selection rows.
- `/opt/homebrew/bin/air format
  tools/summarize-structured-re-gaussian-lowq-row-selection.R
  tests/testthat/test-structured-re-conversion-contracts.R
  tools/validate-mission-control.py`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript parse check from `docs/dev-log/dashboard/index.html`:
  passed.
- First `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: failed because the regenerated
  row-selection text no longer mentioned `raw log-SD Wald` and
  `endpoint profile`.
- First `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: failed for the same stale generated
  text.
- After patching the generator and regenerating, `R_PROFILE_USER=/dev/null
  NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with
  `mission_control_ok`, including 104 Q-Series cells, 35 Gaussian low-q status
  rows, 23 Gaussian low-q row-selection rows, and 4 Gaussian low-q
  sigma-intercept smoke rows.
- After regeneration, `R_PROFILE_USER=/dev/null NOT_CRAN=true
  OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1
  Rscript --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: passed with 8411 PASS / 0 FAIL /
  0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q1-sigma-smoke-status-sync.md')"`:
  passed with `after-task structure check passed`.
- `git diff --check`: passed.
- `find tools -type d -name '__pycache__' -print`: returned no paths after
  removing the `py_compile` scratch directory.

## 6. Tests of the Tests

The validator and test both failed before the final generator text was fixed,
because they required the local-smoke rows to preserve the route phrases
`raw log-SD Wald` and `endpoint profile`. After the generator was patched and
the TSVs were regenerated, the same guards passed.

## 7a. Issue Ledger

- Found: the row-selection and low-q status-audit ledgers still described the
  q1 `sigma` intercept local smoke as pending after the smoke had run.
- Fixed: both ledgers now point at the local smoke and say review is the next
  gate.
- Deferred: Fisher/Gauss/Rose review of the retained smoke rows, then any
  decision on Totoro/FIIA or denominator work.
- No GitHub issue action was taken because this is an internal dashboard/status
  synchronization and no public support claim changed.

## 8. Consistency Audit

- The support-cell TSV still keeps the four q1 `sigma` intercept rows at
  `point_fit/planned/planned`.
- The row-selection dashboard TSV and artifact mirror are byte-identical after
  regeneration.
- The stale phrases `route_contract_ready_local_smoke_pending` and
  `local_sigma_intercept_smoke_after_route_contract` no longer appear in the
  generator, validator, focused test, row-selection TSVs, or low-q status audit.
- The widget build is now `r140` so the preview reloads the synced data.

## 9. What Did Not Go Smoothly

I initially updated the validator/test before regenerating the generated
row-selection TSV, so the first focused test correctly failed on stale data.
Then the validator caught that the new generator text had dropped two route
phrases needed for scientific interpretability. Both were fixed before closing.

## 10. Known Residuals

This promotes exactly no Q-Series row. The local smoke is not coverage evidence,
not interval reliability, not `inference_ready`, not `supported`, not q1 `mu`,
not matched `mu+sigma`, not q2/q4/q8, not non-Gaussian, not REML, not AI-REML,
not bridge support, not public support, and not cluster authorization.

## 11. Team Learning

When a route contract becomes an executed smoke, update both the generated host
gate and the row-level status audit in the same slice. The validator should keep
the route language attached to the smoke evidence so the next agent does not
mistake local route success for calibrated interval evidence.
