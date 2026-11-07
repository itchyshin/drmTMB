# After-task report: overnight SD-regression run, 2026-11-01 evening to 2026-11-02 morning

Reader: Shinichi, and the next agent on the general-sd-regression lane.

## 1. Goal

Continue the general predictor-dependent random-effect SD regression lane
unattended: admit more identifiable routes across Gaussian, Binomial, Poisson,
NB2 and Gamma on both engines, fix the CI failures on PR #1663, close the G1
contract-review conditions, and keep the evidence ledger reconciling. Interval
calibration (G5) stayed deferred throughout.

## 2. Implemented

Native TMB routes admitted, each with a drmTMB-independent oracle (dense
Laplace at the fitted parameters, or an exact Gaussian marginal), shuffled
levels and non-unit-diagonal kernels where structured, and refusal pins for
neighbours:

- Gamma: ordinary intercept plus animal, phylo, spatial or relmat intercept;
  ordinary `sd(g)` beside a structured intercept; slope-only phylo, spatial
  and relmat; joint `mu` plus `sigma` intercepts.
- Poisson and NB2: animal, relmat, phylo and spatial correlated q2 blocks
  (`R kron K` prior), labelled relmat q2; NB2 `phylo_interaction`; NB2 joint
  `mu` plus `sigma` intercepts (also same group).
- Binomial: phylo and spatial q2 with coefficient SDs.
- Gaussian: `sigma` structured intercepts; animal, phylo, relmat and spatial
  q2; `phylo_interaction` slope-only; ordinary q3 and q4 blocks with
  per-coefficient SDs (new C++).
- Zero-inflated Poisson: plain independent slope without `sd()`.
- `miss_control(response = "include")`: ordinary SD for Poisson, NB2, Gamma
  and Binomial; one structured intercept or slope-only term; the
  ordinary-plus-structured iid routes; animal q2. A wholly missing group keeps
  its latent field under the prior.
- `simulate(re.form = NA)` for the q2 routes (rho applied before the
  per-coefficient SD scaling).

Julia (DRModels.jl, branch `codex/general-sd-regression`, now `5ac051eed`):
the lane's long-uncommitted work was committed after a full suite run
(`8fee1ecfb`); NB2 animal now uses raw `A`; NB2 animal slope-only route and
simulator; Gaussian structured slope-only SD; bridge admission for Poisson
relmat slope, NB2 animal slope, Gaussian animal, relmat and spatial slope. R
bridge: the #1551 ordinary-SD fence reopened for `sd()`-bearing bars, the
selected-coefficient label echo fixed, and a coordinate row-order bug fixed
(named `coords` not in first-seen group order paired the wrong kernel rows).

Repairs and contracts: the 25 branch-caused `R CMD check` failures fixed (28
to 2, both environmental); `R/julia-simulate.R` committed; G1 conditions C1
to C7 closed (design rank check, selector contract and exact `predict(dpar=)`
matching, kernel scaling table, raw log SD reporting in every SD block,
`predict()` semantics, q2 route conditions, explicit SD registry lookup in
simulation); G0 universe gained phylo, relmat and spatial correlated-block
mechanisms (896 rows, no existing key changed).

## 3a. Decisions and Rejected Alternatives

- Model-15 CI gate: re-certification at tolerance 1e-9 was proposed and
  blocked twice by the permission system. It needs Shinichi's explicit yes;
  the lane did not route around it.
- Julia relmat K: DRModels.jl normalises relmat K to a correlation for
  Poisson, NB2 and Gamma while native uses it raw. Rather than change Julia
  behaviour without a decision, the R gate refuses non-unit-diagonal K for
  Julia Poisson relmat. Gaussian Julia relmat uses raw K. Needs a decision.
- Receipted test edits: rejected editing receipted tests casually; when
  unavoidable, receipts were refreshed by script with fresh runs.
- Ordinary q3 with `sd()` for Poisson and NB2: kept refused (no per-coefficient
  q>=3 C++ for those families yet).

## 4. Files Touched

drmTMB lane commits from `7309d3cd8` to `386543c70` on
`codex/general-sd-regression` (see `git log 8dcb17f81..386543c70 --stat`):
mainly `R/drmTMB.R`, `R/methods.R`, `R/julia-bridge.R`,
`R/julia-coefficient-labels.R`, `R/julia-simulate.R` (new), `src/drmTMB.cpp`,
`man/drmTMB.Rd`, `man/predict.drmTMB.Rd`, `man/simulate.drmTMB.Rd`,
`man/predict_parameters.Rd`, about 45 new test files, about 30 edited test
files, `NEWS.md`, `docs/design/01`, `02`, `03`, `18`, `capability-status.md`,
`docs/dev-log/known-limitations.md`, the evidence ledger, its summary,
`required-rows.tsv`, universe inputs and tool tests, about 40 new evidence
directories, `inst/extdata/env-skip-census.tsv`, the dashboard and Julia gate
TSVs, and after-task notes dated 2026-11-01 and 2026-11-02. DRModels.jl:
`src/*.jl` and `test/*.jl` in `8fee1ecfb` to `5ac051eed`.

## 5. Checks Run

- Full `R CMD check --as-cran` (no vignettes, `NOT_CRAN=true`) on Totoro:
  `7309d3cd8` FAIL 28; `53504dd39` FAIL 5; staged G1 tree FAIL 4;
  `95c8a58dc` FAIL 2 (PASS 37281; both environmental: no DRModels checkout,
  callr DESCRIPTION lookup in the Rcheck dir). `386543c70` FAIL 2 (PASS
  38364, same two environmental). `fe12743c8` FAIL 3 (PASS 38374): the two
  environmental plus the new restart test on Linux, where nlminb converges
  directly at gradient 2.6e-6 instead of stopping with false convergence; the
  final commit scopes that 1e-6 gradient assertion to the restart path (Mac
  11 pass, Totoro 10 pass).
- Focused test files after every merge (counts in each commit message).
- Live Julia: Poisson SD 30/0; b18 and b20 bridge files; every live file
  using `coords` after the row-order fix.
- DRModels.jl full suite (one process per file, 454 files) before `8fee1ecfb`.
- Reconciler passes at every commit since `d97caf070`; tool tests 39/39.

## 6. Tests of the Tests

Every new oracle test carries emulated-bug checks (swapped SD formulas,
misaligned levels, cov2cor kernels, dropped or sign-flipped rho, NA rows
scored as zero) that must move the oracle far beyond tolerance. Reviewers
mutated source (disabled the Julia fence exemption, reverted gates, removed
the rho mixing, disabled the coords rownames fix) and the tests failed as
intended.

## 7a. Issue Ledger

- Fixed: cross-family Julia bridge regression from `b87566680`; stale gate
  patterns; uncommitted `R/julia-simulate.R`; partial `predict(dpar=)`
  matching; clamp reporting split across SD blocks; coords row alignment on
  the Julia engine; NB2 include start values missing SD blocks.
- Open: model-15 CI gate (decision); Julia relmat K scaling (decision); two
  review of the nlminb false-convergence restart helper (shared optimizer
  code, `fe12743c8`), which cleared `test-julia-biv-q2-reml.R:259`; the
  `test-julia-tmb-parity.R:661` failure was a fixture data-generating
  mismatch, fixed.

## 8. Consistency Audit

Docs, NEWS and the milestone file were synced after each wave; stale
"not admitted" lines and refusal pins were swept when routes opened; the
env-skip census and the evidence ledger were regenerated or refreshed before
each commit once the staleness pattern was noticed.

## 9. What Did Not Go Smoothly

- Editing receipted test files broke ledger seals three times before a
  refresh script and a pre-commit reconciler run became routine.
- Broad `git add` commands twice staged files that do not belong (graft
  cache, the other lane's `active-lane-split.md`, a 25,000-file calibration
  folder); each was caught and unstaged before committing.
- Worktree isolation for workflow agents failed intermittently on the
  Dropbox checkout; private rsync copies replaced it.
- Totoro was saturated by other users early in the night; one verifier ran
  about 385 threads before `OMP_NUM_THREADS` was pinned everywhere.

## 10. Known Residuals

- PR #1663 CI still fails at the model-15 receipt gate until re-certified.
- No calibration, coverage or broad parity claim anywhere; most routes have
  one fixture and one seed.
- Ledger rows are all `unreviewed`; test files added after batch 18
  (missing-include, Gaussian q3, spatial q2, labelled relmat q2, G4
  semantics and others) have no receipt yet.
- Julia docs pages in DRModels.jl (`docs/src/*`) were not updated.
- Gaussian q3 marginal simulation and NB2 Julia relmat slope remain refused.

## 11. Team Learning

- Run the reconciler and regenerate the env-skip census before every commit
  in this lane.
- Stage explicit paths only; never `git add -A` on a directory in this tree.
- For a test that pins a refusal, prefer a new test file over editing a
  receipted one.
- Live Julia checks need `NOT_CRAN=true` or they skip silently and look green.

## 12. Cross-Product Coverage

Covered tonight: the five priority families on the native engine for ordinary,
animal, relmat, phylo, spatial and phylo_interaction providers, `mu` and
selected `sigma` endpoints, q1, q2 and Gaussian q3/q4, plus missing-response
include for the main count and Gamma routes. Cross-cutting flags: the
missing-response flag covers ordinary, single structured, iid-plus-structured,
slope-only and animal q2 routes for the count and Gamma families, and
Binomial ordinary; it does NOT cover Gaussian structured q2, Gaussian q3/q4,
zero-inflated, sigma-target or labelled routes. The engine flag (Julia) covers
the bridge routes listed in section 2; it does NOT cover the native routes
admitted tonight beyond those, REML, or simulation for Gaussian slope routes.
Aggregation and REML were not touched and this run does NOT cover them. Not covered: calibration (G5),
Julia counterparts for most native routes admitted tonight, mesh spatial,
bivariate SD routes, labelled phylo and spatial q2 for count families, NB2
`sigma`-side phylogenetic SD (held), and any family outside the five.
