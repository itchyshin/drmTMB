#!/bin/bash
# Driver (runs on Totoro from ~/drm_ext_20261108/scripts).  usage: bash run_ext.sh <OUT dir> <parallel> <chunk>
# Stages: 1 R data (nb2_phylo); 2 Julia fits (generate the other data); 3 R fits; 4 compare.  One thread per worker.
OUT=$1; P=${2:-55}; CH=${3:-10}
export SC_OUT=$OUT OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
export JULIA_DEPOT_PATH=$HOME/drm_ext_20261108/depot PATH=$HOME/.juliaup/bin:$PATH
export DRMTMB_LIB=$HOME/drm_campaign_20261108/Rlib
JENV=$HOME/drm_ext_20261108/jenv
cd $HOME/drm_ext_20261108/scripts; mkdir -p $OUT/data $OUT/julia $OUT/r $OUT/logs
declare -A NS=( [gauss_q3]=100 [gauss_q4]=100 [gauss_ord]=300 [nb2_relmat]=300 [poisson_relmat]=100 [nb2_animal]=100 [nb2_phylo]=100 [gauss_relmat]=100 )
ROUTES="gauss_ord nb2_relmat gauss_q4 gauss_q3 poisson_relmat nb2_animal nb2_phylo gauss_relmat"
STAGES=${STAGES:-1234}
tasks() { for r in $ROUTES; do n=${NS[$r]}; for ((a=1; a<=n; a+=CH)); do b=$((a+CH-1)); [ $b -gt $n ] && b=$n; echo "$r $a $b"; done; done; }
t0=$(date +%s)
[[ $STAGES == *1* ]] && { echo "[$(date)] stage1 data"; ( for ((a=1; a<=100; a+=CH)); do echo "Rscript make_data_nb2phylo.R $a $((a+CH-1))"; done ) | xargs -P $P -I{} sh -c '{}' > $OUT/logs/stage1.log 2>&1; }
[[ $STAGES == *2* ]] && { echo "[$(date)] stage2 julia"; tasks | xargs -P $P -L1 sh -c 'julia +1.10 --project='$JENV' julia_run.jl $0 $1 $2 > $SC_OUT/logs/julia_$0_$1.log 2>&1'; }
[[ $STAGES == *3* ]] && { echo "[$(date)] stage3 R"; tasks | xargs -P $P -L1 sh -c 'Rscript r_run.R $0 $1 $2 > $SC_OUT/logs/r_$0_$1.log 2>&1'; }
echo "[$(date)] done, wall $(( $(date +%s) - t0 )) s"
