# Plan vs actual — drmTMB 0.7.0 CRAN readiness (Melissa)

**Date:** 2026-08-07 · **Reconciler:** Melissa · **Arc:** 0.7.0 CRAN readiness
(`/goal` slice through `source-clean`) · **Branch:** `cursor/07-cran-readiness`

Material deviations only.

| # | Axis | Planned | Actual | Tag | Note |
|---|---|---|---|---|---|
| 1 | deliverable | Prove `source-clean`; STOP before upload | **done** — gate READY; no upload | — | Honoured. |
| 2 | version | Keep DESCRIPTION at 0.6.0 (D-86) | done | — | Honoured. |
| 3 | claim freeze | Honest reader surfaces + cran-comments | done at `c2b9d6cd6` | — | PR #931 path already on branch tip for claim-freeze. |
| 4 | tarball probe | One `--as-cran` freeze | **two probes** | **adaptive** | Probe 1 exposed top-level `LOOP/` (2 NOTEs). Fixed with `.Rbuildignore ^LOOP$`; Probe 2 = 1 NOTE. Correct fix, not scope creep. |
| 5 | rung honesty | Do not claim `tarball-clean` without clean-worktree commit + bound log | **held** — `clean_worktree: false`; claim stays `source-clean` | — | Honoured even though Probe 2 Status is green enough to tempt a higher claim. |
| 6 | fences | No AGHQ / missing-data / #858 / #893 / #869; no primary checkout | done | — | Honoured. |
| 7 | closeout | after-task + Melissa + LOOP + draft PR | this file + after-task + LOOP updated; draft PR owed on push | — | Honoured. |

**Drift: none.** The only adaptive step (second probe) was forced by Probe 1's LOOP NOTE and stayed inside the packaging fence.

**Highest proven rung:** `source-clean`.
**OPEN GATE:** CRAN upload (owner only).
**Do not:** bump to 0.7.0; upload; claim `tarball-clean` until `.Rbuildignore` is in a clean commit and the tarball is rebuilt from it.
