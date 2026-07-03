#!/usr/bin/env bash
#SBATCH --job-name=drmtmb-t124-model
#SBATCH --account=def-snakagaw
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G
#SBATCH --output=/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/logs/t124-model-smoke-%j.out
#SBATCH --error=/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/logs/t124-model-smoke-%j.err

# Tranche 124 q1 mu one-slope spatial DRAC Rorqual n=5 model-smoke execution.
# Authorized by the local Tranche 123 execution-approval checkpoint only.
set -euo pipefail

APPROVAL_REQUIRED="rose_fisher_gauss_noether_grace"
if [[ "${DRMTMB_QSERIES_T124_APPROVED:-}" != "$APPROVAL_REQUIRED" ]]; then
  echo "Refusing T124 model smoke without Rose/Fisher/Gauss/Noether/Grace approval token." >&2
  exit 2
fi
if [[ "${SLURM_CLUSTER_NAME:-}" != "rorqual" || -z "${SLURM_JOB_ID:-}" ]]; then
  echo "Refusing T124 model smoke outside a Rorqual Slurm allocation." >&2
  exit 2
fi

RUN_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0"
SOURCE_DIR="$RUN_ROOT/source"
OUTPUT_DIR="$RUN_ROOT/results/tranche124-spatial-drac-model-smoke-execution"
META_DIR="$RUN_ROOT/results/tranche124-spatial-drac-model-smoke-execution-slurm-metadata"
INSTALL_LIB="$RUN_ROOT/Rlib-tranche120-drmTMB"
DEPENDENCY_LIB_A="$RUN_ROOT/Rlib-tranche115"
DEPENDENCY_LIB_B="$RUN_ROOT/Rlib-tranche98"
EXPECTED_SHA="56add7f04fab7bec57a42e56eaeb090dff491863"
HOST_LABEL="drac_rorqual_q1mu_slope_spatial_t120_t122_packet_n5"
SEEDS="861001,861002,861003,861004,861005"
RUNNER="$SOURCE_DIR/tools/run-gaussian-mu-slope-tranche85-spatial-drac-host-smoke.R"
STATUS_FILE="$META_DIR/t124-terminal-status.tsv"

mkdir -p "$META_DIR" "$RUN_ROOT/logs"
printf 'stage\tstatus\texit_code\tnote\n' > "$STATUS_FILE"
record_status() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$STATUS_FILE"
}
record_status packet_start passed 0 "authorized_from_tranche123_checkpoint_single_t124_execution"

if [[ -e "$OUTPUT_DIR" ]]; then
  record_status output_dir_guard failed 12 "output_dir_already_exists_refuse_repeat_execution"
  echo "T124 output directory already exists; refusing repeat execution: $OUTPUT_DIR" >&2
  exit 12
fi

if module --force purge; then
  record_status module_purge passed 0 "module_purge_completed"
else
  rc=$?
  record_status module_purge failed "$rc" "module_purge_failed"
  exit "$rc"
fi
if module load StdEnv/2023 && module load r/4.4.0; then
  record_status module_load passed 0 "StdEnv_2023_and_r_4_4_0_loaded"
else
  rc=$?
  record_status module_load failed "$rc" "StdEnv_2023_or_r_4_4_0_load_failed"
  exit "$rc"
fi

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1
export R_LIBS_USER="$INSTALL_LIB:$DEPENDENCY_LIB_A:$DEPENDENCY_LIB_B:${R_LIBS_USER:-}"
record_status r_libs_user configured NA "Rlib_tranche120_then_T115_then_T98"

if [[ ! -d "$SOURCE_DIR" || ! -d "$RUN_ROOT" || ! -f "$RUNNER" ]]; then
  record_status path_guard failed 3 "source_run_root_or_runner_missing"
  echo "T124 source/run root/runner missing." >&2
  exit 3
fi

ACTUAL_SHA=""
SOURCE_SHA_METHOD="unobserved"
if git -C "$SOURCE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ACTUAL_SHA="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
  SOURCE_SHA_METHOD="git_rev_parse"
elif [[ -f "$SOURCE_DIR/SOURCE-PROVENANCE.tsv" ]]; then
  ACTUAL_SHA="$(awk -F '\t' '$1 == "source_sha_full" { print $2; exit }' "$SOURCE_DIR/SOURCE-PROVENANCE.tsv")"
  SOURCE_SHA_METHOD="SOURCE-PROVENANCE.tsv"
else
  record_status source_sha_guard failed 3 "missing_git_metadata_and_SOURCE_PROVENANCE_tsv"
  echo "Missing git metadata and SOURCE-PROVENANCE.tsv; refusing T124." >&2
  exit 3
fi
printf 'source_sha\t%s\nexpected_source_sha\t%s\nsource_sha_method\t%s\n' "$ACTUAL_SHA" "$EXPECTED_SHA" "$SOURCE_SHA_METHOD" > "$META_DIR/source-sha-probe.tsv"
if [[ -z "$ACTUAL_SHA" || "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
  record_status source_sha_guard failed 3 "source_sha_mismatch_or_empty"
  echo "Source SHA mismatch; refusing T124." >&2
  exit 3
fi
record_status source_sha_guard passed 0 "source_sha_matched_expected_from_$SOURCE_SHA_METHOD"

{
  printf 'field\tvalue\n'
  printf 'date\t%s\n' "$(date -Iseconds)"
  printf 'job_id\t%s\n' "${SLURM_JOB_ID:-NA}"
  printf 'cluster\t%s\n' "${SLURM_CLUSTER_NAME:-NA}"
  printf 'node\t%s\n' "${SLURMD_NODENAME:-$(hostname)}"
  printf 'submission_host_context\t%s\n' "${SLURM_SUBMIT_HOST:-NA}"
  printf 'run_root\t%s\n' "$RUN_ROOT"
  printf 'source_root\t%s\n' "$SOURCE_DIR"
  printf 'output_dir\t%s\n' "$OUTPUT_DIR"
  printf 'metadata_dir\t%s\n' "$META_DIR"
  printf 'host_label\t%s\n' "$HOST_LABEL"
  printf 'seeds\t%s\n' "$SEEDS"
  printf 'source_sha\t%s\n' "$ACTUAL_SHA"
  printf 'runner\t%s\n' "$RUNNER"
  printf 'coverage_decision\tcoverage_not_authorized\n'
  printf 'promotion_decision\tdo_not_promote\n'
  printf 'support_cell_decision\tunchanged_point_fit_planned_planned\n'
} > "$META_DIR/host-provenance.tsv"

sha256sum "$0" > "$META_DIR/packet.sha256" || true
sha256sum "$RUNNER" > "$META_DIR/runner.sha256"
Rscript --version > "$META_DIR/rscript-version.txt" 2>&1 || true
Rscript --vanilla -e 'writeLines(capture.output(sessionInfo()))' > "$META_DIR/sessionInfo-before-smoke.txt" 2>&1 || true

if Rscript --vanilla -e 'library(drmTMB); cat("drmTMB_load_ok\t", as.character(packageVersion("drmTMB")), "\n", sep="")' > "$META_DIR/library-drmTMB.tsv" 2> "$META_DIR/library-drmTMB.stderr"; then
  record_status library_drmTMB passed 0 "library_drmTMB_loaded_before_model_smoke"
else
  rc=$?
  record_status library_drmTMB failed "$rc" "library_drmTMB_failed_before_model_smoke"
  exit "$rc"
fi

if Rscript --vanilla -e 'ok <- requireNamespace("devtools", quietly = TRUE); cat("devtools_available\t", ok, "\n", sep=""); if (!ok) quit(status = 13)' > "$META_DIR/devtools-availability.tsv" 2> "$META_DIR/devtools-availability.stderr"; then
  record_status devtools_available passed 0 "devtools_available_for_existing_T85_runner_load_all"
else
  rc=$?
  record_status devtools_available failed "$rc" "dependency_drift_devtools_missing_or_unloadable"
  printf 'missing_result_reason\tdependency_drift_devtools_missing_or_unloadable\nexpected_output_dir\t%s\n' "$OUTPUT_DIR" > "$META_DIR/missing-result-proof.tsv"
  exit "$rc"
fi

COMMAND=(
  Rscript --no-init-file "$RUNNER"
  --mode=execute
  --provider=spatial
  --target=both
  --n-rep=5
  --seeds="$SEEDS"
  --host-label="$HOST_LABEL"
  --source-snapshot-path="$SOURCE_DIR"
  --run-root-path="$RUN_ROOT"
  --output-dir="$OUTPUT_DIR"
  --summary-path=NA
  --overwrite=false
  --write-dashboard=false
)
printf '%q ' "${COMMAND[@]}" > "$META_DIR/exact-command.txt"
printf '\n' >> "$META_DIR/exact-command.txt"

record_status model_smoke started NA "runner_started"
set +e
DRMTMB_Q1MU_SLOPE_T77_EXECUTION_APPROVED="$APPROVAL_REQUIRED" \
  "${COMMAND[@]}" > "$META_DIR/runner.stdout" 2> "$META_DIR/runner.stderr"
RUNNER_EXIT=$?
set -e
record_status model_smoke completed "$RUNNER_EXIT" "runner_exit_code_$RUNNER_EXIT"
if [[ ! -f "$OUTPUT_DIR/structured-re-gaussian-mu-slope-tranche85-spatial-host-smoke-results.tsv" ]]; then
  printf 'missing_result_reason\trunner_did_not_write_results_tsv\nexpected_output_dir\t%s\nrunner_exit_code\t%s\n' "$OUTPUT_DIR" "$RUNNER_EXIT" > "$META_DIR/missing-result-proof.tsv"
fi
Rscript --vanilla -e 'writeLines(capture.output(sessionInfo()))' > "$META_DIR/sessionInfo-after-smoke.txt" 2>&1 || true
record_status denominator held NA "host_separated_t124_terminal_review_required_no_pooling"
record_status coverage not_authorized NA "coverage_not_authorized"
record_status promotion do_not_promote NA "do_not_promote"
exit "$RUNNER_EXIT"
