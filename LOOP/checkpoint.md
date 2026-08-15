# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

GOAL: see LOOP/GOAL.md.  STATE: **all four owner-ordered items DONE. Arc at a decision point.**

116 re-check: 78 pass / 7 fail (all spatial) / 31 no truth · spatial repair + narrowed claim ·
mc-0248 corrected (my error) · 134 off-mainline runners+contracts recovered · the 73 SCOPED as a
construction programme, not a compute job. **No compute spent anywhere in this arc.**

- **DONE (verified):**
  - Wave 1 classify → `docs/dev-log/2026-08-15-interval-truth-coverage-map.md`. 210 uncovered,
    189 defects, split **116 re-check / 73 re-run**.
  - Gate extension points → `docs/dev-log/2026-08-15-truth-gate-extension-points.md`.
  - Cross-arc receipt → `scratchpad/cross-arc-four-cells.md`.
  - **The 116 re-check (owner-authorized) → `docs/dev-log/2026-08-15-interval-truth-recheck-verdicts.md`.**
    Truth recovered from 101 frozen campaign contracts across refs (only 1 on `origin/main`).
    85 checked: **78 PASS, 7 FAIL (all spatial)**. 31 have no recoverable truth and no verdict.
    Mechanism identified for ALL seven failures — see below.
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
  2. ~~`mc-0248`~~ **RESOLVED 2026-08-15 — it was my join error, not a defect.** The cell carries two
     targets and its claim explicitly excludes the slope; against the claimed intercept (truth 0.50)
     its interval `[0.398, 0.664]` brackets. Corrected split: **78 pass / 7 fail, all seven spatial**.
     Standing lesson: join truth on exact `target_id` — a cell is not the unit of a location check,
     a target is.
  3. **Provenance.** 96 of the 116 rest on receipts whose producing runner is not on `origin/main`;
     100 of 101 campaign contracts are likewise off-mainline. Evidence is real and recoverable but
     not reproducible from a clean mainline checkout. Recover the runners onto main, or record the
     limitation?
  4. **The 73 "re-runs" — SCOPED, not started** → `docs/dev-log/2026-08-15-rerun-73-scoping.md`.
     **0 of 73 have a contract; 0 have a profile runner.** So there is no truth to check against and
     nothing to re-run: this is fixture-and-contract *construction*, ~40-70 h across 47 distinct
     (family x provider x dpar x effect) combinations with no reuse. Compute is negligible (7.5 s/fit)
     — **neither Totoro nor DRAC is warranted**. Recommended split: (a) decide whether the truth
     manifest can carry FIXED-EFFECT targets, which unlocks 37 of 47; (b) 3-cell pilot to replace the
     estimate with a measurement; (c) treat the 4 `supported` + 22 `inference_ready_with_caveats` as a
     CLAIMS question, not a fixture one; (d) label the 5 `association` cells out of the gate's domain.
- **WHERE TRUTH LIVES:** branch `claude/lane-interval-truth-audit` — **PUSHED 2026-08-15** to
  `origin/claude/lane-interval-truth-audit` (14 commits, 188 files). **No PR opened** — that is the
  next gate and is Shinichi's call. The branch is 2 commits BEHIND origin/main (PR #1035, the S3
  dispatch fix: DESCRIPTION, R/zzz.R, check-log.md, test-foreign-s3-dispatch.R) — no overlap with
  this lane's files, but rebase or merge before any PR.
  Machine outputs: `scratchpad/recovered-truth.json`, `scratchpad/recheck-verdicts.json`,
  `scratchpad/recheck-runners.json`, `scratchpad/wave1-classification.json`.
- **NO LEDGER ROW CHANGED. NO COMPUTE SPENT.**
- **RESUME:** read GOAL.md → this file → the re-check verdicts doc. Every verdict is
  **magnitude-only** (count arm unreachable at 1 seed) and must be labelled as such in any claim.
