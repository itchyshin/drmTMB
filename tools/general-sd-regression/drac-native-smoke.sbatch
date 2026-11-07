#!/usr/bin/env bash
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=drmtmb-sd-smoke
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=slurm-%j.log
set -euo pipefail
job="$PWD"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 MAKEFLAGS=-j2
module load StdEnv/2023 gcc/12.3 r/4.5.0
module -t list > "$job/modules.txt" 2>&1
mkdir "$job/library"
export R_LIBS="$job/library:$HOME/.local/R/4.5.0"
export DRMTMB_SD_TEST_LIBRARY="$job/library"
printf '%s\n' 'CFLAGS=-O1 -g0' 'CXXFLAGS=-O1 -g0' 'CXX17FLAGS=-O1 -g0' > "$job/Makevars"
export R_MAKEVARS_USER="$job/Makevars"
date -u > "$job/started-utc.txt"
hostname > "$job/node.txt"
Rscript -e 'stopifnot(requireNamespace("TMB"),requireNamespace("digest"),requireNamespace("RcppEigen")); print(R.version.string); print(packageVersion("TMB"))' > "$job/prerequisites.log" 2>&1
/usr/bin/time -v R CMD INSTALL --no-multiarch --library="$job/library" "$job/source/drmTMB" > "$job/install.log" 2>&1
cd "$job/source/drmTMB"
# One predeclared feasibility seed; no production campaign on this job.
timeout --signal=TERM --kill-after=5 120 Rscript tools/general-sd-regression/run-bernoulli-pilot.R "$job/pilot" 1 > "$job/pilot.log" 2>&1
date -u > "$job/completed-utc.txt"
printf '%s\n' DRAC_NATIVE_BERNOULLI_SMOKE_PASS
