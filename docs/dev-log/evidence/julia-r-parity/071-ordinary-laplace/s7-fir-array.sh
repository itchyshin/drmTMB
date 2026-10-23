#!/usr/bin/env bash
# One approved S7 array element.  The launcher, not this payload, supplies
# --array=1-2000 after a successful compute-node preflight and cost probe.
#SBATCH --job-name=drmtmb071
#SBATCH --account=def-snakagaw_cpu
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --mem=8G

set -euo pipefail

: "${SLURM_JOB_ID:?S7 array payload refuses to run outside Slurm}"
: "${SLURM_ARRAY_TASK_ID:?S7 array payload requires a logical task id}"
: "${S7_CAMPAIGN_ROOT:?S7 array payload requires the approved campaign keeper root}"
: "${S7_SOURCE_ROOT:?S7 array payload requires the pinned drmTMB source root}"
: "${S7_DRMJL_ROOT:?S7 array payload requires the pinned DRM.jl source root}"
: "${S7_BUNDLE:?S7 array payload requires the immutable campaign bundle path}"

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export FLEXIBLAS_NUM_THREADS=1
export BLIS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1
export JULIA_NUM_THREADS=1
export R_LIBS_USER="${S7_CAMPAIGN_ROOT}/r-lib"
export JULIA_DEPOT_PATH="${S7_CAMPAIGN_ROOT}/julia-depot"
export DRM_JL_PATH="${S7_DRMJL_ROOT}"
export DRMTMB_JULIA_TESTS=true
export NOT_CRAN=true

module purge
module load StdEnv/2023 r/4.6.1 julia/1.12.5

exec bash "${S7_SOURCE_ROOT}/docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-worker.sh"
