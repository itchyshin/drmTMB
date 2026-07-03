#!/usr/bin/env bash
set -euo pipefail

if [[ "${DRMTMB_Q1_MU_TRANCHE52_EXECUTION_APPROVED:-}" != "rose_fisher_gauss_noether_grace" ]]; then
  echo "Refusing to run Tranche 52 animal q1 mu bootstrap smoke: set DRMTMB_Q1_MU_TRANCHE52_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace after Rose/Fisher/Gauss/Noether/Grace approval." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

OUTPUT_ROOT="${DRMTMB_Q1_MU_TRANCHE52_OUTPUT_ROOT:-docs/dev-log/simulation-artifacts/2026-07-01-gaussian-lowq-tranche52-animal-q1-mu-bootstrap-smoke}"
HOST_CLASS="${DRMTMB_Q1_MU_TRANCHE52_HOST_CLASS:-tranche52_animal_q1_mu_bootstrap_smoke}"
HOST_NAME="${DRMTMB_Q1_MU_TRANCHE52_HOST_NAME:-$(hostname)}"
BOOTSTRAP_R="${DRMTMB_Q1_MU_TRANCHE52_BOOTSTRAP_R:-2}"
BOOTSTRAP_SEED="${DRMTMB_Q1_MU_TRANCHE52_BOOTSTRAP_SEED:-520052}"
SEED_LIST="${DRMTMB_Q1_MU_TRANCHE52_SEED_LIST:-812407,812444}"

if [[ "${BOOTSTRAP_R}" != "2" ]]; then
  echo "Refusing to run Tranche 52 with BOOTSTRAP_R != 2." >&2
  exit 65
fi

if [[ "${SEED_LIST}" != "812407,812444" ]]; then
  echo "Refusing to run Tranche 52 with seeds other than 812407,812444." >&2
  exit 66
fi

artifact_dir="${OUTPUT_ROOT}/animal_q1_mu_hard_seed_bootstrap/artifacts"

R_PROFILE_USER=/dev/null \
OMP_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 \
MKL_NUM_THREADS=1 \
TMB_NTHREADS=1 \
Rscript --no-init-file tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R \
  --run-kind=bootstrap-smoke \
  --providers=animal \
  --n-rep=2 \
  --seed-list="${SEED_LIST}" \
  --bootstrap="${BOOTSTRAP_R}" \
  --bootstrap-seed="${BOOTSTRAP_SEED}" \
  --host-class="${HOST_CLASS}" \
  --host-name="${HOST_NAME}" \
  --output-dir="${artifact_dir}" \
  --overwrite=true \
  --write-dashboard=false
