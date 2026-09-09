#!/bin/bash
# Create one immutable source archive for the storage-consolidating Fir array.
set -euo pipefail
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <40-character-commit> <destination.tar.gz>" >&2
  exit 2
fi
commit=$1
out=$2
case "$commit" in
  [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]) ;;
  *) echo "Commit must be a 40-character lowercase Git SHA." >&2; exit 2 ;;
esac
[ -e "$out" ] && { echo "Refuse to overwrite immutable source archive: $out" >&2; exit 2; }
git cat-file -e "${commit}^{commit}"
tmp="${out}.partial-$$"
trap 'rm -f "$tmp"' EXIT
git archive --format=tar "$commit" | gzip -n > "$tmp"
mv "$tmp" "$out"
trap - EXIT
