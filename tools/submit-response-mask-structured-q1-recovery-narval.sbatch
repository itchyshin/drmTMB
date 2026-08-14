#!/usr/bin/env bash
#SBATCH --job-name=drmtmb-mr-q1
#SBATCH --array=1-300%48
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=3G
#SBATCH --output=%x-%A_%a.out
#SBATCH --error=%x-%A_%a.err

set -euo pipefail
: "${RUN_ROOT:?Submit with --export=ALL,RUN_ROOT=/project/.../run-root}"
module load gcc r/4.6.1

source "$RUN_ROOT/source/tools/run-response-mask-structured-q1-recovery-narval.sh"
