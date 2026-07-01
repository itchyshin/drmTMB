# After Task: Q-Series Count-Intercept Recovery Grid

## 1. Goal

Move the ten non-Gaussian q1 count `mu` intercept Q-Series rows from local
smoke evidence to row-level recovery evidence, while keeping interval,
coverage, `inference_ready`, `supported`, REML, AI-REML, bridge, q2/q4, high-q,
and public-support claims unchanged.

## 2. Implemented

This promotes exactly the ten non-Gaussian count-intercept cells under the
recovery-only point-estimation channel with failures retained in the recovery
denominator and does not claim interval readiness, coverage readiness,
`inference_ready`, `supported`, REML, AI-REML, bridge support, q2/q4 count
covariance, high-q evidence, or public support.

The local 80-rep recovery grid moved seven count-intercept rows to
`non_gaussian_recovery_only` and three count-intercept rows to
`non_gaussian_recovery_caveat`. `qseries_phylo_nbinom2_q1_mu_intercept` is
caveated because 13/320 structured-SD rows had `pdHess = FALSE`; the phylo
Poisson and spatial NB2 intercept rows are caveated because at least 25% of
structured-SD estimates fell below the near-zero threshold `1e-4`.

## 3a. Decisions and Rejected Alternatives

The target is point recovery of the structured random-effect standard deviation
for non-Gaussian q1 count `mu` intercept formulas. The summary reports
convergence, `pdHess`, finite structured-SD estimates, near-zero
structured-SD estimates, boundary-warning rows, bias, RMSE, and MCSE for
bias/RMSE. No interval denominator or coverage denominator is interpreted.

Rejected alternatives: I did not use the local smoke sidecars as recovery
evidence, did not promote non-Gaussian interval or coverage status, and did not
collapse the phylo NB2 pdHess caveat into a clean recovery row.

## 4. Files Touched

- `tools/run-structured-re-count-intercept-recovery-grid.R`
- `docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-grid-local/`
- `docs/dev-log/dashboard/structured-re-count-intercept-recovery-results.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-count-intercept-recovery-grid.md`

## 5. Checks Run

```sh
/opt/homebrew/bin/air format tools/run-structured-re-count-intercept-recovery-grid.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-count-intercept-recovery-grid.md')"
git diff --check
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test()'
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::check()'
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'pkgdown::check_pkgdown()'
```

Results: after the near-zero diagnostic refinement, full `devtools::test()`
passed with 19674 PASS / 0 FAIL / 17 WARN / 43 SKIP in 529.9s, and
`devtools::check()` passed with 0 errors / 0 warnings / 0 notes in 11m 15.2s.
`pkgdown::check_pkgdown()` reported no problems. `tools/validate-mission-control.py`,
dashboard JavaScript syntax, `git diff --check`, and the focused
`structured-re-conversion-contracts` test also passed; the focused test had
6295 PASS / 0 FAIL.

The recovery grid command was:

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-count-intercept-recovery-grid.R --n_rep=80 --seed_start=2026062901 --cores=4 --backend=multicore --overwrite
```

## 6. Tests of the Tests

The focused dashboard test now checks that the ten recovery-result rows cover
the same cells as the three older smoke sidecars, that the non-Gaussian audit
state mirrors the recovery sidecar, that the phylo NB2 intercept row carries
the expected pdHess caveat, and that the phylo Poisson plus spatial NB2 rows
carry the expected near-zero lower-tail caveat.

## 7a. Issue Ledger

No issue action was taken in this slice. The work updates the local Q-Series
evidence ledger and PR branch state; no new public capability claim was opened
or closed.

## 8. Consistency Audit

`tools/validate-mission-control.py` now requires the ten-row recovery-results
sidecar, the exact recovery/caveat state counts, the near-zero diagnostic
fields, the no-promotion claim boundary, and the linked support-cell
interval/coverage statuses. The widget shows recovery, recovery caveats, fit
stability, inference readiness, interval status, and coverage status as
separate columns.

## 9. What Did Not Go Smoothly

The first runner attempt failed because child `Rscript` paths with spaces were
not quoted. The next attempts exposed two empty-failure-ledger edge cases and a
diagnostic-status parsing issue where `ok | ok` was incorrectly counted as a
warning. The runner now quotes child arguments, handles zero-row ledgers, and
parses compound diagnostic statuses.

## 10. Known Residuals

This is a local recovery grid, not cluster confirmation. The phylo NB2 intercept
row remains caveated by `pdHess = FALSE` in 13/320 structured-SD rows. All
non-Gaussian intervals and coverage remain unsupported/planned.

Diagnose the phylo NB2 intercept pdHess caveat and the phylo Poisson/spatial
NB2 near-zero lower-tail caveats, then decide whether to rerun or top up the
count-intercept recovery grid on Nibi/Rorqual before any public recovery
wording. Do not use this evidence for intervals, coverage, q2/q4, REML,
AI-REML, bridge support, `supported`, or high-q claims.

## 11. Team Learning

Recovery sidecars need a generic display path. The old widget assumed
count-slope `sd_mu:x` fields; the recovery renderer now handles generic
structured-SD bias/RMSE fields as well as older count-slope metrics.
