#!/usr/bin/env bash
set -euo pipefail

MODE="manifest"
EXACT_SOURCE_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/source"
EXACT_RUN_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0"
SOURCE_ROOT="${DRMTMB_Q1MU_SLOPE_T85_SOURCE_ROOT:-${EXACT_SOURCE_ROOT}}"
RUN_ROOT="${DRMTMB_Q1MU_SLOPE_T85_RUN_ROOT:-${EXACT_RUN_ROOT}}"
OUTPUT_DIR="${DRMTMB_Q1MU_SLOPE_T85_OUTPUT_DIR:-${RUN_ROOT}/results/tranche85-spatial-drac-path-gate}"
HOST_LABEL="${DRMTMB_Q1MU_SLOPE_T85_HOST_LABEL:-drac_rorqual_q1mu_slope_spatial_t80_t77_runner_n5}"
SEED_LIST="${DRMTMB_Q1MU_SLOPE_T85_SEED_LIST:-861001,861002,861003,861004,861005}"
WRITE_DASHBOARD="${DRMTMB_Q1MU_SLOPE_T85_WRITE_DASHBOARD:-false}"
LOAD_SOURCE="${DRMTMB_Q1MU_SLOPE_T85_LOAD_SOURCE:-true}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode=*)
      MODE="${1#--mode=}"
      shift
      ;;
    --mode)
      MODE="${2:?--mode requires a value}"
      shift 2
      ;;
    --source-root=*)
      SOURCE_ROOT="${1#--source-root=}"
      shift
      ;;
    --source-root)
      SOURCE_ROOT="${2:?--source-root requires a value}"
      shift 2
      ;;
    --run-root=*)
      RUN_ROOT="${1#--run-root=}"
      shift
      ;;
    --run-root)
      RUN_ROOT="${2:?--run-root requires a value}"
      shift 2
      ;;
    --output-dir=*)
      OUTPUT_DIR="${1#--output-dir=}"
      shift
      ;;
    --output-dir)
      OUTPUT_DIR="${2:?--output-dir requires a value}"
      shift 2
      ;;
    --host-label=*)
      HOST_LABEL="${1#--host-label=}"
      shift
      ;;
    --host-label)
      HOST_LABEL="${2:?--host-label requires a value}"
      shift 2
      ;;
    --seeds=*)
      SEED_LIST="${1#--seeds=}"
      shift
      ;;
    --seeds)
      SEED_LIST="${2:?--seeds requires a value}"
      shift 2
      ;;
    --write-dashboard=*)
      WRITE_DASHBOARD="${1#--write-dashboard=}"
      shift
      ;;
    --write-dashboard)
      WRITE_DASHBOARD="${2:?--write-dashboard requires a value}"
      shift 2
      ;;
    --load-source=*)
      LOAD_SOURCE="${1#--load-source=}"
      shift
      ;;
    --load-source)
      LOAD_SOURCE="${2:?--load-source requires a value}"
      shift 2
      ;;
    --help|-h)
      cat <<'EOF'
Usage: tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.sh [--mode=manifest|execute]

Tranche 85 DRAC path gate for the q1 mu one-slope spatial n=5 runner.
manifest mode validates the exact T83 DRAC source/run-root paths and prints
the seed-target manifest without Rscript. execute mode is reserved for a later
smoke-approval gate and refuses unless the preserved approval token is set.
Use --load-source=false only after the reviewed T125 installed-package route gate.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument for Tranche 85 wrapper: $1" >&2
      exit 63
      ;;
  esac
done

if [[ "${MODE}" != "manifest" && "${MODE}" != "execute" ]]; then
  echo "Refusing Tranche 85 wrapper: --mode must be manifest or execute." >&2
  exit 63
fi

if [[ "${SOURCE_ROOT}" != "${EXACT_SOURCE_ROOT}" ]]; then
  echo "Refusing Tranche 85 with a source root other than the exact T83 DRAC source path." >&2
  exit 65
fi

if [[ "${RUN_ROOT}" != "${EXACT_RUN_ROOT}" ]]; then
  echo "Refusing Tranche 85 with a run root other than the exact T83 DRAC run root." >&2
  exit 66
fi

if [[ "${SEED_LIST}" != "861001,861002,861003,861004,861005" ]]; then
  echo "Refusing Tranche 85 with seeds other than 861001,861002,861003,861004,861005." >&2
  exit 67
fi

if [[ "${HOST_LABEL}" != "drac_rorqual_q1mu_slope_spatial_t80_t77_runner_n5" ]]; then
  echo "Refusing Tranche 85 with a host label other than drac_rorqual_q1mu_slope_spatial_t80_t77_runner_n5." >&2
  exit 68
fi

if [[ "${WRITE_DASHBOARD}" != "false" ]]; then
  echo "Refusing Tranche 85 with write-dashboard other than false." >&2
  exit 69
fi

if [[ "${LOAD_SOURCE}" != "true" && "${LOAD_SOURCE}" != "false" ]]; then
  echo "Refusing Tranche 85 with load-source other than true or false." >&2
  exit 71
fi

if [[ "${OUTPUT_DIR}" != "${RUN_ROOT}/"* ]]; then
  echo "Refusing Tranche 85 with an output directory outside the exact T83 DRAC run root." >&2
  exit 70
fi

if [[ "${MODE}" == "manifest" ]]; then
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "manifest_id" "provider" "target" "endpoint_member" "direct_sd_target" \
    "seed" "host_label" "source_snapshot_path" "run_root_path" "output_dir" \
    "execution_status" "denominator_status" "coverage_decision" \
    "promotion_decision" "support_cell_decision"
  IFS=',' read -r -a SEEDS <<< "${SEED_LIST}"
  for target in "mu_intercept" "mu_x"; do
    if [[ "${target}" == "mu_intercept" ]]; then
      endpoint_member="mu:(Intercept)"
      direct_sd_target="sd_mu_intercept"
    else
      endpoint_member="mu:x"
      direct_sd_target="sd_mu_x"
    fi
    for seed in "${SEEDS[@]}"; do
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "tranche85_spatial_${target}_seed_${seed}" \
        "spatial" \
        "${target}" \
        "${endpoint_member}" \
        "${direct_sd_target}" \
        "${seed}" \
        "${HOST_LABEL}" \
        "${SOURCE_ROOT}" \
        "${RUN_ROOT}" \
        "${OUTPUT_DIR}" \
        "manifest_only_no_rscript_no_model_no_denominator" \
        "no_new_denominator" \
        "coverage_not_authorized" \
        "do_not_promote" \
        "unchanged_point_fit_planned_planned"
    done
  done
  exit 0
fi

if [[ "${DRMTMB_Q1MU_SLOPE_T77_EXECUTION_APPROVED:-}" != "rose_fisher_gauss_noether_grace" ]]; then
  echo "Refusing Tranche 85 spatial q1 mu one-slope smoke: set DRMTMB_Q1MU_SLOPE_T77_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace after a post-patch smoke-approval gate and checkpoint." >&2
  exit 64
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

R_PROFILE_USER=/dev/null \
OMP_NUM_THREADS=1 \
OPENBLAS_NUM_THREADS=1 \
MKL_NUM_THREADS=1 \
TMB_NTHREADS=1 \
Rscript --no-init-file "${RUNNER_ROOT}/tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.R" \
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
  --load-source="${LOAD_SOURCE}" \
  --write-dashboard=false
