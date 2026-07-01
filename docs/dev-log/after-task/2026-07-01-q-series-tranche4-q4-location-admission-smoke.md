# After Task: Q-Series Tranche 4 Q4 Location Admission Smoke

## 1. Goal

Finish the Tranche 4 q4 location admission-runner slice by moving from a
design-only contract to local retained-denominator smoke evidence for the exact
16 q4 location direct-SD targets.

## 2. Implemented

Implemented and executed a local `n = 5` retained-denominator q4 location
admission smoke that records all 80 provider/replicate/target rows and a
16-row dashboard summary without authorizing coverage or promotion.

## 3a. Decisions and Rejected Alternatives

The smoke uses the q4 bivariate Gaussian location model already scoped by the
Tranche 3 target map:

- `mu1 = y1 ~ x + provider(1 + x | p | group)`
- `mu2 = y2 ~ x + provider(1 + x | p | group)`
- `sigma1 = ~1`, `sigma2 = ~1`, `rho12 = ~1`

The direct-SD targets are exactly the four `profile_targets()` rows per
provider: `mu1:(Intercept)`, `mu1:x`, `mu2:(Intercept)`, and `mu2:x` for
`phylo`, fixed-covariance `spatial`, A-matrix `animal`, and K-matrix `relmat`.
Derived-correlation intervals remain unavailable and are not reconstructed.

Rejected alternatives: the slice does not launch q4 coverage, does not mix
Totoro/DRAC denominators with local evidence, and does not reuse the old
coverage-grid runner as a claim-bearing admission result.

## 4. Files Touched

- `tools/run-structured-re-q4-location-admission-smoke.R`
- `docs/dev-log/dashboard/structured-re-q4-location-admission-smoke.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-admission-smoke/structured-re-q4-location-admission-smoke-results.tsv`
- `docs/dev-log/simulation-artifacts/2026-07-01-q4-location-admission-smoke/structured-re-q4-location-admission-smoke-run-log.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tools/run-structured-re-q4-location-admission-smoke.R'))"`:
  passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file
  tools/run-structured-re-q4-location-admission-smoke.R --mode=dry-run
  --provider=phylo --n_rep=1 --summary_path=NA
  --out_dir=/tmp/drmtmb-q4-admission-debug`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file tools/run-structured-re-q4-location-admission-smoke.R
  --mode=execute --provider=phylo --n_rep=1 --summary_path=NA
  --out_dir=/tmp/drmtmb-q4-admission-debug`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file tools/run-structured-re-q4-location-admission-smoke.R
  --mode=execute --provider=all --n_rep=5 --host_label=local`: passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `awk '/<script>/{flag=1; next} /<\\/script>/{flag=0} flag {print}'
  docs/dev-log/dashboard/index.html > /tmp/drmtmb-dashboard-index.js &&
  node --check /tmp/drmtmb-dashboard-index.js`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tools/run-structured-re-q4-location-admission-smoke.R'));
  invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- `air format tools/run-structured-re-q4-location-admission-smoke.R
  tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 16 q4 location admission-smoke rows,
  and 80 q4 location admission-smoke raw rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: passed `11277 PASS / 0 FAIL / 0
  WARN / 0 SKIP`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche4-q4-location-admission-smoke.md')"`:
  passed.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused test recomputes `pdHess`, Wald-finite, profile-finite, warning, and
boundary counts from the 80 raw retained rows, then compares them with the
16-row dashboard summary. It also checks that all q4 support cells remain below
`inference_ready`.

## 7a. Issue Ledger

No GitHub issue action was taken in this local slice. The branch records the
evidence in Mission Control and the completion map; any PR text should keep the
same no-promotion boundary.

## 8. Consistency Audit

Rose: the smoke records evidence, not a tier/status promotion. The retained
denominator shows phylo, spatial, and animal fail the first local gate on
`pdHess`/Wald-finite rates; relmat passes this tiny local gate but remains
review-required and not admitted.

Fisher: coverage remains unauthorized because q4 admission is not complete
across providers and the run is a local `n = 5` smoke, not an MCSE-controlled
coverage grid.

Gauss: fit, Hessian, gradient-warning, profile-warning, and boundary indicators
are retained in the raw target rows rather than filtered away.

Noether: the summary preserves the exact Tranche 3 `profile_targets()` names
and does not turn derived correlations into interval targets.

## 9. What Did Not Go Smoothly

The dashboard validator had several duplicated render-signature checks, so the
new sidecar needed both HTML and validator updates to keep Mission Control from
silently omitting the local smoke table.

## 10. Known Residuals

- This is local-only `host_label = local` evidence.
- No Totoro, DRAC, Nibi, Rorqual, or Fir q4 admission run was launched.
- The smoke is not a coverage grid and has no MCSE-controlled coverage claim.
- Relmat's 5/5 local smoke pass is review-required and does not admit the row.
- No q4, q8, REML, AI-REML, derived-correlation, bridge, or public-support
  claim is promoted.

## 11. Team Learning

For denominator-sensitive q4 work, first write a runner that fits once per
provider/replicate and fans out to the direct-SD target rows. This keeps the raw
denominator honest without multiplying q4 fits by target count.

## 12. Next Actions

Review the local retained-denominator smoke with Fisher/Rose/Gauss/Noether.
Only after an admission decision is explicitly banked should any q4 coverage
design be considered.
