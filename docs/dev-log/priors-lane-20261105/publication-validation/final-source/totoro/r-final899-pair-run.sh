#!/usr/bin/env bash
set -u
base=/home/snakagaw/hsq_work/drm-priors-20261105-01a1ad0b
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=4
export R_LIBS_USER="$base/r-final899-lib:/home/snakagaw/R/lib"
cd "$base/r-final899-clean-src"
printf "R=8998056d75b9e1fe9d66264cb4ae35e025535e21 Julia=727ac08590749aef2165337e1e6391b0894f6d6c\nenv LD_PRELOAD=/home/snakagaw/hsq_work/julia-1.10.10/lib/julia/libunwind.so.8.0.1 Rscript r-final899-live-pair.R\npython3 r-final899-pair-verifier.py\n" > "$base/evidence/r-final899-pair-commands.txt"
timeout --kill-after=30s 600 env LD_PRELOAD=/home/snakagaw/hsq_work/julia-1.10.10/lib/julia/libunwind.so.8.0.1 Rscript "$base/r-final899-live-pair.R" > "$base/evidence/r-final899-live-pair.log" 2>&1
s=$?; printf "%s\n" "$s" > "$base/evidence/r-final899-live-pair.exit"
if [ "$s" -eq 0 ]; then
 python3 "$base/r-final899-pair-verifier.py" > "$base/evidence/r-final899-pair-verifier.log" 2>&1
 printf "%s\n" "$?" > "$base/evidence/r-final899-pair-verifier.exit"
fi
