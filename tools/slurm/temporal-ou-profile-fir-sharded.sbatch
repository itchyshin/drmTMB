#!/bin/bash
# Storage-consolidating alternative to temporal-ou-profile-fir.sbatch.
# Each array task runs 50 datasets in node-local storage, then atomically writes
# one immutable tar.gz shard. Submit only after a new G14 authorization because
# it changes the array granularity while preserving all 3,000 data sets.

#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=01:30:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=1-60%10
#SBATCH --job-name=drmtmb-ou-shard
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

set -euo pipefail
: "${DRMTMB_TEMPORAL_OU_SOURCE_ARCHIVE:?Set immutable source archive on durable storage}"
: "${DRMTMB_TEMPORAL_OU_CAMPAIGN_OUT:?Set durable campaign output root}"
: "${DRMTMB_TEMPORAL_OU_SOURCE_COMMIT:?Set frozen source commit}"

export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export DRMTMB_TEMPORAL_OU_CAMPAIGN_AUTHORIZED=1

shard_id=${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID is required}
batch_size=${DRMTMB_TEMPORAL_OU_BATCH_SIZE:-50}
case "$batch_size" in
  1|50) ;;
  *) echo "DRMTMB_TEMPORAL_OU_BATCH_SIZE must be 1 (smoke) or 50 (campaign)." >&2; exit 2 ;;
esac
first_task=$(( (shard_id - 1) * batch_size + 1 ))
last_task=$(( shard_id * batch_size ))
if [ "$last_task" -gt 3000 ]; then
  echo "Shard mapping exceeds the frozen 3,000-dataset campaign." >&2
  exit 2
fi
node_root=${SLURM_TMPDIR:-/tmp}/drmtmb-ou-shard-${SLURM_JOB_ID}-${shard_id}
node_source=${node_root}/source
node_out=${node_root}/artifacts
bundle=${DRMTMB_TEMPORAL_OU_CAMPAIGN_OUT}/shard-$(printf '%03d' "$shard_id").tar.gz
partial=${bundle}.partial-${SLURM_JOB_ID}

cleanup() { rm -rf "$node_root"; }
trap cleanup EXIT
mkdir -p "$node_source" "$node_out"
tar -xzf "$DRMTMB_TEMPORAL_OU_SOURCE_ARCHIVE" -C "$node_source"
printf 'task,status\n' > "$node_out/task-status.csv"

failed=0
for task in $(seq "$first_task" "$last_task"); do
  set +e
  (
    cd "$node_source"
    DRMTMB_TEMPORAL_OU_CAMPAIGN_OUT="$node_out" \
      Rscript --vanilla tools/run-temporal-ou-profile-pilot.R --campaign-task="$task"
  ) >> "$node_out/worker.log" 2>&1
  code=$?
  set -e
  printf '%s,%s\n' "$task" "$code" >> "$node_out/task-status.csv"
  if [ "$code" -ne 0 ]; then failed=1; fi
done

if [ -e "$bundle" ] || [ -e "$partial" ]; then
  echo "Refuse to overwrite retained shard: $bundle" >&2
  exit 2
fi
tar -C "$node_out" -czf "$partial" .
mv "$partial" "$bundle"
[ "$failed" -eq 0 ]
