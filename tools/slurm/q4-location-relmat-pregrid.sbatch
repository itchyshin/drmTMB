#!/bin/bash
#SBATCH --job-name=q4relpre
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=13-16
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=%x-%A_%a.out

# Relmat-only q4 location SR150 pregrid fallback for DRAC.
#
# This script is intentionally narrower than q4-location-coverage-grid.sbatch:
# only array task IDs 13..16 are accepted, n_rep defaults to 150, and execution
# is fail-closed until Rose/Fisher/Grace approval is explicitly exported.

set -euo pipefail

if [[ "${DRMTMB_Q4LOC_EXECUTION_APPROVED:-}" != "rose_fisher_grace" ]]; then
  echo "Refusing execution: export DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace after explicit Rose/Fisher/Grace approval." >&2
  exit 2
fi

if [[ "$SLURM_ARRAY_TASK_ID" -lt 13 || "$SLURM_ARRAY_TASK_ID" -gt 16 ]]; then
  echo "Only relmat q4 location shards 13..16 are allowed; got $SLURM_ARRAY_TASK_ID" >&2
  exit 2
fi

module load StdEnv/2023 gcc/12.3 r/4.4.0

export R_LIBS="${DRMTMB_RLIB:?DRMTMB_RLIB not set -- export it before sbatch}"
REPO="${DRMTMB_REPO:?DRMTMB_REPO not set -- export it before sbatch}"

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

SOURCE_SHA="${DRMTMB_SOURCE_SHA:-unknown}"
SOURCE_DIRTY="${DRMTMB_SOURCE_DIRTY:-unknown}"
HOST_LABEL="${DRMTMB_HOST_LABEL:-drac_q4_t8_relmat_pregrid}"
N_REP="${DRMTMB_Q4LOC_N_REP:-150}"
N_EACH="${DRMTMB_Q4LOC_N_EACH:-20}"
BOOTSTRAP="${DRMTMB_Q4LOC_BOOTSTRAP:-0}"
RUN_ROOT="${DRMTMB_Q4LOC_RUN_ROOT:-/project/def-snakagaw/snakagaw/drmtmb-qseries/20260701-tranche8-q4-relmat-sr150-${SOURCE_SHA}/drac}"

case "$SLURM_ARRAY_TASK_ID" in
  13) TOKEN="shard-13-relmat-mu1-intercept" ;;
  14) TOKEN="shard-14-relmat-mu1-x" ;;
  15) TOKEN="shard-15-relmat-mu2-intercept" ;;
  16) TOKEN="shard-16-relmat-mu2-x" ;;
esac

SEED_START=$((980000 + (SLURM_ARRAY_TASK_ID - 13) * 1000))
OUT_DIR="$SCRATCH/q4relpre/$SLURM_ARRAY_JOB_ID/$TOKEN"
RESULTS_DIR="$RUN_ROOT/results/$TOKEN"
LOG_DIR="$RUN_ROOT/logs"
mkdir -p "$OUT_DIR" "$RESULTS_DIR" "$LOG_DIR"

{
  echo -e "source_sha\tsource_dirty\thost_label\trun_root"
  echo -e "${SOURCE_SHA}\t${SOURCE_DIRTY}\t${HOST_LABEL}\t${RUN_ROOT}"
} > "$RUN_ROOT/source-provenance.tsv"
{
  hostname
  date -Iseconds
  Rscript --version
} > "$RUN_ROOT/host-provenance-${SLURM_ARRAY_TASK_ID}.txt" 2>&1
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'sessionInfo()' \
  > "$RUN_ROOT/sessionInfo-${SLURM_ARRAY_TASK_ID}.txt" 2>&1

echo "[sbatch] date=$(date -Iseconds)"
echo "[sbatch] job=$SLURM_JOB_ID array_task=$SLURM_ARRAY_TASK_ID"
echo "[sbatch] node=$SLURMD_NODENAME"
echo "[sbatch] source_sha=$SOURCE_SHA source_dirty=$SOURCE_DIRTY host_label=$HOST_LABEL"
echo "[sbatch] run_root=$RUN_ROOT"
echo "[sbatch] out_dir=$OUT_DIR"
echo "[sbatch] results_dir=$RESULTS_DIR"
echo "[sbatch] n_rep=$N_REP seed_start=$SEED_START n_each=$N_EACH bootstrap=$BOOTSTRAP"

set +e
env \
  R_PROFILE_USER=/dev/null \
  NOT_CRAN=true \
  OMP_NUM_THREADS=1 \
  OPENBLAS_NUM_THREADS=1 \
  MKL_NUM_THREADS=1 \
  TMB_NTHREADS=1 \
  DRMTMB_SOURCE_SHA="$SOURCE_SHA" \
  DRMTMB_SOURCE_DIRTY="$SOURCE_DIRTY" \
  DRMTMB_HOST_LABEL="$HOST_LABEL" \
  Rscript --no-init-file \
  "$REPO/tools/run-structured-re-q4-location-coverage-grid.R" \
  --shard="$SLURM_ARRAY_TASK_ID" \
  --n_rep="$N_REP" \
  --seed_start="$SEED_START" \
  --n_each="$N_EACH" \
  --bootstrap="$BOOTSTRAP" \
  --out_dir="$OUT_DIR"
EXIT_CODE=$?
set -eo pipefail
echo "[sbatch] R exit code: $EXIT_CODE"

cp -v "$OUT_DIR"/*.tsv "$RESULTS_DIR/" || true
cp -v "$SLURM_SUBMIT_DIR/q4relpre-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.out" "$LOG_DIR/" || true

echo "[sbatch] done $(date -Iseconds)"
exit "$EXIT_CODE"
