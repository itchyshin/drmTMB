# After Task: Lane C C1 NB2 phylogenetic labelled q2 covariance

## 1. Goal

Implement exactly the ordinary-NB2 labelled phylogenetic intercept--slope
covariance route, then retain one approved local point-recovery receipt without
changing a capability status, interval surface, or another lane.

## 2. Implemented

`phylo(1 + x | p | species, tree = tree)` is now a live labelled q2 route only
for ordinary `nbinom2()` `mu` with fixed-effect `sigma`. The TMB penalty is the
joint \(Q^{-1}\otimes\Sigma\) density for two latent fields and reports two
SDs plus `cor(mu:(Intercept),mu:x | p | species)`. The retained 3-seed local
fixture passed its frozen technical point-recovery rule.

## 3a. Decisions and Rejected Alternatives

Kept a single same-dpar NB2--phylo q2 exception rather than relaxing all
labelled count terms. Rejected any reuse of Lane A association parameters as an
association feature, profile/interval code, a capability-ledger update, remote
compute, and expansion to the other 39 rows. A local pass is recorded as a
technical receipt, not a public capability promotion.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-count-structured-mu.R`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `tools/run-lane-c-c1-nb2-phylo-q2-local-recovery.R`
- `docs/dev-log/2026-07-28-lane-c-nb2-phylo-q2-ultra-plan.md`
- `docs/dev-log/implementation-recovery/2026-07-28-lane-c-c1-nb2-phylo-q2-local/README.md`
- `docs/dev-log/implementation-recovery/2026-07-28-lane-c-c1-nb2-phylo-q2-local/raw-attempts.tsv`
- `docs/dev-log/implementation-recovery/2026-07-28-lane-c-c1-nb2-phylo-q2-local/summary.tsv`
- `docs/dev-log/implementation-recovery/2026-07-28-lane-c-c1-nb2-phylo-q2-local/SOURCE-MANIFEST.sha256`
- `docs/dev-log/plan-actual/2026-07-28-lane-c-nb2-phylo-q2.md`
- this report

## 5. Checks Run

- `Rscript -e 'devtools::load_all(...); testthat::test_dir(..., filter = "count-structured-mu")'` — passed after the C1 tests were added.
- `Rscript tools/run-lane-c-c1-nb2-phylo-q2-local-recovery.R` — 3/3 retained local attempts, `PASS_POINT_RECOVERY_LOCAL`.
- `git diff --check` — passed.
- `Rscript -e 'invisible(parse("tools/run-lane-c-c1-nb2-phylo-q2-local-recovery.R"))'` — passed.
- `/Users/z3437171/shinichi-brain/tools/lane_preflight.sh .../drmTMB` — no Claude lane detected in its 12-hour window; weak evidence only.

## 6. Tests of the Tests

The dense oracle separately reconstructs the joint NB2 q2 prior and response
NLL. It would fail if the determinant term, cross-precision term, or SD scale
were wrong; it compares both the objective and central finite-difference
gradient to TMB. A distinct test requires exact `rho = 0` reduction to the
independent q-vector density and proves an interior nonzero `eta_cor_phylo`
changes the objective. Formula tests keep q1 labels, spatial labels, and
zero-inflated C1 syntax closed.

## 7a. Issue Ledger

Fixed the true C1 admission gap: the prior parser rejected the label, mapped
the correlation out, and applied two independent q-vector penalties. Deferred:
the four other count-q2 candidates and 35 other intake rows; no issue or ledger
status was changed by this arc.

## 8. Consistency Audit

Checked the count validator, covariance data builder, parameter map, correlation
splitter, q-pair naming, NB2 C++ branch, and existing independent structured
q-vector branch. The new data flag is set only for NB2 plus the exact labelled
same-`mu` q2 shape. The C++ independent loop remains the fallback for all other
shapes. Formula neighbours were tested as rejections.

## 9. What Did Not Go Smoothly

An initial patch was placed in a neighbouring model-type branch and was removed
before compilation. The focused tests also exposed a non-power-of-two balanced
tree fixture and formula arguments that must be object names; both test setup
errors were corrected. The local runner initially used a non-exported `sigma`
namespace reference and was corrected to `stats::sigma()` before the retained
run.

## 10. Known Residuals

This is one small local, three-attempt technical receipt, not a multi-design
campaign. It does not establish interval feasibility, coverage, public support,
or evidence for Poisson, spatial, animal, relmat, q4, scale-side, ordinary-RE,
multiple-slope, zero-inflated, or mismatched-tree/group forms. The record's
source SHA has a `-dirty` suffix because code was measured before its scoped
commit; the accompanying `SOURCE-MANIFEST.sha256` binds the exact candidate
R/C++/test/runner content.

## 11. Team Learning

Memory receipt: loaded the Lane C handover/C0 partition/C1 path map and the
`r-package-engineer` skill; lane preflight shaped the scope and confirmed only
weak foreign-lane evidence. The `route.py` lookup had no worktree manifest, so
the repository handovers remained the technical authority.

Golden Set: not in scope for this bounded new C1 route; the direct class check
was the count structured-q validator, map, penalty, extraction, and rejection
neighbours listed above.

## 12. Cross-Product Coverage

Covers: ordinary univariate `nbinom2()`, `mu`, one labelled phylogenetic
intercept--slope q2 block, fixed-effect `sigma`, named latent SDs/correlation,
focused local point recovery.

does NOT cover: Lane A `rho12`/association; Lane B `sd()`/clamps/profiles/
intervals/coverage; any public/default/API change; capability ledger/dashboard;
remote compute; bootstrap; other count-q2 providers; q4; zero inflation;
ordinary RE coexistence; scale-side structures; multiple slopes; or the other
39 intake rows.
