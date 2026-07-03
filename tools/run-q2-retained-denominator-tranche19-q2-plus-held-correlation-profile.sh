#!/usr/bin/env bash
set -euo pipefail

if [[ "${DRMTMB_Q2_TRANCHE19_EXECUTION_APPROVED:-}" != "fisher_rose_noether_gauss_grace" ]]; then
  echo "Refusing to run Tranche 19 q2-plus held-correlation profile contract: set DRMTMB_Q2_TRANCHE19_EXECUTION_APPROVED=fisher_rose_noether_gauss_grace after Fisher/Rose/Noether/Gauss/Grace approval." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

OUTPUT_ROOT="${DRMTMB_Q2_TRANCHE19_OUTPUT_ROOT:-docs/dev-log/simulation-artifacts/2026-07-01-q2-tranche19-q2-plus-held-correlation-profile-contract}"
HOST_CLASS="${DRMTMB_Q2_TRANCHE19_HOST_CLASS:-tranche19_local_or_totoro_profile_contract}"
HOST_NAME="${DRMTMB_Q2_TRANCHE19_HOST_NAME:-$(hostname)}"
PROFILE_MAX_EVAL="${DRMTMB_Q2_TRANCHE19_PROFILE_MAX_EVAL:-80}"
N_REP="${DRMTMB_Q2_TRANCHE19_N_REP:-1}"
SEED_START="${DRMTMB_Q2_TRANCHE19_SEED_START:-3}"
SEED_BASE="${DRMTMB_Q2_TRANCHE19_SEED_BASE:-823000}"
BOOTSTRAP_R="${DRMTMB_Q2_TRANCHE19_BOOTSTRAP_R:-0}"

if [[ "${N_REP}" != "1" || "${SEED_START}" != "3" || "${SEED_BASE}" != "823000" || "${BOOTSTRAP_R}" != "0" ]]; then
  echo "Tranche 19 is locked to n_rep=1, seed_start=3, seed_base=823000, and bootstrap=0." >&2
  exit 65
fi

host_text="$(printf '%s %s' "${HOST_CLASS}" "${HOST_NAME}" | tr '[:upper:]' '[:lower:]')"
if [[ "${host_text}" =~ (nibi|rorqual|trillium|drac|slurm|cluster) ]]; then
  echo "Tranche 19 is a local/Totoro profile-geometry micro-contract only; DRAC/Nibi/Rorqual/Trillium execution is blocked." >&2
  exit 66
fi

artifact_dir="${OUTPUT_ROOT}/cor_sigma1_sigma2_seed823003_tmbprofile/artifacts"
R_PROFILE_USER=/dev/null \
OMP_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 \
MKL_NUM_THREADS=1 \
TMB_NTHREADS=1 \
Rscript --no-init-file tools/run-structured-re-q2-plus-q2-intercept-smoke.R \
  --n-rep="${N_REP}" \
  --seed-start="${SEED_START}" \
  --seed-base="${SEED_BASE}" \
  --bootstrap="${BOOTSTRAP_R}" \
  --profile-max-eval="${PROFILE_MAX_EVAL}" \
  --interval-repair-channel=bounded_tmbprofile_direct_correlation_sidecar \
  --contract-ids=q2_plus_q2_intercept_phylo_cor_sigma1_sigma2 \
  --host-class="${HOST_CLASS}" \
  --host-name="${HOST_NAME}" \
  --output-dir="${artifact_dir}" \
  --overwrite=true \
  --write-dashboard=false
