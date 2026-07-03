#!/bin/bash
#SBATCH --job-name=drmtmb-t99-deps
#SBATCH --account=def-snakagaw
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --output=/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/results/tranche99-spatial-drac-allocation-install-load-proof/slurm-%j.out
#SBATCH --error=/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/results/tranche99-spatial-drac-allocation-install-load-proof/slurm-%j.err

set -u
RUN_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0"
SOURCE_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/source"
ART="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/results/tranche99-spatial-drac-allocation-install-load-proof"
LIB="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/Rlib-tranche98"
TMP="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/tmp-tranche99"
REQUESTED_PACKAGES="cli,RcppEigen,TMB"
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1
export MAKEFLAGS="-j${SLURM_CPUS_PER_TASK:-1}"
export R_LIBS_USER="$LIB"
export TMPDIR="$TMP"
mkdir -p "$ART" "$LIB" "$TMP"
STATUS="$ART/t99-terminal-status.tsv"
printf 'stage\tstatus\texit_code\tnote\n' > "$STATUS"
append_status() {
  printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "$STATUS"
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
  printf 'run_root\t%s\n' "$RUN_ROOT"
  printf 'source_root\t%s\n' "$SOURCE_ROOT"
  printf 'proof_dir\t%s\n' "$ART"
  printf 'lib_dir\t%s\n' "$LIB"
  printf 'tmp_dir\t%s\n' "$TMP"
  printf 'requested_top_level_packages\t%s\n' "$REQUESTED_PACKAGES"
} > "$ART/host-provenance.tsv"
if [ -f /cvmfs/soft.computecanada.ca/config/profile/bash.sh ]; then
  . /cvmfs/soft.computecanada.ca/config/profile/bash.sh
fi
(module --force purge && module load StdEnv/2023 gcc/12.3 r/4.4.0) > "$ART/module-load.stdout" 2> "$ART/module-load.stderr"
module_exit=$?
if [ "$module_exit" -ne 0 ]; then
  append_status module_load failed "$module_exit" module_load_failed_before_R
  exit "$module_exit"
fi
append_status module_load passed 0 StdEnv_2023_gcc_12_3_r_4_4_0_loaded
{
  module list 2>&1
  R --version
} > "$ART/module-and-r-version.txt" 2>&1
cat > "$ART/t99-install-packages.R" <<'RSCRIPT'
lib <- Sys.getenv("R_LIBS_USER")
tmp <- Sys.getenv("TMPDIR")
art <- Sys.getenv("DRMTMB_T99_ART")
requested <- c("cli", "RcppEigen", "TMB")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
dir.create(tmp, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
options(repos = c(CRAN = "https://cloud.r-project.org"))
ncpus <- suppressWarnings(as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "1")))
if (is.na(ncpus) || ncpus < 1L) ncpus <- 1L
write_tsv <- function(x, path) {
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")
}
write_tsv(data.frame(package = requested, requested_top_level = TRUE), file.path(art, "requested-top-level-packages.tsv"))
write_tsv(data.frame(order = seq_along(.libPaths()), libpath = .libPaths()), file.path(art, "r-libpaths-before-install.tsv"))
before <- utils::installed.packages()
before_keys <- paste(rownames(before), before[, "LibPath"], sep = "@@")
install_results <- data.frame(package = requested, attempted = FALSE, status = "not_attempted", message = "", stringsAsFactors = FALSE)
for (pkg in requested) {
  i <- install_results$package == pkg
  if (requireNamespace(pkg, quietly = TRUE)) {
    install_results$attempted[i] <- FALSE
    install_results$status[i] <- "already_available"
    install_results$message[i] <- "available_before_install"
    next
  }
  install_results$attempted[i] <- TRUE
  res <- tryCatch({
    utils::install.packages(pkg, lib = lib, dependencies = c("Depends", "Imports", "LinkingTo"), Ncpus = ncpus)
    TRUE
  }, error = function(e) e)
  if (isTRUE(res) && requireNamespace(pkg, quietly = TRUE)) {
    install_results$status[i] <- "installed"
    install_results$message[i] <- "available_after_install"
  } else {
    install_results$status[i] <- "failed"
    install_results$message[i] <- conditionMessage(res)
  }
}
write_tsv(install_results, file.path(art, "install-packages-status.tsv"))
after <- utils::installed.packages()
after_keys <- paste(rownames(after), after[, "LibPath"], sep = "@@")
new_keys <- setdiff(after_keys, before_keys)
if (length(new_keys)) {
  idx <- match(new_keys, after_keys)
  closure <- data.frame(package = rownames(after)[idx], version = after[idx, "Version"], libpath = after[idx, "LibPath"], stringsAsFactors = FALSE)
} else {
  closure <- data.frame(package = character(), version = character(), libpath = character())
}
write_tsv(closure, file.path(art, "installed-package-closure.tsv"))
avail <- do.call(rbind, lapply(requested, function(pkg) {
  ok <- requireNamespace(pkg, quietly = TRUE)
  path <- if (ok) find.package(pkg, quiet = TRUE) else NA_character_
  version <- if (ok) as.character(utils::packageVersion(pkg)) else NA_character_
  data.frame(package = pkg, installed = ok, version = version, libpath = path, stringsAsFactors = FALSE)
}))
write_tsv(avail, file.path(art, "dependency-availability.tsv"))
write_tsv(data.frame(order = seq_along(.libPaths()), libpath = .libPaths()), file.path(art, "r-libpaths-after-install.tsv"))
capture.output(sessionInfo(), file = file.path(art, "sessionInfo-after-dependency-install.txt"))
if (!all(avail$installed)) {
  quit(status = 10, save = "no")
}
RSCRIPT
export DRMTMB_T99_ART="$ART"
Rscript --vanilla "$ART/t99-install-packages.R" > "$ART/install-packages.stdout" 2> "$ART/install-packages.stderr"
install_exit=$?
if [ "$install_exit" -ne 0 ]; then
  append_status install_packages failed "$install_exit" requested_dependency_install_failed_or_missing
  append_status r_cmd_install_drmTMB not_attempted NA dependency_install_not_complete
  append_status library_drmTMB not_attempted NA dependency_install_not_complete
  exit "$install_exit"
fi
append_status install_packages passed 0 requested_dependencies_available
R CMD INSTALL --library="$LIB" "$SOURCE_ROOT" > "$ART/r-cmd-install-drmTMB.stdout" 2> "$ART/r-cmd-install-drmTMB.stderr"
rcmd_exit=$?
printf 'stage\tstatus\texit_code\tnote\n' > "$ART/r-cmd-install-status.tsv"
printf 'r_cmd_install_drmTMB\t%s\t%s\t%s\n' "$([ "$rcmd_exit" -eq 0 ] && echo passed || echo failed)" "$rcmd_exit" "source_root=$SOURCE_ROOT" >> "$ART/r-cmd-install-status.tsv"
if [ "$rcmd_exit" -ne 0 ]; then
  append_status r_cmd_install_drmTMB failed "$rcmd_exit" source_install_failed_before_load
  append_status library_drmTMB not_attempted NA source_install_failed
  exit "$rcmd_exit"
fi
append_status r_cmd_install_drmTMB passed 0 source_install_completed
Rscript --vanilla - <<'RLOAD' > "$ART/library-drmTMB.stdout" 2> "$ART/library-drmTMB.stderr"
lib <- Sys.getenv("R_LIBS_USER")
art <- Sys.getenv("DRMTMB_T99_ART")
.libPaths(c(lib, .libPaths()))
write.table(data.frame(order = seq_along(.libPaths()), libpath = .libPaths()), file.path(art, "r-libpaths-before-library-load.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
library(drmTMB)
write.table(data.frame(package = "drmTMB", loaded = TRUE, version = as.character(utils::packageVersion("drmTMB")), libpath = find.package("drmTMB")), file.path(art, "drmTMB-load-proof.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
capture.output(sessionInfo(), file = file.path(art, "sessionInfo-after-drmTMB-load.txt"))
RLOAD
load_exit=$?
if [ "$load_exit" -ne 0 ]; then
  append_status library_drmTMB failed "$load_exit" library_load_failed
  exit "$load_exit"
fi
append_status library_drmTMB passed 0 library_load_completed_no_model
append_status model_execution not_run NA no_smoke_runner_no_formula_no_fit
append_status denominator not_created NA no_retained_denominator_no_coverage_no_status_move
