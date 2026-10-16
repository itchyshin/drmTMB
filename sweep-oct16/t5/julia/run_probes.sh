#!/usr/bin/env bash
# sweep-oct16 / t5 -- run probe_union.jl one cell per process under a timeout.
# Usage: run_probes.sh <datadir> <outfile> [timeout_seconds]
set -u
datadir=$1; out=$2; tmo=${3:-300}
here=$(cd "$(dirname "$0")" && pwd)
echo "id,mode,status,errtype,errmsg,secs,loglik,nobs,ncoef_mu,b_mu1,log_sd_g,converged,n_groups_seen" > "$out"
for fam in gaussian poisson gamma; do
  for spec in "y00_x00 cc_union" "y00_x00 cc_concrete" "y00_x00 listwise_union" \
              "y00_x00 g_missing" "y00_x00 g_dropped" "y20_x20 cc_union" "y20_x20 cc_concrete"; do
    set -- $spec; id="${fam}_$1"; mode=$2
    line=$(timeout "$tmo" julia --project="${DRMODELS_JL_PATH}" "$here/probe_union.jl" "$datadir" "$id" "$mode" 2>/dev/null | tail -1)
    rc=$?
    if [ -z "$line" ]; then line="$id,$mode,timeout_or_crash,,exit=$rc after ${tmo}s limit,,,,,,,,"; fi
    echo "$line" | tee -a "$out"
  done
done
