# After Task: Q-Series Count-Intercept Top-Up Recovery

## 1. Goal

Move the three non-Gaussian q1 count `mu` intercept rows that were
recovery-caveated under the weak-denominator 80-rep grid into a stronger local
recovery-only evidence state, without changing interval, coverage,
`inference_ready`, `supported`, REML, AI-REML, bridge, q2/q4, high-q, or public
support claims.

## 2. Implemented

This promotes exactly no support cell. It adds a row-level recovery top-up
sidecar for `qseries_phylo_poisson_q1_mu_intercept`,
`qseries_phylo_nbinom2_q1_mu_intercept`, and
`qseries_spatial_nbinom2_q1_mu_intercept` under the recovery-only diagnostic
channel with failures retained in the local denominator and does not claim
interval readiness, coverage readiness, `inference_ready`, `supported`, REML,
AI-REML, bridge support, q2/q4 count covariance, high-q evidence, or public
support.

The top-up sidecar records three rows. Each row aggregates 80 seeds over four
stronger-denominator conditions, so each row has 320 structured-SD target
estimates. All three rows passed the recovery-only top-up gate with 320/320 fit
success, zero `pdHess = FALSE`, zero finite-estimate losses, and zero
near-zero structured-SD estimates below `1e-4`.

## 3a. Decisions and Rejected Alternatives

The top-up target is the structured random-effect standard deviation on the
public SD scale. The top-up uses the stronger-denominator designs from the
previous denominator diagnostic: phylo Poisson/NB2 use 40 species with 8-12
observations per species, larger mean counts, and SD values 0.6 or 0.9;
spatial NB2 uses 16-24 spatial levels, 12-16 observations per level, larger
mean counts, and SD values 0.6 or 0.9.

Rejected alternatives: I did not overwrite the original 80-rep weak-denominator
recovery grid, did not delete the caveat sidecars, did not promote
non-Gaussian intervals or coverage, and did not call these rows `supported`.
The widget now uses the top-up sidecar for recovery-only display state while
the original caveat sidecars remain visible as provenance.

## 4. Files Touched

- `tools/run-structured-re-count-intercept-denominator-diagnostic.R`
- `tools/summarize-structured-re-count-intercept-topup-recovery.R`
- `docs/dev-log/dashboard/structured-re-count-intercept-topup-recovery-results.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-topup-recovery-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-count-intercept-topup-recovery.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-count-intercept-denominator-diagnostic.R --output_dir=docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-topup-recovery-local --dashboard_output=/tmp/drmtmb-count-intercept-topup-condition-diagnostic.tsv --n_rep=80 --seed_start=2026062921 --overwrite
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-count-intercept-topup-recovery.R
/opt/homebrew/bin/air format tools/summarize-structured-re-count-intercept-topup-recovery.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test()'
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::check()'
```

Results: the 80-rep local top-up wrote 960 structured-SD replicate rows and a
three-row top-up recovery sidecar; `tools/validate-mission-control.py` reported
`mission_control_ok`; dashboard JavaScript syntax passed; and the focused
`structured-re-conversion-contracts` test passed with 6335 PASS / 0 FAIL /
0 WARN / 0 SKIP. The full package test suite passed with 19714 PASS / 0 FAIL /
17 WARN / 43 SKIP. `devtools::check()` passed in 11m 9.7s with 0 errors /
0 warnings / 0 notes.

## 6. Tests of the Tests

The focused dashboard test now reads
`structured-re-count-intercept-topup-recovery-results.tsv` and checks the exact
three-row shape, the formerly caveated cells, 320 retained target rows per
cell, 80 seeds, four internal conditions, 320/320 fit success, zero
`pdHess = FALSE`, zero near-zero estimates, the
`topup_recovery_only_passed` verdict, and the no-promotion claim boundary. It
also checks that the non-Gaussian status audit now has 18 recovery-only rows
and zero recovery-caveated rows.

## 7a. Issue Ledger

No GitHub issue action was taken in this slice. The work updates local
mission-control evidence on PR #685's branch and does not open or close a
public capability claim.

## 8. Consistency Audit

`tools/validate-mission-control.py` now requires the three-row top-up sidecar,
exact formerly caveated cell set, exact no-promotion claim boundary,
`interval_status = unsupported`, `coverage_status = planned`,
`authority_status = source`, 320 retained rows per cell, and a next gate that
keeps intervals and coverage unsupported. The widget reads the top-up sidecar
after the original count-intercept recovery sidecar, so top-up-cleared rows get
the recovery-only display state while the old caveat diagnostics remain linked.

## 9. What Did Not Go Smoothly

The top-up reuses the stronger-denominator diagnostic runner and writes the
condition-level diagnostic table to `/tmp`; a separate summarizer produces the
row-level sidecar. This avoids rewriting the original runner but leaves the
top-up as a two-command workflow.

## 10. Known Residuals

This is a local recovery top-up, not a primary-cluster confirmation and not an
interval or coverage grid. It supports recovery-only board wording for the
three rows, but public recovery wording should wait for a primary-cluster
confirmation. Non-Gaussian intervals and q2/q4 count covariance remain
unsupported.

## Next Actions

Use the top-up sidecar as the local recovery-only state for the three rows.
Next Q-Series work should move to the next bounded lane: either primary-cluster
confirmation for this top-up, Gaussian low-q interval/coverage gates, or q4
admission diagnostics. Do not use this sidecar for intervals, coverage, q2/q4,
REML, AI-REML, bridge support, `supported`, or high-q claims.

## 11. Team Learning

Weak-denominator caveats should be preserved as provenance even after a
stronger top-up clears the display state. The widget now supports that pattern:
old caveat evidence remains visible, while the newest recovery-only sidecar can
drive row state.
