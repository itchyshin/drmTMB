TITLE: [Dinnage audit Mi-2] `ranef()`/`fixef()` are drmTMB's own generics, so `library(glmmTMB); library(drmTMB)` breaks `ranef()`/`fixef()` on glmmTMB and lmerMod fits
LABELS: audit-dinnage, bug, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Mi-2; severity minor).
Supporting working: reproduced directly on main during this since-audit check (below).

## What Russell found
`ranef()`/`fixef()` are drmTMB's own generics rather than re-exported from `nlme`. Loading
`library(glmmTMB); library(drmTMB)` masks `nlme`'s (shared by `lme4`/`glmmTMB`) generic with drmTMB's own,
so `ranef(glmmTMB_fit)` fails with an error naming glmmTMB, sending the user to debug the wrong package.
`R/zzz.R`'s own comment identifies the convention (own generic must still dispatch on foreign classes) and
does not follow it for this direction.

## Where (at 945da24f)
`R/zzz.R`, `NAMESPACE`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT, freshly reproduced in this worktree. `R/zzz.R` now has `.onLoad()` -> `register_foreign_s3_methods()`
(lines 1-35) that registers `fixef.drmTMB`/`ranef.drmTMB` onto **`nlme`'s** generic, fixing the reverse
direction (a `drmTMB` fit failing under `nlme`'s generic when `nlme`/`glmmTMB` loads after drmTMB) -- but
it does nothing for Russell's direction. Reproduced directly: `library(glmmTMB); library(lme4);
pkgload::load_all("drmTMB")`, then `ranef(glmmTMB_fit)` -> `Error: no applicable method for 'ranef'
applied to an object of class "glmmTMB"`; same for `ranef(lmerMod_fit)` and `fixef(glmmTMB_fit)`. `git log
--oneline 945da24f..HEAD -- R/zzz.R` shows the `register_foreign_s3_methods()` addition, which addresses
only the direction not reported here. No existing-issue match: `gh issue list --search "ranef"` and
`--search "fixef"` return nothing on this masking direction.

## Proposed fix (Russell's, if stated)
"One NAMESPACE line" -- Russell's framing implies re-exporting `nlme::ranef`/`nlme::fixef` as the shared
generic (matching `lme4`/`glmmTMB`'s own convention) rather than declaring drmTMB's own, which is also
the direction `R/zzz.R`'s existing fix already leans toward for the other case.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after: with `glmmTMB`/`lme4` loaded before
      drmTMB, `ranef()` and `fixef()` on a `glmmTMB` or `lmerMod` fit succeed (not just on a `drmTMB` fit)
- [ ] NEWS.md entry crediting the report
