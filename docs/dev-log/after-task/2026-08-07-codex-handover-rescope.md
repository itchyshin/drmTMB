# After Task: Codex handover + 0.7 rescope (pre-19 Aug)

## Goal

Hand the 0.7 CRAN lane to Codex with an honest rescope (packaging through
`submission-ready`, not science-complete) and a dated pre-blackout cadence,
folding in ERROR-free win-builder evidence **without** advancing
`status_claim` off `tarball-clean`.

## Implemented

Docs only. No `R/` / `src/` / DESCRIPTION / ledger `status_claim` change. No
upload. #946 FTP receipts were not rewritten; #946 itself was **merged** in
this session (`5affb962b`) as docs-only after Shinichi asked whether something
needed merging.

## Mathematical Contract

Not applicable (handover / release-process docs).

## Files Changed

- `docs/dev-log/handover/2026-08-07-codex-handover.md`
- `AGENTS.md` (Latest pointer)
- `docs/dev-log/active-lane-split.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/phase-snapshot.md` + `phase-snapshot-archive.md`
- `docs/dev-log/check-log.md`
- this after-task note

## Checks Run

- `git fetch origin`; `origin/main` = `5affb962b` (#946 merged).
- `gh pr view 945` (CLOSED, not merged) / `gh pr view 946` (**MERGED**; GHA
  never started; docs-only honesty held: ERROR-free evidence, ledger still
  `tarball-clean`).
- `#937` / `#858` left open (foreign / optional; not merged).
- Brain: D-49, D-86, D-93, D-122, CI-17 — rescope keeps first CRAN number
  **0.7.0**, exact-artifact rungs, and owner-only publish.
- Handoff gate on primary: expected FAIL (foreign unpushed + dirty AGHQ
  checkout) → declared CARRIED-OVER / PROTECTED, not mass-pushed.

## Tests Of The Tests

Not applicable. No new test files.

## Consistency Audit

```sh
rg "platform-clean|CRAN-ready|status_claim" docs/dev-log/handover/2026-08-07-codex-handover.md AGENTS.md docs/dev-log/active-lane-split.md docs/dev-log/coordination-board.md docs/dev-log/phase-snapshot.md
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" docs/dev-log/handover/2026-08-07-codex-handover.md docs/dev-log/after-task/2026-08-07-codex-handover-rescope.md
```

Handover states highest proven rung = **`tarball-clean`**; win-builder
ERROR-free is on `main` via #946; `platform-clean` / upload / DESCRIPTION 0.7.0
remain owner-gated. No `meta_gaussian` / `tau ~` drift in these files.

## GitHub Issue Maintenance

Merged **#946**. Did not merge **#937** or **#858**. No new issue opened.

## What Did Not Go Smoothly

#946 was CONFLICTING with `main` (`active-lane-split.md`). Resolved by keeping
#944 merged-useful/CondExp rows plus ERROR-free win-builder evidence, then
merging. First `gh pr merge` failed with “Base branch was modified”; retry
succeeded once GitHub re-evaluated MERGEABLE. Untracked rhub/valgrind raw logs
in the platform worktree were left unstaged.

## Team Learning

Evidence ≠ claim: ERROR-free win-builder + a merged docs PR still does not
auto-write `platform-clean`. A closed #945 plus successor #946 is the same
lesson as stale-tarball FTP — cite the live merge SHA, never chat memory.

## Known Limitations

Valgrind completeness and whether it gates `platform-clean` vs only
`submission-ready` is still an owner question. Rendered-site Gate 2/4 is still
owed. DESCRIPTION remains 0.6.0.

## Next Actions

Codex: rehydrate → ask Shinichi to authorize `platform-clean` (bump/upload still
STOP until after ~19 Aug) → freeze → pkgdown → D-43 → `cran-comments` → hold.

Live verify 2026-08-08 (post-merge ubuntu + pkgdown green; same START HERE
filename): `2026-08-08-codex-handover-live-verify.md`.
