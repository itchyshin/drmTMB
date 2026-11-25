# 2026-11-25 — #1481 factor-response refusal (remaining families)

- Extended `drm_reject_factor_response()` to lognormal, Gamma, Tweedie, beta, Poisson, NB2, and bivariate Gaussian/Student-t builders.
- New tests: `tests/testthat/test-fix-1481-factor-response-more.R`.

## Evidence

```sh
NOT_CRAN=true R_LIBS_USER=$HOME/R/library Rscript -e '
.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
pkgload::load_all(compile = FALSE)
testthat::test_file("tests/testthat/test-fix-1481-factor-response-more.R")
testthat::test_file("tests/testthat/test-fix-1481-factor-continuous-response.R")
'
```

Result: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 25 ]` (new file) and `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 10 ]` (existing continuous file).