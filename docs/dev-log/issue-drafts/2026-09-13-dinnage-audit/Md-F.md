TITLE: [Dinnage audit Md-F] Capability table says 4 families reject mi(); all 4 fit
LABELS: audit-dinnage, documentation, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-F; severity moderate).
Supporting working: fits of `lognormal`, `gamma`, `student`, and `beta_binomial` responses with `mi()`.

## What Russell found
The published capability table is the package's credibility instrument. It says
four families reject `mi()` (`vignettes/capability-and-limits.Rmd:587-591` at
945da24f). All four fit — three with dedicated C++ kernels. "The code is right
and the ledger is stale."

## Where (at 945da24f)
`vignettes/capability-and-limits.Rmd:587-591`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT (table moved and re-worded, defect unchanged). The current table at
vignettes/capability-and-limits.Rmd:590-593 lists only `gaussian()`, and
`binomial()`/`poisson()`/`nbinom2()`/`beta()` (one binary predictor) as
supporting `mi()`, with "every other family" marked "-- (rejects)". But
`drm_build_lognormal_ls_spec`, `drm_build_gamma_ls_spec`,
`drm_build_student_ls_spec`, and `drm_build_beta_binomial_spec` (R/drmTMB.R:5206,
5561, 4586, 7106) each call `drm_prepare_gaussian_mi_setup()` and carry their own
one-binary-predictor `mi()` gate, e.g. R/drmTMB.R:5322-5328: "The first
lognormal-response `mi` slice supports one binary missing predictor" (matching
text exists for student at R/drmTMB.R:4682-4687, gamma at R/drmTMB.R:5666-5671,
beta_binomial at R/drmTMB.R:7192-7197). The vignette's "every other family
rejects" line is still false for these four.

## Related
Issue #962 ("missing-data: mi() likelihood wiring is absent for
Gamma/lognormal/student/beta_binomial/zi-* responses") was the original ask that
appears to have driven most of this wiring (kernel comments cite it directly,
e.g. "S6 A7 / #962" in src/drm_response_kernels.h) but remains open in the
tracker and does not mention the stale vignette table. Issue #1230
("distribution-families detailed sections say skew-normal/Tweedie REs are
planned...") is the same failure class (capability ledger contradicts the code)
for a different feature (random-effect support). Neither is a duplicate of this
finding; both are related context.

## Proposed fix (Russell's, if stated)
Update the table.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
