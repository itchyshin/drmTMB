#!/bin/bash
#SBATCH --job-name=q2t30r108
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=108
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=6G
#SBATCH --time=0-02:00:00
#SBATCH --output=q2t30r108-%A_%a.out

# Tranche 30 q2-plus replicate-108 critical-manifest replay contract.
#
# This job pack is intentionally not submitted by Tranche 30. If later approved,
# it runs exactly one Rorqual SLURM array task, verifies only the listed critical
# q2-plus replay source entries inside the job, then runs the preserved q2-plus
# smoke runner for replicate 108 / seed 823108 and the five retained q2-plus
# targets only. The full source manifest is not rechecked because Tranche 29
# showed a non-target q2-intercept runner drift that stopped the replay before R.

set -euo pipefail

APPROVAL_REQUIRED="fisher_rose_noether_gauss_grace_critical_manifest_contract_verified"
if [[ "${DRMTMB_Q2_TRANCHE30_CRITICAL_REPLAY_APPROVED:-}" != "$APPROVAL_REQUIRED" ]]; then
  echo "Refusing execution: export DRMTMB_Q2_TRANCHE30_CRITICAL_REPLAY_APPROVED=$APPROVAL_REQUIRED after Fisher/Rose/Noether/Gauss/Grace approval." >&2
  exit 2
fi

if [[ "${SLURM_CLUSTER_NAME:-}" != "rorqual" || -z "${SLURM_JOB_ID:-}" ]]; then
  echo "Refusing execution: Tranche 30 critical-manifest replay must run as a Rorqual SLURM job, not on a login node or other host." >&2
  exit 2
fi

if [[ "${SLURM_ARRAY_TASK_ID:-}" != "108" ]]; then
  echo "Refusing execution: only SLURM_ARRAY_TASK_ID=108 is allowed; got ${SLURM_ARRAY_TASK_ID:-unset}." >&2
  exit 2
fi

module load StdEnv/2023 gcc/12.3 r/4.4.0

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

RUN_ROOT="${DRMTMB_Q2_T30_RUN_ROOT:-/project/def-snakagaw/snakagaw/drmtmb-qseries/20260630-q2-retained-pregrid-77b634eda91b-codex-rorqual}"
SOURCE_REPO="${DRMTMB_Q2_T30_SOURCE_REPO:-$RUN_ROOT/source}"
RLIB="${DRMTMB_Q2_T30_RLIB:-$RUN_ROOT/rlib/shard_5}"
BASE_RLIB="${DRMTMB_BASE_RLIB:-/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4}"
PACKAGE_CACHE="${DRMTMB_Q2_T30_PACKAGE_CACHE:-$RUN_ROOT/package-cache}"
SOURCE_METADATA="${DRMTMB_Q2_T30_SOURCE_METADATA:-$RUN_ROOT/metadata/shard_5}"
SOURCE_MANIFEST="${DRMTMB_Q2_T30_SOURCE_MANIFEST:-$SOURCE_METADATA/source-sha256-manifest.txt}"
RUNNER="$SOURCE_REPO/tools/run-structured-re-q2-plus-q2-intercept-smoke.R"
RESULT_ROOT="${DRMTMB_Q2_T30_RESULT_ROOT:-$RUN_ROOT/results/q2-tranche30-critical-manifest-replay/rep108}"
ARTIFACT_DIR="$RESULT_ROOT/artifacts"
META_DIR="$RESULT_ROOT/metadata"
LOG_DIR="$RESULT_ROOT/logs"
HOST_NAME="${SLURMD_NODENAME:-$(hostname)}"
HOST_CLASS="source_matched_replay_critical_manifest"
CONTRACT_IDS="q2_plus_q2_intercept_phylo_mu1_intercept,q2_plus_q2_intercept_phylo_mu2_intercept,q2_plus_q2_intercept_phylo_cor_mu1_mu2,q2_plus_q2_intercept_phylo_sigma1_intercept,q2_plus_q2_intercept_phylo_sigma2_intercept"
EXCLUDED_FULL_MANIFEST_FAILURE="./tools/run-structured-re-q2-intercept-smoke.R"
CRITICAL_MANIFEST_FILES=(
  "tools/run-structured-re-q2-plus-q2-intercept-smoke.R"
  "tools/run-structured-re-q2-retained-denominator-pregrid.R"
  "docs/dev-log/dashboard/structured-re-q2-plus-q2-intercept-contract.tsv"
  "docs/dev-log/dashboard/structured-re-q2-retained-denominator-design.tsv"
  "R/drmTMB.R"
  "R/profile.R"
  "src/drmTMB.cpp"
)

mkdir -p "$ARTIFACT_DIR" "$META_DIR" "$LOG_DIR"

for path in "$SOURCE_REPO" "$RLIB" "$PACKAGE_CACHE" "$SOURCE_METADATA"; do
  if [[ ! -e "$path" ]]; then
    echo "Required Tranche 30 source path is missing: $path" >&2
    exit 2
  fi
done
for file in "$SOURCE_MANIFEST" "$RUNNER"; do
  if [[ ! -f "$file" ]]; then
    echo "Required Tranche 30 source file is missing: $file" >&2
    exit 2
  fi
done

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID}"
  echo "array_task=${SLURM_ARRAY_TASK_ID}"
  echo "node=$HOST_NAME"
  echo "cluster=${SLURM_CLUSTER_NAME}"
  echo "run_root=$RUN_ROOT"
  echo "source_repo=$SOURCE_REPO"
  echo "runner=$RUNNER"
  echo "rlib=$RLIB"
  echo "package_cache=$PACKAGE_CACHE"
  echo "source_manifest=$SOURCE_MANIFEST"
  echo "artifact_dir=$ARTIFACT_DIR"
  echo "replicate_index=108"
  echo "seed=823108"
  echo "n_rep=1"
  echo "contract_ids=$CONTRACT_IDS"
  echo "manifest_verification=critical_manifest_entries_only"
  echo "excluded_full_manifest_failure=$EXCLUDED_FULL_MANIFEST_FAILURE"
  echo "coverage_decision=coverage_not_authorized"
  echo "promotion_decision=do_not_promote"
} > "$META_DIR/run-log.txt"

printf "%s\n" "$EXCLUDED_FULL_MANIFEST_FAILURE" > "$META_DIR/excluded-full-manifest-failure.txt"

: > "$META_DIR/critical-manifest-entries.txt"
for critical in "${CRITICAL_MANIFEST_FILES[@]}"; do
  grep -F "  ./$critical" "$SOURCE_MANIFEST" >> "$META_DIR/critical-manifest-entries.txt"
done

(
  cd "$SOURCE_REPO"
  sha256sum -c "$META_DIR/critical-manifest-entries.txt"
) > "$META_DIR/critical-manifest-check.txt" 2>&1

export R_LIBS="$RLIB:$BASE_RLIB"
export DRMTMB_PACKAGE_CACHE="$PACKAGE_CACHE"
export DRMTMB_RUN_ROOT="$RUN_ROOT"
export DRMTMB_RUN_INSTALLED=true

COMMAND=(
  Rscript --no-init-file "$RUNNER"
  --n-rep=1
  --seed-start=108
  --seed-base=823000
  --bootstrap=0
  --profile-max-eval=80
  --n-each=50
  --contract-ids="$CONTRACT_IDS"
  --host-class="$HOST_CLASS"
  --host-name="$HOST_NAME"
  --output-dir="$ARTIFACT_DIR"
  --overwrite=true
  --write-dashboard=false
)
printf "%q " "${COMMAND[@]}" > "$META_DIR/exact-command.txt"
printf "\n" >> "$META_DIR/exact-command.txt"

Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' \
  > "$META_DIR/sessionInfo.txt" 2>&1

echo "[tranche30] starting critical-manifest replay $(date -Iseconds)"
set +e
"${COMMAND[@]}" > "$LOG_DIR/source-replay.stdout" 2> "$LOG_DIR/source-replay.stderr"
EXIT_CODE=$?
set -e
echo "[tranche30] R exit code: $EXIT_CODE" | tee -a "$META_DIR/run-log.txt"
echo "[tranche30] done $(date -Iseconds)" | tee -a "$META_DIR/run-log.txt"
exit "$EXIT_CODE"
