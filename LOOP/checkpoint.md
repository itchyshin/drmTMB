# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

GOAL: see LOOP/GOAL.md.  STATE: **Wave 1 COMPLETE. STOPPED AT GATE `T1-classify`, awaiting Shinichi.**

- **DONE (verified):**
  - Lane pre-flight; bounded worktree on `claude/lane-interval-truth-audit` off `origin/main` `82cd00560`.
  - Headline re-verified from the ledger, not inherited: 192/41/4 = **237 claiming**, 27 in manifest,
    **210 uncovered**, **209 workload** (`mc-0282` is a documented `UNGATED` exemption).
  - Cross-arc rule discharged → `scratchpad/cross-arc-four-cells.md`. The landed response-mask arc
    measured FORMULA validity, not interval location — orthogonal axes, no conflict, no protection.
    `mc-0321` is already manifest-covered and was never in scope.
  - T1 (gate extension points) → `docs/dev-log/2026-08-15-truth-gate-extension-points.md`.
  - T2a/b/c (classify) → `scratchpad/uncovered-cohort-{A,B,C}.md`, machine form in
    `scratchpad/wave1-classification.json`.
  - T3 (adjudicate) → `docs/dev-log/2026-08-15-interval-truth-coverage-map.md` — **the checkpoint doc.**
    Written by the conductor rather than dispatched, because the census work it depended on had
    already been done here; recorded as a plan deviation.
  - Baseline gates green and untouched: gate tests 24/24 OK; `capability-ledger: OK (31 outputs)`.
- **IN PROGRESS:** nothing. Wave 1 is closed.
- **NEXT (blocked on the gate):** Wave 2 — derive `true_value` per cohort and extend the manifest.
- **OPEN GATE — `T1-classify`.** Four questions for Shinichi, all in the coverage map:
  1. **116 re-check / 73 re-run** over 189 defect cells (the plan's 107/52 was measured over one of
     two receipt trees). Does the 73 get a first-ever profile campaign, and on Totoro or DRAC?
  2. **110 of the 116 re-checks can only ever be magnitude-only** — at one seed the gate's count arm
     is structurally unreachable (`1 > 1` is False, `profile_truth_gate.py:221`). Accept magnitude-only
     verdicts and label every claim, or top up seeds (compute)?
  3. **Zero of the 41 `inference_ready_with_caveats` and zero of the 4 `supported` cells are
     re-checkable**, and all four `supported` cells rest on evidence rows with no command, run_id or
     replicates — two of them stating `coverage=planned` in their own boundary. Scope call.
  4. **`mc-0596`** — `verified`/`interval_feasible` here vs *"false convergence (8)"* on independent
     re-optimization in the landed arc. D-87 says this is yours.
- **WHERE TRUTH LIVES:** branch `claude/lane-interval-truth-audit` (local, unpushed — push is a gate),
  worktree `~/local-scratch/lanes/drmTMB-interval-truth-audit`. Key artefacts:
  `docs/dev-log/2026-08-15-interval-truth-coverage-map.md`,
  `docs/dev-log/2026-08-15-truth-gate-extension-points.md`,
  `scratchpad/wave1-classification.json`, `scratchpad/shared-interval-groups.json`.
- **NO COMPUTE COMMITTED.** No cell has a location verdict yet; 116 are merely *eligible* for one.
- **RESUME:** read LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/arcs.md → LOOP/ultra-plan.md, then the
  coverage map. Do not start Wave 2 until the four questions above are answered.
