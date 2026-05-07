# Check Log

Record meaningful development checks here.

## 2026-05-06: Initial Scaffold

Scope:

- package metadata;
- testthat scaffold;
- design documents;
- Codex agent and skill configuration;
- GitHub Actions R CMD check workflow.

Commands run:

- `devtools::document()`
- `devtools::test()`
- `devtools::check(error_on = "never")`
- `devtools::check(error_on = "never")` after scaffold hygiene fixes
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 1 note

Known issues:

- maintainer metadata uses a placeholder email until the project owner chooses
  final package metadata.
- no model-fitting code exists yet.
- `air` is not installed, so no formatter was run.
- `LinkingTo` is intentionally deferred until the first TMB source template is
  added.
- final check note was `unable to verify current time`, caused by local
  timestamp/repository access conditions rather than package structure.

## 2026-05-06: Grammar Refinement, pkgdown, and Logo

Scope:

- corrected source-of-truth grammar for `rho12`, meta-analysis, bivariate
  formulas, multiple scale components, phylogenetic A-inverse, and spatial SPDE
  plans;
- added initial `bf()` parser entries and formula marker functions;
- added package logo and pkgdown favicons;
- added meta-analysis and phylogenetic/spatial article stubs;
- added Claude Code instructions and after-task protocol.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_favicons(overwrite = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`

Results:

- `devtools::test()`: 16 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- final `pkgdown::build_site()`: URLs, favicons, Open Graph, article metadata,
  and reference metadata all OK.
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes.

Known issues:

- `air` is not installed, so no `air format .` run occurred.
- fitting engine and simulation recovery tests remain the next task.

## 2026-05-06: Gaussian Location-Scale MVP

Scope:

- first TMB template for Gaussian `mu` and `sigma`;
- `drmTMB()` fitting path for fixed-effect `bf(y ~ x, sigma ~ z)`;
- S3 methods for coefficients, prediction, simulation, residuals, sigma,
  log-likelihood, variance-covariance, and summaries;
- simulation recovery tests and Phase 1 rejection tests;
- README, roadmap, design docs, vignette, NEWS, and known limitations updates.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- interactive smoke test for fitting, prediction, `sigma()`, and `simulate()`
- `Rscript -e "devtools::check(error_on = 'never')"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- `devtools::test()`: 30 passed, 0 failed.
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes.
- `pkgdown::check_pkgdown()`: no problems found.
- final `pkgdown::build_site()`: site built successfully.

Known issues:

- `air` is not installed, so no `air format .` run occurred.
- only fixed-effect Gaussian location-scale models are implemented.

## 2026-05-06: Diagonal Meta-Analysis Known Variance

Scope:

- implemented diagonal `meta_known_V(V = vi)` for Gaussian models;
- added known-variance likelihood term `sqrt(V_known + sigma^2)`;
- kept `sigma()` and `predict(..., dpar = "sigma")` as unknown heterogeneity SD;
- added tests for recovery, diagonal matrix input, full covariance rejection,
  missing known variance, malformed marker calls, and near-zero heterogeneity;
- reconciled docs, README, roadmap, NEWS, and known limitations after
  subagent review.

Commands run:

- `Rscript -e "devtools::document(); devtools::test()"`
- interactive smoke test for `meta_known_V(V = vi)` fitting and simulation
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`

Results:

- `devtools::test()`: 73 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- final `pkgdown::build_site()`: site built successfully.
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes.

Known issues:

- full or block-diagonal known covariance matrices are still rejected.
- exact zero heterogeneity is approximated by a small positive `sigma`.

## 2026-05-06: Bivariate Gaussian rho12

Scope:

- implemented `biv_gaussian()` for fixed-effect bivariate Gaussian
  location-scale-coscale models;
- added separate formulas for `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12`;
- used a bounded tanh response transform for `rho12` to avoid singular
  covariance matrices under extreme linear predictors;
- added bivariate simulation recovery tests for constant, near-zero, negative,
  and predictor-dependent residual correlation;
- added whitened bivariate Pearson residuals and coefficient-level `vcov()`
  names;
- reconciled README, roadmap, design docs, vignettes, NEWS, pkgdown reference
  index, and known limitations;
- added a gllvmTMB source map for later phylogenetic A-inverse and SPDE work.

Commands run:

- `Rscript -e "devtools::document()"`
- interactive smoke test for `biv_gaussian()` fitting and coefficient recovery
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`

Results:

- targeted bivariate tests: 40 passed, 0 failed.
- full `devtools::test()`: 113 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- final `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 0 notes.

Known issues:

- `air` is not installed locally, so formatting could not be run.
- bivariate models are fixed-effect only.
- bivariate `meta_known_V()`, random effects, `mvbind()` shorthand,
  phylogenetic terms, and spatial terms are not implemented yet.
