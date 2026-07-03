#!/usr/bin/env bash
set -euo pipefail

if [[ "${DRMTMB_Q1MU_SLOPE_T74_EXECUTION_APPROVED:-}" != "rose_fisher_gauss_noether_grace" ]]; then
  echo "Refusing Tranche 74 spatial q1 mu one-slope smoke: set DRMTMB_Q1MU_SLOPE_T74_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace after Rose/Fisher/Gauss/Noether/Grace approval and checkpoint." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SOURCE_ROOT="${DRMTMB_Q1MU_SLOPE_T74_SOURCE_ROOT:-/home/snakagaw/codex/drmTMB-q1mu-slope-tranche73-clean-source-56add7f0-20260702T123451Z}"
RUN_ROOT="${DRMTMB_Q1MU_SLOPE_T74_RUN_ROOT:-/home/snakagaw/drmtmb-qseries/q1-mu-slope-spatial-tranche73-clean-source-20260702T123451Z}"
OUTPUT_DIR="${DRMTMB_Q1MU_SLOPE_T74_OUTPUT_DIR:-${RUN_ROOT}/tranche74-spatial-host-smoke-artifacts}"
HOST_LABEL="${DRMTMB_Q1MU_SLOPE_T74_HOST_LABEL:-totoro_q1mu_slope_spatial_t74_t73_clean_source_n5}"
SEED_LIST="${DRMTMB_Q1MU_SLOPE_T74_SEED_LIST:-861001,861002,861003,861004,861005}"

if [[ "${SOURCE_ROOT}" != "/home/snakagaw/codex/drmTMB-q1mu-slope-tranche73-clean-source-56add7f0-20260702T123451Z" ]]; then
  echo "Refusing Tranche 74 with a source root other than the exact T73 snapshot." >&2
  exit 65
fi

if [[ "${RUN_ROOT}" != "/home/snakagaw/drmtmb-qseries/q1-mu-slope-spatial-tranche73-clean-source-20260702T123451Z" ]]; then
  echo "Refusing Tranche 74 with a run root other than the exact T73 qseries root." >&2
  exit 66
fi

if [[ "${SEED_LIST}" != "861001,861002,861003,861004,861005" ]]; then
  echo "Refusing Tranche 74 with seeds other than 861001,861002,861003,861004,861005." >&2
  exit 67
fi

R_PROFILE_USER=/dev/null \
OMP_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 \
MKL_NUM_THREADS=1 \
TMB_NTHREADS=1 \
Rscript --no-init-file "${RUNNER_ROOT}/tools/run-gaussian-mu-slope-tranche74-spatial-host-smoke.R" \
  --mode=execute \
  --provider=spatial \
  --target=both \
  --n-rep=5 \
  --seeds="${SEED_LIST}" \
  --host-label="${HOST_LABEL}" \
  --source-snapshot-path="${SOURCE_ROOT}" \
  --run-root-path="${RUN_ROOT}" \
  --output-dir="${OUTPUT_DIR}" \
  --summary-path=NA \
  --overwrite=true \
  --write-dashboard=false
