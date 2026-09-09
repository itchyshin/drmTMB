#!/usr/bin/env bash
# One compute-node preflight for the immutable S7 campaign.  This script is
# deliberately a worker payload: the launcher supplies sbatch, never this file.
#SBATCH --job-name=drmtmb071pre
#SBATCH --account=def-snakagaw_cpu
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --mem=16G

set -euo pipefail

: "${SLURM_JOB_ID:?S7 preflight must run in a Slurm allocation}"
: "${S7_CAMPAIGN_ROOT:?S7 preflight requires the immutable campaign keeper root}"
: "${S7_SOURCE_ROOT:?S7 preflight requires the pinned drmTMB source root}"
: "${S7_DRMJL_ROOT:?S7 preflight requires the pinned DRM.jl source root}"
: "${S7_BUNDLE:?S7 preflight requires the immutable campaign bundle path}"

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

mkdir -p "${S7_CAMPAIGN_ROOT}/preflight" "${R_LIBS_USER}" "${JULIA_DEPOT_PATH}"

module purge
module load StdEnv/2023 r/4.6.1 julia/1.12.5

{
  printf 'slurm_job_id=%s\n' "${SLURM_JOB_ID}"
  printf 'host=%s\n' "$(hostname)"
  Rscript -e 'cat("R=", R.version.string, "\n", sep = "")'
  julia --version
  module list 2>&1
} > "${S7_CAMPAIGN_ROOT}/preflight/runtime-${SLURM_JOB_ID}.txt"

Rscript -e '
  lib <- Sys.getenv("R_LIBS_USER")
  needed <- c("cli", "lifecycle", "TMB", "JuliaCall")
  missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    install.packages(missing, lib = lib, repos = "https://cloud.r-project.org", dependencies = TRUE, Ncpus = 1L)
  }
  unavailable <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
  if (length(unavailable)) stop("missing required R package(s): ", paste(unavailable, collapse = ", "))
'

R CMD INSTALL --library="${R_LIBS_USER}" "${S7_SOURCE_ROOT}"
julia --project="${S7_DRMJL_ROOT}" -e 'using Pkg; Pkg.instantiate(); Pkg.precompile(); using DRM; println("DRM=", pkgversion(DRM))'

# A real coupled-NB2 task exercises all bridge, profile, provenance, and
# atomic-publication boundaries.  The Slurm job is not itself an array, so this
# binds only the immutable logical task id expected by the guarded worker.
export SLURM_ARRAY_TASK_ID=1501
bash "${S7_SOURCE_ROOT}/docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-worker.sh"

printf '%s\n' "S7 compute-node preflight committed logical task 1501" >&2
