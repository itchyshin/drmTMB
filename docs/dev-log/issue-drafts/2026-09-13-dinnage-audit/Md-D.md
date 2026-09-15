TITLE: [Dinnage audit Md-D] mi() is silently discarded on every non-mu formula
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-D; severity moderate).
Supporting working: none cited beyond the direct formula comparison.

## What Russell found
The package has seven formula markers that must be rejected outside the mean
submodel. `mi()` is not one of them: `mi <- function(x) x` is an identity stub
(its six sibling markers are `invisible(NULL)`), and `"mi"` is absent from the
non-mu marker blocklist. `sigma ~ mi(z)` gives a bit-identical logLik to
`sigma ~ z`, with every check green.

## Where (at 945da24f)
`R/drmTMB.R:9788`, the `mi` stub definition.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `mi <- function(x) x` is still the identity stub at
R/formula-markers.R:44-46, unlike its siblings `meta_V()`, `meta_known_V()`,
and `gr()` (R/formula-markers.R:16-18, 55-59, 91-96), which all return
`invisible(NULL)`. The non-mu blocklist, `drm_reject_phase1_terms()` at
R/drmTMB.R:10388-10391, is `unsupported <- c("|", "meta_known_V", "meta_V",
"gr", "phylo", "spatial")` (plus `"offset"` when not allowed) — `"mi"` is
absent. This function is called for `sigma` (R/drmTMB.R:4027) and every other
non-mu `dpar` across the family builders, so `sigma ~ mi(z)` still passes
unblocked and `mi(z)` still evaluates as the identity, reproducing the
bit-identical-logLik behaviour reported. A narrower guard has since been added
for one specific case — `zi ~ mi(x)` is now rejected when `mu` also uses `mi()`
in the Poisson-response route (R/drmTMB.R:8084-8090, "Zero-inflated Poisson
cannot carry `mi` on `zi`") — but this does not cover the general
non-mu-formula case Russell describes (e.g. plain `sigma ~ mi(z)` on a Gaussian
fit).

## Proposed fix (Russell's, if stated)
One word on the blocklist (add `"mi"`), plus the `invisible(NULL)` stub.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
