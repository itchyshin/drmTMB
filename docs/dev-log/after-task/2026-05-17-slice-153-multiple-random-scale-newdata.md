# After Task: Slice 153 multiple random-effect scale newdata targets

## Goal

Pin direct-SD `newdata` validation when a fit has more than one random-effect
scale formula.

## Implemented

`predict(fit, dpar = "sd(id)", newdata = ...)` and
`predict(fit, dpar = "sd(site)", newdata = ...)` now have explicit regression
coverage in the same fitted model. The test fits a Gaussian model with
`sd(id) ~ w_id` and `sd(site) ~ w_site`, then checks that each requested `dpar`
validates its own predictor, ignores sibling-target extra columns, and names
the missing target-specific predictor.

NEWS, the Phase 17 roadmap, and
`docs/design/18-random-effect-scale-models.md` now describe the same
multiple-target `newdata` contract.

## Mathematical Contract

This slice does not change the direct-SD model:

```text
log(sd_id,g) = W_id,g alpha_id,
log(sd_site,h) = W_site,h alpha_site.
```

It records the target-specific prediction contract: the requested `dpar`
chooses the direct-SD formula, model frame, and required predictors used to
construct `W(newdata)`.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-153-multiple-random-scale-newdata.md`
- `tests/testthat/test-gaussian-random-effect-scale.R`

## Checks Run

- No-edit scout before the slice showed that `sd(id)` and `sd(site)` predictions
  each used their own `newdata` predictor, ignored the sibling predictor as an
  extra column, and errored for missing `w_site` with `dpar = "sd(site)"`.
- `air format NEWS.md ROADMAP.md docs/design/18-random-effect-scale-models.md tests/testthat/test-gaussian-random-effect-scale.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'fixed-effect-basis|gaussian-random-effect-scale', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 153 multiple-target wording found the
  expected entries in source files, tests, and rendered pkgdown NEWS/ROADMAP
  pages.
- Stale-claim scan for accidental random-effect scale `emmeans`, bivariate
  random-effect scale prediction, `sd_sigma*()` syntax, transformed-response
  support, or bivariate/multiple-target overclaims found no new false support
  claims; matches were existing spatial, profile-interval, Family B, or
  `sd_sigma1()` / `sd_sigma2()` guardrails.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-030256-codex-checkpoint.md`.

## Tests Of The Tests

The test combines two fitted direct-SD formulas in one model. It checks positive
prediction for both targets, equality when sibling-only extra columns are
removed, and failure when the requested target's own predictor is missing.

## Consistency Audit

The behavior was already routed through `drm_prepare_random_scale_newdata()` and
the requested target's fitted model frame. This slice makes that routing visible
in tests and public/design notes without changing formula grammar, likelihood
parameterization, fitted coefficients, or object structure.

## What Did Not Go Smoothly

Nothing material. The scout confirmed the intended target-specific behavior
before edits.

## Team Learning

Pat should keep target-specific missing-predictor messages concrete. Curie
should keep tests for multiple direct-SD formulas because they catch accidental
cross-target leakage. Rose should keep separating ordinary multiple direct-SD
targets from bivariate direct-SD surfaces and residual-scale `sd_sigma*()`
guardrails.

## Known Limitations

- This slice pins multiple direct-SD `newdata` validation for ordinary
  univariate Gaussian random-effect scale formulas.
- It does not add random-effect scale `emmeans`, bivariate random-effect scale
  prediction surfaces, empirical marginalisation, `sd_sigma*()` syntax,
  transformed-response support, or new random-effect scale model families.

## Next Actions

Continue the direct-SD audit toward row-level helpers and user-facing examples,
or pause this lane if the remaining work is better handled as tutorial polish.
