# Coordination Board — drmTMB

Pointer for humans and agents. Detailed lane rows live in
[`active-lane-split.md`](active-lane-split.md). Do not treat this board as a
census; capability counts belong in the ledger and Mission Control.

## Active Lane Split
- **Codex** — owns the live **0.7 CRAN ladder** through `submission-ready`
  (rescope: packaging + honest caveats, not science-complete). Authoritative
  handover: [`handover/2026-08-07-codex-handover.md`](handover/2026-08-07-codex-handover.md).
  Does not touch #858. Does not upload. Does not bump DESCRIPTION to 0.7.0
  without owner authorization. Does not write `platform-clean` without owner
  authorize even though win-builder is ERROR-free on `f9b9588e…` and #946 is
  merged.
- **Cursor** — #946 win-builder adjudication **merged** (`5affb962b`). #945
  closed. Receipts now on `main`; do not rewrite them.
- **Claude** — prior interval-feasibility / D-117 lane; see handovers under
  `docs/dev-log/handover/`. Sequential with Cursor/Codex on the same subject
  (D-87/D-88). Optional GVA docs #937 remains open and non-blocking.

## Current Rule
- One owner per subject across Cursor / Claude / Codex; hand off explicitly.
- Never stage from the dirty primary checkout on `claude/handover-freshness-0718`.
- Do not re-run Totoro under the closed 135-trace prereg; WITHHOLD cells stay PFR.
- Never claim `platform-clean` or CRAN-ready from local macOS `--as-cran` alone.
- Evidence ≠ ledger: ERROR-free win-builder does not auto-advance `status_claim`.

## Status
- 2026-08-07 night — `origin/main` @ `5affb962b` (#946). Rung **`tarball-clean`**.
  useful-0.7 #942, CondExp #941, and win-builder ERROR-free docs #946 **merged**.
  CRAN submit UI offline until ~19 Aug 2026.
- START HERE for Codex:
  [`handover/2026-08-07-codex-handover.md`](handover/2026-08-07-codex-handover.md).
