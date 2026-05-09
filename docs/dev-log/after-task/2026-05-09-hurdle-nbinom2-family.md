# After Task: Hurdle NB2 Family Component

## Goal

Implement fixed-effect hurdle negative-binomial 2 models without adding a
separate `hurdle_nbinom2()` constructor. The public grammar is
`family = truncated_nbinom2()` plus `hu ~ predictors`.

## Implemented

- `truncated_nbinom2()` still fits positive-only zero-truncated NB2 models when
  no `hu` formula is supplied.
- Adding a one-sided `hu ~ ...` formula fits a hurdle NB2 model with
  non-negative integer responses and at least one positive count.
- TMB `model_type = 12` evaluates the hurdle likelihood.
- Public coefficient, prediction, and summary blocks expose the hurdle
  probability as `hu`.
- `simulate()`, `fitted()`, `residuals()`, `sigma()`, `print()`, and the
  family-link helper understand the new model type.
- Tests cover simulation recovery, independent likelihood agreement,
  response-scale methods, complete-case filtering, Poisson-limit behaviour, and
  malformed inputs.
- README, NEWS, ROADMAP, design docs, vignettes, known limitations, source map,
  testing guide, and generated Rd files now describe hurdle NB2 as implemented.

## Mathematical Contract

For observation `i`:

```text
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
logit(hu_i) = X_hu[i, ] beta_hu
size_i = 1 / sigma_i^2
Z_i = 1 - Pr_NB2(0 | mu_i, size_i)

Pr(y_i = 0) = hu_i
Pr(y_i = k > 0) = (1 - hu_i) Pr_NB2(k | mu_i, size_i) / Z_i
E[y_i] = (1 - hu_i) mu_i / Z_i
```

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat, sigma ~ treatment, hu ~ survey_method),
  family = truncated_nbinom2(),
  data = dat
)
```

`predict(fit, dpar = "mu")` returns the untruncated NB2 component mean.
`predict(fit, dpar = "hu")` returns the hurdle-zero probability. `fitted(fit)`
returns the unconditional response mean.

## Files Changed

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `R/methods.R`
- `R/family.R`
- `tests/testthat/test-hurdle-nbinom2.R`
- `tests/testthat/test-family-link-contract.R`
- `tests/testthat/test-truncated-nbinom2-location-scale.R`
- `DESCRIPTION`
- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/testing-likelihoods.Rmd`
- generated `man/*.Rd` files for changed roxygen topics

## Checks Run

- `Rscript -e "devtools::document(); devtools::test(filter = 'hurdle-nbinom2|truncated-nbinom2|family-link-contract')"`: 166 passed.
- `air format .`: failed because `air` is not installed locally.
- `Rscript -e "devtools::test(filter = 'nbinom2|zi-nbinom2')"`: 198 passed.
- `git diff --check`: clean.
- `Rscript -e "devtools::test()"`: 1161 passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: completed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found after site build.
- `Rscript -e "devtools::check()"`: 0 errors, 0 warnings, 0 notes.

Stale wording scans:

```sh
rg -n 'hurdle NB2.*planned|hu ~.*Planned|Hurdle syntax.*planned|hurdle components.*later|hurdle count models.*planned|Next family sequence: hurdle|add hurdle NB2|hurdle models using .*remain|hurdle.*later phase|rejects `hu`' README.md ROADMAP.md NEWS.md DESCRIPTION docs/design vignettes R tests man
rg -n 'model_type = 12|hu ~|hurdle-zero|hurdle_nbinom2|Hurdle NB2 models are implemented' pkgdown-site/articles pkgdown-site/reference pkgdown-site/index.html pkgdown-site/news/index.html
```

The first scan found no active source documentation still treating hurdle NB2
as planned. A broader generated-site scan produced a false-positive DESCRIPTION
match because the generated meta description correctly says hurdle count models
are implemented and skewness/additional response families remain later phases.

## Tests Of The Tests

- The likelihood test compares fitted `logLik()` to an independent
  `stats::dnbinom()` calculation.
- The Poisson-limit test fixes `sigma` near zero and compares against a
  hand-coded hurdle zero-truncated Poisson likelihood.
- The method test independently reconstructs `fitted()` and Pearson residuals.
- The malformed-input test checks unsupported combinations and invalid
  responses, including `zi + hu`, `hu ~ 0`, random effects, `sd(id)`,
  `meta_known_V()`, `mvbind()`, `cbind()`, all-zero responses, negative counts,
  and noninteger counts.

## Consistency Audit

- Formula grammar now lists `hu ~ ...` with `truncated_nbinom2()` as
  implemented.
- Likelihood design now includes `model_type = 12` and the hurdle equations.
- The distribution-family article moved hurdle NB2 out of the planned section.
- The source map includes the R builder, TMB branch, tests, and docs for the
  hurdle path.
- NEWS and README describe `fitted()` as the unconditional hurdle response
  mean, while `predict(mu)` remains the untruncated NB2 component mean.
- Known limitations now say only hurdle extensions beyond fixed-effect
  univariate NB2 remain planned.

## What Did Not Go Smoothly

- The local `air` formatter is still unavailable, so formatting relied on
  `git diff --check`, tests, documentation generation, and manual inspection.
- The internal TMB branch reuses the existing `X_zi`/`beta_zi` parameter slot
  for the hurdle probability. Public R output consistently renames this to
  `hu`, but a later internal cleanup could add explicit `X_hu`/`beta_hu`
  fields for readability.

## Team Learning

- Hurdle and zero-inflated models need repeated wording checks because both
  involve zeros but imply different data-generating mechanisms.
- Extractor semantics are part of the likelihood contract: `predict(mu)` and
  `fitted()` intentionally differ for truncated and hurdle models.
- Future family additions should update `vignettes/source-map.Rmd` and
  generated pkgdown pages before the after-task report, not as a last-minute
  sweep.

## Known Limitations

- Fixed-effect, univariate NB2 only.
- No hurdle random effects, known sampling covariance, phylogenetic/spatial
  terms, bivariate count models, or mixed composed count families yet.
- No separate `hurdle_nbinom2()` constructor by design.

## Next Actions

- Consider univariate ordinal models next, unless a stronger ecology/evolution
  example argues for denominator-aware beta-binomial counts first.
- Add or install a formatter so the `air format .` step becomes enforceable.
- If hurdle internals are revisited, consider explicit C++/R names for
  `beta_hu` instead of reusing the zero-probability slot.
