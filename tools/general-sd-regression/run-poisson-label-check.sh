#!/usr/bin/env bash
# Invoke in a fresh job directory under an owned 240-second outer timeout.
set -euo pipefail
[[ $# -eq 1 ]]
job="$1"
[[ -d "$job/source/drmTMB" && ! -e "$job/library" ]]
mkdir "$job/library"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 MAKEFLAGS=-j2
printf '%s\n' 'CFLAGS=-O1 -g0' 'CXXFLAGS=-O1 -g0' 'CXX17FLAGS=-O1 -g0' > "$job/Makevars"
export R_MAKEVARS_USER="$job/Makevars"
date -u > "$job/started-utc.txt"
R CMD INSTALL --no-multiarch --library="$job/library" "$job/source/drmTMB" > "$job/install.log" 2>&1
cd "$job/source/drmTMB"
export DRMTMB_SD_TEST_LIBRARY="$job/library"
Rscript tools/general-sd-regression/run-native-tests.R \
  tests/testthat/test-poisson-sd-integration.R \
  tests/testthat/test-binomial-sd-target-selectors-integration.R \
  tests/testthat/test-gaussian-random-effect-scale.R > "$job/tests.log" 2>&1
date -u > "$job/completed-utc.txt"
printf '%s\n' POISSON_LABEL_CHECK_PASS
