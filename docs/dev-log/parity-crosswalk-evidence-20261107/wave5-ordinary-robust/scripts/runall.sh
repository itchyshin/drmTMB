#!/bin/bash
# usage: runall.sh <v:110|112> <datadir> <outdir> <env> ; 15 workers x 20 seeds
export PATH=$HOME/.juliaup/bin:$PATH OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1
v=$1; data=$2; out=$3; env=$4; ch=1.10; [ $v = 112 ] && ch=1.12
export JULIA_DEPOT_PATH=$HOME/drm_fix_20261108/depot$v
cd $HOME/drm_fix_20261108; mkdir -p $out logs
for k in $(seq 0 14); do a=$((k*20+1)); b=$((a+19)); julia +$ch --project=$env fit_ord.jl $data $out $a $b > logs/$(basename $out)_$k.log 2>&1 & done
wait
echo done $out
