#!/usr/bin/env bash
set -euo pipefail

if [[ "${DRMTMB_Q2_TRANCHE15_EXECUTION_APPROVED:-}" != "rose_fisher_noether_grace" ]]; then
  echo "Refusing to run Tranche 15 q2 endpoint-SD bootstrap smoke: set DRMTMB_Q2_TRANCHE15_EXECUTION_APPROVED=rose_fisher_noether_grace after Fisher/Rose/Noether/Grace approval." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

OUTPUT_ROOT="${DRMTMB_Q2_TRANCHE15_OUTPUT_ROOT:-docs/dev-log/simulation-artifacts/2026-07-01-q2-tranche15-endpoint-sd-bootstrap-smoke}"
HOST_CLASS="${DRMTMB_Q2_TRANCHE15_HOST_CLASS:-tranche15_q2_endpoint_sd_bootstrap_smoke}"
HOST_NAME="${DRMTMB_Q2_TRANCHE15_HOST_NAME:-$(hostname)}"
PROFILE_MAX_EVAL="${DRMTMB_Q2_TRANCHE15_PROFILE_MAX_EVAL:-60}"
N_REP="${DRMTMB_Q2_TRANCHE15_N_REP:-8}"
BOOTSTRAP_R="${DRMTMB_Q2_TRANCHE15_BOOTSTRAP_R:-2}"
REQUESTED_PROVIDERS="${DRMTMB_Q2_TRANCHE15_PROVIDERS:-phylo,spatial,animal,relmat}"

seed_base_for() {
  case "$1" in
    phylo) echo 935000 ;;
    spatial) echo 936000 ;;
    animal) echo 937000 ;;
    relmat) echo 938000 ;;
    *)
      echo "Unknown Tranche 15 q2 provider: $1" >&2
      exit 65
      ;;
  esac
}

IFS=',' read -r -a providers <<< "${REQUESTED_PROVIDERS}"
for raw_provider in "${providers[@]}"; do
  provider="$(echo "${raw_provider}" | tr -d '[:space:]')"
  [[ -n "${provider}" ]] || continue
  seed_base="$(seed_base_for "${provider}")"
  artifact_dir="${OUTPUT_ROOT}/${provider}_sd_mu2_intercept/artifacts"
  R_PROFILE_USER=/dev/null \
  OMP_NUM_THREADS=1 \
  OPENBLAS_NUM_THREADS=1 \
  MKL_NUM_THREADS=1 \
  TMB_NTHREADS=1 \
  Rscript --no-init-file tools/run-structured-re-q2-intercept-smoke.R \
    --n-rep="${N_REP}" \
    --providers="${provider}" \
    --estimands=sd_mu2_intercept \
    --bootstrap="${BOOTSTRAP_R}" \
    --seed-start=1 \
    --seed-base="${seed_base}" \
    --profile-max-eval="${PROFILE_MAX_EVAL}" \
    --interval-repair-channel=none \
    --host-class="${HOST_CLASS}" \
    --host-name="${HOST_NAME}" \
    --output-dir="${artifact_dir}" \
    --overwrite=true \
    --write-dashboard=false
done
