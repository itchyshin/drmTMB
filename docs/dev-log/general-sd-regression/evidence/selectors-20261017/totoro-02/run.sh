#!/usr/bin/env bash
set -euo pipefail
job="$1"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 MAKEFLAGS=-j2
mkdir "$job/library"
printf '%s\n' 'CFLAGS=-O1 -g0' 'CXXFLAGS=-O1 -g0' 'CXX17FLAGS=-O1 -g0' > "$job/Makevars"
export R_MAKEVARS_USER="$job/Makevars"
date -u > "$job/started-utc.txt"
R CMD INSTALL --no-multiarch --library="$job/library" "$job/source/drmTMB" > "$job/install.log" 2>&1
cd "$job/source/drmTMB"
export DRMTMB_SD_TEST_LIBRARY="$job/library" DRMTMB_SELECTOR_JOB="$job"
Rscript tools/general-sd-regression/run-native-tests.R \
 tests/testthat/test-binomial-sd-target-selectors-integration.R \
 tests/testthat/test-binomial-random-effect-scale.R \
 tests/testthat/test-binomial-sd-integration.R \
 tests/testthat/test-binomial-sd-links.R \
 tests/testthat/test-binomial-sd-profile.R \
 tests/testthat/test-binomial-sd-simulation.R \
 tests/testthat/test-binomial-sd-clamp.R \
 tests/testthat/test-gaussian-random-effect-scale.R \
 tests/testthat/test-clamp-active-guard.R \
 tests/testthat/test-binomial-links.R \
 tests/testthat/test-binomial-response.R > "$job/tests.log" 2>&1
Rscript -e 'library(digest); .libPaths(c(Sys.getenv("DRMTMB_SD_TEST_LIBRARY"),.libPaths())); library(drmTMB); paths <- c(getLoadedDLLs()[["drmTMB"]][["path"]],file.path(find.package("drmTMB"),"R",c("drmTMB.rdb","drmTMB.rdx"))); write.csv(data.frame(file=paths,sha256=vapply(paths,function(p)digest(file=p,algo="sha256"),character(1))),file.path(Sys.getenv("DRMTMB_SELECTOR_JOB"),"runtime-hashes.csv"),row.names=FALSE); writeLines(capture.output(sessionInfo()),file.path(Sys.getenv("DRMTMB_SELECTOR_JOB"),"sessionInfo.txt"))'
date -u > "$job/completed-utc.txt"
printf '%s\n' SELECTOR_COMPILED_PASS
