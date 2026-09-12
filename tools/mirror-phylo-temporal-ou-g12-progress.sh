#!/bin/bash
# Mirror sealed G12 task archives in verified batches. A source/destination
# manifest decides which files are absent; each batch is transferred in one tar
# stream and checked on Totoro before its files become visible in artifacts/.
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: mirror-phylo-temporal-ou-g12-progress.sh --stage-root=/scratch/... --totoro-root=/home/... [--batch-size=N] [--interval=SECONDS] [--once] [--dry-run]
USAGE
}

stage_root=
totoro_root=
batch_size=250
interval=60
once=0
dry_run=0
for arg in "$@"; do
  case "$arg" in
    --stage-root=*) stage_root=${arg#*=} ;;
    --totoro-root=*) totoro_root=${arg#*=} ;;
    --batch-size=*) batch_size=${arg#*=} ;;
    --interval=*) interval=${arg#*=} ;;
    --once) once=1 ;;
    --dry-run) dry_run=1 ;;
    *) usage; exit 2 ;;
  esac
done

[[ "$stage_root" == /scratch/* && "$totoro_root" == /home/* && "$batch_size" =~ ^[1-9][0-9]*$ && "$interval" =~ ^[1-9][0-9]*$ ]] || {
  usage
  exit 2
}

rorqual=(ssh -n -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@rorqual.alliancecan.ca:22" -o BatchMode=yes snakagaw@rorqual.alliancecan.ca)
totoro_query=(ssh -n -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22" -o BatchMode=yes snakagaw@totoro.biology.ualberta.ca)
totoro_stream=(ssh -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22" -o BatchMode=yes snakagaw@totoro.biology.ualberta.ca)
work_dir=$(mktemp -d "${TMPDIR:-/private/tmp}/g12-bulk-mirror.XXXXXX")
cleanup() { rm -rf "$work_dir"; }
trap cleanup EXIT

manifest_command() {
  local directory=$1
  printf "cd '%s' && find . -maxdepth 1 -type f -name 'task-[0-9][0-9][0-9][0-9].tar.gz' -printf '%%f\\n' | LC_ALL=C sort | xargs -r sha256sum" "$directory"
}

validate_manifest() {
  local manifest=$1
  awk '
    NF != 2 { exit 1 }
    $1 !~ /^[0-9a-f]{64}$/ { exit 1 }
    $2 !~ /^task-[0-9]{4}\.tar\.gz$/ { exit 1 }
  ' "$manifest" || { echo "Malformed manifest: $manifest" >&2; exit 1; }
}

mirror_once() {
  local source_manifest="$work_dir/source.manifest"
  local destination_manifest="$work_dir/destination.manifest"
  local status="$work_dir/status"
  local missing="$work_dir/missing"

  "${rorqual[@]}" "$(manifest_command "$stage_root/artifacts")" > "$source_manifest"
  "${totoro_query[@]}" "mkdir -p '$totoro_root/artifacts'; $(manifest_command "$totoro_root/artifacts")" > "$destination_manifest"
  validate_manifest "$source_manifest"
  validate_manifest "$destination_manifest"

  awk '
    NR == FNR { source[$2] = $1; next }
    { destination[$2] = $1 }
    END {
      for (name in source) {
        if (name in destination && source[name] != destination[name]) {
          print "MISMATCH " name
        } else if (!(name in destination)) {
          print "MISSING " name
        }
      }
    }
  ' "$source_manifest" "$destination_manifest" | LC_ALL=C sort > "$status"
  if grep -q '^MISMATCH ' "$status"; then
    cat "$status" >&2
    echo 'Refuse to replace a non-identical Totoro artifact.' >&2
    exit 1
  fi
  sed -n 's/^MISSING //p' "$status" > "$missing"

  local source_count missing_count
  source_count=$(wc -l < "$source_manifest" | tr -d ' ')
  missing_count=$(wc -l < "$missing" | tr -d ' ')
  if (( missing_count == 0 )); then
    printf 'PHYLO_TEMPORAL_OU_G12_PROGRESS_MIRROR_PASS available=%s copied=0\n' "$source_count"
    return
  fi
  if (( dry_run )); then
    printf 'PHYLO_TEMPORAL_OU_G12_PROGRESS_MIRROR_PLAN available=%s missing=%s batch_size=%s\n' "$source_count" "$missing_count" "$batch_size"
    return
  fi

  local prefix="$work_dir/batch-"
  split -l "$batch_size" "$missing" "$prefix"
  local batch list batch_manifest batch_id remote_list remote_manifest remote_payload remote_stage destination_stage
  for list in "${prefix}"*; do
    [[ -f "$list" ]] || continue
    batch=$(basename "$list")
    batch_id="${batch}-$RANDOM"
    batch_manifest="$work_dir/$batch.manifest"
    awk 'NR == FNR { wanted[$1] = 1; next } ($2 in wanted) { print }' "$list" "$source_manifest" > "$batch_manifest"
    [[ $(wc -l < "$list" | tr -d ' ') == $(wc -l < "$batch_manifest" | tr -d ' ') ]] || {
      echo "Batch manifest is incomplete: $batch" >&2
      exit 1
    }

    remote_list="$stage_root/metadata/.g12-mirror-$batch_id.list"
    remote_manifest="$stage_root/metadata/.g12-mirror-$batch_id.manifest"
    remote_payload="$stage_root/metadata/.g12-mirror-$batch_id.tar.gz"
    destination_stage="$totoro_root/.mirror-staging/$batch_id"
    scp -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@rorqual.alliancecan.ca:22" -o BatchMode=yes "$list" "snakagaw@rorqual.alliancecan.ca:$remote_list"
    scp -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@rorqual.alliancecan.ca:22" -o BatchMode=yes "$batch_manifest" "snakagaw@rorqual.alliancecan.ca:$remote_manifest"
    "${rorqual[@]}" "set -e; while IFS= read -r f; do [[ \"\$f\" =~ ^task-[0-9]{4}\\.tar\\.gz$ ]] && test -f '$stage_root/artifacts/'\"\$f\" || exit 1; done < '$remote_list'; tar -C '$stage_root/metadata' -czf '$remote_payload' '$(basename "$remote_manifest")' -C '$stage_root/artifacts' -T '$remote_list'; sha256sum '$remote_payload' >/dev/null"
    "${rorqual[@]}" "cat '$remote_payload'" | "${totoro_stream[@]}" "set -e; rm -rf '$destination_stage'; mkdir -p '$destination_stage'; tar -xzf - -C '$destination_stage'"
    "${totoro_query[@]}" "set -e; stage='$destination_stage'; root='$totoro_root/artifacts'; manifest=\"\$stage/$(basename "$remote_manifest")\"; cd \"\$stage\"; sha256sum -c \"\$manifest\" >/dev/null; while read -r hash name; do [[ \"\$name\" =~ ^task-[0-9]{4}\\.tar\\.gz$ ]] || exit 1; if test -e \"\$root/\$name\"; then test \"\$(sha256sum \"\$root/\$name\" | awk '{print \$1}')\" = \"\$hash\" || exit 1; rm -f \"\$stage/\$name\"; else mv \"\$stage/\$name\" \"\$root/\$name\"; fi; done < \"\$manifest\"; rm -rf \"\$stage\""
    "${rorqual[@]}" "rm -f '$remote_list' '$remote_manifest' '$remote_payload'"
    printf 'PHYLO_TEMPORAL_OU_G12_BULK_MIRROR_BATCH_PASS %s count=%s\n' "$batch" "$(wc -l < "$list" | tr -d ' ')"
  done

  "${totoro_query[@]}" "$(manifest_command "$totoro_root/artifacts")" > "$destination_manifest"
  validate_manifest "$destination_manifest"
  awk 'NR == FNR { source[$2] = $1; next } { destination[$2] = $1 } END { for (name in source) if (!(name in destination) || source[name] != destination[name]) exit 1 }' "$source_manifest" "$destination_manifest" || {
    echo 'Totoro manifest does not match the Rorqual source manifest.' >&2
    exit 1
  }
  printf 'PHYLO_TEMPORAL_OU_G12_PROGRESS_MIRROR_PASS available=%s copied=%s\n' "$source_count" "$missing_count"
}

while :; do
  mirror_once
  (( once == 1 )) && break
  sleep "$interval"
done
