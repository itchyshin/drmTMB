#!/usr/bin/env bash
# Exercise the campaign source-proof verifier against an actual Git bundle.
set -euo pipefail

readonly here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly verifier="${here}/verify-source-commit.sh"
readonly tmp="$(mktemp -d "${TMPDIR:-/tmp}/071-source-proof.XXXXXX")"
trap 'rm -rf "${tmp}"' EXIT

git init -q "${tmp}/repo"
git -C "${tmp}/repo" config user.email test@example.invalid
git -C "${tmp}/repo" config user.name '071 source-proof test'
printf 'base\n' > "${tmp}/repo/input.txt"
git -C "${tmp}/repo" add input.txt
git -C "${tmp}/repo" commit -qm base
printf 'candidate\n' > "${tmp}/repo/input.txt"
git -C "${tmp}/repo" add input.txt
git -C "${tmp}/repo" commit -qm candidate
readonly commit="$(git -C "${tmp}/repo" rev-parse HEAD)"
git -C "${tmp}/repo" branch -f source-proof "${commit}"
git -C "${tmp}/repo" bundle create "${tmp}/source.bundle" source-proof
git -C "${tmp}/repo" archive --format=tar.gz --output="${tmp}/source.tar.gz" "${commit}"

"${verifier}" fixture "${commit}" "${tmp}/source.bundle" "${tmp}/source.tar.gz" > "${tmp}/pass.txt"
grep -Fx "SOURCE_COMMIT_PROOF_PASS label=fixture commit=${commit}" "${tmp}/pass.txt"

mkdir "${tmp}/tampered"
printf 'tampered\n' > "${tmp}/tampered/input.txt"
tar -czf "${tmp}/tampered.tar.gz" -C "${tmp}/tampered" .
if "${verifier}" fixture "${commit}" "${tmp}/source.bundle" "${tmp}/tampered.tar.gz" > /dev/null 2>&1; then
  printf '%s\n' 'source proof accepted an archive that is not the declared commit tree' >&2
  exit 1
fi

git init -q "${tmp}/foreign"
git -C "${tmp}/foreign" config user.email test@example.invalid
git -C "${tmp}/foreign" config user.name '071 source-proof test'
printf 'foreign\n' > "${tmp}/foreign/input.txt"
git -C "${tmp}/foreign" add input.txt
git -C "${tmp}/foreign" commit -qm foreign
git -C "${tmp}/foreign" branch -f source-proof HEAD
git -C "${tmp}/foreign" bundle create "${tmp}/foreign.bundle" source-proof
if "${verifier}" fixture "${commit}" "${tmp}/foreign.bundle" "${tmp}/source.tar.gz" > /dev/null 2>&1; then
  printf '%s\n' 'source proof accepted a bundle that lacks the declared commit' >&2
  exit 1
fi

printf '%s\n' 'SOURCE_COMMIT_PROOF_TEST_PASS'
