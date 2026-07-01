# Q-Series q1 Sigma Intercept Local Smoke

## 1. Goal

Run the reviewed Gaussian low-q q1 `sigma` intercept route contract as a local
n=5 direct sigma-SD smoke, while keeping all linked Q-Series support-cell
statuses unchanged.

## 2. Implemented

- Added `tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R`.
- Ran the local n=5 smoke for phylo, spatial, animal, and relmat q1 `sigma`
  intercept rows.
- Pinned the Wald interval call to `small_sample_df = "none"` and
  `bias_correct = "none"` for every replicate.
- Attempted endpoint-profile diagnostics for the same direct sigma-SD target
  and retained failed or budget-limited profile rows.
- Wrote the dashboard sidecar
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv`.
- Wrote 20 retained replicate rows, a seed manifest, `sessionInfo.txt`, and
  `git-sha.txt` under
  `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-sigma-intercept-smoke-local/`.
- Updated `tools/validate-mission-control.py` so the sidecar and artifact bundle
  are mission-control guarded.
- Updated the Q-Series widget to show a `Low-q sigma smoke` count and row-level
  `sigma smoke` links.
- Updated the dashboard README and bumped the widget version to `r139`.

## 3a. Decisions and Rejected Alternatives

- I treated this as route-smoke evidence only. Five local replicates are not a
  coverage denominator and cannot promote `interval_status`, `coverage_status`,
  `inference_ready`, or `supported`.
- I kept the q1 `sigma` intercept support cells at
  `point_fit/planned/planned`.
- I did not apply the location-axis bias+t correction. The smoke explicitly
  exercises the raw uncorrected sigma-side Wald route.
- I retained endpoint-profile failures and boundary rows instead of filtering
  to finite intervals. Dropping those rows would make the smoke look cleaner
  while losing the evidence needed for the next denominator design.
- I did not escalate to Totoro/FIIA, Nibi, Rorqual, or DRAC. Fisher/Gauss/Rose
  review must happen before host escalation or denominator work.

## 4. Files Touched

- `tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-sigma-intercept-smoke-local/structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-sigma-intercept-smoke-local/structured-re-gaussian-lowq-sigma-intercept-local-smoke-replicates.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-sigma-intercept-smoke-local/structured-re-gaussian-lowq-sigma-intercept-local-smoke-seed-manifest.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-sigma-intercept-smoke-local/sessionInfo.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-sigma-intercept-smoke-local/git-sha.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-sigma-intercept-local-smoke.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file
  tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R --help`:
  passed and printed the runner options.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R
  --providers=spatial --n-rep=1
  --output-dir=/tmp/drmtmb-sigma-intercept-smoke-rehearsal
  --overwrite=true --write-dashboard=false --profile-endpoint-max-eval=6`:
  passed and confirmed the direct Wald target label.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R
  --overwrite=true --profile-endpoint-max-eval=12`: passed and wrote 4 summary
  rows plus 20 retained replicate rows.
- `/opt/homebrew/bin/air format
  tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R
  tests/testthat/test-structured-re-conversion-contracts.R
  tools/validate-mission-control.py`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript parse check from `docs/dev-log/dashboard/index.html`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 4 Gaussian low-q sigma-intercept
  route-contract rows, and 4 Gaussian low-q sigma-intercept smoke rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: passed with 8409 PASS / 0 FAIL /
  0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q1-sigma-intercept-local-smoke.md')"`:
  passed with `after-task structure check passed`.
- `git diff --check`: passed.
- `find tools -type d -name '__pycache__' -print`: returned no paths after
  removing the `py_compile` scratch directory.

## 6. Tests of the Tests

The focused test reads the dashboard sidecar and the artifact mirror, requires
20 retained replicate rows and 20 seed rows, pins every replicate to
`small_sample_df = "none"` and `bias_correct = "none"`, checks that boundary
rows remain non-usable rather than dropped, and verifies that the four support
cells stay `point_fit/planned/planned`. The mission-control validator repeats
those checks outside testthat and also requires the current deterministic n=5
summary counts for phylo, spatial, animal, and relmat.

## 7a. Issue Ledger

- Added: a reproducible local smoke runner for the four q1 sigma-intercept
  cells.
- Added: a validator-owned smoke sidecar for those rows.
- Found and retained: phylo has one `wald_at_boundary` row; spatial has three
  `wald_at_boundary` rows.
- Found and retained: endpoint profiles are not uniformly clean; failed or
  budget-limited diagnostics are present in the artifact.
- Deferred: Fisher/Gauss/Rose review is still required before Totoro/FIIA
  repetition, Nibi/Rorqual denominator work, or any status edit.
- No GitHub issue action was taken in this slice because this is an internal
  Q-Series evidence artifact and no public-facing support claim changed.

## 8. Consistency Audit

- The support-cell TSV still has the four q1 `sigma` intercept rows at
  `fit_status = point_fit`, `interval_status = planned`, and
  `coverage_status = planned`.
- The sigma route-contract sidecar still records the route as no-promotion and
  keeps `compute_status = not_executed`; the executed evidence lives in the new
  smoke sidecar.
- The dashboard README now distinguishes the route contract from the local n=5
  smoke.
- The Q-Series widget now shows separate `Low-q sigma route` and
  `Low-q sigma smoke` cards and row links.
- Mission control validates that the dashboard summary mirrors the artifact
  summary exactly.

## 9. What Did Not Go Smoothly

Endpoint profiles are noisy in this tiny smoke: even successful profile rows can
record `NA/NaN function evaluation` warnings, and phylo/spatial include retained
boundary Wald rows. That is useful evidence, but it required making the summary
status distinguish raw-Wald route success from profile-diagnostic cleanliness.

## 10. Known Residuals

This promotes exactly no Q-Series row. It is not coverage evidence, not interval
reliability, not `inference_ready`, not `supported`, not q1 `mu`, not matched
`mu+sigma`, not q2/q4/q8, not non-Gaussian, not REML, not AI-REML, not bridge
support, not public support, and not cluster authorization. The next gate is
Fisher/Gauss/Rose review of the retained n=5 rows and a decision on whether a
Totoro/FIIA repeat is useful before any denominator design.

## 11. Team Learning

Sigma-side low-q work needs two parallel ledgers: one for the accepted target
route and one for executed smoke evidence. Keeping them separate prevents a
clean fit/pdHess story from turning into an interval or coverage claim while
still making the boundary/profile diagnostics visible for the next tranche.
