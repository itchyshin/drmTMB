#!/usr/bin/env bash
#SBATCH --job-name=drmtmb-t118-pkg-load
#SBATCH --account=def-snakagaw
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --output=/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/logs/t118-package-install-load-%j.out
#SBATCH --error=/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/logs/t118-package-install-load-%j.err

# Tranche 117 candidate packet only. Do not submit until Tranche 118 is opened
# after checkpoint plus Rose/Fisher/Gauss/Noether/Grace approval.
set -euo pipefail

if [[ "${DRMTMB_QSERIES_T118_APPROVED:-}" != "rose_fisher_gauss_noether_grace" ]]; then
  echo "Refusing T118 package-install/load proof without blocking-review approval." >&2
  exit 2
fi

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

SOURCE_DIR="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/source"
RUN_ROOT="/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0"
PROOF_DIR="$RUN_ROOT/results/tranche118-spatial-drac-package-install-load-proof"
INSTALL_LIB="$RUN_ROOT/Rlib-tranche117-drmTMB"
DEPENDENCY_LIB_A="$RUN_ROOT/Rlib-tranche115"
DEPENDENCY_LIB_B="$RUN_ROOT/Rlib-tranche98"
EXPECTED_SHA="56add7f04fab7bec57a42e56eaeb090dff491863"

mkdir -p "$PROOF_DIR" "$INSTALL_LIB" "$RUN_ROOT/logs"
module --force purge
module load StdEnv/2023
module load r/4.4.0

ACTUAL_SHA="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
printf 'source_sha	%s
expected_source_sha	%s
' "$ACTUAL_SHA" "$EXPECTED_SHA" > "$PROOF_DIR/source-sha-probe.tsv"
if [[ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]]; then
  echo "Source SHA mismatch; refusing install/load proof." >&2
  exit 3
fi

export R_LIBS_USER="$INSTALL_LIB:$DEPENDENCY_LIB_A:$DEPENDENCY_LIB_B:${R_LIBS_USER:-}"
R CMD INSTALL --library="$INSTALL_LIB" "$SOURCE_DIR" > "$PROOF_DIR/r-cmd-install.log" 2>&1
Rscript --vanilla -e 'library(drmTMB); cat("drmTMB_load_ok\t", as.character(packageVersion("drmTMB")), "\n", sep = "")' > "$PROOF_DIR/library-drmTMB.tsv"
printf 'model_boundary\tno_smoke_runner_no_formula_no_fit_no_denominator_no_coverage\n' > "$PROOF_DIR/model-boundary.tsv"
