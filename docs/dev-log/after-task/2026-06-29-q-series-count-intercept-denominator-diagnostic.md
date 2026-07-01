# After Task: Q-Series Count-Intercept Denominator Diagnostic

## 1. Goal

Test whether the three non-Gaussian q1 count `mu` intercept recovery caveats
persist under larger count denominators and stronger structured-SD signals,
without changing interval, coverage, `inference_ready`, `supported`, REML,
AI-REML, bridge, q2/q4, high-q, or public support claims.

## 2. Implemented

This promotes exactly no support cell. It adds a targeted stronger-denominator
diagnostic for `qseries_phylo_poisson_q1_mu_intercept`,
`qseries_phylo_nbinom2_q1_mu_intercept`, and
`qseries_spatial_nbinom2_q1_mu_intercept` under the recovery-only diagnostic
channel with failures retained in the local denominator and does not claim
interval readiness, coverage readiness, `inference_ready`, `supported`, REML,
AI-REML, bridge support, q2/q4 count covariance, high-q evidence, or public
support.

The diagnostic sidecar records 12 condition rows: four stronger-denominator
conditions for each caveated cell. All 12 rows cleared locally with 30/30 fits,
zero `pdHess = FALSE` rows, and zero structured-SD estimates below `1e-4`.

## 3a. Decisions and Rejected Alternatives

The diagnostic target is the structured random-effect standard deviation on
the public SD scale. The design increases the denominator and signal relative
to the caveated 80-rep local grid: phylo Poisson/NB2 use 40 species with 8-12
observations per species, larger mean counts, and SD values 0.6 or 0.9;
spatial NB2 uses 16-24 spatial levels, 12-16 observations per level, larger
mean counts, and SD values 0.6 or 0.9.

Rejected alternatives: I did not overwrite the original 80-rep recovery grid,
did not reclassify the three caveated rows as clean recovery evidence, did not
promote non-Gaussian intervals or coverage, and did not describe the result as
support. The result is a design-sensitivity diagnostic: the caveats clear under
stronger local conditions, but the original row-level recovery state remains
`non_gaussian_recovery_caveat` until a replicated top-up and wording review are
done.

## 4. Files Touched

- `tools/run-structured-re-count-intercept-denominator-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-count-intercept-denominator-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-denominator-diagnostic-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-count-intercept-denominator-diagnostic.md`

## 5. Checks Run

```sh
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-count-intercept-denominator-diagnostic.R --output_dir=/tmp/drmtmb-count-intercept-denominator-smoke --dashboard_output=/tmp/drmtmb-count-intercept-denominator-smoke.tsv --n_rep=2 --cores=1 --backend=none --overwrite
R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-count-intercept-denominator-diagnostic.R --overwrite
/opt/homebrew/bin/air format tools/run-structured-re-count-intercept-denominator-diagnostic.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
sed -n '/<script>/,/<\/script>/p' docs/dev-log/dashboard/index.html | sed '1d;$d' | node --check -
R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'
R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'devtools::check()'
```

Results: the smoke runner wrote 12 rows to `/tmp`; the full local diagnostic
wrote 12 rows to
`docs/dev-log/dashboard/structured-re-count-intercept-denominator-diagnostic.tsv`;
`tools/validate-mission-control.py` reported `mission_control_ok`; dashboard
JavaScript syntax passed; and the focused `structured-re-conversion-contracts`
test passed with 6319 PASS / 0 FAIL / 0 WARN / 0 SKIP. Full
`devtools::check()` passed in 11m 11.3s with 0 errors / 0 warnings / 0 notes.

## 6. Tests of the Tests

The focused dashboard test now reads
`structured-re-count-intercept-denominator-diagnostic.tsv` and checks the exact
12-row shape, the three caveated cells, four condition rows per cell, 30
replicates per condition, 30/30 fit success, zero `pdHess = FALSE`, zero
near-zero estimates, the `denominator_cleared_locally` verdict, no-promotion
claim text, and the unsupported interval/coverage next gate.

## 7a. Issue Ledger

No GitHub issue action was taken in this slice. The work updates local
mission-control evidence on PR #685's branch and does not open or close a
public capability claim.

## 8. Consistency Audit

`tools/validate-mission-control.py` now requires the 12-row sidecar, exact
caveated cell set, exact no-promotion claim boundary, `interval_status =
unsupported`, `coverage_status = planned`, `authority_status = source`, and a
next gate that keeps intervals and coverage unsupported. The widget shows the
new sidecar link, the 12 stronger-denominator condition count, worst near-zero
rate, and verdict class only on recovery-caveated count-intercept rows.

## 9. What Did Not Go Smoothly

The first smoke run exposed two base-R `rbind()` assumptions: the three
condition manifests and the three replicate tables have different columns. The
final runner uses a fill-bind helper so the raw phylo and spatial diagnostic
columns are preserved instead of silently dropping columns.

## 10. Known Residuals

This is a 30-rep local diagnostic, not a recovery promotion grid and not an
interval or coverage grid. It shows that the three caveats are
design-sensitive under stronger denominators, but it does not replace the
80-rep recovery grid, does not provide MCSE-quality public recovery wording,
and does not make non-Gaussian intervals available.

## Next Actions

Use this diagnostic to design a larger primary-cluster recovery top-up for the
three caveated rows. Do not use this sidecar for intervals, coverage, q2/q4,
REML, AI-REML, bridge support, `supported`, or high-q claims.

## 11. Team Learning

Recovery caveats should be split into two questions: whether the original row
is caveated, and whether the caveat is design-sensitive under a stronger
denominator. The widget now has separate rows for both signals.
