# Q-Series q1 `mu` Parallel Top-Up Route

Supersession note, later on 2026-06-30: relmat retry job `16979505` completed
and the four top-up shards were imported and aggregated in
`docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-aggregate.md`. This
route report records the dispatch step; the SR475 aggregate report is the
current evidence boundary.

## 1. Task

Add a parallel top-up route for the four Gaussian q1 `mu` intercept direct-SD
rows after the reviewed Nibi SR150 pregrid, without importing new results or
promoting any Q-Series status.

## 2. Implementation

- Extended `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R` with
  `--run-kind=topup`.
- Added `tools/run-structured-re-gaussian-lowq-mu-intercept-topup.R`.
- Added `tools/slurm/q1-mu-intercept-topup-nibi.sbatch`.
- Updated `tools/validate-mission-control.py` and the focused conversion
  contract test to guard the new top-up route.
- Updated `docs/dev-log/dashboard/README.md` and
  `docs/dev-log/check-log.md`.
- Submitted the Nibi array as job `16978889` from run root
  `/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q1-mu-sr475-topup-77b634ed-r163`.
- Tasks 1-3 completed; task 4 (`relmat`) failed before the R runner with a
  CVMFS R `INSTALL` input/output error, then was resubmitted as relmat-only job
  `16979505`.
- Added
  `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-topup-dispatch.tsv`
  as a dispatch ledger only.

## 3. Parallel Route

The SLURM plan uses a four-task array:

| Array task | Provider |
| ---: | --- |
| 1 | phylo |
| 2 | spatial |
| 3 | animal |
| 4 | relmat |

The default top-up adds seeds 151..475 (`n=325`) to the reviewed SR150 result,
so the aggregate review target is SR475 per provider. The job writes one
artifact directory per shard under
`results/q1-mu-intercept-topup-sr475/shard_<task>_<provider>`.

Immediately after submission, `squeue` reported
`16978889_[1-4] PENDING 0:00 (Priority)`. Later accounting showed tasks 1-3
completed with exit `0:0`, while task 4 failed with exit `126:0` before the R
runner. The relmat retry, job `16979505`, was pending with reason `Priority`
immediately after submission.

## 4. Reproducibility

The array script pins R/TMB and BLAS threads to one thread, loads the same Nibi
R module family as the SR150 run, writes exact command lines, module list,
session info, git SHA, scheduler logs, source SHA256 manifest, raw replicate
TSV, summary TSV, seed manifest, and `seff` when available.

Each array task uses its own R library directory under
`$DRMTMB_RLIB/shard_<task>` so concurrent package installs do not collide on
`00LOCK` directories.

## 5. Claim Boundary

This promotes exactly no Q-Series row. The linked support cells remain
`point_fit/planned/planned`. MCSE <= 0.01 is a top-up target, not a shard-level
pass claim. The top-up route does not claim `interval_status`,
`coverage_status`, `inference_ready`, `supported`, q1 sigma, matched
`mu+sigma`, q2, q4/q8, non-Gaussian interval evidence, REML, AI-REML, bridge
support, or public support.

## 6. Checks

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'parse(file =
  "tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R"); parse(file =
  "tools/run-structured-re-gaussian-lowq-mu-intercept-topup.R")'`: passed.
- `bash -n tools/slurm/q1-mu-intercept-topup-nibi.sbatch`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Local top-up host guard refused a local host label with the expected
  Nibi/Rorqual retained-denominator gate.
- Local one-replicate top-up writer smoke, using a fake Nibi host label and
  writing only to `/tmp/drmtmb-q1-mu-topup-positive`: passed and produced
  `topup_id`, `topup_status`, retained-denominator contract metadata, seed 151,
  and one retained denominator row. This smoke is not imported and is not
  evidence for a status claim.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `git diff --check` on the top-up runner, SLURM script, validator, and focused
  test files: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9104 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- Nibi source snapshot and submission completed; array job `16978889` was
  accepted by SLURM.
- `sacct` for job `16978889` recorded completed phylo/spatial/animal shards and
  the relmat CVMFS/R `INSTALL` failure before runner execution.
- Relmat-only retry job `16979505` was accepted by SLURM.

## 7. Next Gate

Submit the Nibi array only from a prepared campaign root with `logs/`, a source
snapshot, `$DRMTMB_RUN_ROOT`, `$DRMTMB_REPO`, `$DRMTMB_RLIB`, and
`$DRMTMB_GIT_SHA` set. After the shards complete, aggregate SR150 plus top-up
replicates and have Fisher/Rose/Grace inspect retained denominator,
convergence, `pdHess`, finite intervals, warnings, lower/upper misses, coverage
MCSE, and failure taxonomy before any widget import or status-table edit.
