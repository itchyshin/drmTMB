# Q-Series q1 `sigma` SR150 Pregrid Prep

## 1. Task

Move the reviewed animal/relmat q1 `sigma:(Intercept)` retained-denominator
contract from review hold to an executable SR150 pregrid path without changing
any Q-Series support-cell status.

## 2. Scope

In scope:

- `qseries_animal_q1_sigma_intercept`
- `qseries_relmat_q1_sigma_intercept`
- the raw log-SD Wald-z interval channel with `small_sample_df=none` and
  `bias_correct=none`
- endpoint-profile diagnostics retained as diagnostics only
- Nibi primary execution, with Rorqual allowed only for confirmation or overflow

Out of scope: phylo/spatial q1 `sigma`, q1 `mu`, matched `mu+sigma`, q2, q4/q8,
non-Gaussian rows, REML, AI-REML, bridge support, public support, or any
`inference_ready` / `supported` claim.

## 3. Review Decision

Fisher, Gauss, and Rose accepted the existing warning ledger and retained-
denominator policy as sufficient to prepare the SR150 artifact run for exactly
the animal and relmat q1 `sigma` intercept rows. The decision authorizes the
pregrid execution path only. It does not authorize a status-table edit.

The support cells remain `point_fit/planned/planned`.

## 4. Implementation

- Updated
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-sigma-intercept-denominator-contract.tsv`
  to `fisher_gauss_rose_reviewed_sr150_pregrid_ready` while keeping
  `promotion_decision = do_not_promote`.
- Added `tools/run-structured-re-gaussian-lowq-sigma-intercept-pregrid.R`.
  The wrapper refuses non-SR150 replicate counts, provider sets other than
  animal+relmat, dashboard writes, local host classes, stale contract states,
  and promotion-bearing contract rows.
- Added `tools/slurm/q1-sigma-intercept-pregrid-nibi.sbatch` for a scheduler-
  run source snapshot, package install, exact command capture, module list,
  session info, source manifest, runner stdout/stderr, and `seff` when
  available.
- Updated the focused conversion-contract test and mission-control validator so
  the reviewed pregrid state is enforced.

## 5. Claim Boundary

This promotes exactly no Q-Series row under the raw log-SD Wald-z sigma direct-
SD pregrid channel with all attempted replicates retained. It does not claim
`interval_status`, `coverage_status`, `inference_ready`, `supported`,
location-axis bias+t correction, q1 `mu`, matched `mu+sigma`, q2, q4/q8,
non-Gaussian interval evidence, REML, AI-REML, bridge support, completed DRAC
denominator evidence, or public support.

## 6. Next Gate

Run the SR150 Nibi pregrid for exactly animal and relmat with pinned BLAS/TMB
threads and artifact-only dashboard behavior. Import nothing into the dashboard
until the raw output, lower/upper misses, finite interval fraction, warning
ledger, boundary/profile failures, and MCSE are reviewed. `MCSE <= 0.01`
remains a top-up target, not an SR150 pass claim.

## 7. Validation

Validation is recorded in `docs/dev-log/check-log.md`.

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse(file =
  "tools/run-structured-re-gaussian-lowq-sigma-intercept-pregrid.R"); parse(file
  = "tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R")'`: passed.
- `bash -n tools/slurm/q1-sigma-intercept-pregrid-nibi.sbatch`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Scoped `git diff --check` over the touched sigma pregrid files: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells and 2 structured RE Gaussian low-q
  sigma-intercept denominator-contract rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9419 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
