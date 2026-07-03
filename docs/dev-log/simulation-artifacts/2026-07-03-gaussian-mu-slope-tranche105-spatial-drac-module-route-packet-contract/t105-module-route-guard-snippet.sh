#!/usr/bin/env bash
# T105 contract artifact only. Do not execute this file directly.
set -euo pipefail

module load StdEnv/2023
module load r/4.4.0

module list -t > "${ARTIFACT_DIR}/module-list-after-r-load.txt" 2>&1
module avail r > "${ARTIFACT_DIR}/module-avail-r-after-r-load.txt" 2>&1 || true

if ! grep -Fxq "r/4.4.0" "${ARTIFACT_DIR}/module-list-after-r-load.txt"; then
  printf 'module_guard\tfailed\tNA\tr_4_4_0_not_in_loaded_module_list\n' > "${ARTIFACT_DIR}/t105-terminal-status.tsv"
  exit 127
fi

R_PATH="$(command -v R || true)"
RSCRIPT_PATH="$(command -v Rscript || true)"
printf 'R\t%s\nRscript\t%s\n' "${R_PATH:-NA}" "${RSCRIPT_PATH:-NA}" > "${ARTIFACT_DIR}/r-executable-probe.tsv"

if [ -z "${R_PATH}" ] || [ -z "${RSCRIPT_PATH}" ]; then
  printf 'executable_guard\tfailed\tNA\tR_or_Rscript_missing_after_module_load\n' >> "${ARTIFACT_DIR}/t105-terminal-status.tsv"
  printf 'install_packages\tnot_attempted\tNA\tR_or_Rscript_missing_after_module_load\n' >> "${ARTIFACT_DIR}/t105-terminal-status.tsv"
  printf 'r_cmd_install\tnot_attempted\tNA\tR_or_Rscript_missing_after_module_load\n' >> "${ARTIFACT_DIR}/t105-terminal-status.tsv"
  printf 'library_drmTMB\tnot_attempted\tNA\tR_or_Rscript_missing_after_module_load\n' >> "${ARTIFACT_DIR}/t105-terminal-status.tsv"
  printf 'model_execution\tnot_run\tNA\tno_smoke_runner_no_formula_no_fit\n' >> "${ARTIFACT_DIR}/t105-terminal-status.tsv"
  printf 'denominator\tnot_created\tNA\tno_retained_denominator_no_coverage_no_status_move\n' >> "${ARTIFACT_DIR}/t105-terminal-status.tsv"
  exit 127
fi

printf 'executable_guard\tpassed\t0\tR_and_Rscript_present_before_install\n' >> "${ARTIFACT_DIR}/t105-terminal-status.tsv"
