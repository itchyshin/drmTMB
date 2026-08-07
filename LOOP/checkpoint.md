GOAL: see GOAL.md.   STATE: claim-freeze WIP committed next; gate ledger + tarball owed.
ARCS DONE (verified):
- A0 — G0 approved; D-93/D-117 discharged for readiness.
- A1 — #930 merged; CI run 31043189202 success.
- A2 — claim audit written; README + cran-comments edits present (uncommitted until this checkpoint lands).
ARC IN PROGRESS: A3-gate-ledger — product contract + cran_release_gate ledger JSON.
NEXT: A4-tarball-probe — local build + R CMD check --as-cran + SHA.
OPEN GATES (need human): CRAN **upload** (out of scope); optional merge of PR #931 if not already on this branch (docs already FF'd @ 7bacb9e2c).
TRUTH LIVES IN: worktree `~/local-scratch/worktrees/drmTMB-07-cran-exec` · branch `cursor/07-cran-readiness` @ `7bacb9e2c`+WIP · plan `~/.cursor/plans/0.7_cran_ultra-plan_42828b75.plan.md`
RESUME: You are drmTMB-0.7-cran-readiness — RESUME. READ LOOP/GOAL.md → checkpoint.md → ultra-plan.md. WORKSPACE: ~/local-scratch/worktrees/drmTMB-07-cran-exec on cursor/07-cran-readiness. CONTINUE FROM: A3/A4. Do NOT upload. Do NOT bump DESCRIPTION to 0.7.0.
