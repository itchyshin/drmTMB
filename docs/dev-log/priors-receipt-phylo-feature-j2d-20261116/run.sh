#!/bin/sh
set -eu
base=/home/snakagaw/codex-phylo-feature-7bf-j2d355-20261116
export R_LIBS_USER=/home/snakagaw/R/lib
export JULIA_HOME=/home/snakagaw/.julia/juliaup/julia-1.12.6+0.x64.linux.gnu/bin
export LD_PRELOAD=/home/snakagaw/.julia/juliaup/julia-1.12.6+0.x64.linux.gnu/lib/julia/libunwind.so
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 NOT_CRAN=true
cd "$base"
git -C r rev-parse HEAD > r-source.txt
git -C julia rev-parse HEAD > julia-source.txt
git -C r status --porcelain > r-status-before.txt
git -C julia status --porcelain > julia-status-before.txt
sha256sum julia/Project.toml julia/Manifest.toml > julia-env-before.sha256
cd r
Rscript --no-init-file tools/run-julia-phylo-labels-public.R "$base/julia" "$base/feature-receipt.json" tree > "$base/runner.log" 2>&1
Rscript --no-init-file tools/check-julia-phylo-labels-receipt.R "$base/feature-receipt.json" --current --self-test > "$base/checker.log" 2>&1
cd "$base"
git -C r status --porcelain > r-status-after.txt
git -C julia status --porcelain > julia-status-after.txt
sha256sum julia/Project.toml julia/Manifest.toml > julia-env-after.sha256
cmp julia-env-before.sha256 julia-env-after.sha256
