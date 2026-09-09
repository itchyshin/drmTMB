#!/bin/bash
# Copy one immutable Fir temporal-OU campaign file to Totoro through existing
# ControlMaster sockets. This deliberately never removes the Fir source.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  tools/mirror-temporal-ou-shard-to-totoro.sh \
    --fir-root=/home/.../campaign --totoro-root=/home/.../campaign \
    [--source-archive | --shard=001]

Transfers exactly one immutable source archive or sealed shard, then compares
SHA-256 values at Fir and Totoro. It refuses to overwrite a non-identical
Totoro file and never removes the verified Fir copy.
EOF
}

fir_root=
totoro_root=
kind=
for argument in "$@"; do
  case "$argument" in
    --fir-root=*) fir_root=${argument#--fir-root=} ;;
    --totoro-root=*) totoro_root=${argument#--totoro-root=} ;;
    --source-archive) kind=source.tar.gz ;;
    --shard=[0-9][0-9][0-9]) kind=shard-${argument#--shard=}.tar.gz ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

if [ -z "$fir_root" ] || [ -z "$totoro_root" ] || [ -z "$kind" ]; then
  usage >&2
  exit 2
fi

fir_host=snakagaw@fir.alliancecan.ca
totoro_host=snakagaw@totoro.biology.ualberta.ca
fir_socket="$HOME/.ssh/cm-snakagaw@fir.alliancecan.ca:22"
totoro_socket="$HOME/.ssh/cm-snakagaw@totoro.biology.ualberta.ca:22"
fir_file="$fir_root/$kind"
totoro_file="$totoro_root/$kind"

ssh_fir=(ssh -o ControlMaster=no -o ControlPath="$fir_socket" -o BatchMode=yes "$fir_host")
ssh_totoro=(ssh -o ControlMaster=no -o ControlPath="$totoro_socket" -o BatchMode=yes "$totoro_host")

source_hash=$("${ssh_fir[@]}" "sha256sum '$fir_file'" | awk '{print $1}')
if ! [[ "$source_hash" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Fir source is absent or has no valid SHA-256: $fir_file" >&2
  exit 1
fi

destination_hash=$("${ssh_totoro[@]}" "if [ -e '$totoro_file' ]; then sha256sum '$totoro_file'; fi" | awk '{print $1}')
if [ -n "$destination_hash" ]; then
  if [ "$destination_hash" != "$source_hash" ]; then
    echo "Refuse to overwrite non-identical Totoro file: $totoro_file" >&2
    exit 1
  fi
  printf 'TEMPORAL_OU_TOTORO_MIRROR_ALREADY_VERIFIED %s %s\n' "$kind" "$source_hash"
  exit 0
fi

"${ssh_fir[@]}" "cat '$fir_file'" | \
  "${ssh_totoro[@]}" "mkdir -p '$totoro_root'; cat > '$totoro_file.partial' && mv '$totoro_file.partial' '$totoro_file'"

destination_hash=$("${ssh_totoro[@]}" "sha256sum '$totoro_file'" | awk '{print $1}')
if [ "$destination_hash" != "$source_hash" ]; then
  echo "Totoro checksum mismatch for $kind" >&2
  exit 1
fi
printf 'TEMPORAL_OU_TOTORO_MIRROR_VERIFIED %s %s\n' "$kind" "$source_hash"
