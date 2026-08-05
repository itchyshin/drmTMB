GOAL: see GOAL.md.   STATE: S1+S2 DONE. STOPPED at Totoro OPEN GATE.
ARCS DONE (verified):
- S0-scaffold — LOOP/GOAL.md, arcs.md, checkpoint.md, ultra-plan.md present.
- S1-runner — tools/run-135-trace-campaign.R emits 135 jobs; clamp/LR/unimodal computed; tools/run-135-trace-totoro.sh refuses launch without DRMTMB_TOTORO_GO=1.
- S2-c1-smoke — mc-0568 seed 21260806 tmbprofile PASS (promotion_eligible=TRUE; LR both sides; unimodal; clamp computed FALSE). Artifacts: docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/smoke-mc-0568-tmbprofile/SMOKE_PASS.txt. Endpoint×tmbprofile CI agree to ~1e-5.
ARC IN PROGRESS: none (paused).
NEXT: S3-totoro — AFTER explicit owner Totoro approval, set DRMTMB_TOTORO_GO=1 and launch ≤100 cores.
OPEN GATES (need human): **Totoro ≤100-core grid launch** — awaiting Shinichi go.
TRUTH LIVES IN: worktree ~/local-scratch/worktrees/drmTMB-135trace @ cursor/135-trace-campaign; receipts under docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/; LOOP/.
RESUME: You are 135-trace — RESUME after Totoro approval. READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md. WORKSPACE: ~/local-scratch/worktrees/drmTMB-135trace on cursor/135-trace-campaign. CONTINUE FROM: S3 with DRMTMB_TOTORO_GO=1. Then S4 ten-clause review → S5 promote PASSes only → verify-close. Do not touch #858, D-117, #926, primary debris, coi/Tier-2.
