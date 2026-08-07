# Coordination Board — drmTMB

Pointer for humans and agents. Detailed lane rows live in
[`active-lane-split.md`](active-lane-split.md). Do not treat this board as a
census; capability counts belong in the ledger and Mission Control.

## Active Lane Split
- **Cursor** — owns the live **0.7** slices: packaging honesty at
  **`tarball-clean`**, draft **useful-0.7** (#942), and draft **platform-clean**
  (#941, **NOT READY**). Authoritative handover:
  [`handover/2026-08-07-cursor-handover.md`](handover/2026-08-07-cursor-handover.md).
  Does not touch #858. Does not upload. Does not bump DESCRIPTION to 0.7.0
  without owner authorization after a real platform-clean.
- **Claude** — prior interval-feasibility / D-117 lane; see handovers under
  `docs/dev-log/handover/`. Sequential with Cursor on the same subject (D-87/D-88).
- **Codex** — Lane B E0 (#858) and other live-toolchain slices when explicitly
  owned in `active-lane-split.md`. Mesh/SPDE #893 is merged.

## Current Rule
- One owner per subject across Cursor / Claude / Codex; hand off explicitly.
- Never stage from the dirty primary checkout on `claude/handover-freshness-0718`.
- Do not re-run Totoro under the closed 135-trace prereg; WITHHOLD cells stay PFR.
- Never claim `platform-clean` or CRAN-ready from local macOS `--as-cran` alone.

## Status
- 2026-08-07 — Packaging **#930/#931/#938/#939/#940** on `main`; rung
  **`tarball-clean`**. Live drafts: **#942** (useful @ `e6f781388`; CI watch
  `31214014701`) and **#941** (platform @ `fb30d60ff`; path fix + resubmit
  receipt; win-builder adjudication owed; CI `31215197798`).
- START HERE for Cursor:
  [`handover/2026-08-07-cursor-handover.md`](handover/2026-08-07-cursor-handover.md).
