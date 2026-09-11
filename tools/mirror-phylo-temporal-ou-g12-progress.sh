#!/bin/bash
# Mirror every sealed G12 task archive currently present on Rorqual to Totoro.
# The single-task helper refuses non-identical destination files, so this is
# safe to rerun while an array is still producing additional artifacts.
set -euo pipefail

usage() {
  echo 'Usage: mirror-phylo-temporal-ou-g12-progress.sh --stage-root=/scratch/... --totoro-root=/home/... [--interval=SECONDS] [--once]' >&2
}

stage_root=
totoro_root=
interval=60
once=0
for arg in "$@"; do
  case "$arg" in
    --stage-root=*) stage_root=${arg#*=} ;;
    --totoro-root=*) totoro_root=${arg#*=} ;;
    --interval=*) interval=${arg#*=} ;;
    --once) once=1 ;;
    *) usage; exit 2 ;;
  esac
done

[[ "$stage_root" == /scratch/* && -n "$totoro_root" && "$interval" =~ ^[1-9][0-9]*$ ]] || {
  usage
  exit 2
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
mirror_one="$script_dir/mirror-phylo-temporal-ou-g12-to-totoro.sh"
[[ -x "$mirror_one" ]] || { echo "Missing executable helper: $mirror_one" >&2; exit 2; }

rorqual=(ssh -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@rorqual.alliancecan.ca:22" -o BatchMode=yes snakagaw@rorqual.alliancecan.ca)

mirror_available() {
  local listing label task
  listing=$("${rorqual[@]}" "find '$stage_root/artifacts' -maxdepth 1 -type f -name 'task-[0-9][0-9][0-9][0-9].tar.gz' -printf '%f\\n' 2>/dev/null | sort")
  local count=0
  while IFS= read -r label; do
    [[ -z "$label" ]] && continue
    [[ "$label" =~ ^task-([0-9]{4})\.tar\.gz$ ]] || { echo "Unexpected artifact name: $label" >&2; exit 1; }
    task=$((10#${BASH_REMATCH[1]}))
    (( task >= 1 && task <= 3500 )) || { echo "Task outside frozen denominator: $label" >&2; exit 1; }
    "$mirror_one" --stage-root="$stage_root" --totoro-root="$totoro_root" --task="$task" </dev/null
    count=$((count + 1))
  done <<< "$listing"
  printf 'PHYLO_TEMPORAL_OU_G12_PROGRESS_MIRROR_PASS available=%s\n' "$count"
}

while :; do
  mirror_available
  (( once == 1 )) && break
  sleep "$interval"
done
