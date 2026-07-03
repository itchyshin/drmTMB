#!/usr/bin/env bash
# T109 contract artifact only. Do not execute this file directly.
set -euo pipefail

: "${ARTIFACT_DIR:?ARTIFACT_DIR is required}"

STATUS="${ARTIFACT_DIR}/t109-terminal-status.tsv"
printf 'stage\tstatus\texit_code\tnote\n' > "${STATUS}"
append_status() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "${STATUS}"
}

module load StdEnv/2023
module load r/4.4.0

module list > "${ARTIFACT_DIR}/module-list-after-r-load.txt" 2>&1
module avail r > "${ARTIFACT_DIR}/module-avail-r-after-r-load.txt" 2>&1 || true

if ! grep -Eq '(^|[[:space:]])r/4[.]4[.]0([[:space:]]|$)' "${ARTIFACT_DIR}/module-list-after-r-load.txt"; then
  append_status loaded_module_guard failed 127 r_4_4_0_not_in_plain_module_list
  append_status executable_guard not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status install_packages not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status r_cmd_install_drmTMB not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status library_drmTMB not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
  append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
  exit 127
fi
append_status loaded_module_guard passed 0 r_4_4_0_present_in_plain_module_list

R_BIN="$(command -v R || true)"
RSCRIPT_BIN="$(command -v Rscript || true)"
{
  printf 'tool\tpath\n'
  printf 'R\t%s\n' "${R_BIN:-NA}"
  printf 'Rscript\t%s\n' "${RSCRIPT_BIN:-NA}"
} > "${ARTIFACT_DIR}/r-executable-probe.tsv"

if [ -z "${R_BIN}" ] || [ -z "${RSCRIPT_BIN}" ]; then
  append_status executable_guard failed 127 R_or_Rscript_missing_after_plain_module_list_guard
  append_status install_packages not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status r_cmd_install_drmTMB not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status library_drmTMB not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
  append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
  exit 127
fi

append_status executable_guard passed 0 R_and_Rscript_present_before_install
append_status install_packages not_attempted NA t109_contract_stops_before_package_install
append_status r_cmd_install_drmTMB not_attempted NA t109_contract_stops_before_R_CMD_INSTALL
append_status library_drmTMB not_attempted NA t109_contract_stops_before_library_load
append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
