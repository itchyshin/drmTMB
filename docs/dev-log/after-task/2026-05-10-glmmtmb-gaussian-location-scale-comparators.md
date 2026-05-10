# glmmTMB Gaussian Location-Scale Comparator Tests

Date: 2026-05-10

Reader: contributors validating the first individual-difference location-scale
replication targets before implementing richer double-hierarchical covariance
blocks.

## Goal

Add a small optional comparator check showing that the implemented Gaussian
location-scale route agrees with `glmmTMB` on overlapping location-scale models.
This is the first rung toward reproducing the Gaussian examples from the
location-scale paper and tutorial.

## Changes

- Added a fixed-effect Gaussian location-scale comparator against
  `glmmTMB::glmmTMB(y ~ x, dispformula = ~ z, family = gaussian())`.
- Added a Gaussian random-intercept location-scale comparator against
  `glmmTMB::glmmTMB(y ~ x + (1 | id), dispformula = ~ z, family = gaussian())`.
- Checked `mu` fixed effects, `sigma` formula coefficients, random-intercept
  SDs where present, and log-likelihood agreement.
- Suppressed only the optional-dependency namespace warning emitted by the
  local `glmmTMB`/`TMB` version mismatch during skip checks; the model
  comparator itself still has warning-clean assertions.
- Updated `docs/design/05-testing-strategy.md` and
  `vignettes/source-map.Rmd` so the new comparator coverage is discoverable.

## Validation

- `air format tests/testthat/test-comparators.R`: passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-comparators.R')"`:
  54 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::test()"`: 1387 passed, 0 failed, 0 warnings,
  0 skips.
- `Rscript -e "pkgdown::build_site()"`: passed and regenerated the source-map
  article with the comparator-test pointer.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  first run found one warning because `glmmTMB` was used in tests but missing
  from `Suggests`; after adding `glmmTMB` to `DESCRIPTION`, the final rerun
  reported 0 errors, 0 warnings, and 0 notes.

## Remaining Limitations

These are simulation-based smoke tests, not full real-data reproductions of
the individual-difference location-scale tutorial examples. The next
replication step is a local script or optional test harness that loads the
tutorial data and records paper-facing `sigma^2` summaries beside drmTMB's
public `sigma` estimates.
