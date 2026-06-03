# After Task: Bivariate Q4 Location Source Gate

Supersession note: this report records the source-gate slice before the Phase
18 smoke/artifact lane existed. The later
`2026-06-02-bivariate-q4-location-smoke-artifact-lane.md` report adds the
`biv_gaussian_q4_location` smoke lane and keeps q6 at source-tested-only status.

## Goal

Open the smallest bivariate Gaussian route where baseline individual
differences and slope differences share one ordinary group-level location
covariance block: matching `(1 + x | p | id)` terms in `mu1` and `mu2`.

## Implemented

`biv_gaussian()` now detects matching labelled one-slope intercept-plus-slope
location terms in `mu1` and `mu2`, expands them into four location members, and
routes the block through the existing q > 2 covariance backend. The fitted
object reports four location SDs in `sdpars$mu`, six derived group-level
correlations in `corpars$re_cov`, rows in `corpairs()` and
`summary(fit)$covariance`, direct SD rows in `profile_targets()`, and the
existing q4 covariance diagnostic in `check_drm()`.

## Mathematical Contract

For each group, the latent location vector is

```text
(b_mu1_intercept, b_mu1_x, b_mu2_intercept, b_mu2_x)
```

with four positive SDs and a full 4 by 4 correlation matrix represented by the
existing Cholesky-style `theta_re_cov` parameterization. These are group-level
location effects. They are separate from the residual bivariate correlation
`rho12`, and they do not add random effects to `rho12`.

The four SDs are direct `log_sd_re_cov` profile targets. The six correlations
are derived unstructured-correlation rows, so interval methods report them as
derived-unavailable unless a later derived-interval method is designed and
tested.

## Files Changed

- `R/drmTMB.R`
- `R/profile.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/45-cross-dpar-correlation-gate.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/52-phase-18-bivariate-rho12-ademp.md`
- `docs/design/61-structural-parity-slices-83-140.md`
- `docs/design/63-implementation-map-slices-311-325.md`
- `docs/design/64-implementation-map-slices-326-340.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/144-phase6c-gaussian-random-slope-ademp.md`
- `docs/design/145-phase6c-bivariate-slope-ademp.md`
- `docs/design/145-phase6c-bivariate-slope-evidence-gate.md`
- `docs/design/146-phase6c-bivariate-slope-artifact-schema-audit.md`
- `docs/design/148-phase6c-random-slope-simulation-plan.md`
- `docs/design/151-phase6c-random-slope-tutorial-ledger.md`
- `docs/design/152-phase6c-random-slope-sprint-closeout.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/implementation-map.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/which-scale.Rmd`
- `docs/dev-log/after-task/2026-06-02-bivariate-q4-location-source-gate.md`

## Checks Run

```sh
air format R/drmTMB.R R/profile.R tests/testthat/test-biv-gaussian.R
Rscript -e "devtools::test(filter = 'biv-gaussian')"
Rscript -e "devtools::test(filter = 'profile-targets|check-drm|covariance-block-registry|gaussian-random-intercepts|phase18-gaussian-mu-random-slope')"
rg -n 'intercept-plus-slope q4|intercept-plus-slope bivariate blocks|broader bivariate random slopes|First future bivariate slope|\| q4 location slope \|.*Planned|q4 location-only slope block|intercept-plus-slope q=4 bivariate location blocks|intercept-plus-slope q=4 blocks' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes
rg -n 'matching one-slope q=4|one-slope intercept-plus-slope q=4|q=4 bivariate location|q4 location block|multiple-slope bivariate location|residual-scale slope blocks|all-four p8/q8|derived-unavailable' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes tests/testthat/test-biv-gaussian.R
git diff --check
```

Results:

- Formatter completed without errors.
- Focused bivariate tests returned 840 passes, no failures, warnings, or skips.
- The broader profile/diagnostic/registry/random-slope subset returned 1,569
  passes, no failures, warnings, or skips.
- The stale-planned scan returned no matches.
- The positive boundary/status scan returned expected hits in the synced docs,
  vignettes, NEWS, README, ROADMAP, and test guard.
- `git diff --check` passed after the final closeout edits.

Not run: full `devtools::test()`, `pkgdown::check_pkgdown()`, and
`devtools::check()`. No roxygen comments changed, so `devtools::document()` was
not needed.

## Tests Of The Tests

The new test simulates a four-member location block with intercept and slope
effects for both responses, fits the public formula, and checks the fitted
object through independent surfaces: optimizer convergence, random-effect
backend selection, `sdpars$mu`, `corpars$re_cov`, `corpairs()`,
`summary(fit)$covariance`, `profile_targets()`, `check_drm()`, random-effect
contribution, and `simulate()`. The malformed-input guard checks that two
location formulas with more than one slope still fail with an explicit
multiple-slope boundary.

## Consistency Audit

The status docs now distinguish three nearby routes:

- matching slope-only `mu1`/`mu2` blocks such as `(0 + x | p | id)`, which are
  fitted and artifact-ready;
- matching one-slope q4 location blocks such as `(1 + x | p | id)`, which are
  fitted and source-tested but do not yet have a Phase 18 artifact lane;
- multiple-slope bivariate location blocks, residual-scale slope blocks,
  random effects in `rho12`, and p8/q8 location-scale endpoints, which remain
  planned.

The final stale-wording scan checked README, ROADMAP, NEWS, design notes,
known-limitations, and vignette sources for old planned-language around
`intercept-plus-slope q4`, `broader bivariate random slopes`, and q4 location
slope rows. The remaining positive scan checks that the fitted/source-tested
claim and planned-neighbour boundaries are present.

## GitHub Issue Maintenance

Live issue audit:

- #440 and #446 are closed historical gates for the slope-only artifact lane
  and the random-slope simulation plan.
- #33 and #59 remain open. This source gate advances #33 and informs #59, but it
  should not close either issue because no artifact lane, recovery grid,
  coverage grid, power analysis, or comparator evidence was added.
- No GitHub comment was added from this local branch; update #33 after the work
  is committed or opened as a PR.

## What Did Not Go Smoothly

The first status pass left several stale reader-facing lines saying the
intercept-plus-slope q4 location route was still closed or planned. Those were
corrected across the Phase 18 workflow registry, bivariate-coscale article,
model map, implementation map, source map, which-scale article, and planning
ledgers.

## Team Learning

When a planned covariance cell becomes source-tested, update both the formal
support matrix and the tutorial boundary text in the same change. Otherwise a
new fitted route can remain invisible to readers even though the tests pass.

## Known Limitations

This task does not add multiple-slope location covariance, residual-scale
slope covariance, same-response location-scale slope covariance, p8/q8
all-endpoint covariance, predictor-dependent slope `corpair()` regression,
structured slope covariance, non-Gaussian bivariate covariance, or any new
operating-characteristic evidence.

## Next Actions

Add a Phase 18 artifact-lane preflight for this q4 location route before making
recovery, coverage, power, or timing claims.
