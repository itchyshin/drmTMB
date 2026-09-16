# Dinnage Arc3 Coordinator Checkpoint

Updated: **2026-09-16 ~13:22 MDT** · **`main` @ `542ca455a`** (B2 merge @ `4806b4839`)

## Current scope

**Wave A: CLOSED.** **B1 [#1373](https://github.com/itchyshin/drmTMB/pull/1373) MERGED** @ `f822a34da`. **B2 [#1375](https://github.com/itchyshin/drmTMB/pull/1375) MERGED** @ `4806b4839` (not OPEN; pre-merge tips like `296a1f763` are historical only). **`main` `receipt-staleness` RED** until hotfix. **Hotfix [#1379](https://github.com/itchyshin/drmTMB/pull/1379) OPEN** @ `59667a423` — merge when R-CMD-check green. **[#1377](https://github.com/itchyshin/drmTMB/pull/1377) OPEN** — close after #1379 if redundant. **DRM.jl twin map (Jason):** [`drm-jl-followups.md`](drm-jl-followups.md).

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
| #1375 | B2 surfaces | **MERGED** | `4806b4839` |
| #1379 | A-2 gate hotfix + receipts | OPEN | `59667a423` |
| #1377 | tip-identity receipt (post-B2) | OPEN (likely redundant) | `cursor/receipt-staleness-b1375-20260916` |

## Wave B

**B2 closed.** [#1375](https://github.com/itchyshin/drmTMB/pull/1375) merged @ `4806b4839`. **Unblock `main`:** merge [#1379](https://github.com/itchyshin/drmTMB/pull/1379) @ `59667a423` when green; then close [#1377](https://github.com/itchyshin/drmTMB/pull/1377) if redundant. See [`wave-b-brief.md`](wave-b-brief.md) § B2.

## Resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor
git pull --ff-only origin main
gh pr checks 1379 --watch
gh pr checks 1377 --watch
cat docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/wave-b-brief.md
```
