#!/usr/bin/env bash
# One compute-node-only S7 closeout payload. The launcher supplies the exact
# campaign variables after every array task has atomically committed; this is
# never a submission command.
#SBATCH --job-name=drmtmb071rec
#SBATCH --account=def-snakagaw_cpu
#SBATCH --partition=cpubase_bycore_b1
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --mem=16G

set -euo pipefail

: "${SLURM_JOB_ID:?S7 reconciliation must run in a Slurm allocation}"
: "${S7_CAMPAIGN_ROOT:?S7 reconciliation requires the immutable campaign root}"
: "${S7_SOURCE_ROOT:?S7 reconciliation requires the source root used by the workers}"
: "${S7_DRMJL_ROOT:?S7 reconciliation requires the DRM.jl root used by the workers}"
: "${S7_COLLECTOR:?S7 reconciliation requires the staged coverage writer}"

export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 FLEXIBLAS_NUM_THREADS=1
export BLIS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 JULIA_NUM_THREADS=1
export R_LIBS_USER="${S7_CAMPAIGN_ROOT}/r-lib"
export JULIA_DEPOT_PATH="${S7_CAMPAIGN_ROOT}/julia-depot"
export DRM_JL_PATH="${S7_DRMJL_ROOT}"

module purge
module load StdEnv/2023 r/4.6.1 julia/1.12.5

scratch="${SLURM_TMPDIR:-${TMPDIR:-/tmp}}/s7-reconcile-${SLURM_JOB_ID}"
check_dir="${S7_CAMPAIGN_ROOT}/postprocess"
check_path="${check_dir}/source-tree-archive-compare-${SLURM_JOB_ID}.txt"
mkdir -p "${scratch}" "${check_dir}"
trap 'rm -rf "${scratch}"' EXIT

compare_tree() {
  local label="$1" archive="$2" live="$3" extracted="${scratch}/${label}"
  mkdir -p "${extracted}"
  tar -xzf "${archive}" -C "${extracted}"
  diff -qr "${extracted}" "${live}"
}

compare_tree drmTMB "${S7_CAMPAIGN_ROOT}/source-staging/drmTMB-764ceaf9.tar.gz" "${S7_SOURCE_ROOT}"
compare_tree DRMjl "${S7_CAMPAIGN_ROOT}/source-staging/DRMjl-b877f513.tar.gz" "${S7_DRMJL_ROOT}"
tmp_check="${check_path}.tmp-${SLURM_JOB_ID}"
{
  printf 'source_tree_archive_compare=PASS\n'
  printf 'drmtmb_source=%s\n' "${S7_SOURCE_ROOT}"
  printf 'drmjl_source=%s\n' "${S7_DRMJL_ROOT}"
  printf 'drmtmb_archive_sha256=%s\n' "$(sha256sum "${S7_CAMPAIGN_ROOT}/source-staging/drmTMB-764ceaf9.tar.gz" | awk '{print $1}')"
  printf 'drmjl_archive_sha256=%s\n' "$(sha256sum "${S7_CAMPAIGN_ROOT}/source-staging/DRMjl-b877f513.tar.gz" | awk '{print $1}')"
} > "${tmp_check}"
mv "${tmp_check}" "${check_path}"

Rscript "${S7_COLLECTOR}" \
  "--campaign-root=${S7_CAMPAIGN_ROOT}" \
  "--source-root=${S7_SOURCE_ROOT}" \
  "--drmjl-source-root=${S7_DRMJL_ROOT}" \
  "--source-tree-check=${check_path}" \
  "--out=${S7_CAMPAIGN_ROOT}/postprocess/s7-coverage-summary.tsv"

printf '%s\n' 'S7 reconciliation and source-tree verification completed' >&2
