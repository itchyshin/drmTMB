#!/bin/bash
#SBATCH --job-name=drmtmb-ce-q2-setup
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:30:00

set -euo pipefail
: "${CE_PACKET:?set CE_PACKET to the frozen packet directory}"
: "${CE_RUN_ROOT:?set CE_RUN_ROOT to the immutable run directory}"
: "${DRMTMB_LIB:?set DRMTMB_LIB to the isolated R library}"
: "${CE_BASE_R_LIB:?set CE_BASE_R_LIB to the read-only dependency library}"

module --force purge
module load StdEnv/2023 gcc/12.3 r/4.4.0
export R_PROFILE_USER=/dev/null
export R_LIBS="${DRMTMB_LIB}:${CE_BASE_R_LIB}"
export R_LIBS_USER="${DRMTMB_LIB}"
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

expected_sha=$(awk -F '\t' '$1 == "source_sha" {print $2}' "${CE_PACKET}/metadata.tsv")
test -n "${expected_sha}"
test "$(cat "${CE_RUN_ROOT}/source/SOURCE_SHA")" = "${expected_sha}"
mkdir -p "${DRMTMB_LIB}"
Rscript --vanilla -e 'required <- c("TMB", "RcppEigen", "cli", "lifecycle", "Matrix"); missing <- required[!vapply(required, requireNamespace, logical(1L), quietly = TRUE)]; if (length(missing)) stop("Missing frozen dependency-library packages: ", paste(missing, collapse = ", "))'
R CMD INSTALL --preclean --library="${DRMTMB_LIB}" "${CE_RUN_ROOT}/source"
Rscript --vanilla -e 'library("drmTMB", lib.loc = Sys.getenv("R_LIBS_USER")); stopifnot(nzchar(as.character(packageVersion("drmTMB"))))'
Rscript --vanilla -e 'packages <- c("drmTMB", "TMB", "RcppEigen", "cli", "lifecycle", "Matrix"); out <- data.frame(package = packages, version = vapply(packages, function(x) as.character(packageVersion(x)), character(1L)), library = vapply(packages, function(x) dirname(find.package(x)), character(1L))); write.table(out, file.path(Sys.getenv("CE_RUN_ROOT"), "receipts", "r-environment.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)'
printf '%s\n' "${SLURM_JOB_ID}" > "${CE_RUN_ROOT}/install.complete"
