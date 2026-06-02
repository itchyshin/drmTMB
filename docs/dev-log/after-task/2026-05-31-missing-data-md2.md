# After Task: Missing Data MD2 Bivariate Gaussian Response Masks

## Goal

Extend the missing-data lane after MD1 so independent-observation bivariate
Gaussian models can retain rows with missing `y1`, missing `y2`, or both
responses missing, while keeping missing predictors, dense known-`V` slicing,
EM/REML, imputation summaries, and measurement-error models out of scope.

## Implemented

- Added MD2 bivariate missing-data metadata through `fit$missing_data`, including
  `observed_y1`, `observed_y2`, `response_pattern`, complete-pair,
  one-response, both-missing, and likelihood-row counts.
- Extended the bivariate Gaussian builder so `missing = miss_control(response =
  "include")` keeps partial-response rows after requiring complete predictors,
  grouping variables, and structured-effect inputs.
- Added TMB likelihood masks for independent bivariate Gaussian rows. Complete
  pairs use the bivariate Gaussian density with residual `rho12`; one-response
  rows use the relevant marginal Gaussian density; both-missing rows contribute
  zero response likelihood.
- Kept dense bivariate `meta_V(V = V)` partial-response rows rejected with a
  clear error because component-level covariance slicing is not implemented.
- Updated bivariate response and Pearson residuals so missing response cells are
  `NA`, and `y2`-only rows use marginal standardization.

## Mathematical Contract

For row `i`, MD2 uses `observed_y1_i` and `observed_y2_i` to choose the
likelihood contribution:

```text
both observed     -> p(y1_i, y2_i | mu1_i, mu2_i, sigma1_i, sigma2_i, rho12_i)
only y1 observed  -> p(y1_i | mu1_i, sigma1_i)
only y2 observed  -> p(y2_i | mu2_i, sigma2_i)
both missing      -> 1 on the likelihood scale, so zero log-likelihood
```

The marginal one-response densities do not contain `rho12`, so complete response
pairs remain the direct evidence for residual correlation. MD2 warns when the
complete-pair count is too small for the fitted `rho12` formula.

## Files Changed

- `R/drmTMB.R`
- `R/missing-data.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-missing-response-biv-gaussian.R`
- `tests/testthat/test-missing-data-control.R`
- `tests/testthat/test-phylo-utils.R`
- `docs/design/149-missing-data-design.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`
- `man/drmTMB.Rd`
- `man/miss_control.Rd`

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-data-control.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-missing-response-biv-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-biv-gaussian.R')"
Rscript -e "devtools::load_all(); testthat::test_file('tests/testthat/test-phylo-utils.R')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Results:

- `devtools::document()` completed.
- `test-missing-data-control.R`: 11 expectations, no failures.
- `test-missing-response-gaussian.R`: 32 expectations, no failures.
- `test-missing-response-biv-gaussian.R`: 45 expectations, no failures.
- `test-gaussian-location-scale.R`: 71 expectations and the existing CRAN skip,
  no failures.
- `test-biv-gaussian.R`: 718 expectations, no failures.
- `test-phylo-utils.R`: 79 expectations, no failures.
- `devtools::test()`: 8,699 expectations, no failures, warnings, or skips in the
  final summary.
- `pkgdown::check_pkgdown()`: no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

The new bivariate missing-response test failed before the main `model_type == 2`
TMB branch was masked: changing the internal sentinel from `0` to `1e6` changed
the log-likelihood, coefficients, gradient, and fitted values. After the fix,
the sentinel-invariance test passes. The test also compares the fitted
log-likelihood to an independent R calculation for complete-pair, `y1`-only,
`y2`-only, and both-missing row patterns.

## Consistency Audit

- `docs/design/149-missing-data-design.md` now records MD1 and MD2 as separate
  implemented boundaries.
- `docs/design/01-formula-grammar.md` lists univariate Gaussian and independent
  bivariate Gaussian `response = "include"` support separately.
- `docs/design/03-likelihoods.md` documents the bivariate observed-response
  mask equations and the dense known-`V` deferral.
- `NEWS.md`, `man/drmTMB.Rd`, and `man/miss_control.Rd` describe the fitted
  support without claiming missing predictors, dense known-`V` partial rows,
  EM/REML, imputation summaries, or measurement-error support.

Stale-wording searches:

```sh
rg -n "implemented only for univariate Gaussian|bivariate partial pairs|bivariate partial response pairs|Missing predictors, bivariate partial|partial pairs.*planned|univariate Gaussian response masks" R man NEWS.md docs/design vignettes README.md ROADMAP.md docs/dev-log/known-limitations.md
rg -n "response = \"include\"|partial-response|dense known.*V|observed_y1|observed_y2|both-missing|rho12.*complete" R man NEWS.md docs/design vignettes README.md ROADMAP.md docs/dev-log/known-limitations.md tests/testthat/test-missing-response-biv-gaussian.R
```

The first scan found only current univariate+bivariate support wording, the
intentional historical "After MD1" claim in the missing-data design note, and
unrelated non-missing-data univariate Gaussian boundaries. The second scan
confirmed that current claims preserve the dense known-`V` and missing-predictor
boundaries.

## GitHub Issue Maintenance

```sh
gh issue list --repo itchyshin/drmTMB --search "missing data miss_control response include" --limit 20
gh issue list --repo itchyshin/drmTMB --search "bivariate missing response partial y1 y2" --limit 20
```

Both searches returned no matching open issues, so no issue comment, new issue,
or closure was made.

## What Did Not Go Smoothly

The sentinel test caught a real implementation miss. The first C++ edit masked
the bivariate covariance-probe branch but not the main `model_type == 2` branch.
That left the sentinel visible to the fitted likelihood. The adversarial
sentinel test made the leak obvious and is now the main guard against repeating
that mistake.

## Team Learning

Curie and Gauss should treat sentinel-invariance tests as required for every
future response-mask route. Rose should keep asking for pattern-specific tests
whenever a likelihood branch has more than one observed-data pattern, because
the visually similar TMB branches are easy to patch unevenly.

## Known Limitations

- Missing predictors and `mi()` are not implemented.
- Dense bivariate known `meta_V(V = V)` partial-response rows are not
  implemented.
- EM/profile engines, REML, imputation summaries, and measurement-error models
  are not implemented.
- Mixed-response bivariate models, non-Gaussian response masks, and pigauto
  interoperability remain future work.

## Next Actions

The next missing-data implementation slice should be MD3a: one continuous
Gaussian missing predictor with a fixed-effect covariate model and no covariate
random-effect block. Keep MD3a separate from grouped covariate random effects,
factors, transformations, splines, non-Gaussian predictor models, and structured
imputation.
