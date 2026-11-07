#!/usr/bin/env bash
set -u
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=1 MAKEFLAGS=-j2
export PATH="$HOME/codex-runs/sd-article-ml-tools/pandoc-3.13/bin:$PATH"
export RSTUDIO_PANDOC="$HOME/codex-runs/sd-article-ml-tools/pandoc-3.13/bin"
export NOT_CRAN=true DRMTMB_JULIA_TESTS=false DRM_JL_PATH='' DRMODELS_JL_PATH='' _R_CHECK_FORCE_SUGGESTS_=false
cd "$(dirname "$0")" || exit 2
printf 'PID=%s\nSTARTED=' "$$" > status.txt
date -u '+%Y-%m-%dT%H:%M:%SZ' >> status.txt
sha256sum input.tar.gz > input.sha256
pandoc --version > pandoc-version.txt
Rscript -e 'stopifnot(rmarkdown::pandoc_available()); cat(as.character(rmarkdown::pandoc_version()), "\n")' > pandoc-r-preflight.txt
mkdir source
tar -xzf input.tar.gz -C source
R CMD build --no-manual source/drmTMB > build.log 2>&1
build_code=$?
printf 'BUILD_EXIT=%s\n' "$build_code" >> status.txt
if [ "$build_code" -eq 0 ]; then
  R CMD check --no-manual drmTMB_0.7.1.tar.gz > check.log 2>&1
  check_code=$?
  printf 'CHECK_EXIT=%s\n' "$check_code" >> status.txt
else
  check_code=2
fi
printf 'FINISHED=' >> status.txt
date -u '+%Y-%m-%dT%H:%M:%SZ' >> status.txt
exit "$check_code"
