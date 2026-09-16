# Dinnage Arc3 Coordinator Checkpoint

Updated: **2026-09-16 ~11:06 MDT** · **`main` @ `fb35e4b5a`**

## Current scope

**Receipt gate CLEAR** on `main` (tip-identity green @ `e169d7a76`, run `35111843393`; coord-only moves since — no receipt PR). **Coord/docs push OK.** **Wave A: CLOSED.** **B1 [#1373](https://github.com/itchyshin/drmTMB/pull/1373) MERGED** @ `f822a34da`. **B2 [#1375](https://github.com/itchyshin/drmTMB/pull/1375) OPEN** @ `78df3d4d6` — local **47/47** reported; **C17 recert** @ `14618e6e4`; **tip** @ `78df3d4d6`. **D-263: re-ACCEPT @ `78df3d4d6`**. **MERGE-READY** pending settled green CI [`35125446950`](https://github.com/itchyshin/drmTMB/actions/runs/35125446950); **merge-commit poller** (not squash). **P2:** confint Rd cross-link, audit note (fixer). Tip-identity receipt **LAST** on `R/` before merge. Prefer **Composer** / Grace watchers. **DRM.jl twin map (Jason):** [`drm-jl-followups.md`](drm-jl-followups.md).

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
| #1375 | B2 surfaces | **MERGE-READY** (await CI `35125446950`) | `78df3d4d6` (C17 @ `14618e6e4`) |

## Wave B

**MERGE-READY pending CI.** [#1375](https://github.com/itchyshin/drmTMB/pull/1375) @ `78df3d4d6` on `cursor/dinnage-arc3-b2-surfaces-20260916`. **C17 recert** @ `14618e6e4`; **D-263 re-ACCEPT @ `78df3d4d6`**. CI [`35125446950`](https://github.com/itchyshin/drmTMB/actions/runs/35125446950) must settle green; then **merge-commit poller** (`tools/pr_merge_when_green.sh`, not squash). Tip-identity receipt **LAST** on branch before merge. P2: confint Rd, audit note (fixer). See [`wave-b-brief.md`](wave-b-brief.md) § B2.

## Resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor
git pull --ff-only origin main
gh pr view 1375 --json number,state,headRefOid,mergeStateStatus
gh pr checks 1375 --watch
cat docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/wave-b-brief.md
```
