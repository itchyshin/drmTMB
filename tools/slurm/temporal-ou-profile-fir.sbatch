#!/bin/bash
# Submit only after a live Fir capacity check and the one-task smoke receipt.
# One task is one generated data set; task IDs 1--3000 map to U1--U3 x 1000.
# Required exports in the submission environment:
#   DRMTMB_TEMPORAL_OU_SOURCE_DIR   immutable archived-source checkout on /project
#   DRMTMB_TEMPORAL_OU_CAMPAIGN_OUT durable campaign output root on /project
#   DRMTMB_TEMPORAL_OU_SOURCE_COMMIT 40-character frozen source commit

#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --array=1-3000%50
#SBATCH --job-name=drmtmb-ou-profile
#SBATCH --output=slurm-ou-profile-%A_%a.out
#SBATCH --error=slurm-ou-profile-%A_%a.err

set -euo pipefail
: "${DRMTMB_TEMPORAL_OU_SOURCE_DIR:?Set immutable /project source directory}"
: "${DRMTMB_TEMPORAL_OU_CAMPAIGN_OUT:?Set durable /project output root}"
: "${DRMTMB_TEMPORAL_OU_SOURCE_COMMIT:?Set frozen source commit}"
case "$DRMTMB_TEMPORAL_OU_SOURCE_COMMIT" in
  ????????* ) ;;
  * ) echo "DRMTMB_TEMPORAL_OU_SOURCE_COMMIT is not a commit hash" >&2; exit 2 ;;
esac

export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export DRMTMB_TEMPORAL_OU_CAMPAIGN_AUTHORIZED=1
cd "$DRMTMB_TEMPORAL_OU_SOURCE_DIR"
Rscript --vanilla tools/run-temporal-ou-profile-pilot.R \
  --campaign-task="$SLURM_ARRAY_TASK_ID"
