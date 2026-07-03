#!/usr/bin/env bash
set -euo pipefail

if [[ "${DRMTMB_Q1_SIGMA_TRANCHE54_EXECUTION_APPROVED:-}" != "rose_fisher_gauss_noether_grace" ]]; then
  echo "Refusing to run Tranche 54 animal/relmat q1 sigma bootstrap smoke: set DRMTMB_Q1_SIGMA_TRANCHE54_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace after Rose/Fisher/Gauss/Noether/Grace approval." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

OUTPUT_ROOT="${DRMTMB_Q1_SIGMA_TRANCHE54_OUTPUT_ROOT:-docs/dev-log/simulation-artifacts/2026-07-01-gaussian-lowq-tranche54-q1-sigma-bootstrap-smoke}"
HOST_CLASS="${DRMTMB_Q1_SIGMA_TRANCHE54_HOST_CLASS:-tranche54_q1_sigma_bootstrap_smoke}"
HOST_NAME="${DRMTMB_Q1_SIGMA_TRANCHE54_HOST_NAME:-$(hostname)}"
BOOTSTRAP_R="${DRMTMB_Q1_SIGMA_TRANCHE54_BOOTSTRAP_R:-2}"
BOOTSTRAP_SEED="${DRMTMB_Q1_SIGMA_TRANCHE54_BOOTSTRAP_SEED:-540054}"
SEED_LIST="${DRMTMB_Q1_SIGMA_TRANCHE54_SEED_LIST:-914008,914011}"

if [[ "${BOOTSTRAP_R}" != "2" ]]; then
  echo "Refusing to run Tranche 54 with BOOTSTRAP_R != 2." >&2
  exit 65
fi

if [[ "${SEED_LIST}" != "914008,914011" ]]; then
  echo "Refusing to run Tranche 54 with seeds other than 914008,914011." >&2
  exit 66
fi

artifact_dir="${OUTPUT_ROOT}/animal_relmat_q1_sigma_boundary_seed_bootstrap/artifacts"

R_PROFILE_USER=/dev/null \
OMP_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 \
MKL_NUM_THREADS=1 \
TMB_NTHREADS=1 \
Rscript --no-init-file tools/run-structured-re-gaussian-lowq-sigma-intercept-smoke.R \
  --run-kind=bootstrap-smoke \
  --providers=animal,relmat \
  --n-rep=2 \
  --seed-list="${SEED_LIST}" \
  --bootstrap="${BOOTSTRAP_R}" \
  --bootstrap-seed="${BOOTSTRAP_SEED}" \
  --profile=false \
  --host-class="${HOST_CLASS}" \
  --host-name="${HOST_NAME}" \
  --output-dir="${artifact_dir}" \
  --overwrite=true \
  --write-dashboard=false
