#!/bin/bash
# Make the minimal, source-only archive used by the G12 Rorqual worker.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo 'Usage: create-phylo-temporal-ou-g12-source-archive.sh /absolute/output.tar.gz' >&2
  exit 2
fi
out=$1
root=$(git rev-parse --show-toplevel)
[[ -d "$root" && ! -e "$out" ]] || { echo 'Output exists or repository is unavailable.' >&2; exit 2; }
cd "$root"
tar --exclude='._*' --exclude='*/._*' --exclude='*.o' --exclude='*.so' --exclude='*.dylib' --exclude='*.dll' \
  -czf "$out" DESCRIPTION NAMESPACE R src inst \
  tools/run-phylo-temporal-ou-g12-task.R tools/assess-phylo-temporal-ou-g11.R \
  docs/dev-log/simulation-artifacts/2026-09-10-phylo-temporal-ou-g11-contract/manifest.csv
tar -tzf "$out" | grep -E '(^|/)\._|\.(o|so|dylib|dll)$' && { echo 'Refusing archive with platform artifacts.' >&2; exit 1; } || true
sha256sum "$out"
