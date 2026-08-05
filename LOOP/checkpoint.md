GOAL: see GOAL.md.   STATE: COMPLETE — 5/14 promoted; 9 withheld.
ARCS DONE (verified):
- S0–S2 — LOOP, runner, tmbprofile smoke.
- S3-totoro — 135/135 ok on Totoro parallel -j64; receipts synced.
- S4-review — CELL-VERDICTS + FISHER-REVIEW; 5 PASS / 9 WITHHOLD.
- S5-promote — mc-0568/0576/0595/0596/0653 → interval_feasible; FROZEN 59→54; NEWS; ledger --check OK; unittest OK.
- verify-close — after-task + plan-vs-actual written.
ARC IN PROGRESS: none.
NEXT: owner push/PR for `cursor/135-trace-campaign` (not auto-pushed). Optional new prereg for WITHHOLD re-pilot — separate goal.
OPEN GATES (need human): push/PR only.
TRUTH LIVES IN: worktree @ cursor/135-trace-campaign; artifacts under docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/; ledger cells.tsv; LOOP/.
RESUME: Goal complete. Do not re-run Totoro or re-promote. For a WITHHOLD re-pilot, open a new ultra-plan/prereg.
