# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

GOAL: see LOOP/GOAL.md.  STATE: **the 116 re-check is DONE. 77 pass / 8 fail / 31 no truth.**

- **DONE (verified):**
  - Wave 1 classify → `docs/dev-log/2026-08-15-interval-truth-coverage-map.md`. 210 uncovered,
    189 defects, split **116 re-check / 73 re-run**.
  - Gate extension points → `docs/dev-log/2026-08-15-truth-gate-extension-points.md`.
  - Cross-arc receipt → `scratchpad/cross-arc-four-cells.md`.
  - **The 116 re-check (owner-authorized) → `docs/dev-log/2026-08-15-interval-truth-recheck-verdicts.md`.**
    Truth recovered from 101 frozen campaign contracts across refs (only 1 on `origin/main`).
    85 checked: **77 PASS, 8 FAIL**. 31 have no recoverable truth and no verdict.
    Mechanism identified for 7 of the 8 failures — see below.
  - Gates re-run after every step and unchanged: 24/24 OK; `capability-ledger: OK (31 outputs)`.
- **IN PROGRESS:** nothing.
- **OPEN — needs Shinichi:**
  1. **The spatial-fixture defect.** 7 of 8 failures involve `spatial`. The q4 adapter generates
     effects from `K = 0.25^|i-j| + 0.35I` and hands animal/relmat the matching `Ainv = solve(K)`
     (they PASS), but hands spatial only `coords`, from which `drm_spatial_coords_precision`
     (`R/drmTMB.R:13395`) builds `exp(-d/median(d))` — correlation 0.94 at lag 1 vs the DGP's 0.25,
     a ~30x mismatch. **The declared truth is not the model's estimand.** Disposition: the
     `interval_feasible` claim is *not currently supported* — but as a FIXTURE defect, not an
     interval-machinery defect. Demote, repair the fixture, or scope out?
  2. **`mc-0248`** (gamma × relmat) fails at 99% and does **NOT** share that mechanism.
     **NOT ESTABLISHED** — needs its own partition before any disposition.
  3. **Provenance.** 96 of the 116 rest on receipts whose producing runner is not on `origin/main`;
     100 of 101 campaign contracts are likewise off-mainline. Evidence is real and recoverable but
     not reproducible from a clean mainline checkout. Recover the runners onto main, or record the
     limitation?
  4. Still open from the T1 gate: the **73 re-runs** (compute), and the **26 top-tier cells** with no
     receipt (4 `supported` on evidence rows with no command/run_id/replicates).
- **WHERE TRUTH LIVES:** branch `claude/lane-interval-truth-audit` (local, unpushed — push is a gate).
  Machine outputs: `scratchpad/recovered-truth.json`, `scratchpad/recheck-verdicts.json`,
  `scratchpad/recheck-runners.json`, `scratchpad/wave1-classification.json`.
- **NO LEDGER ROW CHANGED. NO COMPUTE SPENT.**
- **RESUME:** read GOAL.md → this file → the re-check verdicts doc. Every verdict is
  **magnitude-only** (count arm unreachable at 1 seed) and must be labelled as such in any claim.
