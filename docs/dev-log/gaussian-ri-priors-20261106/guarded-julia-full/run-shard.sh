#!/bin/bash
set -u
cd "/home/snakagaw/hsq_work/drmodels-ri-priors-guard-final-ff10a2f9-20261106" || exit 2
export JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_PRECOMPILE_TASKS=1
export DRM_PARITY_TESTS=0 DRM_TEST_SHARD="$1/8"
DRM_TEST_LIST_ONLY=1 "/home/snakagaw/.julia/juliaup/julia-1.10.12+0.x64.linux.gnu/bin/julia" --project=. -e 'include("test/runtests.jl")' > "/home/snakagaw/hsq_work/ri-priors-guard-final-julia-suite-ff10-20261106/shard-$1-list.log" 2>&1 || exit 3
date -u +%FT%TZ > "/home/snakagaw/hsq_work/ri-priors-guard-final-julia-suite-ff10-20261106/shard-$1-start"
timeout --signal=TERM --kill-after=30 10200 "/home/snakagaw/.julia/juliaup/julia-1.10.12+0.x64.linux.gnu/bin/julia" --project=. -e 'using Pkg; Pkg.test(;allow_reresolve=false)'
code=$?
printf '%s
' "$code" > "/home/snakagaw/hsq_work/ri-priors-guard-final-julia-suite-ff10-20261106/shard-$1-exit"
date -u +%FT%TZ > "/home/snakagaw/hsq_work/ri-priors-guard-final-julia-suite-ff10-20261106/shard-$1-end"
exit "$code"
