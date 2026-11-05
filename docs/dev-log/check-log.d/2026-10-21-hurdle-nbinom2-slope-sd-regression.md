# Check Log: Hurdle NB2 Independent-Slope SD Regression

- Targeted command: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^(hurdle-nbinom2-sd-regression|hurdle-nbinom2|truncated-nbinom2-sd-regression)$")'`
- Result: 119 expectations passed; 0 failures, warnings, or skips; 68.9 seconds. No live Julia engine test ran.
- Vignette: `Rscript -e 'rmarkdown::render("vignettes/count-nbinom2.Rmd", quiet = TRUE)'` completed. Pandoc emitted a `--mathjax` deprecation warning.
- Whitespace: `git diff --check -- R/drmTMB.R tests/testthat/test-hurdle-nbinom2.R vignettes/count-nbinom2.Rmd` passed.
- Scope: one native complete-response hurdle NB2 location slope whose coefficient has a matching predictor-dependent SD formula. Interval coverage and Julia parity remain unverified.
