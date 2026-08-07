# After-task — useful-0.7 user-facing onboarding + honesty

**Date:** 2026-08-07  
**Lane:** `cursor/useful-07-user-facing` · worktree `~/local-scratch/worktrees/drmTMB-useful-07`  
**Contract:** Arc Card `scratchpad/2026-08-07-arc-useful-07-user-facing.md` (PR #940)  
**Reader:** applied ecology/evolution user in week one; release reader of NEWS/`?confint`

## Purpose

Land four first-week user-facing deliverables distinct from the packaging
ladder: default uncertainty freeze, onboarding spine, parseable capability
skim, and Ayumi-scale `se_group_sd` advice. No platform-clean, no upload, no
DESCRIPTION `0.7.0` bump, no Totoro, no ledger promotions.

## Arc 0 decision

**Thin new vignette** (`first-week-intervals.Rmd`, ≤~150 lines) rather than
only front-loading `model-workflow`. `model-workflow` already walks
`profile_targets()` / `confint` / `conf.status`, but it is too long for a
first-week spine and the D-117 “when not to trust” story lived mainly in
`?confint` Boundary intervals. Reuse surfaces stay linked from the new page.

## What landed

| Rung | Deliverable | Files |
| --- | --- | --- |
| R1 | Default uncertainty story (profile RE-SD; Wald FE; boundary warn; no nominal-coverage-everywhere) | `R/profile.R` → `man/confint.drmTMB.Rd`; `NEWS.md` unreleased notes (DESCRIPTION stays 0.6.0) |
| R2 | Onboarding path fit → `profile_targets()` → `confint(method="profile")` → `profile.boundary` → when not to trust | `vignettes/first-week-intervals.Rmd`; `_pkgdown.yml` Getting Started + navbar; `vignettes/drmTMB.Rmd` learning path |
| R3 | Parseable family × dpar × RE × interval-tier skim citing 2026-08-05 snapshot | `vignettes/capability-and-limits.Rmd` §Capability skim; `README.md` Start here links |
| R4 | Ayumi-scale `se_group_sd` default advice | `vignettes/large-data.Rmd`; learning-path token in `drmTMB.Rmd` |

## Verify

- `devtools::document()` regenerated `man/confint.drmTMB.Rd` with §Default uncertainty story.
- `pkgdown::check_pkgdown()` after `_pkgdown.yml` / article edits.
- Prose restates measured behaviour; no “CRAN ready”; no ledger promotions.
- Fences held: no `docs/dev-log/release/` edits; no
  `test-guard-branch-continuity.R`; DESCRIPTION Version remains 0.6.0.

## Not covered

- platform-clean / win-builder / R-hub / CRAN upload
- DESCRIPTION bump to 0.7.0
- AGHQ / Cox-Reid non-Gaussian REML corner (deferred post-submit)
- any capability-ledger regeneration or cell promotion

## Next

Hand to platform-clean owner (separate lane) or post-submit AGHQ corner as a
separate science arc. This lane STOPs at draft PR.
