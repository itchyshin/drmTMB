#!/bin/bash
# T114 contract artifact only. Do not submit without a later reviewed T115 gate.
# Scope: allocation-safe no-model dependency-route proof only.
# No smoke runner, model formula, model fit, retained denominator, coverage,
# top-up, support-cell status edit, inference_ready, supported, REML, AI-REML,
# or denominator-pooling command.
#SBATCH --job-name=drmtmb-t115-deps
#SBATCH --account=def-snakagaw
#SBATCH --time=00:45:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

set -o pipefail
if [ -f /cvmfs/soft.computecanada.ca/config/profile/bash.sh ]; then
  : "${SKIP_CC_CVMFS:=0}"
  . /cvmfs/soft.computecanada.ca/config/profile/bash.sh
fi
set -u

RUN_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0"
SOURCE_ROOT="${RUN_ROOT}/source"
ART="${RUN_ROOT}/results/tranche115-spatial-drac-dependency-route-proof"
LIB="${RUN_ROOT}/Rlib-tranche115"
DEPENDENCY_LIB="${RUN_ROOT}/Rlib-tranche98"
TMP="${RUN_ROOT}/tmp-tranche115"
EXPECTED_SOURCE_SHA="56add7f04fab7bec57a42e56eaeb090dff491863"
: "${DRMTMB_T115_DEPENDENCY_REPO:?DRMTMB_T115_DEPENDENCY_REPO must name a file:// or pre-staged repository}"

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1
export MAKEFLAGS="-j${SLURM_CPUS_PER_TASK:-1}"
export R_LIBS_USER="${LIB}:${DEPENDENCY_LIB}"
export TMPDIR="${TMP}"

mkdir -p "${ART}" "${LIB}" "${DEPENDENCY_LIB}" "${TMP}"
STATUS="${ART}/t115-terminal-status.tsv"
printf 'stage\tstatus\texit_code\tnote\n' > "${STATUS}"
append_status() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "${STATUS}"
}

{
  printf 'field\tvalue\n'
  printf 'observed_at_utc\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'remote_host\t%s\n' "$(hostname)"
  printf 'remote_user\t%s\n' "$(whoami)"
  printf 'slurm_job_id\t%s\n' "${SLURM_JOB_ID:-NA}"
  printf 'run_root\t%s\n' "${RUN_ROOT}"
  printf 'source_root\t%s\n' "${SOURCE_ROOT}"
  printf 'proof_dir\t%s\n' "${ART}"
  printf 'lib_dir\t%s\n' "${LIB}"
  printf 'dependency_lib_dir\t%s\n' "${DEPENDENCY_LIB}"
  printf 'dependency_repo\t%s\n' "${DRMTMB_T115_DEPENDENCY_REPO}"
  printf 'expected_source_sha\t%s\n' "${EXPECTED_SOURCE_SHA}"
  printf 'model_boundary\t%s\n' "no_smoke_runner_no_formula_no_fit_no_denominator_no_coverage"
} > "${ART}/host-provenance.tsv"

{
  module load StdEnv/2023
  module load r/4.4.0
} > "${ART}/module-load.stdout" 2> "${ART}/module-load.stderr"
module_exit=$?
if [ "${module_exit}" -ne 0 ]; then
  append_status module_load failed "${module_exit}" module_load_failed_before_plain_module_list
  append_status loaded_module_guard not_attempted NA module_load_failed
  append_status executable_guard not_attempted NA module_load_failed
  append_status source_sha_guard not_attempted NA module_load_failed
  append_status dependency_source_guard not_attempted NA module_load_failed
  append_status install_packages not_attempted NA module_load_failed
  append_status r_cmd_install_drmTMB not_attempted NA module_load_failed
  append_status library_drmTMB not_attempted NA module_load_failed
  append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
  append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
  exit "${module_exit}"
fi
append_status module_load passed 0 StdEnv_2023_then_r_4_4_0_loaded_command_exit_0

module list > "${ART}/module-list-after-r-load.txt" 2>&1
module avail r > "${ART}/module-avail-r-after-r-load.txt" 2>&1 || true
if ! grep -Eq '(^|[[:space:]])r/4[.]4[.]0([[:space:]]|$)' "${ART}/module-list-after-r-load.txt"; then
  append_status loaded_module_guard failed 127 r_4_4_0_not_in_plain_module_list
  append_status executable_guard not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status source_sha_guard not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status dependency_source_guard not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status install_packages not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status r_cmd_install_drmTMB not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status library_drmTMB not_attempted NA r_4_4_0_not_in_plain_module_list
  append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
  append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
  exit 127
fi
append_status loaded_module_guard passed 0 r_4_4_0_present_in_plain_module_list

R_BIN="$(command -v R 2>/dev/null)"
r_exit=$?
RSCRIPT_BIN="$(command -v Rscript 2>/dev/null)"
rscript_exit=$?
{
  printf 'tool\texit_code\tpath\n'
  printf 'R\t%s\t%s\n' "${r_exit}" "${R_BIN:-NA}"
  printf 'Rscript\t%s\t%s\n' "${rscript_exit}" "${RSCRIPT_BIN:-NA}"
} > "${ART}/r-executable-probe.tsv"
if [ "${r_exit}" -ne 0 ] || [ -z "${R_BIN}" ] || [ "${rscript_exit}" -ne 0 ] || [ -z "${RSCRIPT_BIN}" ]; then
  append_status executable_guard failed 127 R_or_Rscript_missing_after_plain_module_list_guard
  append_status source_sha_guard not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status dependency_source_guard not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status install_packages not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status r_cmd_install_drmTMB not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status library_drmTMB not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
  append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
  exit 127
fi
append_status executable_guard passed 0 R_and_Rscript_present_before_install

SOURCE_SHA="$(git -C "${SOURCE_ROOT}" rev-parse HEAD 2>/dev/null || awk -F '\t' '$1 == "source_sha_full" {print $2}' "${SOURCE_ROOT}/SOURCE-PROVENANCE.tsv" 2>/dev/null || printf 'NA')"
printf 'field\tvalue\nsource_sha\t%s\nexpected_source_sha\t%s\n' "${SOURCE_SHA}" "${EXPECTED_SOURCE_SHA}" > "${ART}/source-sha-probe.tsv"
if [ "${SOURCE_SHA}" != "${EXPECTED_SOURCE_SHA}" ]; then
  append_status source_sha_guard failed 125 source_sha_missing_NA_or_mismatch
  append_status dependency_source_guard not_attempted NA source_sha_guard_failed
  append_status install_packages not_attempted NA source_sha_guard_failed
  append_status r_cmd_install_drmTMB not_attempted NA source_sha_guard_failed
  append_status library_drmTMB not_attempted NA source_sha_guard_failed
  append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
  append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
  exit 125
fi
append_status source_sha_guard passed 0 source_sha_matches_expected_snapshot

case "${DRMTMB_T115_DEPENDENCY_REPO}" in
  file://*|/*) append_status dependency_source_guard passed 0 offline_or_prestaged_dependency_source ;;
  *) append_status dependency_source_guard failed 126 direct_or_unaudited_dependency_source_rejected; exit 126 ;;
esac

cp "${SLURM_SUBMIT_DIR:-.}/t114-install-packages-contract.R" "${ART}/t115-install-packages.R"
export DRMTMB_T114_ART="${ART}"
export DRMTMB_T114_LIB="${LIB}"
export DRMTMB_T114_DEPENDENCY_LIB="${DEPENDENCY_LIB}"
export DRMTMB_T114_REPO="${DRMTMB_T115_DEPENDENCY_REPO}"
"${RSCRIPT_BIN}" --vanilla "${ART}/t115-install-packages.R" > "${ART}/install-packages.stdout" 2> "${ART}/install-packages.stderr"
install_exit=$?
if [ "${install_exit}" -ne 0 ]; then
  append_status install_packages failed "${install_exit}" requested_dependency_install_failed_or_missing
  append_status r_cmd_install_drmTMB not_attempted NA dependency_install_not_complete
  append_status library_drmTMB not_attempted NA dependency_install_not_complete
  append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
  append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
  exit "${install_exit}"
fi
append_status install_packages passed 0 requested_dependencies_available
append_status r_cmd_install_drmTMB not_attempted NA t115_dependency_route_proof_stops_before_R_CMD_INSTALL
append_status library_drmTMB not_attempted NA t115_dependency_route_proof_stops_before_library_load
append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
