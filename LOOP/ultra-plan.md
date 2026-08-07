---
name: 0.7 CRAN ultra-plan
overview: "PR #930 is already merged to main (`8df6f240`). This ultra-plan executes the remaining 0.7.0 CRAN readiness arc (Arc Card: 5h) from a clean worktree: discharge D-93/D-117 by plan approval, claim-freeze, then cran-release-gate through source-clean and a local tarball probe. No AGHQ, no missing-data expansion, no CRAN upload."
todos:
  - id: s0-watch-ci
    content: Watch post-merge main CI run 31043189202 (75m ceiling)
    status: completed
  - id: s1-worktree
    content: Create clean worktree drmTMB-07-cran from origin/main
    status: completed
  - id: s2-claim-audit
    content: Rose claim-surface audit vs ledger 187 IF
    status: completed
  - id: s3-claim-freeze
    content: Apply claim-freeze edits + refresh cran-comments.md
    status: completed
  - id: s4-gate-ledger
    content: Init cran-release-gate ledger Gates -1/0/1
    status: in_progress
  - id: s5-tarball
    content: Local tarball + --as-cran + cran_release_gate.py; record SHA
    status: pending
  - id: s6-verify-close
    content: Mechanical verify + after-task + Melissa reconcile; STOP before upload
    status: pending
isProject: false
---

# Ultra-plan: drmTMB 0.7.0 CRAN readiness (post-#930)

## GOAL (paste-ready)

```text
PLATFORM: Cursor
LANE: drmTMB-0.7-cran-readiness
DELIVERABLE: cran-release-gate highest proven rung = source-clean; local candidate tarball SHA recorded; after-task + LOOP checkpoint
HEADLINE: Claim-freeze + D-49 source-clean after #930 (already MERGED at 8df6f240)
IN PARALLEL: claim-surface audit vs ledger · Gate −1/0/1 inventory draft · watch post-merge main CI
DEFER: CRAN upload · full 3-OS/R-hub platform-clean · AGHQ · missing-data G4+ · WITHHOLD re-prereg · primary-checkout cleanup · #858/#893/#869
DISCIPLINE: work only in a fresh worktree off origin/main · never stage primary debris · bump DESCRIPTION to 0.7.0 only at freeze (D-86) · never claim "CRAN ready" — report highest proven rung · verify with cran_release_gate.py + local --as-cran · Totoro/DRAC N/A · close via /goal LOOP
```

## ARC PROGRAM

From [scratchpad/2026-08-05-arc-07-cran-release-readiness.md](/Users/z3437171/local-scratch/worktrees/drmTMB-135trace/scratchpad/2026-08-05-arc-07-cran-release-readiness.md):

| Rung | Budget | Status after this plan starts |
| --- | ---: | --- |
| Arc 0 discharge | 45 min | **Locked by approving this plan** (see DECISIONS LOCKED) |
| Rung 1 #930 merge | 75 min | **DONE** — MERGED `8df6f240` · post-merge CI run `31043189202` must be watched |
| Rung 2 claim freeze | 90 min | OWED |
| Rung 3 source-clean + tarball probe | 75 min | OWED |
| Closeout | 15 min | OWED |
| Remaining capacity | ~180 min | |

## Phase 0.25 sweep receipt

| Surface | Evidence | Finding | Call |
| --- | --- | --- | --- |
| repo git | `gh pr view 930` → MERGED; `git fetch`; `origin/main` = `8df6f240`; `branch_drift_check` campaign branch 0 ahead / 1 behind main | #930 landed; campaign worktree tip is parent of merge | resume from **new worktree on main**, not dirty primary |
| twin/sister | DRM.jl / gllvmTMB not needed for claim freeze | n/a | n/a |
| brain `search_notes` | query `drmTMB 0.7.0 CRAN release readiness source-clean` | D-86/D-93/D-117/D-122/D-125; dossier LOAD-FIRST says gate RUN, publish call remains | reuse decisions; build gate ledger gap |
| grep AGENT_LOG / DECISIONS / OPEN_QUESTIONS / journal / deep-research | `grep D-117\|0.7\|CRAN` | CI-17 still open for publish half; D-125 claim mend done; dr20 is AGHQ literature (DEFER) | build-the-gap = source-clean only |
| Verdict | | | **reuse** protocol + prior audits; **resume** nothing half-built for 0.7 gate; **build** claim-freeze + gate ledger + tarball probe |

## WHAT THE BRAIN ALREADY KNOWS

- First CRAN number is **0.7.0**; 0.6 never submits (D-86).
- D-93 hold was about RE-SD coverage; profile accepted (D-97); 10-group gate ran (D-117); PASS withheld; warning shipped; **publish half never said**.
- D-122: "0.7 coming later" (urgency off) — this plan **reopens readiness work**, not upload.
- D-49 / [`~/shinichi-brain/protocols/cran-release-gate.md`](/Users/z3437171/shinichi-brain/protocols/cran-release-gate.md): fail-closed rungs; `cran_release_gate.py` lives in **brain** `tools/`, not the repo.
- Experimental banner already on README; `cran-comments.md` exists but is stale vs current evidence.
- Post-merge `main` CI is **ubuntu-only**; full 3-OS is tag/`workflow_dispatch` only — platform-clean is a **later** arc.

## WHAT SHINICHI TOLD US

- Leave D-117 discussion for now earlier, then asked for CRAN-facing arc + arc-creation.
- Explicit: **merge #930** (done).
- Explicit: **/ultra-plan the arc**.

## WHAT THE TEAM RAISED

```
TEAM RAISED
  Rose   — Do not say "CRAN ready"; report source-clean / NOT READY. · Overclaim risk on IF census vs experimental. · Recommend rung language only. · Q: discharge? · Default: discharge via plan approval.
  Fisher — D-117 PASS stays WITHHELD; profile+warning is the honest position, not a coverage claim. · Publish ≠ coverage PASS. · Recommend discharge without reinstating PASS. · Default: same.
  Grace  — Watch post-merge run 31043189202; local --as-cran on frozen hash; no DESCRIPTION bump until freeze. · Platform-clean later. · Default: ubuntu watch now, 3-OS later.
  Ada    — Merge done; lock discharge on plan approval; execute Rungs 2–3 via /goal; STOP before upload.
```

## ADA'S RECOMMENDATION

Approve this plan = discharge D-93/D-117 under **profile RE-SD + `profile.boundary` warning** as the honest 0.7.0 position (PASS remains withheld). Then run claim-freeze + source-clean. Do **not** upload.

## DECISIONS LOCKED

1. Approving this plan **discharges** D-93/D-117 for readiness work as above.
2. #930 is on `main`; do not re-run Totoro / re-promote WITHHOLD.
3. No CRAN upload in this arc.
4. No AGHQ / missing-data expansion / primary cleanup.
5. `DESCRIPTION` stays `0.6.0` until an explicit freeze slice bumps to `0.7.0` (D-86) — this arc may draft NEWS for 0.7 but does not tag.
6. After G0 approval, execution continues via **`/goal`** (not this planning chat).

## QUESTIONS STILL OPEN

None that block Rungs 2–3. Upload word remains future-only.

## SLICE TABLE

| Slice | Member | Model+effort | Bar | Time | Detail | Dep |
| --- | --- | --- | --- | ---: | --- | --- |
| S0 Watch post-merge CI | Grace | Composer / low | Cursor Models | 5+async | `gh run watch 31043189202`; cancelled≠fail (duration vs 75m) | — |
| S1 Fresh worktree | Ada | Composer / low | Cursor Models | 10 | `git worktree add … origin/main` @ `8df6f240`+; never primary | S0 green or noted |
| S2 Claim-surface audit | Rose | Auto Cost / medium | Other Models | 40 | Diff README/NEWS/`?confint`/capability-surface vs ledger 187 IF; list overclaims | S1 |
| S3 Claim freeze edits | docs + Rose | Composer / medium | Cursor Models | 50 | Fix only audit hits; refresh `cran-comments.md` evidence dates; experimental banner already present — verify only | S2 |
| S4 Gate −1/0/1 ledger | Grace | Auto Cost / medium | Other Models | 35 | Init release ledger JSON for Gate −1 (compiled TMB, first submission), Gate 0 product contract, Gate 1 rights skim | S1 |
| S5 Local tarball probe | Grace | Composer / medium | Cursor Models | 60 | document → build → `R CMD check --as-cran` on tarball; record SHA; run `python3 ~/shinichi-brain/tools/cran_release_gate.py` | S3, S4 |
| S6 Mechanical verify | Curie-style | Composer / low | Cursor Models | 15 | ledger `--check` if touched; census 187/55; CI conclusion | S5 |
| S7 Closeout | Rose | Auto Cost / medium | Other Models | 15 | after-task; update arc Actuals; `/goal` checkpoint; DECISIONS discharge note draft for brain (owner paste) | S6 |
| RECONCILE | Melissa | Auto Cost / low | Other Models | 10 | plan-vs-actual → `docs/dev-log/plan-actual/2026-08-05-07-cran-readiness.md` | S7 |

**PARALLEL:** {S2, S4} after S1 · S0 async with S1–S2  
**SEQUENTIAL:** S3←S2 · S5←S3,S4 · S6←S5 · S7←S6  
**FAN-OUT BUDGET:** checkpoint=`07-cran` · children ≤4 · scout=1 (S2) · build=2 · ceiling=0  
**LUNA SUITABILITY:** yes — S2/S6 mechanical audit on cheap bar  
**SEARCH:** none (no novelty claim)  
**ESTIMATE:** ~3 h wall remaining · fits one `/goal` session if CI already green  
**VERIFY:** highest rung language + tarball SHA + post-merge CI conclusion  
**CONSOLIDATE:** after-task under `docs/dev-log/after-task/` + arc Actuals

## Execution cwd

```bash
# after G0 — in /goal, not here
cd /Users/z3437171/Dropbox/Github\ Local/drmTMB
git fetch origin
git worktree add ~/local-scratch/worktrees/drmTMB-07-cran origin/main
cd ~/local-scratch/worktrees/drmTMB-07-cran
```

## Risk branch

If post-merge CI fails: stop claim freeze; diagnose from logs; no DESCRIPTION bump.  
If `--as-cran` ERROR/WARNING: leave gate **NOT READY**; open repair sub-arc.  
If claim audit finds a live overclaim that needs owner wording: pause only that sentence; continue ledger init.

## After G0 — paste into `/goal`

```text
Execute approved ultra-plan: drmTMB 0.7.0 CRAN readiness (post-#930).
Read scratchpad/2026-08-05-arc-07-cran-release-readiness.md and the plan.
Worktree: ~/local-scratch/worktrees/drmTMB-07-cran from origin/main.
Do Rungs 2–3 only: claim freeze + source-clean + local tarball probe.
Do NOT upload to CRAN. Do NOT touch AGHQ/missing-data/primary checkout/#858.
Watch main CI run 31043189202. Report highest proven cran-release-gate rung.
```
