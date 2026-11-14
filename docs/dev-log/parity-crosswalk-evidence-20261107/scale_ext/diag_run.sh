#!/bin/bash
# Runs the flagged-seed diagnoses, one process per route (<= 4 processes, 1 thread each). Seeds from summary/flagged_seeds.csv.
export SC_OUT=$HOME/drm_ext_20261108/out OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 DRMTMB_LIB=$HOME/drm_campaign_20261108/Rlib
cd $HOME/drm_ext_20261108/scripts; mkdir -p $SC_OUT/logs/diag; : > $SC_OUT/summary/diagnosis.csv; rm -f $SC_OUT/summary/diagnosis.csv
for r in $(Rscript -e 'x<-read.csv(file.path(Sys.getenv("SC_OUT"),"summary","flagged_seeds.csv")); cat(unique(x$route))'); do
  s=$(Rscript -e 'x<-read.csv(file.path(Sys.getenv("SC_OUT"),"summary","flagged_seeds.csv")); cat(x$seed[x$route=="'$r'"])')
  Rscript diagnose.R $r $s > $SC_OUT/logs/diag/$r.log 2>&1 &
done
wait; echo diag done
