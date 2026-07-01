# Q-Series q1 `sigma` Denominator Contract

## 1. Task

Add the first retained-denominator contract for the Gaussian low-q q1
`sigma:(Intercept)` route-passed rows without changing any support-cell status.

## 2. Scope

Rows covered:

- `qseries_animal_q1_sigma_intercept`
- `qseries_relmat_q1_sigma_intercept`

The contract does not cover phylo or spatial q1 `sigma` intercept rows because
their local n=5 smoke retained boundary/profile blockers. It also does not
cover q1 `mu`, matched `mu+sigma`, q2, q4/q8, non-Gaussian rows, REML,
AI-REML, bridge support, or public-support claims.

## 3. Evidence Basis

The source smoke is
`docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-local-smoke.tsv`.
Animal and relmat each had 5/5 usable raw-Wald intervals and 5/5 finite endpoint
profiles in the local n=5 route smoke. Both rows also retained warning
replicates, so the contract keeps warnings inside the denominator and requires
Fisher/Gauss/Rose review before any Nibi or Rorqual pregrid.

## 4. Added Artifact

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-denominator-contract.tsv`

The two-row sidecar pins:

- raw log-SD Wald intervals with `small_sample_df=none` and `bias_correct=none`;
- endpoint profiles as diagnostics only;
- all attempted replicates retained;
- finite-Wald subset reported but not used to delete boundary/profile rows;
- lower/upper misses, warnings, boundary rows, and profile failures retained;
- SR150 as the first pregrid denominator target;
- MCSE threshold `0.01`;
- no support-cell status edit before Fisher/Gauss/Rose and Rose audit.

## 5. Claim Boundary

This promotes exactly no Q-Series row under the q1 `sigma` retained-denominator
contract with no status-table edit and does not claim `interval_status`,
`coverage_status`, `inference_ready`, `supported`, location-axis bias+t
correction, q1 `mu`, matched `mu+sigma`, q2, q4/q8, non-Gaussian intervals,
REML, AI-REML, bridge support, completed DRAC denominator evidence, or public
support.

The linked support cells remain `point_fit/planned/planned`.

## 6. Next Gate

Fisher/Gauss/Rose must review the warning ledger and denominator policy. If
accepted, the next executable step is an SR150 Nibi pregrid for exactly animal
and relmat, with one thread per BLAS/TMB layer, raw replicate TSVs, summaries,
seed manifest, exact command, module list, source manifest, scheduler logs,
session info, and dirty-source label.

## 7. Validation

Validation is recorded in `docs/dev-log/check-log.md`.

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Embedded dashboard script syntax check via extracted `<script>` and
  `node --check /tmp/drmtmb-dashboard-script.js`: passed.
- Scoped `git diff --check` over the dashboard, validator, focused test,
  contract TSV, and after-task files: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 2 structured RE Gaussian low-q sigma-intercept denominator-contract
  rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9391 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
