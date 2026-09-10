#!/bin/bash
# Submit after the one-time build receipt and a live Fir capacity check. One
# array task is one frozen data set: task IDs 1--4000 map to P1--P3 and S1,
# each with 1,000 replicates. Each task writes exactly one tar.gz artifact to
# durable nearline project storage; its expanded CSV evidence exists only node-locally.

#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=1-4000%50
#SBATCH --job-name=drmtmb-homtoep-profile

set -euo pipefail
: "${DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR:?Set immutable /nearline source directory}"
: "${DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT:?Set durable campaign output root on /nearline}"
: "${DRMTMB_TEMPORAL_HOMTOEP_R_LIBS:?Set immutable installed R library on /nearline}"
: "${DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT:?Set frozen source commit}"
case "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR" in /nearline/* ) ;; * ) echo "Campaign source must be under /nearline" >&2; exit 2 ;; esac
case "$DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT" in /nearline/* ) ;; * ) echo "Campaign output must be under /nearline" >&2; exit 2 ;; esac
case "$DRMTMB_TEMPORAL_HOMTOEP_R_LIBS" in /nearline/* ) ;; * ) echo "Campaign R library must be under /nearline" >&2; exit 2 ;; esac
case "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT" in ???????????????????????????????????????? ) ;; * ) echo "Source commit must have 40 characters" >&2; exit 2 ;; esac

export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_AUTHORIZED=1
export DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_ATTEMPT=1
export DRMTMB_TEMPORAL_HOMTOEP_USE_INSTALLED=1
export R_LIBS="$DRMTMB_TEMPORAL_HOMTOEP_R_LIBS${R_LIBS:+:$R_LIBS}"
task=${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID is required}
bundle="$DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT/task-$(printf '%04d' "$task").tar.gz"
partial="${bundle}.partial-${SLURM_JOB_ID}"
node_root="${SLURM_TMPDIR:?SLURM_TMPDIR is required}/drmtmb-homtoep-${SLURM_JOB_ID}-${task}"
node_out="$node_root/artifacts"

cd "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR"
[ "$(git rev-parse HEAD)" = "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT" ]
git diff --quiet
[ ! -e "$bundle" ] && [ ! -e "$partial" ]
mkdir -p "$DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT" "$node_out"
module load StdEnv/2023 r/4.4.0

set +e
DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT="$node_out" \
  Rscript --vanilla tools/run-temporal-homtoep-marginal-profile-campaign.R \
    --campaign-task="$task"
worker_status=$?
set -e

tar -C "$node_out" -czf "$partial" "task-$(printf '%04d' "$task")"
mv "$partial" "$bundle"
rm -rf "$node_root"
exit "$worker_status"
