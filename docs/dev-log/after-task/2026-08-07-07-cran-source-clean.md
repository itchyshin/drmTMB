# After-task — drmTMB 0.7.0 CRAN gate to `source-clean`

**Date:** 2026-08-07 · **Platform:** Cursor (Composer) ·
**Lane:** `cursor/07-cran-readiness` in worktree
`~/local-scratch/worktrees/drmTMB-07-cran-exec` ·
**Foreign lanes:** AGHQ/missing-data, #858, #893, #869 — untouched.

## 1. Goal

Prove the **`source-clean`** rung for the 0.7.0 CRAN readiness slice: claim-freeze
surfaces, Gate −1/0/1 evidence, a local tarball probe with `--as-cran`, and a
fail-closed ledger that prints READY FOR CLAIMED RUNG. Stop before upload.
DESCRIPTION stays **0.6.0** (D-86).

## 2. Outcome

**Highest proven rung: `source-clean`.** Probe 2 finished
**Status: 1 NOTE** (New submission only). LOOP no longer ships in the tarball.
`cran_release_gate.py` prints **READY FOR CLAIMED RUNG** at `status_claim:
source-clean`. No CRAN upload; no version bump; `tarball-clean` deliberately
withheld.

## 3. Probe sequence

| Probe | SHA (prefix) | Inventory | `--as-cran` |
|---|---|---|---|
| 1 (pre-fix) | `783ce3a1…` | 922 | **2 NOTEs** — New submission + top-level `LOOP/` |
| 2 (after `^LOOP$`) | `5db0111a…` | 917 | **1 NOTE** — New submission only |

Probe 2 identity:

- SHA-256 `5db0111a683fd91d42ba11d66eb4ed83b2b4ba61dd7d58f5e2fb493b4f9662d3`
- Size **9817128** bytes
- Inventory **917** entries; `LOOP` absent
- Logs under `docs/dev-log/release/0.7.0-cran-gate/`
- Binary `drmTMB_0.6.0.tar.gz` at worktree root, **not** committed

Source commit for the claim-freeze ledger remains `c2b9d6cd6`. The `.Rbuildignore`
`^LOOP$` line was present for the rebuild but not yet in that clean commit, so
`artifact.clean_worktree` stays `false`.

## 4. Files created or changed

- `.Rbuildignore` — add `^LOOP$`
- `docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` — probe SHA/size/inventory paths; `status_claim: source-clean`
- `docs/dev-log/release/0.7.0-cran-gate/` — FREEZE-NOTES, sha, size, inventory, check logs, probe-driver log
- `docs/dev-log/after-task/2026-08-07-07-cran-source-clean.md` (this file)
- `docs/dev-log/plan-actual/2026-08-07-07-cran-readiness.md` — Melissa reconcile
- `LOOP/arcs.md`, `LOOP/checkpoint.md` — slice complete; OPEN GATE = upload

## 5. Checks run and exact outcomes

- Probe-driver `REBUILD_DONE` at `2026-08-07T12:10:17Z`
- `R CMD check --as-cran --no-manual`: **Status: 1 NOTE**; 0 ERROR; 0 WARNING
- Incoming feasibility NOTE text: **New submission** only; top-level files OK
- `python3 ~/shinichi-brain/tools/cran_release_gate.py docs/dev-log/release-audits/2026-08-07-07-cran-release-ledger.json` → **READY FOR CLAIMED RUNG**

## 6. Consistency audit

- No DESCRIPTION bump to 0.7.0
- No unqualified “CRAN ready” claim; rung named as `source-clean`
- Binary tarball excluded from git; only text gate artifacts committed
- Sibling lanes (#858 / #893 / #869 / AGHQ / missing-data) not touched

## 7. Why not `tarball-clean`

The gate requires `clean_worktree: true` and a freeze from a commit that includes
the `.Rbuildignore` fix. This slice records probe-2 evidence but keeps
`clean_worktree: false` until that commit lands and a rebuild is re-bound.

## 8. Known limitations and next actions

- **Owner gate:** CRAN upload (out of agent scope)
- Optional next engineering step: commit `.Rbuildignore` on a clean tree, rebuild,
  re-bind SHA + `--as-cran` log, then evaluate `tarball-clean`
- Platform matrix and D-43 panel remain later rungs
- GitHub issues: no new issue opened; tracker left unchanged for this packaging slice
