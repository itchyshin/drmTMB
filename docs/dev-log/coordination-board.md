# Coordination Board — drmTMB

Pointer for humans and agents. Detailed lane rows live in
[`active-lane-split.md`](active-lane-split.md). Do not treat this board as a
census; capability counts belong in the ledger and Mission Control.

## Active Lane Split
- **2026-08-11 reassignment (Shinichi, in session):** the live 0.7 CRAN ladder is
  now owned by **Claude**, superseding the 2026-08-07 Codex-ownership line below.
  Scope of that decision: lane ownership only. It does **not** authorise a rung
  advance, a submission, or the merge of any open PR.
  Factual note, not an approval: the DESCRIPTION 0.7.0 bump currently sits on the
  Claude branch `claude/07-candidate-freeze-2` in **PR #996, open and unmerged** —
  the merge decision remains Shinichi's and has not been given.
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
- 2026-08-08 morning verify — `origin/main` @ `5affb962b` (#946). Rung
  **`tarball-clean`**. useful-0.7 #942, CondExp #941, and win-builder ERROR-free
  docs #946 **merged**. Post-merge ubuntu R-CMD-check + pkgdown **green**.
  CRAN submit UI offline until ~19 Aug 2026. Draft **#947** (do not auto-merge).
  Sibling **#937** / **#858** still open.
- START HERE for Codex (same 2026-08-07 filename):
  [`handover/2026-08-07-codex-handover.md`](handover/2026-08-07-codex-handover.md).
