#!/usr/bin/env bash
# Run only inside a fresh, isolated remote directory under an outer timeout.
set -euo pipefail
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
export MAKEFLAGS=-j2
test "$#" -eq 1
job="$1"
test -d "$job/source/drmTMB"
test ! -e "$job/library"
mkdir "$job/library"
printf '%s\n' "CFLAGS=-O1 -g0" "CXXFLAGS=-O1 -g0" "CXX17FLAGS=-O1 -g0" > "$job/Makevars"
export R_MAKEVARS_USER="$job/Makevars"
printf '%s\n' "$$" > "$job/worker.pid"
date -u > "$job/started-utc.txt"
R CMD INSTALL --no-multiarch --library="$job/library" "$job/source/drmTMB" > "$job/install.log" 2>&1
cd "$job/source/drmTMB"
export DRMTMB_SD_TEST_LIBRARY="$job/library"
Rscript tools/general-sd-regression/run-bernoulli-pilot.R "$job/pilot" > "$job/pilot.log" 2>&1
date -u > "$job/completed-utc.txt"
printf '%s\n' TOTOrO_BERNOULLI_PILOT_PASS
