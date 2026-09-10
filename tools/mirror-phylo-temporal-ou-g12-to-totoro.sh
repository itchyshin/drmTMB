#!/bin/bash
# Copy one sealed G12 artifact from Rorqual /scratch to Totoro and prove equal SHA-256.
set -euo pipefail
usage() { echo 'Usage: mirror-phylo-temporal-ou-g12-to-totoro.sh --stage-root=/scratch/... --totoro-root=/home/... --task=1..3500' >&2; }
stage_root= totoro_root= task=
for arg in "$@"; do
  case "$arg" in
    --stage-root=*) stage_root=${arg#*=} ;;
    --totoro-root=*) totoro_root=${arg#*=} ;;
    --task=*) task=${arg#*=} ;;
    *) usage; exit 2 ;;
  esac
done
[[ "$stage_root" == /scratch/* && -n "$totoro_root" && "$task" =~ ^[0-9]+$ && "$task" -ge 1 && "$task" -le 3500 ]] || { usage; exit 2; }
label=$(printf 'task-%04d' "$task")
source_file="$stage_root/artifacts/$label.tar.gz"
destination="$totoro_root/artifacts/$label.tar.gz"
rorqual=(ssh -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@rorqual.alliancecan.ca:22" -o BatchMode=yes snakagaw@rorqual.alliancecan.ca)
totoro=(ssh -o ControlMaster=no -o ControlPath="$HOME/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22" -o BatchMode=yes snakagaw@totoro.biology.ualberta.ca)
source_sha=$("${rorqual[@]}" "sha256sum '$source_file'" | awk '{print $1}')
[[ "$source_sha" =~ ^[0-9a-f]{64}$ ]] || { echo 'Source artifact missing or checksum invalid.' >&2; exit 1; }
destination_sha=$("${totoro[@]}" "test -f '$destination' && sha256sum '$destination' || true" | awk '{print $1}')
if [[ -n "$destination_sha" ]]; then
  [[ "$destination_sha" == "$source_sha" ]] || { echo 'Refuse to replace non-identical Totoro artifact.' >&2; exit 1; }
  printf 'PHYLO_TEMPORAL_OU_G12_MIRROR_ALREADY_VERIFIED %s %s\n' "$label" "$source_sha"
  exit 0
fi
"${rorqual[@]}" "cat '$source_file'" | "${totoro[@]}" "mkdir -p '$totoro_root/artifacts'; cat > '$destination.partial' && mv '$destination.partial' '$destination'"
destination_sha=$("${totoro[@]}" "sha256sum '$destination'" | awk '{print $1}')
[[ "$destination_sha" == "$source_sha" ]] || { echo 'Totoro checksum mismatch.' >&2; exit 1; }
printf 'PHYLO_TEMPORAL_OU_G12_MIRROR_VERIFIED %s %s\n' "$label" "$source_sha"
