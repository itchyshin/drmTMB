# Dinnage Arc3 Coordinator Checkpoint

Updated: **2026-09-16 ~12:00 MDT** · **`main` @ `7e1d187dc`** (B2 merge @ `4806b4839`)

## Current scope

**Wave A: CLOSED.** **B1 [#1373](https://github.com/itchyshin/drmTMB/pull/1373) MERGED** @ `f822a34da`. **B2 [#1375](https://github.com/itchyshin/drmTMB/pull/1375) MERGED** @ `4806b4839`. **`main` R-CMD-check RED** — A-2 predictor-fail gate from B2 too broad. **Hotfix [#1379](https://github.com/itchyshin/drmTMB/pull/1379) OPEN** — merge first. **Tip-identity receipt [#1377](https://github.com/itchyshin/drmTMB/pull/1377) OPEN** — receipt-only; merge **after #1379** when R-CMD-check green. **DRM.jl twin map (Jason):** [`drm-jl-followups.md`](drm-jl-followups.md).

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
| #1379 | A-2 gate hotfix | OPEN | `hotfix/a2-missing-predictor-gate` |
| #1377 | tip-identity receipt (post-B2) | OPEN (after #1379) | `cursor/receipt-staleness-b1375-20260916` |

## Wave B

**B2 closed.** [#1375](https://github.com/itchyshin/drmTMB/pull/1375) merged @ `4806b4839`. **Unblock `main`:** [#1379](https://github.com/itchyshin/drmTMB/pull/1379) then receipt [#1377](https://github.com/itchyshin/drmTMB/pull/1377). See [`wave-b-brief.md`](wave-b-brief.md) § B2.

## Resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor
git pull --ff-only origin main
gh pr checks 1379 --watch
gh pr checks 1377 --watch
cat docs/dev-log/lanes/dinnage-arc3-cursor/LOOP/wave-b-brief.md
```
