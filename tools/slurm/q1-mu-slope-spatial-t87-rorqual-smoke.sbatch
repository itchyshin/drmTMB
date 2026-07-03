#!/bin/bash
#SBATCH --job-name=q1mut87
#SBATCH --account=def-snakagaw_cpu
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=6G
#SBATCH --time=0-01:00:00
#SBATCH --output=q1mut87-%j.out

# Tranche 87 q1 mu one-slope spatial n=5 Rorqual smoke packet.
#
# This packet is intentionally narrow. It must run as one Rorqual SLURM job,
# not from a login shell, and it delegates the model work to the reviewed T85
# wrapper with the preserved Rose/Fisher/Gauss/Noether/Grace approval token.

set -euo pipefail

APPROVAL_REQUIRED="rose_fisher_gauss_noether_grace"
if [[ "${DRMTMB_Q1MU_SLOPE_T87_SLURM_APPROVED:-}" != "$APPROVAL_REQUIRED" ]]; then
  echo "Refusing execution: export DRMTMB_Q1MU_SLOPE_T87_SLURM_APPROVED=$APPROVAL_REQUIRED after T87/T88 review and checkpoint." >&2
  exit 2
fi

if [[ "${SLURM_CLUSTER_NAME:-}" != "rorqual" || -z "${SLURM_JOB_ID:-}" ]]; then
  echo "Refusing execution: Tranche 87 q1 mu one-slope smoke must run as a Rorqual SLURM job, not on a login node or other host." >&2
  exit 2
fi

module load StdEnv/2023 gcc/12.3 r/4.4.0

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

RUN_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0"
SOURCE_ROOT="$RUN_ROOT/source"
OUTPUT_DIR="$RUN_ROOT/results/tranche87-spatial-drac-smoke-n5"
META_DIR="$RUN_ROOT/results/tranche87-spatial-drac-smoke-n5-slurm-metadata"
HOST_LABEL="drac_rorqual_q1mu_slope_spatial_t80_t77_runner_n5"
SEEDS="861001,861002,861003,861004,861005"
WRAPPER="$SOURCE_ROOT/tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.sh"
RUNNER="$SOURCE_ROOT/tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.R"
EXPECTED_WRAPPER_SHA="b18885eaca8501e996d56ea8a2e7082c53b862b350ed7aacca6778973e4017ad"
EXPECTED_RUNNER_SHA="6a4fa7e8c77d20172929368ce17852073439c69400ea8221255f08b51dd3411e"

mkdir -p "$META_DIR"

for path in "$SOURCE_ROOT" "$RUN_ROOT"; do
  if [[ ! -d "$path" ]]; then
    echo "Required Tranche 87 path is missing: $path" >&2
    exit 2
  fi
done
for file in "$WRAPPER" "$RUNNER"; do
  if [[ ! -f "$file" ]]; then
    echo "Required Tranche 87 source file is missing: $file" >&2
    exit 2
  fi
done
if [[ ! -x "$WRAPPER" ]]; then
  echo "Required Tranche 87 wrapper is not executable: $WRAPPER" >&2
  exit 2
fi

ACTUAL_WRAPPER_SHA="$(sha256sum "$WRAPPER" | awk '{print $1}')"
ACTUAL_RUNNER_SHA="$(sha256sum "$RUNNER" | awk '{print $1}')"
if [[ "$ACTUAL_WRAPPER_SHA" != "$EXPECTED_WRAPPER_SHA" ]]; then
  echo "Wrapper SHA drift: expected $EXPECTED_WRAPPER_SHA got $ACTUAL_WRAPPER_SHA" >&2
  exit 2
fi
if [[ "$ACTUAL_RUNNER_SHA" != "$EXPECTED_RUNNER_SHA" ]]; then
  echo "Runner SHA drift: expected $EXPECTED_RUNNER_SHA got $ACTUAL_RUNNER_SHA" >&2
  exit 2
fi

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID}"
  echo "cluster=${SLURM_CLUSTER_NAME}"
  echo "node=${SLURMD_NODENAME:-$(hostname)}"
  echo "run_root=$RUN_ROOT"
  echo "source_root=$SOURCE_ROOT"
  echo "wrapper=$WRAPPER"
  echo "runner=$RUNNER"
  echo "output_dir=$OUTPUT_DIR"
  echo "metadata_dir=$META_DIR"
  echo "host_label=$HOST_LABEL"
  echo "seeds=$SEEDS"
  echo "wrapper_sha=$ACTUAL_WRAPPER_SHA"
  echo "runner_sha=$ACTUAL_RUNNER_SHA"
  echo "coverage_decision=coverage_not_authorized"
  echo "promotion_decision=do_not_promote"
  echo "support_cell_decision=unchanged_point_fit_planned_planned"
} > "$META_DIR/slurm-run-log.txt"

{
  hostname
  date -Iseconds
  Rscript --version
} > "$META_DIR/host-provenance.txt" 2>&1

Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' \
  > "$META_DIR/sessionInfo.txt" 2>&1

COMMAND=(
  bash "$WRAPPER"
  --mode=execute
  --source-root="$SOURCE_ROOT"
  --run-root="$RUN_ROOT"
  --output-dir="$OUTPUT_DIR"
  --host-label="$HOST_LABEL"
  --seeds="$SEEDS"
  --write-dashboard=false
)
printf "%q " "${COMMAND[@]}" > "$META_DIR/exact-command.txt"
printf "\n" >> "$META_DIR/exact-command.txt"

echo "[tranche87] starting q1 mu one-slope spatial n=5 smoke $(date -Iseconds)"
set +e
DRMTMB_Q1MU_SLOPE_T77_EXECUTION_APPROVED="$APPROVAL_REQUIRED" \
  "${COMMAND[@]}" > "$META_DIR/wrapper.stdout" 2> "$META_DIR/wrapper.stderr"
EXIT_CODE=$?
set -e
echo "[tranche87] wrapper exit code: $EXIT_CODE" | tee -a "$META_DIR/slurm-run-log.txt"
echo "[tranche87] done $(date -Iseconds)" | tee -a "$META_DIR/slurm-run-log.txt"
exit "$EXIT_CODE"
