# Coordination Board — drmTMB

Pointer for humans and agents. Detailed lane rows live in
[`active-lane-split.md`](active-lane-split.md). Do not treat this board as a
census; capability counts belong in the ledger and Mission Control.

## Active Lane Split
- **⚡ 2026-08-16 — PLATFORM MOVE: the authoring Claude session CLOSED; Shinichi is moving fully
  to CURSOR. Its automation loop (win-builder polling + the platform-clean cascade) died with it —
  the cascade is now a MANUAL checklist.** Two live lanes, each with its own Cursor handover;
  neither pointer covers the other:
  - **0.7.0 release lane** → [`handover/2026-08-16-cursor-handover-070-release.md`](handover/2026-08-16-cursor-handover-070-release.md)
    — **Cursor owns the win-builder → platform-clean unlock (2026-08-16).** R-devel filed and
    clean (`Status: 1 NOTE`, `winbuilder-devel.txt` + `00check.log`). R-release and
    R-oldrelease emails are **absent** from `itchyshin@gmail.com` (incl. Trash; positive
    control OK); both lanes **re-uploaded** at 14:47Z against immutable bytes
    (`winbuilder-reupload-2026-08-16.md`) — awaiting Ligges mail. `status_claim` stays
    `tarball-clean`; `platform-clean` advance remains PRE-AUTHORISED only when R-release +
    R-devel are filed clean and the gate passes; **submission remains withheld**. The QUIESCE
    below still stands until `external_logs` lands. Peer facts (not this lane's work): held
    test-guard `4699cf934` on `claude/eloquent-driscoll-521fa1` belongs to the **next**
    candidate; PR **#1050** merged shipped files during the quiesce (breach recorded;
    adjudication is Shinichi's). `DESCRIPTION` still reads `Version: 0.7.0` while `main` has
    drifted from `302ac2579` — **re-bump to `0.7.0.9000` awaits Shinichi's word** (do not bump).
  - **MSPL boundary lane** → [`handover/2026-08-16-cursor-handover-mspl-boundary.md`](handover/2026-08-16-cursor-handover-mspl-boundary.md)
    — S0+S1 complete on `claude/mspl-boundary-s0-s1`; **S2 gated** on design 256's two unchecked
    sign-off boxes (independent Noether + Fisher re-checks).
  - **THIRD lane, not this session's:** the interval-truth programme also handed to Cursor today —
    `origin/claude/cursor-handover-0816` carries
    `handover/2026-08-16-cursor-handover.md` (unmerged at this writing). That lane's pointer is its
    own; listed here so no split reader orphans it.
- **2026-08-16 — the `se = TRUE` PSOCK worker leak is NOT drmTMB's; stop chasing it.** (peer lane
  `claude/eloquent-driscoll-521fa1` @ `4699cf934`, held out of `main` under the quiesce — adds a
  `tests/` file.) The 2026-08-15 report did not reproduce: drmTMB has no cluster constructor in
  `R/`; the captured worker traced to a concurrent `pigauto` lane. Receipts:
  [`after-task/2026-08-16-se-path-worker-leak-nonrepro.md`](after-task/2026-08-16-se-path-worker-leak-nonrepro.md).
  Merge after the platform matrix completes.
- **⚠ 2026-08-15 (evening) — QUIESCE: the 0.7.0 re-freeze is IN PROGRESS (Shinichi: "merge all
  three PRs and start the re-freeze", after lifting BOTH D-93 and D-117 the same evening).**
  PRs #1039/#1041/#1042 are merged; the cut point is the `claude/07-freeze-3` merge on `main`
  (DESCRIPTION back to `0.7.0`). **Until the new candidate's platform matrix completes, do NOT
  merge to `main` anything that changes shipped files** (`R/ src/ tests/ man/ vignettes/
  NAMESPACE DESCRIPTION inst/ data/ NEWS.md`) — a post-cut shipped-file merge invalidates the
  candidate and forces another freeze (the exact failure the 2026-08-12 re-freeze notice
  documents). Docs-only merges under `docs/` are safe. Decision records:
  `docs/dev-log/release-audits/2026-08-15-d93-decision-reading-b.md` ·
  `…/2026-08-15-d117-discharge.md` · freeze lane: Claude, `claude/07-cran-ladder`.
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
