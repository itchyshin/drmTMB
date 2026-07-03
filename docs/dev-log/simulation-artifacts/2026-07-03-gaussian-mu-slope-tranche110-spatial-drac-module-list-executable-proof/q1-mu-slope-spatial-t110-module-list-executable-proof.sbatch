#!/bin/bash
# T110: allocation-safe no-model module-list/executable proof only.
# No package install, R CMD INSTALL, library(drmTMB), smoke runner, model formula,
# model fit, retained denominator, or coverage command.
#SBATCH --job-name=drmtmb-t110-modlist
#SBATCH --account=def-snakagaw
#SBATCH --time=00:05:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --output=/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/results/tranche110-spatial-drac-module-list-executable-proof/slurm-%j.out
#SBATCH --error=/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/results/tranche110-spatial-drac-module-list-executable-proof/slurm-%j.err

set -o pipefail
if [ -f /cvmfs/soft.computecanada.ca/config/profile/bash.sh ]; then
  : "${SKIP_CC_CVMFS:=0}"
  . /cvmfs/soft.computecanada.ca/config/profile/bash.sh
fi
set -u

RUN_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0"
SOURCE_ROOT="${RUN_ROOT}/source"
ART="${RUN_ROOT}/results/tranche110-spatial-drac-module-list-executable-proof"
TMP="${RUN_ROOT}/tmp-tranche110"

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1
export TMPDIR="${TMP}"

mkdir -p "${ART}" "${TMP}"
STATUS="${ART}/t110-terminal-status.tsv"
printf 'stage\tstatus\texit_code\tnote\n' > "${STATUS}"
append_status() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "${STATUS}"
}

{
  printf 'field\tvalue\n'
  printf 'observed_at_utc\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'remote_host\t%s\n' "$(hostname)"
  printf 'remote_user\t%s\n' "$(whoami)"
  printf 'pwd\t%s\n' "$(pwd)"
  printf 'slurm_job_id\t%s\n' "${SLURM_JOB_ID:-NA}"
  printf 'slurm_job_name\t%s\n' "${SLURM_JOB_NAME:-NA}"
  printf 'slurm_submit_dir\t%s\n' "${SLURM_SUBMIT_DIR:-NA}"
  printf 'slurm_cpus_per_task\t%s\n' "${SLURM_CPUS_PER_TASK:-NA}"
  printf 'slurm_mem_per_node\t%s\n' "${SLURM_MEM_PER_NODE:-NA}"
  printf 'run_root\t%s\n' "${RUN_ROOT}"
  printf 'source_root\t%s\n' "${SOURCE_ROOT}"
  printf 'proof_dir\t%s\n' "${ART}"
  printf 'tmp_dir\t%s\n' "${TMP}"
  printf 'source_sha\t%s\n' "$(git -C "${SOURCE_ROOT}" rev-parse HEAD 2>/dev/null || printf 'NA')"
  printf 'profile_guard\t%s\n' "SKIP_CC_CVMFS_defined_before_profile_source;set_u_after_profile_source"
  printf 'module_route_guard\t%s\n' "module_load_StdEnv_2023_then_r_4_4_0;plain_module_list_capture;require_r_4_4_0_in_raw_module_list"
  printf 'executable_guard\t%s\n' "command_v_R_and_Rscript_after_plain_module_list_guard;fail_closed_before_install_if_missing"
  printf 'model_boundary\t%s\n' "no_package_install_no_R_CMD_INSTALL_no_library_drmTMB_no_smoke_runner_no_formula_no_fit_no_denominator"
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
  append_status install_packages not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status r_cmd_install_drmTMB not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status library_drmTMB not_attempted NA R_or_Rscript_missing_after_plain_module_list_guard
  append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
  append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
  exit 127
fi
append_status executable_guard passed 0 R_and_Rscript_present_before_install

{
  module list 2>&1
  "${R_BIN}" --version
  "${RSCRIPT_BIN}" --version
} > "${ART}/module-and-r-version.txt" 2>&1

append_status install_packages not_attempted NA t110_contract_stops_before_package_install
append_status r_cmd_install_drmTMB not_attempted NA t110_contract_stops_before_R_CMD_INSTALL
append_status library_drmTMB not_attempted NA t110_contract_stops_before_library_load
append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
