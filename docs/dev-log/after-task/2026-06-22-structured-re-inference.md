# After Task: Structured Random-Effect Inference Status

## Goal

Bank the inference tranche for the structured random-effect balance arc without
turning target availability into interval coverage.

## Implemented

Added `docs/design/212-structured-inference-status.md` and linked SR061-SR070
to existing Wald, profile, bootstrap, coverage, and boundary ledgers.

## Mathematical Contract

The contract is target-specific. A direct SD target, a derived q4 correlation,
a profile-ready parameter, a bootstrap refit count, and replicated coverage are
different evidence classes.

## Files Changed

- `docs/design/212-structured-inference-status.md`
- `docs/dev-log/dashboard/structured-re-balance-100-slices.tsv`
- `docs/dev-log/check-log.md`

## Checks Run

Final validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

This was a mission-control/status pass. It reused existing focused test
evidence from the profile-target, bootstrap-accounting, q2/q4 extractor, and
boundary-status ledgers.

## Consistency Audit

Coverage reliability remains blocked. SR064-SR066 were later unblocked only as
labelled pilot-accounting rows by
`docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/`.
No q1, q2, q4, or Ayumi-scale coverage claim was added.

## GitHub Issue Maintenance

No issue comment was posted.

## What Did Not Go Smoothly

The phrase "coverage pilot" is tempting to bank as a tiny smoke. The later
unblock pass solved that by banking only target/failure/MCSE accounting, not
coverage reliability.

## Team Learning

Fisher's rule is now explicit in the tranche: coverage needs replicated
known-truth evidence and MCSE, not just profile or bootstrap machinery.

## Known Limitations

Spatial, animal, and `relmat()` inference rows remain less detailed than the
phylo-specific ledgers.

## Next Actions

Design calibrated q1/q2/q4 coverage grids only after the target identities and
failure taxonomy are fixed.
