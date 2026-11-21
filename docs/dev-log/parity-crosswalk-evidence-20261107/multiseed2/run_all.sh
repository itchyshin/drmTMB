#!/bin/bash
# One process at a time. usage: ./run_all.sh  (from this directory)
export JULIA_NUM_THREADS=2 OPENBLAS_NUM_THREADS=1 DRMJL=/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/ms2-jl DRMTMB_LIB=/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/agree-poisson-q2/lib
for r in gauss_q3 gauss_q4 gamma_same nb2_same nb2_corr gamma_corr gauss_phylo gauss_spatial gauss_lphylo gauss_lspatial gauss_joint nb2_joint nb2_jcross; do
  echo "##### $r julia"; julia --project=/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/ms2-jl/test julia_run2.jl $r 1 10 2>&1
  echo "##### $r R"; Rscript r_run2.R $r 1 10 2>&1
done
echo ALLDONE
