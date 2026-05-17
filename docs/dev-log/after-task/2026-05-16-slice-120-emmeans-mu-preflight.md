# After Task: Slice 120 emmeans mu preflight

## Goal

Add one private eligibility gate for the first future `emmeans` basis path so
unsupported targets fail before any future `emm_basis.drmTMB()` method can
return a partly valid `emmGrid`.

## Implemented

`drm_emmeans_mu_basis()` now wraps `drm_fixed_effect_basis()` for the first
possible `emmeans` target. The helper is private and dependency-free. It
accepts only fixed-effect univariate `mu` targets, requires covariance, and
returns the Slice 119 basis object plus the requested `type`.

`drm_validate_emmeans_mu_target()` rejects non-`mu` `dpar`, unsupported model
types, ordinary random effects, structured effects, covariance-block random
effects, and random-effect scale models. Missing covariance is rejected by the
underlying fixed-effect basis helper.

This slice does not add `emmeans`, register S3 methods, implement
`recover_data.drmTMB()` or `emm_basis.drmTMB()`, or expose public EMM support.

## Mathematical Contract

The accepted path still targets the native fixed-effect linear predictor for
one `mu` formula:

```text
eta = X_mu beta_mu + offset_mu
```

The preflight gate does not define contrasts, slopes, marginal weights,
degrees of freedom, or a response-mean estimand. It only confirms that the
future basis path is allowed to use the fixed-effect `mu` basis and covariance
for a simple univariate fit.

## Files Changed

- `R/emmeans-preflight.R`
- `tests/testthat/test-emmeans-preflight.R`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/40-emmeans-interface-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-191004-codex-checkpoint.md`

## Checks Run

- `air format R/emmeans-preflight.R tests/testthat/test-emmeans-preflight.R ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md`
- `Rscript -e "devtools::test(filter = 'emmeans-preflight', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'emmeans-preflight|fixed-effect-basis|reference-grid-link-scale-contract|predict-parameters', reporter = 'summary')"`
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `rg -n 'Slice 120|drm_emmeans_mu_basis|first internal eligibility gate|fixed-effect univariate `mu`|before any future method could return an `emmGrid`|not public `emmeans`' ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site/ROADMAP.html`
- `rg -n 'exported `emmeans` method|implemented `emmeans`|emmeans support is implemented|public `emmeans` support|return an `emmGrid`.*implemented|contrast workflow|contrast API.*implemented|slope.*implemented' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/design/40-emmeans-interface-contract.md pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`
- `Rscript tools/codex-checkpoint.R --goal "Slice 120 emmeans mu preflight" --next "wait for Slice 119 PR #84 CI, merge when green, rebase Slice 120 onto origin/main, rerun post-rebase checks, commit, push, open PR"`

All checks passed. The stale-claim scan found only the intentional "not
exported" wording and unrelated existing slope-status text.

## Tests Of The Tests

The new tests cover one accepted fixed-effect Gaussian `mu` path and four
failure paths: requesting `sigma`, fitting without covariance, zero-inflated
Poisson, and ordinary Gaussian random effects. The failure cases are important
because the first future `emmeans` method should error before constructing an
`emmGrid` when the estimand or uncertainty contract is not explicit.

## Consistency Audit

`ROADMAP.md`, `docs/design/39-visualization-grammar.md`, and
`docs/design/40-emmeans-interface-contract.md` now describe Slice 120 as a
private preflight gate. The rendered roadmap contains the same wording after
`pkgdown::build_site()`.

No public reference topic, NEWS entry, or `_pkgdown.yml` change was added
because there is no user-facing function or method.

## What Did Not Go Smoothly

The main naming risk was making a private helper sound like public `emmeans`
support. The docs now use "private", "internal", "future", and "preflight" to
keep that boundary visible.

## Team Learning

Boole and Pat should keep adding explicit rejection tests before the first
public method appears. Grace should continue checking rendered docs and stale
claims because it is easy for a private `emmeans` helper to sound user-facing
once it appears in roadmap prose.

## Known Limitations

- No `recover_data.drmTMB()` or `emm_basis.drmTMB()` method exists yet.
- No `emmeans` dependency or conditional registration hook was added.
- Bivariate, zero-inflated, hurdle, ordinal expected-score, random-effect,
  structured-effect, contrast, slope, and interval-aware targets remain blocked
  until their algebra and tests are explicit.

## Next Actions

After Slice 119 PR #84 merges, rebase Slice 120 onto `origin/main`, rerun
post-rebase checks, and open a focused PR. The next slice can either add a
`recover_data()`-style model-frame preflight or start a direct
`emmeans::ref_grid()` comparison if the dependency decision is ready.
