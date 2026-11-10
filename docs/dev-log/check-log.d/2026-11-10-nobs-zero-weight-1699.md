# 2026-11-10: nobs() ignores zero-weight rows (#1699)

`nobs()` and `attr(logLik(fit), "nobs")` now count likelihood rows whose weight is positive. `BIC()`, `df.residual()`, and `aicc()` read that count. `fitted()`, `residuals()`, and `weights()` keep their previous lengths. The log-likelihood value and `AIC()` are unchanged.

`drm_fit_df()` does not read `nobs`. REML still rebuilds `df` from the optimized vector plus marginalized fixed-effect columns, and the restricted likelihood scales each row by its weight inside TMB. A Gaussian `REML = TRUE` fit with five zero weights matches the dropped-row fit on log-likelihood, `df`, `nobs()`, and `BIC()`.

`engine = "julia"` aborts when `weights` is supplied (`R/julia-bridge.R`), so `nobs.drmTMB_julia()`, `nobs.drmTMB_julia_xfam()`, and `nobs.drmTMB_julia_joint()` were left unchanged. `weights.drmTMB_julia()` is still `rep(1, nobs(object))`.

Stored `fit$nobs` is still the likelihood-row count, including zero-weight rows. `check_drm()` observations-per-parameter and dropped-row text, and vector builders that size themselves with `object$nobs`, keep that row count.

Before the fix, on the installed package whose `nobs.drmTMB` was `object$nobs` (same method as `main` at `ddc62e7f9`; `R/methods.R` did not change between `1e0f545` and that commit):

`Rscript -e 'library(drmTMB); testthat::test_file("tests/testthat/test-fix-1699-nobs-zero-weight.R", reporter = "summary")'`

7 tests, 33 failed expectations. The issue example reported `nobs` 20 versus 15 and `BIC` 48.36 versus 47.49. Log-likelihood, `AIC`, and `fitted` / `residuals` / `weights` lengths already matched.

After the fix, the same file: 7 tests, 0 failures, 73 expectations. Also passed: `test-gaussian-location-scale.R` (1 CRAN skip), `test-bootstrap-response-mask.R`, `test-lrt-boundary.R` (3 skips), and under `pkgload::load_all()` `test-model-comparison.R` (2 Julia skips), `test-poisson-mean.R`, and `test-dinnage-audit-a3-misc.R` (1 `{ape}` skip).

Stale-wording search, no remaining hits: `rg -n "fitted rows after complete-case|fitted-row count" R vignettes README.md man/model-fit-extractors.Rd`. Open issues matching `nobs weight OR BIC zero-weight`: #1699 only. #1464 is the unrelated test-sweep tracker. No issue comment was posted.
