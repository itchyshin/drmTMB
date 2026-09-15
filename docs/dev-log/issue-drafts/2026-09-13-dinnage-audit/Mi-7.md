TITLE: [Dinnage audit Mi-7] The ordinal guard tests for an ordered factor, so an integer-coded response bypasses semantic-ordering validation
LABELS: audit-dinnage, documentation, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Mi-7; severity minor).
Supporting working: `as.integer(Sat)` fit compared against the ordered-factor fit, and against a
scrambled integer coding.

## What Russell found
`as.integer(Sat)` fits and returns coefficients identical to the ordered-factor fit at 0.00e+00, and a
scrambled coding gives `mu:x = 0.54` against a truth of 1.0. Interface exposure, not a hole: drmTMB's own
error message names that route as supported ("Use `ordered(y)` or integer category scores 1, 2, ..., K"),
and no package can detect that an integer ordering is semantically wrong.

## Where (at 945da24f)
`R/drmTMB.R` (ordinal validation).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `prepare_ordinal_response()` (`R/drmTMB.R:17918-17940`) branches on `is.ordered(y)`; when FALSE
and `y` is a plain unordered factor it aborts ("Ordinal models require an ordered response ... Use
`ordered({response})` or integer category scores 1, 2, ..., K"), but when `y` is numeric/integer it falls
through to `validate_ordinal_codes()` with no check that the numeric coding reflects the user's intended
category order -- any monotonic-looking integer sequence is accepted at face value. `git log --oneline
945da24f..HEAD -- R/drmTMB.R` (grep-filtered to `prepare_ordinal_response`) shows no commit adding
semantic-order validation. No existing-issue match: `gh issue list --search "ordinal"` returns
capability-twin and feature issues (e.g. #966, #1280), none about this specific interface gap.

## Proposed fix (Russell's, if stated)
"Interface note only" -- Russell frames this as a documented, unavoidable ambiguity rather than a code
defect, since no package can validate a user's intended ordering from raw integers.

## Acceptance
- [ ] `?cumulative_logit` (or the relevant ordinal family doc) states explicitly that integer-coded
      responses are accepted at face value with no semantic-order check, so a scrambled coding fits
      silently
- [ ] NEWS.md entry crediting the report
