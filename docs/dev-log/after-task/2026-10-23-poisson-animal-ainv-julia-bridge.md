+# After Task: Poisson animal precision through the Julia bridge

## Goal

Expose the reviewed Julia Poisson animal-intercept SD precision route through drmTMB's `engine = "julia"` bridge and verify a same-data comparison with native TMB.

## Implemented

The R bridge now recognizes animal `Ainv`, reorders labeled precision matrices to first-seen group order, and passes the matrix separately from covariance `A`. A guard restricts the bridge route to the currently implemented complete-data Poisson animal-intercept SD model. The paired Julia bridge forwards precision to the Poisson fitter without normalization.

## Mathematical Contract

For `Q = Ainv` and group SD matrix `D = diag(exp(W alpha))`, the latent covariance is `D Q^-1 D`. The input stays a precision matrix. Labeled rows and columns are aligned to data group order before the bridge call; unlabeled matrices remain positional.

## Files Changed

- `R/julia-bridge.R`: matrix admission, label alignment, narrow route guard, positional wrapper argument.
- `tests/testthat/test-julia-poisson-animal-ainv-sd-parity.R`: payload alignment and same-data engine comparison.
- `NEWS.md`, `vignettes/predictor-dependent-random-sd.Rmd`, `vignettes/formula-grammar.Rmd`, and `vignettes/structural-dependence.Rmd`: bounded user-facing capability statements.
- This report and `docs/dev-log/check-log.d/2026-10-23-poisson-animal-ainv-julia-bridge.md`.

## Checks Run

- `devtools::test(filter = "julia-poisson-animal-ainv-sd-parity")` without Julia: 4 assertions passed; the live test was skipped.
- Same test with `DRM_JL_PATH` set to the paired candidate: 14 assertions passed in 35.0 seconds, including the live fit. JuliaCall emitted one warning because its optional dependency-install command returned status 1; the fit and comparisons succeeded.
- The live comparison checked convergence, SD coefficient names and estimates, log likelihood, and named animal SD predictions.
- `git diff --check`: passed.
- `pkgdown::check_pkgdown()`: passed with no problems; the full site and vignette render were not run.

## Tests Of The Tests

The initial payload test failed because the bridge rejected `animal(..., Ainv = ...)`. After implementation, the test checks that matrix labels are reordered to match the data and that the formula sent to Julia omits the matrix expression. It also verifies the bridge rejects Ainv for an animal model without an SD formula. The live fixture uses independent synthetic Poisson data and compares the Julia route with native TMB.

## Consistency Audit

The R bridge keeps `A` covariance and `Ainv` precision distinct. The family and capability pages in the paired Julia candidate now describe the same precision convention and limit their parity claim to this one fixture. No collaborators' data or examples were used.

## GitHub Issue Maintenance

No issue was opened or changed. This is one capability slice in the active general predictor-dependent SD programme.

## What Did Not Go Smoothly

The first preflight invocation used Python on a shell script and did not run. The first live fixture also inherited TMB-only control settings, so it stopped before fitting; removing that control from the Julia call let the test proceed. JuliaCall's optional dependency-install command warned during the successful live run.

## Team Learning

For bridge parity, verify matrix names and ordering before fitting, and keep covariance and precision as separate arguments through the entire R-to-Julia call chain.

## Known Limitations

Only one Poisson animal-intercept SD route is admitted for Ainv. Profile and bootstrap refits through the R bridge do not yet carry this precision target. This does not establish broader family/effect parity or interval calibration.

## Next Actions

1. Extend structured profile/bootstrap refits to retain Ainv and add target-identity checks.
2. Continue the full family, random-effect, endpoint, and engine inventory.
3. Complete the required uncertainty calibration and broader checks before closing the full goal.

