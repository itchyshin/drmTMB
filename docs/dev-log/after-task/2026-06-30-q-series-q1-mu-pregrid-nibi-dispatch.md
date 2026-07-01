# Q-Series q1 `mu` SR150 Nibi Dispatch And Import

## 1. Task

Dispatch the reviewed artifact-only SR150 retained-denominator pregrid for the
four Gaussian q1 `mu` intercept direct-SD rows.

## 2. Dispatch

- Host: Nibi.
- Original SLURM job: `16976756`, failed before simulation.
- Resubmitted SLURM job: `16977254`, completed successfully.
- Submit state at dispatch: `PD` with reason `Priority`; final state:
  `COMPLETED` with exit code `0:0`.
- Run root:
  `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-mu-sr150-77b634ed-r162`.
- Source snapshot:
  `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-mu-sr150-77b634ed-r162/source`.
- Runner:
  `tools/run-structured-re-gaussian-lowq-mu-intercept-pregrid.R`.
- SLURM script:
  `tools/slurm/q1-mu-intercept-pregrid-nibi.sbatch`.

## 3. Reproducibility

The local working tree was copied as a source snapshot because the Q-Series
branch is an active dirty worktree with many uncommitted dashboard, runner, and
artifact records. The active resubmission uses
`DRMTMB_GIT_SHA=77b634ed-dirty-r162`; the SLURM script also writes a source
SHA256 manifest, module list, exact command,
session info, git SHA, scheduler logs, raw replicate TSV, summary TSV, seed
manifest, and `seff` when available.

Job `16976756` installed the package successfully, then stopped before any
simulation rows because the runner still required the older row-selection
statuses and rejected the reviewed
`nibi_rorqual_substitution_smoke_reviewed` state. I patched the runner to accept
that reviewed state while keeping the exact four-provider set, Nibi/Rorqual host
gate, retained-denominator contract, and `do_not_promote` checks. The active
resubmission, job `16977254`, completed and the artifacts were imported locally
under
`docs/dev-log/simulation-artifacts/2026-06-30-gaussian-lowq-mu-intercept-pregrid-nibi/`.

## 4. Dashboard Record

`structured-re-gaussian-lowq-mu-intercept-pregrid-dispatch.tsv` records one
dispatch row per provider: phylo, spatial, animal, and relmat. Each row keeps
`promotion_decision = do_not_promote`.

`structured-re-gaussian-lowq-mu-intercept-pregrid-results.tsv` records the
imported SR150 result rows. All four providers retained 150/150 attempted
replicates with convergence, `pdHess`, and finite intervals. Coverage and
one-sided misses were:

| Provider | Coverage | MCSE | Lower miss | Upper miss |
| --- | ---: | ---: | ---: | ---: |
| phylo | 0.9800 | 0.011431 | 2 | 1 |
| spatial | 0.9733 | 0.013154 | 2 | 2 |
| animal | 0.9800 | 0.011431 | 2 | 1 |
| relmat | 0.9800 | 0.011431 | 1 | 2 |

MCSE remains above the <=0.01 top-up target, so these are review/top-up
artifacts, not status-promotion evidence.

## 5. Checks

- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 4 q1 `mu` retained-denominator contract rows,
  and 4 q1 `mu` pregrid-dispatch rows.
- Embedded dashboard script syntax check via extracted `<script>` and
  `node --check /tmp/drmtmb-dashboard-script.js`: passed.
- `git diff --check` on touched files: passed.
- Focused R test before result import:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 8997 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- Final focused R test after result import:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9076 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- Final mission-control validator:
  `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 4 structured RE Gaussian low-q `mu` intercept pregrid-result rows.

## 6. Claim Boundary

This promotes exactly no Q-Series row. Job `16977254` completed as an
artifact-only SR150 retained-denominator pregrid and the result is imported for
Fisher/Rose/Grace review only. Job `16976756` failed before simulation and is
retained only as dispatch/failure provenance. This does not claim
`interval_status`, `coverage_status`,
`inference_ready`, `supported`, q1 sigma, matched `mu+sigma`, q2, q4/q8,
non-Gaussian interval evidence, REML, AI-REML, bridge support, or public
support.

## 7. Next Gate

Fisher/Rose/Grace should review finite denominator, convergence, `pdHess`,
warnings, one-sided misses, coverage MCSE, and failure taxonomy, then decide
whether to top up to SR475/SR1000 before any status-table edit.
