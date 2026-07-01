# Q-Series q2 intercept interval contract

## 1. Goal

Replace the vague q2 intercept hold with an exact interval-denominator contract
for the four Gaussian q2 `mu1+mu2` intercept support cells, without promoting any
row or using connected cluster hosts prematurely.

## 2. Implemented

- Added `structured-re-q2-intercept-interval-contract.tsv`, a 12-row contract
  covering phylo, spatial, animal, and relmat q2 intercept rows.
- Split each provider into two direct-SD endpoint targets and one separate
  direct-correlation target so endpoint evidence cannot be inherited by the
  correlation target.
- Updated the Gaussian low-q row-selection generator and regenerated the
  dashboard and local artifact so q2 intercept rows point at the new contract.
- Registered the contract in `tools/validate-mission-control.py` and the focused
  structured-RE conversion-contract test.
- Documented the sidecar in the dashboard README.

## 3a. Decisions and Rejected Alternatives

The contract stays local-first even though Totoro, Nibi, Rorqual, and other DRAC
hosts are reachable. Totoro/FIIA are only smoke hosts after Fisher/Rose review;
Nibi/Rorqual/DRAC remain blocked until local deterministic q2 intercept smoke
passes.

The q2-plus-q2 location-and-scale row is excluded. It needs its own target and
denominator contract because scale-side and cross-endpoint targets cannot inherit
q2 location-intercept evidence.

No `inference_ready` or `supported` promotion is made. The linked support cells
remain `fit_status = point_fit`, `interval_status = planned`, and
`coverage_status = planned`.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-intercept-interval-contract.tsv`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q2-intercept-interval-contract.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed; wrote 23 Gaussian low-q row-selection rows.
- `/opt/homebrew/bin/air format tests/testthat/test-structured-re-conversion-contracts.R tools/summarize-structured-re-gaussian-lowq-row-selection.R`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 7,918 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `python3 tools/validate-mission-control.py`: passed with
  `mission_control_ok`, including 104 structured RE q-series cells, 23
  Gaussian low-q row-selection rows, and 12 structured RE q2 intercept
  interval-contract rows.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q2-intercept-interval-contract.md')"`:
  passed with `after-task structure check passed`.

## 6. Tests of the Tests

The focused test now asserts that the contract has exactly 12 rows, excludes
q2-plus-q2 cells, separates direct-SD and direct-correlation target kinds, and
keeps linked q2 support-cell interval and coverage statuses at `planned`. The
mission-control validator repeats those checks and also requires local-first
host gating, claim-boundary non-promotions, and provider-specific exclusions for
range-estimating spatial, pedigree/Ainv, and Q bridge marshalling.

## 7a. Issue Ledger

- Fixed: the row-selection ledger no longer says only "write q2 endpoint/correlation
  target contract" for q2 intercept rows; it points to the exact sidecar.
- Deferred: q2-plus-q2 intercept still needs a separate row-specific contract.
- Deferred: no q2 intercept smoke or coverage grid has been run.

## 8. Consistency Audit

Checked the q2 acceptance gate, q2 target-contract sidecar, low-q row-selection
ledger, support-cell rows, dashboard README, validator, and focused tests. The
new contract is tied to the four existing q2 point/fixture support cells and
does not change the source-of-truth support-cell statuses.

## 9. What Did Not Go Smoothly

The dashboard README first used a line break around "location + scale" that
could render like a Markdown list marker. It was rewritten as
"location-and-scale" before validation.

## 10. Known Residuals

The contract is not runtime evidence. The next executable step is a local
deterministic q2 intercept smoke that retains fit, convergence, `pdHess`,
`confint()`, profile, and bootstrap-attempt accounting. Totoro/FIIA, Nibi,
Rorqual, and DRAC stay blocked until the local and review gates named in the
contract pass.

## 11. Team Learning

When all cluster hosts are reachable, the safest move is still to encode the
host ladder before launching compute. q2 endpoint SDs and q2 correlations should
be separate denominator targets from the start, or later status edits will be
tempted to promote by analogy.
