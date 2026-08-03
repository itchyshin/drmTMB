#!/bin/bash

set -euo pipefail
: "${CE_PACKET:?set CE_PACKET to the frozen full packet directory}"
: "${CE_RUN_BASE:?set CE_RUN_BASE to project-backed immutable run storage}"
: "${CE_ACCOUNT:?set CE_ACCOUNT to the DRAC allocation}"
: "${CE_BASE_R_LIB:?set CE_BASE_R_LIB to the read-only dependency library}"
test -d "${CE_BASE_R_LIB}"

packet=$(cd "${CE_PACKET}" && pwd -P)
packet_sha=$(awk -F '\t' '$1 == "packet_sha256" {print $2}' "${packet}/metadata.tsv")
source_sha=$(awk -F '\t' '$1 == "source_sha" {print $2}' "${packet}/metadata.tsv")
test -n "${packet_sha}"
test -n "${source_sha}"
test "$(sha256sum "${packet}/manifest.tsv" | awk '{print $1}')" = "${packet_sha}"
while IFS=$'\t' read -r path expected; do
  test "${path}" = "path" && continue
  test "$(sha256sum "${packet}/${path}" | awk '{print $1}')" = "${expected}"
done < "${packet}/manifest.tsv"
test "$(awk -F '\t' 'NR == 2 {print $1}' "${packet}/smoke-evidence/decision.tsv")" = "SMOKE_COMPLETE"
test "$(awk -F '\t' 'NR == 2 {print $15}' "${packet}/smoke-evidence/resource-projection.tsv")" = "TRUE"
test "$(awk -F '\t' 'NR == 2 {print $16}' "${packet}/smoke-evidence/resource-projection.tsv")" = "TRUE"

run_root="${CE_RUN_BASE}/spatial-q2-confidence-eye-full-${packet_sha}"
if test -e "${run_root}"; then
  echo "Immutable run root already exists: ${run_root}" >&2
  exit 73
fi
mkdir -p "${run_root}/source" "${run_root}/lib" "${run_root}/raw" \
  "${run_root}/reconciled" "${run_root}/logs" "${run_root}/receipts"
tar -xzf "${packet}/drmTMB-source.tar.gz" -C "${run_root}/source"
test "$(cat "${run_root}/source/SOURCE_SHA")" = "${source_sha}"

setup_job=$(sbatch --parsable \
  --account="${CE_ACCOUNT}" \
  --output="${run_root}/logs/setup-%j.out" \
  --error="${run_root}/logs/setup-%j.err" \
  --export="ALL,CE_PACKET=${packet},CE_RUN_ROOT=${run_root},DRMTMB_LIB=${run_root}/lib,CE_BASE_R_LIB=${CE_BASE_R_LIB}" \
  "${packet}/tools/slurm/setup-spatial-q2-confidence-eye.sbatch")
array_job=$(sbatch --parsable \
  --account="${CE_ACCOUNT}" \
  --dependency="afterok:${setup_job}" \
  --array="1-1500%100" \
  --output="${run_root}/logs/full-%A_%a.out" \
  --error="${run_root}/logs/full-%A_%a.err" \
  --export="ALL,CE_PACKET=${packet},CE_RUN_ROOT=${run_root},CE_OUTPUT=${run_root}/raw,DRMTMB_LIB=${run_root}/lib,CE_BASE_R_LIB=${CE_BASE_R_LIB}" \
  "${packet}/tools/slurm/spatial-q2-confidence-eye-full.sbatch")

cat > "${run_root}/receipts/submission.tsv" <<EOF
key	value
source_sha	${source_sha}
packet_sha256	${packet_sha}
setup_job_id	${setup_job}
array_job_id	${array_job}
array_contract	1-1500%100
account	${CE_ACCOUNT}
base_r_library	${CE_BASE_R_LIB}
run_root	${run_root}
submitted_utc	$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
printf 'SETUP_JOB=%s\nARRAY_JOB=%s\nRUN_ROOT=%s\n' "${setup_job}" "${array_job}" "${run_root}"
