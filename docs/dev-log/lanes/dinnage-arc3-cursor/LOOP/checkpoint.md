# Dinnage Arc3 Coordinator Checkpoint

Updated: **2026-09-16 ~10:48 MDT** · **`main` @ `9c4f021fc`**

## Current scope

**Receipt gate CLEAR** on `main` (tip-identity green @ `e169d7a76`, run `35111843393`; coord-only moves since — no receipt PR). **Coord/docs push OK.** **Wave A: CLOSED.** **B1 [#1373](https://github.com/itchyshin/drmTMB/pull/1373) MERGED** @ `f822a34da`. **B2 [#1375](https://github.com/itchyshin/drmTMB/pull/1375) OPEN** @ `1424f1971` — release-shard fixes (**REML IC**, **A-2 `missing=` gating**, **census TSV**). Prior **D-263 ACCEPT stale**; **C17 re-cert + fresh D-263 in flight** (**not MERGE-READY**). Tip-identity receipt **LAST** on `R/` before merge. Prefer **Composer** / Grace watchers. **DRM.jl twin map (Jason):** [`drm-jl-followups.md`](drm-jl-followups.md).

## Merge record

| PR | Slice | State | Merge / head SHA |
| --- | --- | --- | --- |
| #1374 | receipt refresh (main) | **MERGED** | `f7b40b75a` |
| #1372 | receipt refresh (prior) | **MERGED** | `dd937ac3` |
| #1370 | D-263 audit md | **MERGED** | `3dcd7ab1` |
| #1368 | A1 docs | **MERGED** | `f8745242` |
| #1369 | A2 check/profile | **MERGED** | `2c15ae63e` |
| #1367 | A3 misc | **MERGED** | `e6ca0dc8e` |
| #1371 | Wave B docs-only | **MERGED** | `6580d74b1` |
| #1373 | B1 check diagnostics | **MERGED** | `f822a34da` |
| #1375 | B2 surfaces | OPEN (shard fixes; stale D-263; C17+D-263 in flight) | `1424f1971` |

## Wave B

**C17 re-cert + fresh D-263 in flight; prior ACCEPT stale.** [#1375](https://github.com/itchyshin/drmTMB/pull/1375) @ `1424f1971` on `cursor/dinnage-arc3-b2-surfaces-20260916`. Tip shard fixes: **REML IC**, **A-2 `missing=` gating**, **census TSV**. **Not MERGE-READY** — no merge until fresh D-263 settles and CI green; tip-identity receipt **LAST** on branch. P2: confint Rd cross-link, audit note, check-log (fixer). See [`wave-b-brief.md`](wave-b-brief.md) § B2.

## Resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor
git pull --ff-only origin main
gh pr view 1375 --json number,state,headRefOid,mergeStateStatus
gh pr checks 1375 --watch
cat docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/wave-b-brief.md
```
