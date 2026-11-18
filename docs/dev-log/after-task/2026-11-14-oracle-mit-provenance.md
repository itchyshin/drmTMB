# Two-intercept oracle MIT provenance

## Goal

Make the independent oracle and its license trace available to reviewers of the prior-table change.

## Changes and checks

The two-intercept fixture directory now includes the generators, frozen-input manifests, verifier scripts, provenance and MIT notice. Existing JSON values are unchanged. Both manifest checks and both numerical verifier scripts passed; the replacement converter reproduced the Julia fixture byte for byte. See the matching check-log shard for counts and hashes.

## Consistency and tests of checks

The notices identify the same source and fixture hashes as the independent oracle review. The original generators and verifiers remain byte-identical to their manifests. A final independent provenance review is required before merging.

## Documentation and tracker

The fixture-local provenance explains reproduction and licensing. No public API, formula grammar, pkgdown navigation or issue state changed.

## Limitations and next actions

The original Julia converter and original SciPy version remain unrecorded. Parent-source full checks do not attest this added fixture directory; run checks on the new commit. No merge or release was performed as part of this report.
