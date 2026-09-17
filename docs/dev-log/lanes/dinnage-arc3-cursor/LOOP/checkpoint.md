# Dinnage Arc3 Coordinator Checkpoint

Updated: **2026-09-17** · **`main` @ `a59d0e64f`** · **Wave C MERGE-PENDING** ([#1380](https://github.com/itchyshin/drmTMB/pull/1380) @ `b60beecc9`)

## Current scope

**Wave A/B: CLOSED.** **Wave C:** PR [#1380](https://github.com/itchyshin/drmTMB/pull/1380) @ `b60beecc9` · **D-263 ACCEPT** @ tip ([5718829248](https://github.com/itchyshin/drmTMB/pull/1380#issuecomment-5718829248)). Census fix landed; branch merged `main` for coord conflicts. **Await green CI** → merge → receipt on `main`.

## Wave C deliverables (in flight)

| Issue | Change |
| --- | --- |
| #1339 Mi-1 | Export `beta_family()`; deprecated unexported `drmTMB::beta()` alias; tests + NEWS |
| #1340 Mi-2 | Re-export `nlme::fixef` / `nlme::ranef`; S3 registration; wave4c tests |

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
| #1379 | A-2 gate hotfix + receipts | **MERGED** | `9aeb36664` |
| #1377 | tip-identity receipt (post-B2) | **MERGED** | `4f9699855` |
| #1378 | tip-identity receipt (alt) | **CLOSED** (duplicate) | — |
| #1380 | Wave C API (#1339 #1340) | **OPEN** | `b60beecc9` |

## Resume

```sh
cd /Users/z3437171/local-scratch/lanes/drmTMB-dinnage-arc3-cursor
git checkout cursor/dinnage-arc3-wave-c
gh pr checks 1380 -R itchyshin/drmTMB --watch
```
