#1240

Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4 Minor, bundled in the "Also:" line and
Appendix A's "Mi-rest" row; severity minor).

Russell's independent evaluation hit this same defect: `anova.drmTMB()` always aborts with "likelihood-
ratio comparisons are not implemented for drmTMB fits," bundled among ten further minor papercuts in §4,
listed alongside items now filed separately as `docs/dev-log/issue-drafts/2026-09-13-dinnage-audit/
Mi-bundle.md`. No new information beyond what this issue already tracks; filed here only for
cross-evaluation attribution.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `anova.drmTMB()` (`R/methods.R:2708-2717`) is unchanged: `fits <- c(list(object), list(...))`,
an MSPL-specific abort, then unconditionally `cli::cli_abort("{.fn anova} likelihood-ratio comparisons are
not implemented for {.cls drmTMB} fits.")` for every other input.
