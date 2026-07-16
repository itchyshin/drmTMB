# After Task: Beta phylogenetic q1 pilot abort

## 1. Goal

Test whether one exact ML univariate `beta()` cell can support
`point_fit_recovery`: fixed effects in `mu` and family `sigma`, plus one
unlabelled intercept-only `phylo(1 | spp_id, tree = tree)` location effect with
a constant latent phylogenetic SD. PR 2 direct-SD regression was conditional on
this prerequisite passing and merging separately.

## 2. Implemented

The branch admits only the exact PR 1 syntax and rejects labels, structured
slopes, phylogenetic family-`sigma` effects, ordinary-plus-phylogenetic random
effects, REML, and neighbouring families. Prediction and extraction helpers
recognize the admitted Beta location effect. This implementation remains
branch-only because its recovery gate failed; no capability claim was added.

## 3. Mathematical Contract

For observation `i` in species `s(i)`, the tested model is

```text
y_i | a ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
logit(mu_i) = beta_0 + beta_x x_i + a_s(i)
log(sigma_i) = gamma_0 + gamma_x x_i
phi_i = sigma_i^(-2)
a_tip ~ Normal(0, tau^2 A)
```

Family `sigma` controls conditional Beta precision through
`phi = sigma^(-2)`. Latent `tau` is the constant SD of the phylogenetic
location effect. Tests and prose keep these parameters separate. PR 2's
`sd(spp_id, level = "phylogenetic") ~ 1 + x` target was not implemented.

## 3a. Decisions and Rejected Alternatives

The predeclared abort-only pilot stopped the 1,200-attempt certification after
reproducing the mandatory moderate-tree mean log-latent-SD failure. The pooled
rule also requires a new equal-sized block bias of at least `+0.046998`, while
the disjoint pilot was `-0.2214`. Noether, Fisher, and Rose independently
returned STOP.

The team rejected post-result raw-SD rescoring, relaxing the absolute `0.10`
gate, dropping `g = 256`, treating the pilot as certification evidence, opening
a diagnostic-only feature PR, or starting PR 2 without a recovered constant-SD
prerequisite. Any high-information or estimator-method redesign requires a new
maintainer-approved contract.

## 4. Files Touched

- `R/drmTMB.R` and `R/methods.R`: narrow Beta q1 admission and helper routing.
- `tests/testthat/test-beta-location-scale.R`: independent likelihood, joint
  NLL, gradient, prediction, extraction, and rejection tests.
- `tools/run-beta-phylo-q1-recovery.R` and its runner tests: retained-
  denominator recovery, disjoint seed schedules, frozen complete-DGP RNG,
  source/artifact authentication, and pooled conflict handling.
- `docs/dev-log/2026-07-16-beta-phylo-q1-pr1-symbolic-alignment.md`: equation,
  R syntax, implementation, and estimand alignment.
- Three retained evidence blocks and the disjoint smoke/pilot artifacts under
  `docs/dev-log/simulation-artifacts/`.

## 5. Checks Run

- Focused Beta, runner, and estimator-conformance gate: 307 expectations
  passed.
- Runner-only fail-closed gate: 54 expectations passed.
- Clean design-only provenance audit: 19/19 rows passed.
- Local smoke: 3/3 convergence code zero, 3/3 `pdHess = TRUE`, no warnings or
  boundaries.
- Totoro smoke: the same mechanical result; design, provenance, seed audit,
  and run provenance match the local run byte for byte.
- Totoro pilot: 30/30 convergence code zero and `pdHess = TRUE`, no warnings or
  boundaries; all fixed-slope and RMSE gates passed.
- `git diff --check` passed outside verbatim `sessionInfo()` files.

The full package test, `R CMD check`, pkgdown build, and public documentation
refresh were not run because the recovery prerequisite stopped before PR 1
admission. These remain required only if Shinichi authorizes a new promotable
route.

## 6. Tests of the Tests

The fixed-parameter Beta likelihood is compared with independent `dbeta()` and
augmented-GMRF calculations, including a wrong-parameterization sentinel and
finite-difference gradients. Runner negatives exercise altered RNG kinds,
duplicate and overlapping seeds, missing or malformed designs, real source and
runner drift in a temporary Git repository, real copied-artifact tampering,
hidden-only output directories, frozen-design mismatch, and pooled decision
conflicts.

## 7a. Issue Ledger

Read-only GitHub search found broad open issues #59, #491, and #710, but no
focused Beta phylogenetic q1 issue. No issue or PR was opened because the
branch failed its pre-PR recovery gate. The implementation branch remains
pushed for reviewable provenance, not publication.

## 8. Consistency Audit

Task-specific searches covered `beta` with `phylo`, `point_fit_recovery`,
`sd(spp_id`, family `sigma`, and log-`tau` across `README.md`, `ROADMAP.md`,
`NEWS.md`, `docs/dev-log/known-limitations.md`, formula grammar, design docs,
and vignettes. No public capability wording or ledger row claims this cell.
Historical notes remain intact; current design, disposition, artifact READMEs,
check log, and this report state HOLD/abort. Family `sigma` and latent `tau`
wording is stable.

The after-task audit did not update README, NEWS, roadmap, formula grammar,
pkgdown, or the capability ledger because the feature was not admitted. That
absence is intentional, not missing documentation.

## 9. What Did Not Go Smoothly

The first `m = 4` addendum differed from the `m = 2` master seed by one while
using additive per-cell offsets, causing 1,197/1,200 numeric seed overlaps.
Review then found that freezing the seed schedule did not initially freeze the
complete DGP RNG, and that a hidden-only output directory could bypass the
overwrite guard. Each defect was repaired and covered by a negative test before
new fits ran.

The statistical limitation persisted after those provenance repairs. The valid
earlier `m = 4, g = 256` mean log-`tau` bias was `-0.2470`; the disjoint pilot
was `-0.2214` (MCSE `0.0861`). Clean optimizer diagnostics show that more of the
same computation would measure the same finite-information limitation, not fix
an execution problem.

## 10. Known Residuals

This work does not establish Beta phylogenetic q1 `point_fit_recovery` over the
frozen moderate- and high-tree ladder. It does not support REML, q2/q4,
phylogenetic family-`sigma` effects, structured slopes, labels, hierarchical
`sd()` RHS effects, `zero_one_beta()`, missing data, external data, intervals,
coverage, or any all-family direct-SD claim. The high-information `g = 1024`
cell passed repeatedly, but narrowing the claim after seeing the result would
require a new approved and predeclared goal.

The branch-only implementation remains pushed and unmerged. Shinichi must
decide whether to revert it and retain only the negative documentation, or
authorize a separate redesign.

## 11. Team Learning

Seed independence requires auditing complete numeric seed sets, not comparing
master seeds. A reproducible seed also requires freezing the RNG algorithms for
the entire DGP, not only for schedule generation. Abort-only pilots need an
explicit decision role; here the pooled rule prevented a rerun-until-pass
interpretation and saved 1,200 unnecessary fits.

## 12. Cross-Product Coverage

`drmTMB` R/TMB was the sole implementation and evidence authority. No code,
claim, or comparator result was transferred to `DRM.jl`, `gllvmTMB`, or
`GLLVM.jl`; Julia remains optional and outside this stopped lane. Mission
Control records the abort and keeps PR 2 blocked. No pkgdown or public release
surface changed because the feature never reached admission.

This stopped arc does NOT cover Beta direct-SD regression, REML, penalties,
Julia engines, q2/q4 providers, phylogenetic family-`sigma` effects, structured
slopes, missing-data paths, posterior-tree aggregation, intervals, coverage,
pkgdown, or downstream package mirrors.

## 13. Next Actions

Stop on this branch. Do not launch the 1,200-attempt certification, open PR 1,
or begin PR 2. Shinichi must choose a new goal before further implementation or
compute. Evidence-valid options include abandoning/reverting the admission or
approving a separately predeclared high-information or estimator-method
redesign. Do not rescore raw `tau`, relax the `0.10` gate, drop `g = 256`, or
reinterpret the pilot as certification evidence within the current goal.
