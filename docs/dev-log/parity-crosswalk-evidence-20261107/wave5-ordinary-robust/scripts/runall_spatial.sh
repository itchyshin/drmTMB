#!/bin/bash
# usage: runall_spatial.sh <outdir> <env>   (Julia 1.10; 30 workers x 10 seeds)
export PATH=$HOME/.juliaup/bin:$PATH OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1
out=$1; env=$2
export JULIA_DEPOT_PATH=$HOME/drm_fix_20261108/depot110
cd $HOME/drm_fix_20261108; mkdir -p $out logs
for k in $(seq 0 29); do a=$((k*10+1)); b=$((a+9)); julia +1.10 --project=$env fit_spatial.jl data_sp $out $a $b > logs/$(basename $out)_$k.log 2>&1 & done
wait; echo done $out
