#!/bin/bash
# Totoro driver, ~/drm_weak_20261108. usage: bash run_weak.sh <variant: base|fix> <parallel>
# Runs the scale_ext Julia fits (julia_run.jl, unchanged) for the three NB2 routes that share the structured q2 helper,
# against the source in ~/drm_weak_20261108/src_<variant>, Julia 1.10.12, one thread per worker.
V=$1; P=${2:-30}; W=$HOME/drm_weak_20261108
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
export JULIA_DEPOT_PATH=$HOME/drm_ext_20261108/depot PATH=$HOME/.juliaup/bin:$PATH
export SC_OUT=$W/out_$V
mkdir -p $SC_OUT/julia $SC_OUT/logs; mkdir -p $SC_OUT/data
for f in $HOME/drm_ext_20261108/out/data/nb2_phylo_s*.csv; do ln -sf $f $SC_OUT/data/; done
cd $HOME/drm_ext_20261108/scripts
t0=$(date +%s)
( for r in nb2_phylo:100 nb2_animal:100 nb2_relmat:300; do n=${r##*:}; rt=${r%%:*}; for ((a=1; a<=n; a+=10)); do b=$((a+9)); [ $b -gt $n ] && b=$n; echo "$rt $a $b"; done; done ) | \
  xargs -P $P -L1 sh -c 'julia +1.10.12 --project='$W'/jenv_'$V' julia_run.jl $0 $1 $2 > $SC_OUT/logs/julia_$0_$1.log 2>&1'
echo "variant $V done, wall $(( $(date +%s) - t0 )) s"
