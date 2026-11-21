#!/bin/bash
S=/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad
cd $S/gapclose
for t in "$@"; do
  s=$(date +%s)
  JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 nice -n 10 julia --project=$S/gj test/$t.jl > $S/w9/log_$t.txt 2>&1
  echo "$t exit=$? secs=$(( $(date +%s)-s ))" >> $S/w9/regress_$1.txt
done
