# Q-Series q>2 Partial-Correlation Equivalence Harness

## 1. Goal

Bank the first lower-level q>2 correlation-parameterization harness for the
animal q4/q8 blocker without changing public syntax, defaults, support-cell
status, or cluster authorization.

## 2. Implemented

- Added the hidden TMB data flag `qgt2_corr_parameterization`.
- Kept the R-side production builder fixed at `qgt2_corr_parameterization = 0`,
  preserving the current `density::UNSTRUCTURED_CORR_t(theta_phylo)` route.
- Added a non-public `qgt2_corr_parameterization = 1` branch for the hidden
  `model_type = 93` probe that reconstructs a q>2 correlation matrix through a
  partial-correlation Cholesky transform.
- Hardened `tests/testthat/test-phylo-utils.R` so the partial-correlation route
  is checked against independent R algebra and against the current
  `UNSTRUCTURED_CORR_t` route at matched q=8 correlation matrices.
- Updated `docs/design/03-likelihoods.md` and
  `docs/design/220-structured-q4-animal-production-transform-gate.md` to record
  the internal-only boundary.

## 3a. Decisions and Rejected Alternatives

- I kept the switch non-public. It is not a `drm_control()` option and is not
  reachable from user formula syntax.
- I did not launch Totoro, FIIA, Nibi, Rorqual, or DRAC work. This slice only
  proves the hidden objective/report path; it does not satisfy the hard-seed
  admission gate.
- I added matched-correlation equivalence against the current TMB
  `UNSTRUCTURED_CORR_t` route rather than accepting an independent R-only
  algebra check. That is the smallest useful proof before any admission runner.

## 4. Files Touched

- `src/drmTMB.cpp`
- `R/drmTMB.R`
- `tests/testthat/test-phylo-utils.R`
- `docs/design/03-likelihoods.md`
- `docs/design/220-structured-q4-animal-production-transform-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-qgt2-partial-correlation-equivalence-harness.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format tests/testthat/test-phylo-utils.R`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter = "phylo-utils")'`: passed with
  167 PASS / 0 FAIL / 0 WARN / 0 SKIP after the row-major lower-triangle
  packing helper fix.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "wald-small-sample-default")'`: passed with 21 PASS / 0 FAIL / 0 WARN /
  0 SKIP, exercising the production fit path with the new hidden data default.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-qgt2-partial-correlation-equivalence-harness.md')"`:
  passed.

## 6. Tests of the Tests

The focused test now checks three layers for the hidden candidate: independent
R reconstruction, the TMB report/objective under
`qgt2_corr_parameterization = 1`, and the current `UNSTRUCTURED_CORR_t` route
at the same correlation matrices. The first strengthened run failed because
the helper mapped the correlation matrix back to TMB's lower triangle in
column-major order, while the existing TMB helper uses row-major pair order.
Fixing that helper made the same test pass, so this also tests the packing
contract.

## 7a. Issue Ledger

- Fixed: the lower-level parameterization design gate now has a hidden C++/R
  equivalence harness instead of only a prose requirement.
- Deferred: the local hard-seed admission runner for seeds `910101`, `910102`,
  and `910110`.
- Deferred: any Nibi/Rorqual admission job.
- Deferred: any q4/q8 coverage grid.

## 8. Consistency Audit

- The production R data builder still sets `qgt2_corr_parameterization = 0`.
- The only test-side override is inside the hidden `model_type = 93` harness.
- The design docs state that the switch is not user-facing and not a status
  promotion.
- Mission control still reports 104 Q-Series support cells and 5
  inference-ready rows; this slice changes neither count.

## 9. What Did Not Go Smoothly

The existing hidden route had an independent R check, but not the stronger
matched-correlation comparison against the current `UNSTRUCTURED_CORR_t` route.
Adding that comparison exposed the lower-triangle packing-order mismatch in the
test helper before the harness was accepted.

## 10. Known Residuals

This promotes exactly no Q-Series row. It is not q4 or q8 `inference_ready`,
not `supported`, not interval reliability, not coverage evidence, not REML,
not AI-REML, not a public production transform, and not cluster authorization.
The animal q4 all-four row remains blocked until the hard-seed local admission
runner passes.

## 11. Team Learning

For high-q work, the right order is algebra, hidden objective/report
equivalence, hard-seed admission, then cluster work. Running connected clusters
before the hidden route has this proof would spend compute without improving
the claim boundary.
