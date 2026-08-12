# Coordination Board — drmTMB

Pointer for humans and agents. Detailed lane rows live in
[`active-lane-split.md`](active-lane-split.md). Do not treat this board as a
census; capability counts belong in the ledger and Mission Control.

## Active Lane Split
- **2026-08-11 reassignment (Shinichi, in session):** the live 0.7 CRAN ladder is
  now owned by **Claude**, superseding the 2026-08-07 Codex-ownership line below.
  That reassignment covered lane ownership only.
  **Later the same day Shinichi authorised the merges**, and both landed on `main`:
  **#1000** (`5a225378d`, the CRAN-gate docs) and **#996** (`a3217da93`, the candidate
  freeze), which is what put `Version: 0.7.0` on `main`.
  **Still NOT authorised by any of the above:** advancing `status_claim` past
  `tarball-clean`, writing `platform-clean`, or uploading to CRAN. `platform-clean`
  additionally remains mechanically blocked — the release gate rejects the claim while
  `platform_matrix` and `external_logs` are absent, and win-builder has not run against
  the candidate.
- **Claude** — **owns the 0.7 CRAN ladder** (reassigned above). Also holds the prior
  interval-feasibility / D-117 lane; see handovers under `docs/dev-log/handover/`.
  Start here: [`handover/2026-08-11-070-gate-truth-handover.md`](handover/2026-08-11-070-gate-truth-handover.md).
  Optional GVA docs #937 remains open and non-blocking.
- **Codex** — ~~owns the live 0.7 CRAN ladder through `submission-ready`~~ **SUPERSEDED
  2026-08-11** by the reassignment above; the 2026-08-07 handover
  ([`handover/2026-08-07-codex-handover.md`](handover/2026-08-07-codex-handover.md)) is now a
  historical record of that lane, not a live claim. Codex still holds **#858** (Lane B E0) and
  **#955**; both are **PROTECTED FOREIGN** — do not push, clean, or reconcile them.
- **Cursor** — #946 win-builder adjudication **merged** (`5affb962b`). #945 closed. Receipts now
  on `main`; do not rewrite them. **Carried-over:** `cursor/handover-0807`,
  `cursor/07-tarball-clean` and `cursor/07-cran-readiness` are **unmerged** (2026-08-07) and each
  rewrites ~60 lines of *this* section. Read before merging, because they are **not** wholly in
  conflict with it: their version already retires Codex's CRAN-ladder claim and demotes Codex to
  Lane B E0, which **agrees** with this board. The single genuine conflict is ownership of the live
  0.7 slices — they say **Cursor**, this board says **Claude** per the 2026-08-11 reassignment.
  **Rebase, do not straight-merge:** a straight merge drops the reassignment and the merge record
  below. Resolving that one conflict is Shinichi's call (D-87), not a rebaser's.

## Current Rule
- One owner per subject across Cursor / Claude / Codex; hand off explicitly.
- Never stage from the dirty primary checkout on `claude/handover-freshness-0718`.
- Do not re-run Totoro under the closed 135-trace prereg; WITHHOLD cells stay PFR.
- Never claim `platform-clean` or CRAN-ready from local macOS `--as-cran` alone.
- Evidence ≠ ledger: ERROR-free win-builder does not auto-advance `status_claim`.

## Status
- **2026-08-11 — `origin/main` @ `aa76c2399`; `DESCRIPTION` is now `0.7.0`.** Rung unchanged:
  **`tarball-clean` proven, `platform-clean` unproven.** Merged today: **#1000** (the CRAN gate now
  names the live candidate), **#996** (candidate freeze + the 0.7.0 bump), **#1002** (NEWS stops
  claiming a CRAN release drmTMB has not had), **#1003** (all 42 open issues triaged — **0
  BLOCKING**), **#1006** (the one user-surface fix + four documented limits + C17 re-certification),
  **#1013** (CI receipts). Post-merge `R-CMD-check` and `pkgdown` on `aa76c2399` both **green**.
- **The candidate no longer matches `main`.** `NEWS.md` and today's source fixes are shipped files,
  so a **re-freeze is required before submission**. Recorded as
  `known_evidence_gaps.candidate_no_longer_matches_main` in the 0.7.0 ledger.
- **What actually gates the release — none of it engineering.** **D-93** holds 0.7.0, undischarged.
  **D-117** was re-run 2026-08-09 (400,000 attempts, pooled 0.9248, clearing `ss_floor(10)=0.918`);
  discharge is **RECOMMENDED, NOT DECIDED**. **win-builder is ABSENT** for the candidate. The rights
  re-review and the source-clean re-cut are owed before `submission-ready`.
- START HERE: [`handover/2026-08-11-070-gate-truth-handover.md`](handover/2026-08-11-070-gate-truth-handover.md).
  The 2026-08-07 Codex handover is historical.
- Superseded and kept for the record: 2026-08-08 morning verify — `origin/main` @ `5affb962b`
  (#946), rung `tarball-clean`, #942 / #941 / #946 merged, draft **#947** (do not auto-merge).
