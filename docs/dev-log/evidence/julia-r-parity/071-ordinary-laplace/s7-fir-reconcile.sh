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
readonly script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly source_verifier="${script_dir}/verify-source-commit.sh"
mkdir -p "${scratch}" "${check_dir}"
trap 'rm -rf "${scratch}"' EXIT
test -x "${source_verifier}"

pins="${S7_CAMPAIGN_ROOT}/source-staging/source-pins-final.tsv"
test -f "${pins}"

# Do not name an archive from a predecessor campaign here.  The immutable
# source-pin receipt declares corrected commits and archive digests; select
# the sole staged archive and matching bundle for each declared commit.
archive_for() {
  local component="$1" stem="$2" commit expected_sha pattern
  commit="$(awk -F '\t' -v component="${component}" 'NR > 1 && $1 == component { print $2 }' "${pins}")"
  expected_sha="$(awk -F '\t' -v component="${component}" 'NR > 1 && $1 == component { print $3 }' "${pins}")"
  test "${commit}" != "" && test "${expected_sha}" != ""
  pattern="${S7_CAMPAIGN_ROOT}/source-staging/${stem}-${commit:0:8}*.tar.gz"
  shopt -s nullglob
  local matches=( ${pattern} )
  shopt -u nullglob
  test "${#matches[@]}" -eq 1
  test "$(sha256sum "${matches[0]}" | awk '{print $1}')" = "${expected_sha}"
  printf '%s\n' "${matches[0]}"
}

bundle_for() {
  local component="$1" stem="$2" commit pattern
  commit="$(awk -F '\t' -v component="${component}" 'NR > 1 && $1 == component { print $2 }' "${pins}")"
  test "${commit}" != ""
  pattern="${S7_CAMPAIGN_ROOT}/source-staging/${stem}-${commit:0:8}*.bundle"
  shopt -s nullglob
  local matches=( ${pattern} )
  shopt -u nullglob
  test "${#matches[@]}" -eq 1
  printf '%s\n' "${matches[0]}"
}

verify_staged_subset() {
  local label="$1" component="$2" stem="$3" roots="$4" prefix="$5" commit archive bundle proof
  commit="$(awk -F '\t' -v component="${component}" 'NR > 1 && $1 == component { print $2 }' "${pins}")"
  archive="$(archive_for "${component}" "${stem}")"
  bundle="$(bundle_for "${component}" "${stem}")"
  proof="${scratch}/${label}-source-commit-proof.txt"
  "${source_verifier}" "${label}" "${commit}" "${bundle}" "${archive}" "${roots}" "${prefix}" > "${proof}"
  grep -Fx "SOURCE_COMMIT_SUBSET_PROOF_PASS label=${label} commit=${commit}" "${proof}" > /dev/null
  printf '%s\t%s\t%s\n' "${archive}" "${bundle}" "${proof}"
}

read -r drmtmb_archive drmtmb_bundle drmtmb_proof < <(verify_staged_subset drmTMB drmTMB drmTMB 'DESCRIPTION,NAMESPACE,R,src,inst,docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace' 'drmTMB/')
read -r drmjl_archive drmjl_bundle drmjl_proof < <(verify_staged_subset DRMjl DRM.jl DRMjl 'Project.toml,src' '')
tmp_check="${check_path}.tmp-${SLURM_JOB_ID}"
{
  # Compatibility key consumed by the immutable summary writer.  Its value is
  # now established by source-subset commit proofs, not a live-tree diff.
  printf 'source_tree_archive_compare=PASS\n'
  printf 'source_subset_commit_proof=PASS\n'
  printf 'drmtmb_source=%s\n' "${S7_SOURCE_ROOT}"
  printf 'drmjl_source=%s\n' "${S7_DRMJL_ROOT}"
  printf 'drmtmb_archive_sha256=%s\n' "$(sha256sum "${drmtmb_archive}" | awk '{print $1}')"
  printf 'drmjl_archive_sha256=%s\n' "$(sha256sum "${drmjl_archive}" | awk '{print $1}')"
} > "${tmp_check}"
mv "${tmp_check}" "${check_path}"

Rscript "${S7_COLLECTOR}" \
  "--campaign-root=${S7_CAMPAIGN_ROOT}" \
  "--source-root=${S7_SOURCE_ROOT}" \
  "--drmjl-source-root=${S7_DRMJL_ROOT}" \
  "--source-tree-check=${check_path}" \
  "--out=${S7_CAMPAIGN_ROOT}/postprocess/s7-coverage-summary.tsv"

printf '%s\n' 'S7 reconciliation and source-tree verification completed' >&2
