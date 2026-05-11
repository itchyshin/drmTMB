# After-Task Report: Explicit `rho12` In `corpairs()` Example

## Task

Make the `corpairs()` help example show the residual correlation formula it is
summarising.

## Reader

This note is for applied users learning the correlation-pair namespace and for
contributors staging issue #5 covariance-block work.

## What Changed

- Updated the `corpairs()` roxygen example in `R/methods.R` to include
  `rho12 = ~ 1` explicitly.
- Regenerated `man/corpairs.Rd`.
- Kept behaviour unchanged; bivariate Gaussian models already default to an
  intercept-only `rho12` formula, but the example now names the correlation
  being reported.

## Checks Run

- `air format R/methods.R docs/dev-log/after-task/2026-05-11-corpairs-example-rho12.md docs/dev-log/check-log.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'corpairs')"`: passed.
- `rg -n "rho12 = ~ 1|corpairs\\(fit\\)|issue #5|Explicit" R/methods.R man/corpairs.Rd docs/dev-log/after-task/2026-05-11-corpairs-example-rho12.md docs/dev-log/check-log.md`:
  confirmed source, generated docs, and dev-log wording.
- `git diff --check`: passed.

## Known Limitations

- This is documentation clarity only. It does not add new covariance-block
  likelihoods or extend `corpairs()` to planned issue #5 pair classes.
