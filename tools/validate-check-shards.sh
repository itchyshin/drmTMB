#!/usr/bin/env bash
set -euo pipefail
: "${RUNNER_TEMP:?}" "${RUN_ID:?}" "${RUN_ATTEMPT:?}"
dir="$RUNNER_TEMP/r-check-proofs"
for shard in 1 2 3 4 5 6 7 8; do
  proof="$dir/r-check-proof-$RUN_ID-$RUN_ATTEMPT-$shard/proof.txt"
  test -f "$proof"
  test "$(cat "$proof")" = "$RUN_ID:$RUN_ATTEMPT:$shard"
done
test "$(find "$dir" -type f -name proof.txt | wc -l)" -eq 8
