# Check log: native zero-inflated NB2 independent-slope SD regression

## Scope

Native complete-response zero-inflated NB2 now admits one ordinary independent
numeric `mu` slope with a selected predictor-dependent SD. The recovery
fixture uses fixed-intercept `sigma` and `zi` formulas. It is point-recovery
evidence only.

## Checks

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zi-nbinom2")'`: PASS, 105 expectations, 0 failures, 2 existing clamp warnings, 0 skips, 29.3 seconds.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "zi-")'`: PASS, 234 expectations, 0 failures, 2 existing clamp warnings, 1 skipped live Julia test (engine path unavailable), 98.7 seconds.
- Test-first receipt: the new assembly test initially failed at the ZI-NB2 intercept-only guard. The new fit test checks seeded SD-trend recovery, group-SD prediction, and a separate scalar Laplace calculation with slope loading.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'rmarkdown::render("vignettes/formula-grammar.Rmd", quiet = TRUE)'`: PASS; Pandoc emitted the existing deprecated `--mathjax` option warning.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'pkgdown::check_pkgdown()'`: PASS, no problems found; existing Pandoc `--mathml` deprecation warnings were emitted.
- The issue search `sd random-effect standard deviation predictor zero-inflated NB2 independent slope` in `itchyshin/drmTMB` returned no matching open issues.
- The status scan is recorded verbatim in the after-task report. Whole-tree `git diff --check` identifies an unrelated pre-existing trailing blank line in `tests/testthat/test-binomial-sd-integration.R`; scoped checks for this change passed.

## Limits

No Julia fitting, same-data parity, interval calibration, correlated or
structured effects, or missing-response route was tested. The live Julia test
skip is not counted as Julia validation.
