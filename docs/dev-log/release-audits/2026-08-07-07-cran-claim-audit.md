# Claim-surface audit — 0.7.0 CRAN readiness (2026-08-07)

Source commit: `8df6f2402` (post-#930 main). Worktree:
`~/local-scratch/worktrees/drmTMB-07-cran-exec` on `cursor/07-cran-readiness`.

## Census (model_surface evidence_tier)

| Tier | Count |
| --- | ---: |
| interval_feasible | **187** |
| point_fit_recovery | **55** |
| inference_ready_with_caveats | 29 |
| supported | 4 |
| diagnostic_only | 58 |
| none | 366 |

`FROZEN_CENSUS_POINT_FIT_RECOVERY = 54` in `tools/capability_ledger.py` (matches
135-trace promotion). Capability surface headline agrees: **187 interval-feasible /
55 recovery-grade**.

## Public surfaces checked

| Surface | Verdict |
| --- | --- |
| README experimental banner + lifecycle badge | OK (D-41) |
| README "not on CRAN yet" / CRAN target 0.7.0 | OK (D-86 / D-125) |
| README "built from 0.5.0 development version" | **FIXED** → 0.6.0 development cycle |
| NEWS 0.6.0: 135-trace + D-117 boundary warning | OK / honest |
| `?confint` Boundary intervals section | OK |
| `cran-comments.md` | **REFRESHED** (was stale vs post-#930 evidence) |
| No unqualified "CRAN ready" / "on CRAN" | OK |

## Overclaim search

No live claim that D-117 PASS was reinstated. No claim that WITHHOLD cells were
promoted. Interval_feasible is not conflated with coverage/`supported`.

## Discharge (plan approval)

Approving the 0.7 CRAN ultra-plan discharges D-93/D-117 for readiness work:
profile RE-SD intervals + `profile.boundary` warning are the honest 0.7.0
position; the PASS claim remains withheld. Upload remains a separate owner word.
