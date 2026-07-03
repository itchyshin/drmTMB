#!/usr/bin/env bash
set -euo pipefail

if [[ "${DRMTMB_Q2_TRANCHE11_EXECUTION_APPROVED:-}" != "rose_fisher_noether_grace" ]]; then
  echo "Refusing to run Tranche 11 q2 smoke: set DRMTMB_Q2_TRANCHE11_EXECUTION_APPROVED=rose_fisher_noether_grace after Fisher/Rose/Noether/Grace approval." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

OUTPUT_ROOT="${DRMTMB_Q2_TRANCHE11_OUTPUT_ROOT:-docs/dev-log/simulation-artifacts/2026-07-01-q2-tranche11-direct-correlation-smoke}"
HOST_CLASS="${DRMTMB_Q2_TRANCHE11_HOST_CLASS:-tranche11_q2_direct_correlation_smoke}"
HOST_NAME="${DRMTMB_Q2_TRANCHE11_HOST_NAME:-$(hostname)}"
PROFILE_MAX_EVAL="${DRMTMB_Q2_TRANCHE11_PROFILE_MAX_EVAL:-60}"
N_REP="${DRMTMB_Q2_TRANCHE11_N_REP:-32}"
REQUESTED_PROVIDERS="${DRMTMB_Q2_TRANCHE11_PROVIDERS:-phylo,spatial,animal,relmat}"

seed_base_for() {
  case "$1" in
    phylo) echo 925000 ;;
    spatial) echo 926000 ;;
    animal) echo 927000 ;;
    relmat) echo 928000 ;;
    *)
      echo "Unknown Tranche 11 q2 provider: $1" >&2
      exit 65
      ;;
  esac
}

IFS=',' read -r -a providers <<< "${REQUESTED_PROVIDERS}"
for raw_provider in "${providers[@]}"; do
  provider="$(echo "${raw_provider}" | tr -d '[:space:]')"
  [[ -n "${provider}" ]] || continue
  seed_base="$(seed_base_for "${provider}")"
  artifact_dir="${OUTPUT_ROOT}/${provider}_cor_mu1_mu2_intercept/artifacts"
  R_PROFILE_USER=/dev/null \
  OMP_NUM_THREADS=1 \
  OPENBLAS_NUM_THREADS=1 \
  MKL_NUM_THREADS=1 \
  TMB_NTHREADS=1 \
  Rscript --no-init-file tools/run-structured-re-q2-intercept-smoke.R \
    --n-rep="${N_REP}" \
    --providers="${provider}" \
    --estimands=cor_mu1_mu2_intercept \
    --bootstrap=0 \
    --seed-start=1 \
    --seed-base="${seed_base}" \
    --profile-max-eval="${PROFILE_MAX_EVAL}" \
    --interval-repair-channel=bounded_tmbprofile_direct_correlation_sidecar \
    --host-class="${HOST_CLASS}" \
    --host-name="${HOST_NAME}" \
    --output-dir="${artifact_dir}" \
    --overwrite=true \
    --write-dashboard=false
done
