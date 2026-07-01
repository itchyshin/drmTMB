# Q-Series q1 sigma-intercept route-pass hold

## 1. Goal

Make the Gaussian q1 sigma-intercept animal/relmat local-smoke state more
precise without promoting any support cell. The local n=5 smoke already split
the providers: phylo/spatial retained boundary/profile blockers, while
animal/relmat had 5/5 usable raw-Wald intervals and no boundary/profile
failures, but retained warning replicates and no calibrated denominator.

## 2. Implemented

- Changed `qseries_animal_q1_sigma_intercept` and
  `qseries_relmat_q1_sigma_intercept` row-selection status from
  `sigma_smoke_route_review_pending` to
  `sigma_smoke_route_passed_denominator_review_hold`.
- Changed their run mode to
  `fisher_gauss_rose_denominator_review_before_host`.
- Regenerated `structured-re-gaussian-lowq-row-selection.tsv` and its mirror
  artifact.
- Updated the support-cell claim boundaries and Gaussian low-q audit rows to
  state that animal/relmat q1 sigma smoke is route-passed
  denominator-review-hold evidence only.
- Updated mission-control and focused dashboard tests to enforce the new split.
- Bumped the dashboard widget build to `r151`.

## 3a. Decisions and Rejected Alternatives

- Did not promote interval or coverage status. The smoke uses five replicates,
  so it is route evidence, not coverage evidence.
- Did not send the rows to Nibi/Rorqual/DRAC. The retained denominator,
  one-sided miss policy, warning policy, profile policy, and host-escalation
  rule still need Fisher/Gauss/Rose review.
- Did not collapse animal/relmat with phylo/spatial. The latter remain
  `sigma_smoke_diagnostic_blocked` because they have boundary and profile
  failure rows.

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

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `cmp docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series support cells.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8619 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## 8. Consistency Audit

The support-cell rows, Gaussian low-q audit rows, generated row-selection rows,
row-selection artifact mirror, mission-control validator, and focused R test
now agree on the split:

- phylo/spatial q1 sigma intercept: diagnostic blocked;
- animal/relmat q1 sigma intercept: route-passed denominator-review hold.

## 10. Known Residuals

- No q1 sigma intercept row was promoted to interval-ready, coverage-ready,
  `inference_ready`, or `supported`.
- Animal/relmat need Fisher/Gauss/Rose review of the warning ledger, retained
  denominator, one-sided misses, profile policy, and host-escalation rule before
  any Totoro/FIIA repeat or Nibi/Rorqual/DRAC denominator work.
- Phylo/spatial remain blocked on boundary/profile failure diagnostics.

## 11. Team Learning

A clean finite-Wald smoke is still not a denominator. The row can move out of a
generic route-review bucket, but it still needs a retained-denominator contract
before it can spend cluster time or support an interval claim.
