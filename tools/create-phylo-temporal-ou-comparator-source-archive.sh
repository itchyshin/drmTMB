#!/bin/bash
# Create the exact committed source bundle for the paired comparator array.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo 'Usage: create-phylo-temporal-ou-comparator-source-archive.sh /absolute/output.tar.gz' >&2
  exit 2
fi
out=$1
root=$(git rev-parse --show-toplevel)
[[ -d "$root" && ! -e "$out" ]] || { echo 'Output exists or repository is unavailable.' >&2; exit 2; }
cd "$root"
git archive --format=tar HEAD -- DESCRIPTION NAMESPACE R src inst \
  tools/run-phylo-temporal-ou-comparator-task.R \
  tools/reverify-phylo-temporal-ou-comparator.R \
  tools/assess-phylo-temporal-ou-g11.R \
  | gzip -n > "$out"
tar -tzf "$out" | grep -E '(^|/)\._|\.(o|so|dylib|dll)$' && { echo 'Refusing archive with platform artifacts.' >&2; exit 1; } || true
sha256sum "$out"
