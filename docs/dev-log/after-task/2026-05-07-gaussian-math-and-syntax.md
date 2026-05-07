# After Task: Gaussian Math And Syntax

## Purpose

Clarify that `drmTMB` documentation should teach symbolic models and matching R
syntax together, starting with the Gaussian location-scale MVP.

## Changes Created

- Added a mathematical specification section to
  `vignettes/location-scale.Rmd`.
- Added matching syntax examples for:
  - fixed-effect Gaussian location-scale regression;
  - Gaussian location-scale regression with a location random intercept.
- Added `docs/design/13-gaussian-location-scale-math.md` as a
  source-of-truth note for the Gaussian location-scale equations.
- Updated `docs/design/03-likelihoods.md` so the implemented Gaussian
  likelihood has symbolic equations and matching R syntax side by side.
- Updated `docs/design/00-vision.md` to make math-plus-syntax a project
  principle.

## Consistency Checks Run

- Regenerate roxygen documentation because the `bf()` examples were also
  corrected in this task series.
- Run package tests.
- Run pkgdown checks and rebuild the local site preview.
- Search the docs for stale bare bivariate examples that omit the planned
  random-intercept/random-slope mean structure.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg` searches over `README.md`, `vignettes`, `docs`, `R`, and `man` for
  stale `rho12`, bivariate syntax, `sigma_i`, and `sd_mu` examples.

Results:

- `devtools::document()`: completed and updated generated Rd files.
- `devtools::test()`: 148 passed, 0 failed.
- `air format .`: not available locally.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully in `pkgdown-site`.
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

## Design Decision

Use `sigma`, `sigma1`, and `sigma2` for residual or within-observation scale.
Use separate group-level names for random-effect scale components. This keeps
double-hierarchical interpretation clear: residual predictability is not the
same parameter as personality or plasticity variance.

## Follow-Up

- The fixed-effect bivariate `biv_gaussian()` example remains in the docs
  because it is implemented now.
- The O'Dea-style random-intercept/random-slope bivariate syntax is explicitly
  labelled as planned, not implemented.
- Future model families should follow the same pattern: symbolic equations,
  matching R syntax, implementation mapping, and simulation/comparator tests.
