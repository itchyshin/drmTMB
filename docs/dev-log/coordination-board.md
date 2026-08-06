# Coordination Board — drmTMB

Pointer for humans and agents. Detailed lane rows live in
[`active-lane-split.md`](active-lane-split.md). Do not treat this board as a
census; capability counts belong in the ledger and Mission Control.

## Active Lane Split
- **Cursor** — owns the **0.7.0 CRAN release-readiness** arc (claim-freeze →
  source-clean / local tarball probe). Arc card:
  `scratchpad/2026-08-05-arc-07-cran-release-readiness.md`. CI-17 trigger
  **10 Aug**. Does not touch #858 / #893 / #869.
- **Claude** — prior interval-feasibility / D-117 lane; see handovers under
  `docs/dev-log/handover/`. Sequential with Cursor on the same subject (D-87/D-88).
- **Codex** — Mesh/SPDE (#893), Lane B E0 (#858), and other live-toolchain
  slices when explicitly owned in `active-lane-split.md`.

## Current Rule
- One owner per subject across Cursor / Claude / Codex; hand off explicitly.
- Never stage from the dirty primary checkout on `claude/handover-freshness-0718`.
- Do not re-run Totoro under the closed 135-trace prereg; WITHHOLD cells stay PFR.

## Status
- 2026-08-05 — PR **#930** merged to `main` (`8df6f240`): five cells promoted
  after the 135-trace campaign; nine WITHHOLD remain `point_fit_recovery`.
- **Next** — 0.7 CRAN readiness claim-freeze (README / NEWS / pkgdown honesty),
  then cran-release-gate through source-clean + local tarball probe. Owner
  discharge of D-93/D-117 remains a separate publish call.
