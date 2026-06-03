# After Task: Missing Data Article

## Goal

Add a user-facing article that explains the newly fitted missing-data routes
without widening the implementation surface.

## Implemented

`vignettes/missing-data.Rmd` now explains:

- default complete-case behaviour through `miss_control()`;
- univariate Gaussian response masks with original-row accounting;
- bivariate Gaussian partial-response rows and the `rho12` complete-pair
  warning;
- one numeric `mi()` predictor model with fixed, grouped, or structured
  Gaussian covariate models;
- `fit$missing_data` metadata; and
- `imputed()` conditional-mode summaries.

`_pkgdown.yml` lists the article under `Start Here` and the Model Guides
navbar as "Handling missing data".

## Mathematical Contract

The article states the same fitted contracts as the implementation and design
note: missing univariate responses contribute
`I_i log p(y_i | mu_i, sigma_i)`, bivariate partial rows use bivariate or
marginal Gaussian row contributions according to the observed response pattern,
and missing predictors are latent quantities in a joint Gaussian
response/predictor likelihood integrated by TMB's Laplace approximation.

## Files Changed

- `vignettes/missing-data.Rmd`
- `_pkgdown.yml`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-missing-data-article.md`

No runtime code changed.

## Checks Run

```sh
Rscript -e "devtools::load_all(); rmarkdown::render('vignettes/missing-data.Rmd', output_dir = tempdir(), quiet = TRUE, envir = globalenv())"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::load_all(); pkgdown::build_article('missing-data', new_process = FALSE)"
git diff --check
```

Results:

- `rmarkdown::render()` completed successfully against the development package.
- `pkgdown::check_pkgdown()` reported no problems.
- `pkgdown::build_article('missing-data', new_process = FALSE)` wrote the
  pkgdown article page successfully.
- `git diff --check` found no whitespace errors.

## Tests Of The Tests

This was documentation-only. The executable article chunks fit the supported
univariate response-mask, bivariate response-mask, and fixed-effect
missing-predictor routes. The article also includes non-evaluated grouped and
structured predictor-model syntax so the reader sees the fitted surface without
forcing every example to run.

## Consistency Audit

Stale-wording scan:

```sh
rg -n "miss_control|mi\\(|imputed|multiple imputation|measurement-error|missing response|missing predictor" vignettes/missing-data.Rmd _pkgdown.yml docs/design/149-missing-data-design.md docs/dev-log/known-limitations.md NEWS.md README.md ROADMAP.md
```

The scan confirmed that the article uses implemented syntax and keeps
multiple-imputation, measurement-error, and unsupported predictor-model
boundaries explicit. NEWS and the design note already describe the fitted
missing-data surface.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "missing data article" --limit 20
gh issue list --repo itchyshin/drmTMB --search "miss_control imputed vignette" --limit 20
```

The first search returned only issue `#58`, the broad visualization tracker,
which does not need an update for this missing-data article. The second search
returned no matching open issues.

## What Did Not Go Smoothly

A plain `rmarkdown::render()` and default `pkgdown::build_article()` picked up
an older installed `drmTMB` without `miss_control()`. Rendering with
`devtools::load_all()` and building the article in-process validated the article
against the current checkout without installing over the user's library.

## Team Learning

For articles written immediately after adding new exports, validate examples
against the development checkout explicitly. Otherwise local pkgdown runs may
silently use an older installed package and report a false missing-export
failure.

## Known Limitations

The article documents that EM/profile/REML engines, dense known-`V`
partial-response slicing, multiple missing predictors, non-Gaussian predictor
models, response imputation summaries, simulated imputations, multiple-
imputation pooling, and measurement-error models remain outside the current
missing-data surface.

## Next Actions

The next documentation polish step is a rendered-site visual pass after the
larger mixed dirty worktree is split or committed. The next statistical step is
a small simulation-recovery article or report for MD3a/MD3b/MD4.
