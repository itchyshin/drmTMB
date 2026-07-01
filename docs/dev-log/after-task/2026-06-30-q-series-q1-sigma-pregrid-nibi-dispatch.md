# Q-Series q1 `sigma` SR150 Nibi Dispatch

## 1. Task

Dispatch the reviewed artifact-only SR150 retained-denominator pregrid for the
Gaussian low-q q1 `sigma:(Intercept)` direct-SD rows that passed the local route
smoke and Fisher/Gauss/Rose denominator review.

## 2. Dispatch

- Host: Nibi.
- Original SLURM job: `16982141`, failed before simulation.
- Retry SLURM job: `16982458`.
- Retry submit state: completed `0:0` in 4m20s on `c321`.
- Run root:
  `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-sigma-sr150-77b634ed-r169`.
- Source snapshot:
  `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-sigma-sr150-77b634ed-r169/source`.
- Runner:
  `tools/run-structured-re-gaussian-lowq-sigma-intercept-pregrid.R`.
- SLURM script:
  `tools/slurm/q1-sigma-intercept-pregrid-nibi.sbatch`.

## 3. Scope

Rows covered:

- `qseries_animal_q1_sigma_intercept`
- `qseries_relmat_q1_sigma_intercept`

The job uses the raw log-SD Wald-z channel with `small_sample_df=none` and
`bias_correct=none`; endpoint profiles are diagnostic only. The job excludes
phylo and spatial q1 `sigma` intercept rows because their local n=5 smoke
retained boundary/profile blockers.

## 4. Reproducibility

The local working tree was copied as a source snapshot because the Q-Series
branch is an active dirty worktree with uncommitted dashboard, runner, and
artifact records. The retry dispatch uses `DRMTMB_GIT_SHA=77b634ed-dirty-r169`.

Job `16982141` installed the package successfully, then failed before any
simulation rows because the runner tried `devtools::load_all()` on the compute
node and `devtools` was not in the isolated R library. I patched the sigma
runner to fall back to `library(drmTMB)` when the package has already been
installed by the SLURM script, then submitted retry job `16982458`.

The SLURM script pins R/TMB and BLAS threads to one thread, writes exact command
lines, module list, session info, git SHA, scheduler logs, source SHA256
manifest, raw replicate TSV, summary TSV, seed manifest, and `seff` when
available.

## 5. Dashboard Record

`structured-re-gaussian-lowq-sigma-intercept-pregrid-dispatch.tsv` records one
dispatch row per provider: animal and relmat. Each row keeps
`promotion_decision = do_not_promote` and
`submit_status = completed_imported_reviewed_blocked_no_topup` after the
follow-up Fisher/Gauss/Rose blocker sync.

`structured-re-gaussian-lowq-sigma-intercept-pregrid-results.tsv` records the
imported Nibi SR150 summary. For both animal and relmat, fit, convergence,
`pdHess`, and `confint()` succeeded for 150/150 replicates. The raw Wald
interval route is still diagnostic-blocked: only 115/150 intervals were usable,
coverage on the finite subset was 113/115 (`0.9826`, MCSE `0.012190`), misses
were lower `2` / upper `0`, and 118/150 replicates retained warnings.

## 6. Claim Boundary

This promotes exactly no Q-Series row. Retry job `16982458` completed and its
artifacts were imported, but the result is diagnostic-blocked by finite
raw-Wald interval censoring and warnings. This is not reviewed coverage
evidence and does not claim `interval_status`, `coverage_status`,
`inference_ready`, `supported`, location-axis bias+t correction, q1 `mu`,
matched `mu+sigma`, q2, q4/q8, non-Gaussian interval evidence, REML, AI-REML,
bridge support, or public support.

## 7. Next Gate

Fisher/Gauss/Rose must review the retained denominator, 115/150 usable
intervals, 118/150 warning replicates, lower/upper misses, MCSE `0.012190`,
profile failures, boundary rows, failure taxonomy, and whether the sigma
interval route must be hardened before any SR475/SR1000 top-up or status-table
edit.

## 8. Checks

Validation is recorded in `docs/dev-log/check-log.md`:

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Scoped `git diff --check` over the touched sigma import/widget/test files:
  passed.
- Dashboard JavaScript extracted from `docs/dev-log/dashboard/index.html` and
  checked with `node --check`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9517 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
