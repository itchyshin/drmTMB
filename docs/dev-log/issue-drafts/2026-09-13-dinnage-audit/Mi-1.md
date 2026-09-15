TITLE: [Dinnage audit Mi-1] `beta()` masks `base::beta()`
LABELS: audit-dinnage, bug, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Mi-1; severity minor).
Supporting working: two runs hit it independently.

## What Russell found
`beta(2, 3)` errors after `library(drmTMB)`, because drmTMB's `beta()` family constructor (0-argument)
masks `base::beta()` (2-argument, the Euler beta function). Every peer package renamed for exactly this
reason.

## Where (at 945da24f)
`R/families.R`, `NAMESPACE`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `beta <- function() {...}` is defined at `R/family.R:278` (file name drifted from `families.R`
to `family.R`) and exported at `NAMESPACE:118` (`export(beta)`). `beta(2, 3)` after `library(drmTMB)`
still resolves to drmTMB's 0-argument constructor rather than `base::beta`, and errors on unused
arguments. `git log --oneline 945da24f..HEAD -- R/family.R NAMESPACE` shows no rename commit. No
existing-issue match: `gh issue list --search "beta() mask"` and `--search "base::beta"` return nothing.

## Proposed fix (Russell's, if stated)
Rename (fix size: "rename"). Russell does not propose a specific replacement name.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after: `base::beta(2, 3)` works unqualified after
      `library(drmTMB)`
- [ ] NEWS.md entry crediting the report, noting the renamed export as a breaking change if applicable
