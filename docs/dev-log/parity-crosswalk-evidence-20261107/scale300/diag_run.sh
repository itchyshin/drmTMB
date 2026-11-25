#!/bin/bash
# runs the flagged-seed diagnoses, one process per route (<=9 processes, 1 thread each)
export SC_OUT=$HOME/drm_campaign_20261108/full300 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 DRMTMB_LIB=$HOME/drm_campaign_20261108/Rlib
cd $HOME/drm_campaign_20261108/scale300; rm -f $SC_OUT/diagnosis.csv
mkdir -p $SC_OUT/logs/diag
Rscript diagnose.R poisson_spatial 20 88 91 118 147 157 204 211 279 282 > $SC_OUT/logs/diag/spatial.log 2>&1 &
Rscript diagnose.R nb2_relmat 133 > $SC_OUT/logs/diag/nb2.log 2>&1 &
Rscript diagnose.R poisson_phylo 54 > $SC_OUT/logs/diag/phylo.log 2>&1 &
Rscript diagnose.R lord_poisson 41 > $SC_OUT/logs/diag/lordp.log 2>&1 &
Rscript diagnose.R lord_nb2 58 78 93 116 139 148 184 195 203 207 232 262 276 293 > $SC_OUT/logs/diag/lordn.log 2>&1 &
wait; echo diag done
