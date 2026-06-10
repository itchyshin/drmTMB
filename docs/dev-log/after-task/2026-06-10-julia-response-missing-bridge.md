# After-Task Report: Julia Response-Missing Bridge Gate

## Scope

This drmTMB slice lets `engine = "julia"` pass response-missing Gaussian models
to DRM.jl. It covers the R-side policy gate and payload handoff only; the
observed-data likelihood is implemented in DRM.jl.

Supported in this slice:

- univariate Gaussian response-missing rows with
  `missing = miss_control(response = "include")`;
- bivariate Gaussian partial-response rows with `family = biv_gaussian()`;
- predictor policy `predictor = "fail"`.

Still blocked:

- missing predictors / `mi()` / `impute`;
- non-Gaussian response-missing Julia-engine fits;
- bivariate q=4 phylogenetic location-scale response-missing rows until the
  DRM.jl sparse kernel has observed-cell masks.

## Implementation

`drmTMB_julia_bridge()` now computes `family_type` before the missing-policy
guard. It accepts response-missing rows for `gaussian` and `biv_gaussian`,
rejects missing-predictor routes with a targeted message, and keeps non-Gaussian
response-missing routes on the native TMB path.

The bridge payload still sends the original data frame columns to Julia, so
response `NA` cells are preserved for JuliaCall/DRM.jl rather than being dropped
inside R.

## Verification

Commands run:

```sh
Rscript -e 'pkgload::load_all("."); testthat::test_file("tests/testthat/test-julia-bridge.R")'
```

The focused bridge test file passed with 84 expectations. The new mocked test
checks that univariate `y = NA` and bivariate `y1`/`y2 = NA` cells are present
in the data passed to the Julia boundary.

After installing `JuliaCall` and `rjson`, a live smoke was run with:

```sh
DRM_JL_PATH=/Users/z3437171/Dropbox/Github Local/DRM.jl
```

Results:

- univariate Gaussian: Julia vs TMB logLik difference `4.831691e-13`, both
  `nobs = 18`, missing-response residuals `NaN`;
- bivariate Gaussian: Julia vs TMB logLik difference `2.915925e-10`, both
  `nobs = 29`, missing-response residuals `NaN` for both response margins.

## Next

The next bridge parity target is the q=4 phylogenetic location-scale missing
response path. That should start in DRM.jl by adding observed-cell masks to the
sparse latent q=4 kernel before drmTMB exposes it.
