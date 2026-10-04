# After Task: S7 source-subset commit reconciliation

## Goal

Repair the local S7 reconciliation guard so it proves retained campaign source
subsets against their declared Git commits, instead of comparing them with a
live checkout that is not part of the retained evidence boundary.

## Implemented

`s7-fir-reconcile.sh` now reads the corrected source pins and archive hashes
from `source-pins-final.tsv`, selects only matching staged bundles and archives,
and invokes `verify-source-commit.sh`.  The verifier supports both an exact
full archive and a required-root source-subset proof.  It rejects unsafe paths,
links and special files, missing required roots, files absent from the commit,
and changed file bytes.  It also handles the harmless `drmTMB/` archive wrapper
used by one tar implementation and its wrapper-free representation on Nibi.

## Evidence Boundary

This is a reconciliation/verifier repair only.  It did not rerun, alter, or
reclassify the campaign; it did not change the source pins, fixtures, manifest,
profile cap, attempted-seed denominators, or coverage summary.  The retained
Nibi receipt `s7-source-commit-proof-21753825.tsv` already records successful
subset proofs for drmTMB `453cff782900aa55211d3f5971c229fc485d291e` and DRM.jl
`b2caf00f23f080fe89028966a4bfb098ef095510`.

## Tests

- `test-source-commit-proof.sh` passed its full-archive positive control,
  source-subset positive control, wrapped and wrapper-free portability controls,
  altered-file rejection, missing-required-root rejection, and foreign-bundle
  rejection.
- `bash -n` passed for the verifier and reconciliation payload.
- `devtools::test(filter = "071-four-fixture-summary")` passed.  Two live
  scoreboard tests were skipped because `DRM_JL_PATH` was intentionally unset.
- `git diff --check` passed.

## Consistency Audit

The reconciliation now has no predecessor archive names and uses the corrected
pin receipt dynamically.  The coverage writer requires both the legacy
compatibility status field and the new source-subset-proof status field before
it accepts archive hashes and source paths.

## What Did Not Change

The generated scoreboard, capability registry, and four-fixture contract were
already modified in this worktree by another lane and were deliberately not
edited here.  Their integration, full-suite evidence, and draft-PR assembly are
separate G8 work.

## Known Limitation

The large retained archive was not rehashed on a Nibi login node.  Its existing
compute-node receipt remains the retained proof; the local verifier was tested
against independent Git fixtures and its required roots were checked read-only
against the retained archive.

## Next Action

Integrate the pre-existing generated-artifact edits with this repair, run the
full bridge closure suite in the owning lane, obtain the required independent
reviews, and prepare the draft PR.  Do not claim a general coverage or release
result.
