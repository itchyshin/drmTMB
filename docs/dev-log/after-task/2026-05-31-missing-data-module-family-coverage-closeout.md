# After Task: Missing Data Module Family Coverage Closeout

## Goal

Finish the current missing-data module by auditing missing-predictor family
coverage, checking related `gllvmTMB` and `glmmTMB` behaviour, improving the
missing-data article, and rerunning the relevant verification gates.

## Implemented

No new likelihood route was added in this closeout pass. The work consolidated
the module-level contract after the earlier MD slices: `drmTMB` now supports
missing Gaussian response masks and one `mi()` missing predictor at a time in a
univariate Gaussian location model. The Gaussian missing-predictor route may be
fixed-effect, grouped, or structured; the family-aware non-Gaussian
missing-predictor routes in this closeout are fixed-effect.

The audited missing-predictor families are Gaussian, Bernoulli/logit, ordered
categorical, unordered categorical, strict beta, zero-one beta, beta-binomial
with known trials, Poisson, NB2, zero-truncated NB2, lognormal, Gamma, and
Tweedie.

## Mathematical Contract

For missing responses, `observed_y_i = 0` gates the Gaussian response
likelihood so retained missing-response rows contribute zero response
likelihood while preserving original-row accounting.

For a missing predictor `x_i`, the response model contains `mi(x)`, the
predictor model is supplied through `impute = list(x = impute_model(...))`,
and the likelihood integrates or sums over the predictor support:

```text
L_i = integral p(y_i | x_i, beta, sigma) ^ observed_y_i
             p(x_i | alpha, theta_x) dx_i
```

For discrete predictors, the integral is a finite sum over the allowed states.
For positive or semi-continuous predictors, the implementation uses the
family-specific quadrature or deterministic support described in
`docs/design/03-likelihoods.md`.

## Files Changed

- `R/drmTMB.R` and `R/missing-data.R`: roxygen wording now says the current
  missing-predictor contract is one `mi()` missing predictor at a time in a
  univariate Gaussian location model, not one Gaussian predictor.
- `vignettes/missing-data.Rmd`: adds a family-choice table and clarifies that
  `drm_formula()` belongs in the fitted model while `impute` holds predictor
  model formulas or `impute_model()` objects with explicit families.
- `pkgdown-site/articles/missing-data.html`: rebuilt from the article source.
- `docs/design/149-missing-data-design.md`: records the consolidated
  family-coverage claim and remaining boundaries, with historical staged
  claims labelled as historical checkpoints.
- `docs/design/03-likelihoods.md`: removes stale language that count
  predictors still belonged to a later missing-data slice.
- `docs/dev-log/check-log.md`: records the module-level audit, issue audit,
  and verification evidence.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); rmarkdown::render('vignettes/missing-data.Rmd', output_dir = 'pkgdown-site/articles', output_file = 'missing-data.html', quiet = FALSE)"
Rscript -e "devtools::load_all(); devtools::test(filter = 'missing-predictor')"
Rscript -e "pkgdown::check_pkgdown()"
air format --check R/drmTMB.R R/missing-data.R
git diff --check
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE, quiet = FALSE)"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Results:

- `devtools::document()` passed and regenerated `man/drmTMB.Rd` and
  `man/miss_control.Rd`.
- `rmarkdown::render()` completed 39 chunks and wrote the article HTML.
- `devtools::test(filter = 'missing-predictor')` passed with 376 expectations.
- `pkgdown::build_article("missing-data")` completed.
- The full `devtools::test()` suite passed with 9,077 expectations, no
  failures, warnings, or skips.
- `pkgdown::check_pkgdown()`, `air format --check`, and `git diff --check`
  passed.

## Tests Of The Tests

The missing-predictor tests cover each supported family route and include
independent likelihood recomputations, response-mask composition checks,
`imputed()` summaries, and malformed-input failures. The family routes are
therefore tested as likelihood contributions, not only as parser acceptance.

## Consistency Audit

The closeout stale-wording scan was:

```sh
rg -n 'one univariate Gaussian `mi\(\)` predictor|one univariate Gaussian mi\(\) predictor|missing predictors still require explicit future|count predictors, multiple missing predictors|beta/proportion, count|Poisson count predictors belong to the later MD7b slice' vignettes/missing-data.Rmd pkgdown-site/articles/missing-data.html R/drmTMB.R R/missing-data.R man/drmTMB.Rd man/miss_control.Rd NEWS.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md
```

It returned no matches after the likelihood-design wording was corrected.

Local `gllvmTMB` shares the main vocabulary but is organized around
multivariate per-unit response masking and a different missing-predictor lane.
Installed `glmmTMB` uses standard `na.action` row-dropping behaviour rather
than an in-likelihood `mi()` predictor mechanism.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "missing predictor family" --limit 20
gh issue list --repo itchyshin/drmTMB --search "missing data article" --limit 20
gh issue list --repo itchyshin/drmTMB --search "mi impute_model" --limit 20
```

The first search returned only #436, the broad Phase 6c sprint issue. The
second returned only #58, an older visualization/pkgdown issue. The third
returned no issue rows. No issue was changed because none of the hits was a
specific missing-data family-coverage tracker.

## What Did Not Go Smoothly

The main risk was stale prose. Earlier slices were correct when written, but
the module-level article and likelihood notes needed a final pass after the
count, proportion, positive, and semi-continuous predictor routes landed.

## Team Learning

The family table in the article is now the best public entry point for applied
users. Future missing-data additions should update that table first, then keep
the design docs, tests, and `fit$missing_data` metadata in sync.

## Known Limitations

The current missing-predictor module handles one `mi()` predictor at a time in a
univariate Gaussian location model. Gaussian missing predictors may use
fixed-effect, grouped, or structured predictor models; family-aware
non-Gaussian missing predictors are fixed-effect. Multiple missing predictors,
grouped or structured non-Gaussian predictor models, transformed or interacted
`mi()` terms, non-Gaussian response routes beyond the separately audited MD9a
Poisson-binary slice, hurdle count predictor models, EM/profile engines, REML,
simulation-based imputed summaries, response imputation helpers,
measurement-error models, and pigauto interoperability remain future work.

## Next Actions

Open a separate design slice before implementing multiple missing predictors or
random-effect predictor models. Those features require an explicit joint
predictor-model contract rather than more family-by-family accumulation.
