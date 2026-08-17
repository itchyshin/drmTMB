#!/usr/bin/env bash
# mc-0717 Totoro 27-fit smoke launcher.
# Brief: docs/dev-log/research/2026-08-16-mc0717-totoro-smoke-brief.md
# Core guard copied from the brief / D-143. Do not re-derive nproc.

set -euo pipefail

readonly TOTORO_CORE_CAP=150
NWORKERS=${NWORKERS:-8}
(( NWORKERS <= 16 && NWORKERS <= TOTORO_CORE_CAP && NWORKERS <= $(nproc) - 4 )) || {
  echo "NWORKERS=$NWORKERS fails the brief guard (cap 16 / D-143 150 / nproc-4)." >&2
  exit 2
}

REPO="${DRMTMB_REPO:-$HOME/hsq_work/drmTMB-mc0717}"
LIB="${DRMTMB_LIB:-$HOME/hsq_work/drmTMB-mc0717-library}"
OUT="${DRMTMB_OUT:-$REPO/docs/dev-log/simulation-artifacts/2026-08-16-mc0717-totoro-smoke}"
RUNNER="${DRMTMB_RUNNER:-$OUT/run-mc0717-smoke.R}"
RSCRIPT="${RSCRIPT:-Rscript}"

export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export R_PROFILE_USER=/dev/null
export DRMTMB_REPO="$REPO"
export DRMTMB_LIB="$LIB"

mkdir -p "$OUT/rows" "$OUT/logs"

cd "$REPO"
GIT_SHA="$(git rev-parse HEAD)"
export DRMTMB_GIT_SHA="$GIT_SHA"
echo "$GIT_SHA" > "$OUT/git-sha.txt"
git log -1 --oneline > "$OUT/git-log.txt"
hostname > "$OUT/host-provenance.txt"
{
  echo "date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "hostname=$(hostname)"
  echo "nproc=$(nproc)"
  echo "nworkers=$NWORKERS"
  echo "core_cap=16"
  echo "totoro_core_cap=$TOTORO_CORE_CAP"
  echo "git_sha=$GIT_SHA"
  echo "repo=$REPO"
  echo "lib=$LIB"
  echo "loadavg=$(cat /proc/loadavg)"
} >> "$OUT/host-provenance.txt"

echo "[mc0717] HEAD=$GIT_SHA workers=$NWORKERS out=$OUT"

run_one() {
  local mode="$1"
  local out="$2"
  shift 2
  "$RSCRIPT" --no-init-file "$RUNNER" \
    --mode "$mode" \
    --repo "$REPO" \
    --lib "$LIB" \
    --out "$out" \
    --git_sha "$GIT_SHA" \
    "$@"
}

echo "[mc0717] 1-fit toy"
run_one toy "$OUT/toy.tsv"
if ! awk 'NR==2 {exit !($7 != "" && $7 != "NA")}' "$OUT/toy.tsv"; then
  echo "TOY FAIL: empty/NA extractors. Aborting 27-fit smoke." >&2
  exit 3
fi

echo "[mc0717] rejection matrix"
run_one reject "$OUT/rejection.tsv"

JOBFILE="$OUT/joblist.txt"
{
  printf '%s\t%s\t%s\n' 4 871401 drmtmb_corr
  printf '%s\t%s\t%s\n' 4 871401 drmtmb_iid
  printf '%s\t%s\t%s\n' 4 871401 glmmtmb_corr
  printf '%s\t%s\t%s\n' 4 871402 drmtmb_corr
  printf '%s\t%s\t%s\n' 4 871402 drmtmb_iid
  printf '%s\t%s\t%s\n' 4 871402 glmmtmb_corr
  printf '%s\t%s\t%s\n' 4 871403 drmtmb_corr
  printf '%s\t%s\t%s\n' 4 871403 drmtmb_iid
  printf '%s\t%s\t%s\n' 4 871403 glmmtmb_corr
  printf '%s\t%s\t%s\n' 8 871801 drmtmb_corr
  printf '%s\t%s\t%s\n' 8 871801 drmtmb_iid
  printf '%s\t%s\t%s\n' 8 871801 glmmtmb_corr
  printf '%s\t%s\t%s\n' 8 871802 drmtmb_corr
  printf '%s\t%s\t%s\n' 8 871802 drmtmb_iid
  printf '%s\t%s\t%s\n' 8 871802 glmmtmb_corr
  printf '%s\t%s\t%s\n' 8 871803 drmtmb_corr
  printf '%s\t%s\t%s\n' 8 871803 drmtmb_iid
  printf '%s\t%s\t%s\n' 8 871803 glmmtmb_corr
  printf '%s\t%s\t%s\n' 14 871141 drmtmb_corr
  printf '%s\t%s\t%s\n' 14 871141 drmtmb_iid
  printf '%s\t%s\t%s\n' 14 871141 glmmtmb_corr
  printf '%s\t%s\t%s\n' 14 871142 drmtmb_corr
  printf '%s\t%s\t%s\n' 14 871142 drmtmb_iid
  printf '%s\t%s\t%s\n' 14 871142 glmmtmb_corr
  printf '%s\t%s\t%s\n' 14 871143 drmtmb_corr
  printf '%s\t%s\t%s\n' 14 871143 drmtmb_iid
  printf '%s\t%s\t%s\n' 14 871143 glmmtmb_corr
} > "$JOBFILE"

NJOBS=$(wc -l < "$JOBFILE")
if (( NJOBS != 27 )); then
  echo "REFUSED: joblist has $NJOBS rows, expected 27." >&2
  exit 2
fi

echo "[mc0717] launching $NJOBS fits with GNU parallel -j $NWORKERS"
START_EPOCH=$(date +%s)
parallel -j "$NWORKERS" --colsep '\t' --joblog "$OUT/logs/parallel.joblog" \
  "$RSCRIPT" --no-init-file "$RUNNER" \
  --mode fit \
  --repo "$REPO" \
  --lib "$LIB" \
  --git_sha "$GIT_SHA" \
  --n_each {1} \
  --seed {2} \
  --method {3} \
  --out "$OUT/rows/{2}_{1}_{3}.tsv" \
  :::: "$JOBFILE"

END_EPOCH=$(date +%s)
echo "wall_sec=$((END_EPOCH - START_EPOCH))" > "$OUT/wall.txt"
echo "nworkers=$NWORKERS" >> "$OUT/wall.txt"

# Concatenate retained rows. Never drop a missing file from the denominator.
{
  first=1
  while IFS=$'\t' read -r n_each seed method; do
    f="$OUT/rows/${seed}_${n_each}_${method}.tsv"
    if [[ ! -f "$f" ]]; then
      printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$seed" "$n_each" "$method" "" "" "" "" "" "" "" "" "missing_row" "$GIT_SHA" "" "" "" "row file absent"
      continue
    fi
    if (( first )); then
      cat "$f"
      first=0
    else
      tail -n +2 "$f"
    fi
  done < "$JOBFILE"
} > "$OUT/results.tsv"

NROWS=$(($(wc -l < "$OUT/results.tsv") - 1))
echo "[mc0717] wrote $NROWS result rows to $OUT/results.tsv"
if (( NROWS != 27 )); then
  echo "DENOMINATOR FAIL: expected 27 rows, got $NROWS." >&2
  exit 4
fi
echo "[mc0717] DONE"
