TITLE: [Dinnage audit UX-1] `print(ck[ck$status != "ok", ])` prints `<drm_check: 0 checks>` -- a subset of a diagnostic table looks like a complete one
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §7.2, Appendix A row UX-1; severity moderate
per Appendix A's 🟡).
Supporting working: one of nineteen documentation-only first-contact runs.

## What Russell found
`print(ck[ck$status != "ok", ])` on a `drm_check` object prints `<drm_check: 0 checks>` when every row is
`ok`. The run **briefly believed `check_drm()` had returned an empty table with `ok = TRUE`** -- which
would have been a serious finding. It was a subset printed by the class's summary line, which counts
`nrow(x)` without noticing that `x` is a filtered subset, not the full check table.

## Where (at 945da24f)
`R/check.R` (`print.drm_check`).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `print.drm_check()` (`R/check.R:345-355`) opens with `cli::cli_text("<drm_check: {nrow(x)}
checks>")` and then a status-count line, both computed from `x` as given -- there is no check for whether
`x` still carries its original class-defining row count, no stored "total checks" attribute, and no
warning that the printed object is a subset. Subsetting a `drm_check` object with `[` uses the default
`data.frame` method (no custom `[.drm_check`), so `ck[ck$status != "ok", ]` silently returns a plain (or
still-classed, depending on subset semantics) object whose row count is whatever survived the filter.
`git log --oneline 945da24f..HEAD -- R/check.R` shows no commit adding a `[.drm_check` method or an
original-count attribute. No existing-issue match: `gh issue list --search "print.drm_check"` and
`--search "drm_check subset"` return nothing.

## Proposed fix (Russell's, if stated)
"Small" -- either a `[.drm_check` method that drops the class (so it prints as a plain data frame) or one
that preserves and reports the original total alongside the filtered count.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after: `print(ck[ck$status != "ok", ])` on a
      fully-`ok` check table does not read as "0 checks were run" (either drops the `drm_check` class on
      subset, or reports "0 of N checks shown")
- [ ] NEWS.md entry crediting the report
