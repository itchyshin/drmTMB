#!/bin/bash
# Campaign driver (runs on Totoro from ~/drm_campaign_20261108/scale300).
# usage: bash run_campaign.sh <OUT dir> <n_seeds> <chunk> <parallel>
# Stages: (1) R data generation for phylo/spatial/lord routes; (2) Julia fits (Julia-native, generates data for the
# five fixture routes); (3) R fits (R-native, reads data/); (4) offline compare.  One thread per worker.
OUT=$1; NS=$2; CH=$3; P=$4
JCH=${JCH:-1.10}; JENV=${JENV:-jenv}; JDEPOT=${JDEPOT:-depot}; STAGES=${STAGES:-1234}   # Julia channel/env/depot and which stages to run
export JCH JENV SC_OUT=$OUT OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1
export JULIA_DEPOT_PATH=$HOME/drm_campaign_20261108/$JDEPOT PATH=$HOME/.juliaup/bin:$PATH
export DRMTMB_LIB=$HOME/drm_campaign_20261108/Rlib
cd $HOME/drm_campaign_20261108/scale300; mkdir -p $OUT/data $OUT/julia $OUT/r $OUT/logs
ALL="poisson_animal nb2_relmat gauss_ord gauss_animal poisson_phylo poisson_spatial poisson_labelled lord_poisson lord_nb2"
chunks() { for ((a=1; a<=NS; a+=CH)); do b=$((a+CH-1)); [ $b -gt $NS ] && b=$NS; echo "$a $b"; done; }
t0=$(date +%s)
[[ $STAGES == *1* ]] && { echo "[$(date)] stage1 data"
( chunks | while read a b; do echo "Rscript make_data_ps.R $a $b"; echo "Rscript make_data_lord.R $a $b"; done ) | xargs -P $P -I{} sh -c '{}' > $OUT/logs/stage1.log 2>&1; }
[[ $STAGES == *2* ]] && { echo "[$(date)] stage2 julia"
( for r in $ALL; do chunks | while read a b; do echo "$r $a $b"; done; done ) | xargs -P $P -L1 sh -c 'julia +$JCH --project=$HOME/drm_campaign_20261108/$JENV julia_run.jl $0 $1 $2 > $SC_OUT/logs/julia_$0_$1.log 2>&1'; }
[[ $STAGES == *3* ]] && { echo "[$(date)] stage3 R"
( for r in $ALL; do chunks | while read a b; do echo "$r $a $b"; done; done ) | xargs -P $P -L1 sh -c 'Rscript r_run.R $0 $1 $2 > $SC_OUT/logs/r_$0_$1.log 2>&1'; }
[[ $STAGES == *4* ]] && { echo "[$(date)] stage4 compare"
Rscript compare.R $NS > $OUT/logs/compare.log 2>&1; tail -30 $OUT/logs/compare.log; }
echo "[$(date)] done, wall $(( $(date +%s) - t0 )) s"
