# ⚠ READ FIRST — everything in this directory is PREDECESSOR evidence

**Written:** 2026-08-09 · **By:** Claude task 1, staged 0.7.0 candidate preparation, Stage A
**Applies to:** every file in `docs/dev-log/release/0.7.0-cran-gate/`, including `platform/`

## The one-sentence warning

Every result in this directory is a **truthful proof about an artifact that is no
longer current `main`**, and the fail-closed gate **still returns green** for it — so a
reader can pick up a valid receipt and mistake it for the 0.7.0 candidate.

## Why this note exists

Nothing here is corrupt, wrong, or discredited. That is precisely the hazard. Under
[[DECISIONS#D-49|D-49]], a result belongs to the exact artifact hash it was measured
on. These results belong to **two hashes, neither of which is current `main`**, and
there is currently **no 0.7.0 candidate tarball at all**.

## The three identities

| Identity | SHA-256 | Bytes | Source commit | What it actually proves |
| --- | --- | --- | --- | --- |
| `tarball-clean` freeze | `2e5234bd…c5ea` | 9,831,204 | `ad475cc39` | local `R CMD check --as-cran --run-donttest` → 1 NOTE (New submission) |
| win-builder "fixed" | `f9b9588e…8065` | 9,818,425 | repair on `13e8cafb0` | win-builder R-release + R-devel → 1 NOTE, 0 ERROR |
| **current `main` `ac363cadb`** | **none** | — | — | **nothing — no tarball has ever been built from it** |

## The drift, measured

`git diff --name-only ad475cc39 ac363cadb` over build-included paths = **15 files**
(66 across all paths): `R/drmTMB.R`, `R/julia-bridge.R`, `man/drmTMB.Rd`, seven
vignettes, both generated capability includes, two test files, `NEWS.md`, `README.md`.

These are the #952 / #953 / #954 capability-truth landings. They change installed
bytes. Therefore **every artifact-bound result in this directory is superseded as
current evidence**, while remaining valid history.

## The trap, demonstrated

```
$ python3 ~/shinichi-brain/tools/cran_release_gate.py \
    docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json
READY FOR CLAIMED RUNG          (exit 0)
```

The checker is healthy — its 14 planted negative controls all fail closed, including
`predecessor-hash`. It validates *artifact against claim*, and that pairing is sound.
It simply has **no control for "was this artifact built from current `main`?"**

Compounding it: the predecessor tarball is **still on disk** at
`/private/tmp/drmTMB-07-reader-boundaries-tarball/drmTMB_0.6.0.tar.gz`, and its hash
and size still match the recorded values exactly (re-verified 2026-08-09). A green
ledger plus a present, hash-matching tarball is very easy to mistake for a current
candidate.

## What you may and may not do with this directory

**May:** reuse the *instruments* — the ledger JSON schema, the inventory format,
`FREEZE-NOTES.md` structure, the check-log layout, the platform matrix table. They are
good and this arc reuses them. Cite these results as **history**, clearly labelled as
predecessor evidence.

**May not:** copy a ledger and change only its SHA · cite `tarball-clean` as the state
of current `main` · treat the win-builder 1-NOTE result as covering the 0.7.0
candidate · advance `status_claim` to `platform-clean` (still requires Shinichi's
explicit authorization, unchanged) · reuse the incoming NOTE list as *proof* rather
than as a *prediction to re-verify*.

## Current state, stated plainly

- Release verdict: **NOT READY**
- `DESCRIPTION`: **`0.6.0`** (D-86 puts the bump inside the release slice)
- Highest rung proven for current `main`: **none**
- Highest rung proven anywhere: **`tarball-clean`**, for predecessor `ad475cc39`
- Blocking gate: the complete/quasi-complete separation lane must reach a reviewed
  finite disposition (MERGE / DEFER / DEFECT) before any candidate freeze

## Where the current arc lives

- Orientation: `docs/dev-log/release-audits/2026-08-09-07-gate-orientation.md`
- Instrument reuse map: `…/2026-08-09-07-instrument-salvage.md`
- Current product contract: `…/2026-08-09-07-product-contract.md`
  (supersedes the 2026-08-07 one, whose census predates #953)
- Rights ledger: `…/2026-08-09-07-rights-ledger.md`
- Stage-B prepared fixes: `…/2026-08-09-07-stage-b-byte-fixes.md`
- Current ledger: `…/2026-08-09-07-cran-release-ledger.json` — deliberately claims
  **no artifact rung**

## Suggested gate improvement (flagged, not implemented)

Add an optional `source_commit_is_current` control to
`~/shinichi-brain/tools/cran_release_gate.py` that fails closed when the ledger's
`source_commit` is not equal to the named release branch tip. A `git merge-base
--is-ancestor` plus a tip comparison would have turned today's green into a red.
Owner's call; it belongs to the brain's tooling, not this repository.
