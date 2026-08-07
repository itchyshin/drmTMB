GOAL: see GOAL.md.   STATE: **tarball-clean proven**; platform-clean attempt **NOT READY**.
ARCS DONE (verified):
- A0–A5 — source-clean / probe-2 / ledger (prior).
- Tarball-clean — #938/#939; freeze SHA `c787ee40…aa156cbb`; local --as-cran 1 NOTE.
- useful-0.7 — MERGED to main via #942 (`9e85ff91d`); LOOP useful lane complete.
- Platform attempt (2026-08-07) — GHA 3-OS green (run 31195187084); win-builder
  R-release+R-devel **1 ERROR** (CondExp `drm_src_path`); path repair + resubmit
  receipt on this branch; R-hub sanitizers OK / rchk noise; valgrind incomplete.
  Ledger claim **not** advanced (`status_claim` remains `tarball-clean`).
OPEN GATES (need human / repair):
- Adjudicate win-builder re-submit (FTP-550 / missing results); ERROR-free required.
- Finish valgrind adjudication; then re-evaluate `platform-clean`.
- Submission-ready / DESCRIPTION 0.7.0 / upload — owner only.
TRUTH LIVES IN: worktree `~/local-scratch/worktrees/drmTMB-07-platform` · branch
`cursor/07-platform-clean` · ledger
`docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` ·
`docs/dev-log/release/0.7.0-cran-gate/platform/PLATFORM-NOT-READY.md`
RESUME: Highest proven rung = **tarball-clean**. Do NOT claim platform-clean.
Do NOT upload. Do NOT bump DESCRIPTION to 0.7.0.
