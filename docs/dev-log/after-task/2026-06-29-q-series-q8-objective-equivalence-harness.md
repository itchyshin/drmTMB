## 1. Goal

Bank a local q=8 objective/report equivalence harness for the current
phylogenetic q>2 `UNSTRUCTURED_CORR_t` covariance route before spending
connected Totoro, FIIA, Nibi, Rorqual, or DRAC compute on q4/q8 animal
admission work.

## 2. Implemented

- Added a focused q=8 `model_type = 93` test in
  `tests/testthat/test-phylo-utils.R`.
- The test exercises both the zero-correlation point and three finite
  28-coordinate `theta_phylo` vectors.
- The test compares TMB reports for `sd_phylo`, `theta_phylo`,
  `phylo_q4_corr`, `phylo_q4_covariance`, `log_det_covariance`,
  `quadratic`, and `quadratic_matrix` against independent R algebra.
- The test compares the TMB objective against both a hand-computed objective
  and `drmTMB:::drm_phylo_correlated_precision_nll()`.
- Updated
  `docs/design/220-structured-q4-animal-production-transform-gate.md` to mark
  this as a banked baseline harness for future lower-level TMB/C++ transform
  candidates.

## 3a. Decisions and Rejected Alternatives

- I extended the existing q4 scaffold test instead of adding a new dashboard
  row because this slice is an internal equivalence harness, not new row-level
  evidence.
- I did not submit any Totoro, FIIA, Nibi, Rorqual, or DRAC job. The current
  animal q4 all-four route remains locally blocked by the hard-seed admission
  diagnostics, so cluster time would not be evidence-efficient yet.
- I tested the current `UNSTRUCTURED_CORR_t` route at zero and three finite
  q=8 parameter vectors. This satisfies the baseline several-vector
  equivalence step for the current route; any proposed replacement transform
  still needs its own matched-parameter proof and tests.

## 4. Files Touched

- `tests/testthat/test-phylo-utils.R`
- `docs/design/220-structured-q4-animal-production-transform-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q8-objective-equivalence-harness.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format tests/testthat/test-phylo-utils.R`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "phylo-utils")'`: passed with 119 PASS / 0 FAIL / 0 WARN / 0 SKIP after the fixture correction and several-vector hardening.
- `git diff --check`: passed.
- `python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 104 structured RE q-series cells and 5 structured RE q-series inference-evidence summary rows.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q8-objective-equivalence-harness.md')"`: passed.

## 6. Tests of the Tests

The first focused run failed inside the new q=8 test because the fixture
provided 24 effects while the augmented phylogenetic precision has four rows
and q=8 therefore needs 32 effects. After fixing the fixture shape, the same
focused test file passed. The final test also uses a hand-computed objective,
not only the existing R helper, so a mismatch in the reported determinant,
quadratic form, covariance reconstruction, or objective path has an independent
check. The test now repeats that independent check at zero and at three finite
q=8 parameter vectors.

## 7a. Issue Ledger

- Fixed: q=8 fixture effect matrix had the wrong row-by-column length on the
  first attempt.
- Deferred: lower-level TMB/C++ production transform design for the animal q4
  all-four row.
- Deferred: local hard-seed admission runner for any replacement transform.
- Deferred: cluster smoke or DRAC coverage for this row.

## 8. Consistency Audit

- Checked the existing q=4 scaffold test in `tests/testthat/test-phylo-utils.R`
  and reused the same helper path.
- Checked `src/drmTMB.cpp` `model_type == 93` and the production q>2
  `UNSTRUCTURED_CORR_t` route to confirm the reported quantities and objective
  target being locked down.
- Ran mission-control validation to ensure no dashboard/source-of-truth drift
  was introduced.
- Updated the q4 animal production-transform gate so the design note reflects
  the new baseline harness without implying inference readiness.
- Probed connected compute routes without submitting work: `ssh nibi hostname`
  returned `l5.nibi.sharcnet`, `ssh rorqual hostname` returned `rorqual2`, and
  `ssh narval hostname` returned `narval2`. Totoro still requires interactive
  authentication from this shell, and the FIIA alias is not present.

## 9. What Did Not Go Smoothly

The first test fixture assumed three phylogenetic rows, but the augmented
precision for the tiny tree has four rows. The focused test caught this before
any broader package run.

## 10. Known Residuals

This promotes exactly no Q-Series row. It is not q4/q8 `inference_ready`, not
`supported`, not interval reliability, not coverage evidence, not REML, not
AI-REML, and not a production replacement transform. The animal q4 all-four
row remains blocked until a lower-level transform candidate and local
hard-seed admission runner pass.

## 11. Team Learning

High-q work should keep banking small equivalence checks before cluster
campaigns. For q8-shaped rows, lock down the current objective and report
algebra first, then use Totoro/FIIA/Nibi/Rorqual/DRAC only after the local
admission contract has something worth testing.
