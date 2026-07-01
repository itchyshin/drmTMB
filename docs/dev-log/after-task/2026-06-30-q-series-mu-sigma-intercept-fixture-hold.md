# Q-Series q1 mu+sigma intercept fixture-hold split

## 1. Goal

Make the Gaussian q1 `mu+sigma` intercept local-smoke state precise without
promoting any support cell. The local n=1 target smoke split the rows: phylo
retains a nonusable boundary/correlation signal, while spatial/animal/relmat
had fixture-only target-smoke passes that still need denominator review.

## 2. Implemented

- Kept `qseries_phylo_q1_mu_sigma_intercept` at
  `mu_sigma_smoke_diagnostic_blocked`.
- Changed `qseries_spatial_q1_mu_sigma_intercept`,
  `qseries_animal_q1_mu_sigma_intercept`, and
  `qseries_relmat_q1_mu_sigma_intercept` from
  `mu_sigma_smoke_fixture_review_pending` to
  `mu_sigma_smoke_fixture_passed_denominator_review_hold`.
- Changed the three fixture-passed rows to run mode
  `fisher_noether_rose_denominator_review_before_host`.
- Regenerated `structured-re-gaussian-lowq-row-selection.tsv` and its mirror
  artifact.
- Updated support-cell and Gaussian low-q audit prose to state that the
  fixture-passed rows remain `point_fit / planned / planned`.
- Bumped the dashboard widget build to `r152`.

## 3a. Decisions and Rejected Alternatives

- Did not promote interval status, coverage status, `inference_ready`, or
  `supported`. The evidence is local n=1 target smoke only.
- Did not collapse phylo with spatial/animal/relmat. Phylo keeps the
  nonusable boundary/correlation interval signal and stays diagnostic-blocked.
- Did not send the rows to Totoro/FIIA or DRAC. Fisher/Noether/Rose still need
  target-specific denominator and blocker-retention rules before any host smoke.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/after-task/2026-06-30-q-series-mu-sigma-intercept-fixture-hold.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `cmp docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series support cells and
  23 Gaussian low-q row-selection rows.
- First focused test run:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  failed with 8620 PASS / 1 FAIL / 0 WARN / 0 SKIP because the new test
  incorrectly required `denominator-review-held` on the phylo diagnostic row.
- Final focused test run with the row-specific assertion:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8622 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## 6. Tests of the Tests

The first focused test run failed because the assertion treated the
fixture-passed hold phrase as common to all four rows. That failure caught a real
row-specific mistake in the test design: phylo is diagnostic-blocked, not
denominator-review-held. The corrected test now checks common no-promotion
language across all four rows and checks `denominator-review-held` only for
spatial/animal/relmat.

## 7a. Issue Ledger

No GitHub issue was updated in this slice. This is an internal Q-Series ledger
and widget consistency change, not a new public capability claim.

## 8. Consistency Audit

Rose audit result: the generator, generated row-selection TSV, artifact mirror,
mission-control validator, focused R test, support-cell source TSV, and Gaussian
low-q audit TSV now agree on the row split:

- phylo q1 `mu+sigma` intercept: diagnostic-blocked;
- spatial/animal/relmat q1 `mu+sigma` intercept: fixture-passed
  denominator-review hold;
- all four rows remain `point_fit / planned / planned`.

Targeted stale-wording scan:

```sh
rg -n "mu_sigma_smoke_fixture_review_pending|mu_sigma_smoke_fixture_passed_denominator_review_hold|denominator-review-held" \
  tools/summarize-structured-re-gaussian-lowq-row-selection.R \
  tools/validate-mission-control.py \
  tests/testthat/test-structured-re-conversion-contracts.R \
  docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv \
  docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv
```

Only the new fixture-hold status and fixture-specific test phrase remain.

## 9. What Did Not Go Smoothly

The first test update overgeneralized the fixture-hold wording to phylo. The
failure was useful: it forced the test to encode the actual row-level split
instead of a convenient common phrase.

## 10. Known Residuals

- No q1 `mu+sigma` intercept row is interval-ready, coverage-ready,
  `inference_ready`, or `supported`.
- The fixture-passed rows need Fisher/Noether/Rose target-specific denominator,
  blocker-retention, and host-smoke review before Totoro/FIIA, Nibi/Rorqual, or
  DRAC work.
- Phylo remains blocked on the retained nonusable boundary/correlation interval
  signal.

## 11. Team Learning

Matched `mu+sigma` rows need two layers of honesty: split the endpoint targets
inside the row, then split provider rows. A phrase that is true for
spatial/animal/relmat can still be false for phylo, even when all four share the
same smoke artifact.
