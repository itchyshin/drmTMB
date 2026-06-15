# After Task: Julia Confint Target Wording

## Goal

Make the Julia-engine article and `confint.drmTMB_julia()` manual page match
the bridge surface that users can actually call. Rose's concern was that the
article sounded broader than the code: it implied that univariate Gaussian
sigma-phylo profile/bootstrap extraction was already exposed, while the R
bridge currently exposes the univariate `mu` phylogenetic SD target and the
four bivariate q = 4 among-axis SD targets.

## Implemented

- Reworded `vignettes/julia-engine.Rmd` to separate fitted-model support from
  inference-extraction support.
- Reworded the bridge capability table so Gaussian sigma-phylo location-scale
  models are described as admitted for fitting and `REML` forwarding only when
  the installed `DRM.jl` build supports the cell.
- Reworded the profile/bootstrap section so it names the current target
  inventory: univariate `sd:mu:phylo(1 | species)` and q = 4
  `sd:mu1:*`, `sd:mu2:*`, `sd:sigma1:*`, and `sd:sigma2:*`.
- Updated the `confint.drmTMB_julia()` roxygen and generated Rd page to match
  the article.
- Updated the unsupported-target error hint in
  `drm_julia_validate_inference_targets()`.

## Files Changed

- `R/julia-bridge.R`
- `man/confint.drmTMB_julia.Rd`
- `vignettes/julia-engine.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format R/julia-bridge.R
Rscript --vanilla -e "devtools::document()"
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-julia-biv-confint.R'); testthat::test_file('tests/testthat/test-julia-inference.R')"
```

## Results

- `test-julia-biv-confint.R` passed with 31 expectations.
- `test-julia-inference.R` passed with 44 expectations.
- Unrelated roxygen-version churn from `devtools::document()` was removed from
  the patch before committing.

## Claim Boundary

This slice does not add speed, add a new inference target, implement native-TMB
REML for bivariate q4, or validate 10k-tip runtime. It keeps the documentation
honest while the active plan pivots toward completing the native R/TMB side
first, then using Julia for the harder speed and extended-inference frontier.

For Ayumi-style q4 workflows, native `engine = "tmb"` remains useful for
supported ML point-estimate and profile-status checks, but it is still not a
full REML fallback for the bivariate q4 phylogenetic location-scale model.
