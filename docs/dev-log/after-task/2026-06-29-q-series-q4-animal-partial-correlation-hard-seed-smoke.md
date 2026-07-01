# Q-Series q4 Animal Partial-Correlation Hard-Seed Smoke

## 1. Goal

Wire the hidden q>2 `partial_cholesky` parameterization into the animal q4
all-four admission runner and run the retained local hard seeds `910101`,
`910102`, and `910110` without promoting any Q-Series row.

## 2. Implemented

- Added `--replicate-indexes` to
  `tools/run-structured-re-q4-animal-all-four-admission-probe.R` so the runner
  can replay exact retained hard seeds rather than replacing failed seeds.
- Added `--qgt2-parameterization=unstructured|partial_cholesky` and wired it to
  the hidden internal option
  `drmTMB.internal.qgt2_corr_parameterization`.
- Blocked accidental dashboard writes for the hidden `partial_cholesky` route;
  it must be artifact-only until a separate dashboard contract exists.
- Labelled seed, fit, replicate, summary, and run-log artifacts with
  `qgt2_parameterization`.
- Ran the local `more_levels` hard-seed smoke with `methods = wald`.
- Updated the verdict order so retained fit and Hessian failures are reported
  before small-denominator smoke status.
- Updated the q4 animal production-transform design gate with the hard-seed
  result.
- Updated the high-q audit row, next-campaign queue, dashboard README, and
  dashboard version so the widget surfaces the hidden TMB hard-seed blocker as
  the current animal q8-shaped all-four gate.

## 3a. Decisions and Rejected Alternatives

- I did not write a dashboard sidecar for the hidden route. The existing
  `structured-re-q4-animal-all-four-admission-probe.tsv` is validator-owned for
  the public unstructured route, and overwriting it with a hidden candidate
  would blur the claim boundary.
- I ran only Wald-target admission rows. The first pass showed `pdHess = FALSE`
  for every retained fit, so profile intervals would be uninformative and were
  correctly not attempted.
- I did not submit Totoro, FIIA, Nibi, Rorqual, or DRAC work. The local gate
  failed on Hessian conditioning, so cluster work would only multiply a known
  blocker.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-phylo-utils.R`
- `tools/run-structured-re-q4-animal-all-four-admission-probe.R`
- `docs/design/03-likelihoods.md`
- `docs/design/220-structured-q4-animal-production-transform-gate.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/structured-re-high-q-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/structured-re-q4-animal-all-four-admission-probe-fit-status.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/structured-re-q4-animal-all-four-admission-probe-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/structured-re-q4-animal-all-four-admission-probe-run-log.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/structured-re-q4-animal-all-four-admission-probe-seed-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/structured-re-q4-animal-all-four-admission-probe-target-summary.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/sessionInfo.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/git-sha.txt`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-partial-correlation-hard-seed-smoke.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format R/drmTMB.R
  tests/testthat/test-phylo-utils.R
  tools/run-structured-re-q4-animal-all-four-admission-probe.R`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  'parse("tools/run-structured-re-q4-animal-all-four-admission-probe.R");
  cat("parse_ok\n")'`: passed with `parse_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter = "phylo-utils")'`: passed with
  172 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file
  tools/run-structured-re-q4-animal-all-four-admission-probe.R
  --replicate-indexes=910101,910102,910110 --seed-base=910000
  --variant=more_levels
  --qgt2-parameterization=partial_cholesky --methods=wald
  --profile-max-eval=20
  --output-dir=docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local
  --overwrite=true --write-dashboard=false`: passed and wrote artifacts.
- Artifact inspection with `Rscript --no-init-file`: fit-status has 3 rows,
  `fit_ok = 3`, `pdHess = 0`; replicate TSV has 24 rows and all are
  `not_run_pdhess_false`; target-summary reports `pdhess_admission_blocked`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 structured RE q-series cells and 5 structured RE q-series
  inference-evidence summary rows.
- Dashboard JavaScript parse check from `docs/dev-log/dashboard/index.html`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: passed with 8253 PASS / 0 FAIL /
  0 WARN / 0 SKIP.
- Widget source check: the high-q row
  `qseries_animal_q4_all_four_one_slope_planned` and queue row
  `qseries_queue_high_q_geometry_stability` both point to
  `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-partial-correlation-hard-seed-smoke.md`
  and both include the `0/3 pdHess` blocker; dashboard version is `r136`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "wald-small-sample-default")'`: passed with 21 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-partial-correlation-hard-seed-smoke.md')"`:
  passed.

## 6. Tests of the Tests

The first artifact inspection exposed a verdict-order problem: the data showed
`pdHess = 0/3`, but the runner labelled the result
`smoke_only_insufficient_denominator` because it checked `n_rep < 16` first. I
changed `diagnostic_verdict()` to check fit and Hessian failures before the
small-denominator branch, reran the identical seeds, and the same artifact now
reports `pdhess_admission_blocked`. That gives a direct regression test of the
claim boundary: small retained smokes cannot hide a hard Hessian failure.

## 7a. Issue Ledger

- Fixed: the hard-seed runner can now replay exact replicate indexes.
- Fixed: hidden partial-correlation admission runs are labelled in artifact
  TSVs and cannot overwrite the public dashboard sidecar.
- Fixed: small retained smokes now report Hessian blockers before denominator
  size.
- Found and deferred: the hidden `partial_cholesky` route still fails the
  animal q4 all-four local admission gate because all three retained fits have
  `pdHess = FALSE`.

## 8. Consistency Audit

- The hidden route remains unavailable from public formula syntax and
  `drm_control()`.
- The public production default remains the unstructured q>2 route.
- The partial-correlation smoke wrote only to
  `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-partial-correlation-admission-probe-local/`;
  `dashboard_output` in the run log is `not_written`.
- The widget was updated through the high-q audit and campaign queue, not by
  overwriting the public q4 animal admission sidecar.
- The design note now says the next gate is Hessian/geometry diagnosis, not
  Nibi/Rorqual admission.

## 9. What Did Not Go Smoothly

The hidden route passed objective/report equivalence but did not survive the
public all-four hard-seed fit. The first runner verdict also under-reported the
blocker because denominator size was checked before Hessian status; that was
fixed and the artifacts were regenerated. I also caught an initial rehearsal
that used short replicate indexes `101,102,110`; the final preserved artifact
was rerun with the true retained hard-seed replicate indexes
`910101,910102,910110`.

## 10. Known Residuals

This promotes exactly no Q-Series row. It is not q4 or q8 `inference_ready`,
not `supported`, not interval reliability, not coverage evidence, not REML,
not AI-REML, not a public production transform, and not cluster authorization.
The animal q4 all-four row remains blocked on Hessian conditioning under the
public all-four fit.

## 11. Team Learning

For q4/q8 admission, objective equivalence is necessary but not sufficient.
The next useful high-q work should inspect Hessian geometry around the public
all-four fit before adding another optimizer wrapper or launching cluster
admission.
