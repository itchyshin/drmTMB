#!/bin/bash
# Submit only after the live Fir capacity check. One array task is one frozen
# generated data set: task IDs 1--4000 map to P1--P3 and S1, each x 1000.
# Required exports in the submission environment:
#   DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR    immutable clean git checkout on /project
#   DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT  durable campaign output root on /project
#   DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT 40-character frozen source commit

#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=1-4000%50
#SBATCH --job-name=drmtmb-homtoep-profile

set -euo pipefail
: "${DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR:?Set immutable /project source directory}"
: "${DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT:?Set durable /project output root}"
: "${DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT:?Set frozen source commit}"
case "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT" in
  ???????????????????????????????????????? ) ;;
  * ) echo "DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT is not a 40-character commit hash" >&2; exit 2 ;;
esac
case "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR" in
  /project/* ) ;;
  * ) echo "Campaign source must be a durable /project checkout" >&2; exit 2 ;;
esac
case "$DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT" in
  /project/* ) ;;
  * ) echo "Campaign output must be under durable /project storage" >&2; exit 2 ;;
esac

export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_AUTHORIZED=1
export DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_ATTEMPT=1
cd "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR"
[ "$(git rev-parse HEAD)" = "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT" ]
git diff --quiet
module load StdEnv/2023 r/4.4.0
Rscript --vanilla tools/run-temporal-homtoep-marginal-profile-campaign.R \
  --campaign-task="$SLURM_ARRAY_TASK_ID"
