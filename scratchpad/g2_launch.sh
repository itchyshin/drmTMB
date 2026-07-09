set -e
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
OUT=docs/dev-log/simulation-artifacts/2026-07-08-g2-sigma-oneslope-adjudication
run_shard() {
  OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
    Rscript --no-init-file tools/run-structured-re-sigma-slope-coverage-grid.R \
      --shard=$1 --n_rep=600 --n_each=20 --seed_start=800000 --out_dir="$OUT" \
      > "$OUT/shard-$1.log" 2>&1 && echo "shard $1 done" || echo "shard $1 FAILED (see log)"
}
export -f run_shard; export OUT
printf '1\n2\n5\n6\n7\n' | xargs -P 5 -I{} bash -c 'run_shard {}'
echo "ALL SHARDS COMPLETE"
ls -1 "$OUT"/*-replicates.tsv 2>/dev/null | wc -l | xargs echo "replicate files:"
