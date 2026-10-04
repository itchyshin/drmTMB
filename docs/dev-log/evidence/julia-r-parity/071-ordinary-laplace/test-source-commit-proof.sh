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
printf 'Package: fixture\n' > "${tmp}/repo/DESCRIPTION"
printf 'export(fixture)\n' > "${tmp}/repo/NAMESPACE"
mkdir -p "${tmp}/repo/R" "${tmp}/repo/src"
printf 'fixture <- function() 1\n' > "${tmp}/repo/R/fixture.R"
printf 'int fixture(void) { return 1; }\n' > "${tmp}/repo/src/fixture.c"
git -C "${tmp}/repo" add input.txt DESCRIPTION NAMESPACE R src
git -C "${tmp}/repo" commit -qm candidate
readonly commit="$(git -C "${tmp}/repo" rev-parse HEAD)"
git -C "${tmp}/repo" branch -f source-proof "${commit}"
git -C "${tmp}/repo" bundle create "${tmp}/source.bundle" source-proof
git -C "${tmp}/repo" archive --format=tar.gz --output="${tmp}/source.tar.gz" "${commit}"

"${verifier}" fixture "${commit}" "${tmp}/source.bundle" "${tmp}/source.tar.gz" > "${tmp}/pass.txt"
grep -Fx "SOURCE_COMMIT_PROOF_PASS label=fixture commit=${commit}" "${tmp}/pass.txt"

# Retained campaign archives are intentionally source subsets rather than full
# Git archives.  Every staged file must still be the declared commit's blob,
# and the required execution roots must all be present.
git -C "${tmp}/repo" archive --format=tar.gz --output="${tmp}/subset.tar.gz" "${commit}" DESCRIPTION NAMESPACE R src
"${verifier}" fixture-subset "${commit}" "${tmp}/source.bundle" "${tmp}/subset.tar.gz" "DESCRIPTION,NAMESPACE,R,src" > "${tmp}/subset-pass.txt"
grep -Fx "SOURCE_COMMIT_SUBSET_PROOF_PASS label=fixture-subset commit=${commit}" "${tmp}/subset-pass.txt"

# GNU tar exposes the retained Nibi payload without its harmless wrapper
# component, so the same declared prefix must also accept this representation.
"${verifier}" fixture-subset-unwrapped "${commit}" "${tmp}/source.bundle" "${tmp}/subset.tar.gz" "DESCRIPTION,NAMESPACE,R,src" drmTMB/ > "${tmp}/subset-unwrapped-pass.txt"
grep -Fx "SOURCE_COMMIT_SUBSET_PROOF_PASS label=fixture-subset-unwrapped commit=${commit}" "${tmp}/subset-unwrapped-pass.txt"

# The retained drmTMB payload has a single archive wrapper, which must be
# stripped before paths are compared to the pinned commit.
mkdir -p "${tmp}/wrapped/drmTMB"
cp "${tmp}/repo/DESCRIPTION" "${tmp}/wrapped/drmTMB/DESCRIPTION"
cp "${tmp}/repo/NAMESPACE" "${tmp}/wrapped/drmTMB/NAMESPACE"
cp -R "${tmp}/repo/R" "${tmp}/repo/src" "${tmp}/wrapped/drmTMB/"
tar -czf "${tmp}/subset-wrapped.tar.gz" -C "${tmp}/wrapped" drmTMB
"${verifier}" fixture-subset-wrapped "${commit}" "${tmp}/source.bundle" "${tmp}/subset-wrapped.tar.gz" "DESCRIPTION,NAMESPACE,R,src" drmTMB/ > "${tmp}/subset-wrapped-pass.txt"
grep -Fx "SOURCE_COMMIT_SUBSET_PROOF_PASS label=fixture-subset-wrapped commit=${commit}" "${tmp}/subset-wrapped-pass.txt"

mkdir -p "${tmp}/subset-tampered/R" "${tmp}/subset-tampered/src"
printf 'Package: tampered\n' > "${tmp}/subset-tampered/DESCRIPTION"
cp "${tmp}/repo/NAMESPACE" "${tmp}/subset-tampered/NAMESPACE"
cp "${tmp}/repo/R/fixture.R" "${tmp}/subset-tampered/R/fixture.R"
cp "${tmp}/repo/src/fixture.c" "${tmp}/subset-tampered/src/fixture.c"
tar -czf "${tmp}/subset-tampered.tar.gz" -C "${tmp}/subset-tampered" DESCRIPTION NAMESPACE R src
if "${verifier}" fixture-subset "${commit}" "${tmp}/source.bundle" "${tmp}/subset-tampered.tar.gz" "DESCRIPTION,NAMESPACE,R,src" > /dev/null 2>&1; then
  printf '%s\n' 'source subset proof accepted a tampered staged file' >&2
  exit 1
fi

tar -czf "${tmp}/subset-missing-required.tar.gz" -C "${tmp}/repo" DESCRIPTION NAMESPACE R
if "${verifier}" fixture-subset "${commit}" "${tmp}/source.bundle" "${tmp}/subset-missing-required.tar.gz" "DESCRIPTION,NAMESPACE,R,src" > /dev/null 2>&1; then
  printf '%s\n' 'source subset proof accepted a missing required root' >&2
  exit 1
fi

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
