#!/usr/bin/env bash
# Launch the approved Narval campaign from its frozen run root.  This is a
# development-only SLURM launcher; results are retained under $RUN_ROOT.
set -euo pipefail

: "${RUN_ROOT:?Set RUN_ROOT to the frozen remote campaign root}"
: "${SLURM_ARRAY_TASK_ID:?This launcher must run as a SLURM array task}"
export DRMTMB_RESPONSE_MASK_OUTPUT_DIR="$RUN_ROOT/results"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1
export R_PROFILE_USER=/dev/null
cd "$RUN_ROOT/source"
exec Rscript --no-init-file \
  tools/run-response-mask-structured-q1-recovery.R "$SLURM_ARRAY_TASK_ID"
