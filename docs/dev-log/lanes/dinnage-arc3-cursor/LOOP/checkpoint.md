# Dinnage Arc3 Coordinator Checkpoint

Updated: **2026-09-16 ~10:45 MDT** · **`main` @ `2d80d22de`**

## Current scope

**Receipt gate CLEAR** on `main` (tip-identity green @ `e169d7a76`, run `35111843393`; coord-only moves since — no receipt PR). **Coord/docs push OK.** **Wave A: CLOSED.** **B1 [#1373](https://github.com/itchyshin/drmTMB/pull/1373) MERGED** @ `f822a34da`. **B2 [#1375](https://github.com/itchyshin/drmTMB/pull/1375) OPEN** @ `05c28c1bb` — **`R/bf.R` `call_names` fix**; local **47/47** reported. **D-263: ACCEPT** @ `05c28c1bb` (Shinichi). **MERGE-READY pending settled green CI** — **keep-going:** merge when CI green (run [`35123724324`](https://github.com/itchyshin/drmTMB/actions/runs/35123724324) **in flight**). **P0:** C17 inert re-cert on earlier tip (`mc-0568` / C17+C14 @ `c493fc0bb`). Tip-identity receipt **LAST** on `R/` before merge. Prefer **Composer** / `pr_merge_when_green.sh`. **DRM.jl twin map (Jason):** [`drm-jl-followups.md`](drm-jl-followups.md).

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
| #1375 | B2 surfaces | OPEN (D-263 ACCEPT; CI in flight → merge) | `05c28c1bb` |

## Wave B

**D-263 ACCEPT @ `05c28c1bb`; await settled green CI then merge.** [#1375](https://github.com/itchyshin/drmTMB/pull/1375) on `cursor/dinnage-arc3-b2-surfaces-20260916`. CI run [`35123724324`](https://github.com/itchyshin/drmTMB/actions/runs/35123724324) **in flight**. **Keep-going:** `pr_merge_when_green.sh itchyshin/drmTMB 1375` when settled green; tip-identity receipt **LAST** on branch. P2: confint Rd cross-link, audit note (fixer). See [`wave-b-brief.md`](wave-b-brief.md) § B2.

## Resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor
git pull --ff-only origin main
gh pr view 1375 --json number,state,headRefOid,mergeStateStatus
gh pr checks 1375 --watch
cat docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/wave-b-brief.md
```
