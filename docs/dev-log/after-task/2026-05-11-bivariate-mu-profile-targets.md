# After Task: Bivariate Mu Profile Targets

## Goal

Close the issue #13 follow-up from the bivariate Gaussian `mu1`/`mu2`
random-intercept covariance work by making the profile-target surface explicit
and tested.

## Implemented

- Added a focused `profile_targets()` test for a fitted `biv_gaussian()` model
  with matching labelled `mu1` and `mu2` random intercepts.
- The test checks exact target names for `sd:mu:mu1:(1 | p | id)`,
  `sd:mu:mu2:(1 | p | id)`, and
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)`.
- The test checks `tmb_parameter`, `index`, response-scale transformation,
  target type, `profile_ready`, and `profile_note`.
- The test also checks that residual `rho12` remains a separate residual
  correlation target rather than being mixed with group-level `mu1`/`mu2`
  covariance targets.
- Updated `NEWS.md`, `docs/design/12-profile-likelihood-cis.md`, and
  `vignettes/bivariate-coscale.Rmd` so readers can discover the new target
  names before requesting profile intervals.

## Checks Run

- `air format tests/testthat/test-profile-targets.R NEWS.md docs/design/12-profile-likelihood-cis.md vignettes/bivariate-coscale.Rmd`:
  passed.
- `Rscript -e "devtools::test(filter = 'profile-targets|biv-gaussian')"`:
  passed with 303 expectations.
- `Rscript -e "devtools::document()"`: passed.
- `Rscript -e "devtools::test()"`: passed with 1776 expectations.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.

## Known Limitations

- This slice covers the target inventory and direct target mapping. It does not
  add a separate long-running profile-interval simulation study for the
  bivariate group-level covariance parameters.
