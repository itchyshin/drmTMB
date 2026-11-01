#!/bin/bash
# One-time scheduled installation of the immutable campaign source. This keeps
# the 4,000 scientific tasks within their measured profile-time envelope.

#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --job-name=drmtmb-homtoep-build

set -euo pipefail
: "${DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR:?Set immutable source directory under /home/snakagaw}"
: "${DRMTMB_TEMPORAL_HOMTOEP_R_LIBS:?Set immutable campaign R library under /home/snakagaw}"
: "${DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT:?Set frozen source commit}"
case "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR" in /home/snakagaw/* ) ;; * ) echo "Source must be under /home/snakagaw" >&2; exit 2 ;; esac
case "$DRMTMB_TEMPORAL_HOMTOEP_R_LIBS" in /home/snakagaw/* ) ;; * ) echo "R library must be under /home/snakagaw" >&2; exit 2 ;; esac

export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
module load StdEnv/2023 r/4.4.0
cd "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_DIR"
[ "$(git rev-parse HEAD)" = "$DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT" ]
git diff --quiet
mkdir -p "$DRMTMB_TEMPORAL_HOMTOEP_R_LIBS"
R CMD INSTALL --library="$DRMTMB_TEMPORAL_HOMTOEP_R_LIBS" .
R_LIBS="$DRMTMB_TEMPORAL_HOMTOEP_R_LIBS${R_LIBS:+:$R_LIBS}" \
  Rscript --vanilla -e 'library(drmTMB); cat("DRMTMB_TEMPORAL_HOMTOEP_BUILD_PASS\\n")'
