# After Task: Reference Model-Fit Extractors

## Goal

Continue the comprehensive function/reference audit by fixing the grouped
model-fit extractor page.

## Implemented

- Added `logLik.drmTMB` to the grouped `model-fit-extractors` Rd topic.
- Clarified that `logLik()` returns a `"logLik"` object with `df` and `nobs`
  attributes used by `AIC()` and `BIC()`.
- Kept the existing warning that `deviance()` is `-2 * logLik`, not a
  saturated-model GLM deviance.
- Added a runnable example that shows `logLik()`, `nobs()`, `df.residual()`,
  `deviance()`, `AIC()`, and `BIC()` on one stable Gaussian fit.

## Mathematical Contract

No likelihood or extractor calculation changed. The slice only documents the
existing `logLik.drmTMB` method beside the related base-R extractor methods.

## Files Changed

- `R/methods.R`
- `man/model-fit-extractors.Rd`
- `docs/dev-log/audits/2026-05-21-function-reference-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-22-reference-model-fit-extractors.md`

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e 'devtools::load_all(quiet = TRUE); set.seed(20260524); n <- 36; x <- seq(-1.5, 1.5, length.out = n); dat <- data.frame(y = 0.3 + 0.6 * x + rnorm(n, sd = 0.7), x = x); fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat); print(logLik(fit)); print(nobs(fit)); print(df.residual(fit)); print(deviance(fit)); print(AIC(fit)); print(BIC(fit))'
air format R/methods.R
Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|student-location-scale', reporter = 'summary')"
Rscript -e "pkgdown::build_reference()"
rg -n 'logLik\(\)|AIC\(|BIC\(|complete-case|negative twice log-likelihood|logLik.drmTMB|df.residual\(fit\)' R/methods.R man/model-fit-extractors.Rd pkgdown-site/reference/model-fit-extractors.html -S
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
gh issue list --search "model-fit extractors logLik AIC BIC reference" --limit 20
```

## Tests Of The Tests

The revised example was executed directly before focused tests. The first tiny
candidate example produced a positive log likelihood and negative deviance,
which was technically possible but poor as public teaching output; the final
fixture gives ordinary-looking likelihood criteria.

## Consistency Audit

The reference page now matches the exported S3 surface: `logLik()` supplies the
likelihood object, and `nobs()`, `df.residual()`, `deviance()`, `AIC()`, and
`BIC()` form the expected base-R comparison path.

## GitHub Issue Maintenance

Issue search found no matching open issue to close.

## What Did Not Go Smoothly

The missing `logLik()` alias was easy to overlook because the method was
exported and tested, but the grouped reference page did not show it.

## Known Limitations

This slice does not review the adjacent extractor pages such as `fitted()`,
`predict()`, `residuals()`, `sigma()`, `simulate()`, `weights()`, `fixef()`,
`ranef()`, `rho12()`, or `vcov()`.

## Next Actions

1. Continue rendered reference inspection with the adjacent S3 extractor pages.
2. Keep checking reference examples for numerically useful teaching output.
