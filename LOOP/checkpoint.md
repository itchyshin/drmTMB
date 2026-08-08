GOAL: see GOAL.md.   STATE: **tarball-clean** proven; win-builder fixed tarball
  ERROR-free (1 NOTE ×2); **`platform-clean` claim awaits owner authorize**.
ARCS DONE (verified):
- A0–A5 — source-clean / probe-2 / ledger (prior).
- Tarball-clean — #938/#939; freeze SHA `c787ee40…aa156cbb`; local --as-cran 1 NOTE.
- useful-0.7 — MERGED to main via #942 (`9e85ff91d`); LOOP useful lane complete.
- Platform attempt (2026-08-07) — GHA 3-OS green (run 31195187084); morning
  win-builder CondExp ERROR; path repair on main (#941); fixed tarball
  `f9b9588e…` / 9818425 FTP 226; R-release+R-devel **1 NOTE** (CondExp cleared).
  Ledger claim **not** advanced (`status_claim` remains `tarball-clean`).
OPEN GATES (need human):
- Owner authorize `status_claim` → `platform-clean` (or withhold for valgrind /
  other review). Evidence: `platform/winbuilder-emails.md`.
- Finish valgrind adjudication if still owed.
- Submission-ready / DESCRIPTION 0.7.0 / upload — owner only.
TRUTH LIVES IN: worktree `~/local-scratch/worktrees/drmTMB-07-platform` · branch
`cursor/07-winbuilder-adjudicate` · PR #945 · ledger
`docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` ·
`docs/dev-log/release/0.7.0-cran-gate/platform/PLATFORM-NOT-READY.md`
RESUME: Highest proven rung = **tarball-clean**. Do NOT claim platform-clean
without owner word. Do NOT upload. Do NOT bump DESCRIPTION to 0.7.0.
