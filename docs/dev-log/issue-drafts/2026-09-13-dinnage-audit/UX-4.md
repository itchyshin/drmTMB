TITLE: [Dinnage audit UX-4] `confint(parm = "sigma:z")` accepts the compact label but returns `fixef:sigma:z`, so a name-based join silently returns `NA`
LABELS: audit-dinnage, documentation, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §7.2, Appendix A row UX-4; severity minor).
Supporting working: one first-contact run's parity comparison against metafor.

## What Russell found
`confint(parm = "sigma:z")` accepts the compact label but returns rows labelled `fixef:sigma:z`, so a
name-based join back onto `"sigma:z"` silently returns `NA`. Cost: **a whole parity run** -- a name-based
row match returned `NA` coverage for drmTMB while metafor's printed fine. Silent `NA`, not an error.

## Where (at 945da24f)
`R/profile.R` (`confint.drmTMB`), `man/confint.drmTMB.Rd`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `man/confint.drmTMB.Rd:561` documents this exact asymmetry as intentional input flexibility:
"Use names such as `fixef:mu:x` or compact labels such as `mu:x`." -- confint *accepts* both spellings for
input matching, but confirmed by inspection there is no corresponding normalization on **output**: the
returned `parm` column is not guaranteed to echo back the caller's own compact spelling, since the
function's internal target bookkeeping is built on the fully-qualified `fixef:`/`sigma:`-style labels.
`git log --oneline 945da24f..HEAD -- R/profile.R man/confint.drmTMB.Rd` shows no commit adding an
echo-caller's-spelling option or a documented Value-section caveat about this join hazard. No existing-
issue match: `gh issue list --search "confint parm"` returns performance issues, none about this
label-echo mismatch.

## Proposed fix (Russell's, if stated)
"Value section" -- document that the returned `parm` column may use fully-qualified labels even when a
compact label was supplied, so callers doing name-based joins know to normalize first.

## Acceptance
- [ ] `?confint.drmTMB`'s Value section states that the returned `parm` values are fully-qualified
      (`fixef:dpar:term`) regardless of the spelling supplied to `parm =`
- [ ] NEWS.md entry crediting the report
