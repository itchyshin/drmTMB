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
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

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
- `drmTMB()` fitting path for fixed-effect `bf(y ~ x1, sigma ~ x1)`;
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

## 2026-05-07: First Push and pkgdown Workflow Fix

Scope:

- committed and pushed the initial `drmTMB` scaffold and Gaussian MVP work to
  `origin/main`;
- confirmed GitHub R-CMD-check succeeded after the push;
- diagnosed the first pkgdown workflow failure;
- changed the pkgdown workflow from `pkgdown::build_site_github_pages()` to
  `pkgdown::build_site()` so the site builds into `pkgdown-site` rather than
  trying to clean the tracked `docs/` design directory;
- updated Pages artifact actions to current major versions where available.

Commands run:

- `git fetch origin`
- `git add -A`
- `git commit -m "Scaffold drmTMB package and Gaussian MVPs"`
- `git push origin main`
- `gh run list --repo itchyshin/drmTMB --limit 10`
- `gh run view 25492948840 --repo itchyshin/drmTMB --job 74805330699 --log`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- pushed commit `69f11f8` to `origin/main`.
- GitHub R-CMD-check for commit `69f11f8`: success.
- Initial GitHub pkgdown run for commit `69f11f8`: failed because
  `build_site_github_pages()` tried to clean `docs/`.
- Local pkgdown after workflow diagnosis: no problems found; site built
  successfully into `pkgdown-site`.
- pushed commit `d8082a1` with the corrected pkgdown workflow.
- GitHub pkgdown for commit `d8082a1`: success, including deployment to
  `https://itchyshin.github.io/drmTMB/`.
- GitHub R-CMD-check for commit `d8082a1`: success.

Known issues:

- The pkgdown site intentionally publishes root Markdown pages such as
  `AGENTS.html`, `CLAUDE.html`, and `ROADMAP.html`; revisit later if those
  should be hidden.

## 2026-05-07: Gaussian mu Random Intercepts

Scope:

- implemented univariate Gaussian random intercepts in the `mu` formula;
- supported one or multiple additive terms such as `(1 | id)` and
  `(1 | site) + (1 | observer)`;
- used TMB Laplace integration with a non-centered parameterization:
  `b_group = sd_group * u_group`, `u_group ~ Normal(0, 1)`;
- kept random effects unsupported in `sigma` formulae, bivariate models,
  random slopes, and brms-style labelled covariance blocks;
- added conditional fitted-data prediction and residuals that include `mu`
  random-intercept modes;
- left `newdata` prediction fixed-effect-only for now;
- added tests for recovery, multiple grouping factors, missing grouping
  variables, singleton-group rejection, unsupported syntax, and fixed-parameter
  counting.

Commands run:

- `Rscript -e "devtools::document()"`
- interactive smoke test for `bf(y ~ x1 + (1 | id), sigma ~ x1)`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'gaussian')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`
- `air format .`

Results:

- targeted random-intercept tests: 24 passed, 0 failed.
- full `devtools::test()`: 139 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- Standard `devtools::check(error_on = "never")`: 0 errors, 0 warnings,
  1 environment note about verifying the current time.
- `devtools::check(error_on = "never")` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`:
  0 errors, 0 warnings, 0 notes.

Known issues:

- `air` is not installed locally, so formatting could not be run.
- random slopes, bivariate random effects, random effects in scale formulae,
  and random-effect scale models remain future work.

## 2026-05-07: Formula, Family, Audience, and Validation Refinements

Scope:

- recorded that `drmTMB` should develop a package-specific formula grammar
  rather than copying `brms` wholesale;
- documented `formula = drm_formula(...)` as the canonical long-form direction,
  with `bf()` retained as the current prototype;
- documented composed bivariate family syntax such as
  `family = c(gaussian(), gaussian())` and
  `family = c(gaussian(), poisson())` as the public direction;
- clarified that `rho12` is residual response-response correlation, while
  O'Dea-style correlations among personality, plasticity, predictability, and
  malleability live in group-level covariance blocks;
- recorded a random-effect eligibility table for downstream distributional
  parameters;
- retargeted pkgdown/tutorial wording toward ecologists, evolutionary
  biologists, and environmental scientists;
- documented the two-tier validation strategy: comparator-package checks plus
  simulation recovery;
- added Shinichi Nakagawa as author, maintainer, and copyright holder with
  ORCID `0000-0002-7765-5182`.

Sidecar agents used:

- Boole: R API and formula parser review.
- Gauss: TMB and random-effect likelihood review.
- Noether: formula and correlation taxonomy review.
- Darwin: ecological examples and pkgdown review.
- Fisher: validation strategy review.

Commands run:

- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- stale-text scan for placeholder author metadata and old `z`/`w` examples.

Results:

- `air format .`: not available locally.
- full `devtools::test()`: 139 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check(error_on = "never")` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`:
  0 errors, 0 warnings, 0 notes.
- stale-text scan found no placeholder maintainer metadata or old `z`/`w`
  formula examples in active docs.

Known issues:

- `drm_formula()` and composed bivariate family objects are design directions,
  not implemented API yet.
- `biv_gaussian()` remains the implemented bivariate Gaussian prototype.
- Comparator-package tests are planned; current passing tests are simulation and
  unit tests.

## 2026-05-07: Profile-Likelihood CI Roadmap

Scope:

- added profile-likelihood confidence intervals as a later inference phase;
- documented the likelihood-ratio drop criterion
  `qchisq(0.95, df = 1) / 2`;
- recorded `TMB::tmbprofile()` plus `uniroot()` as the preferred first strategy
  for direct TMB parameters;
- distinguished direct parameters, linear combinations, and nonlinear derived
  quantities such as ICCs and variance-component correlations;
- recorded fix-and-refit profiling as the first robust route for nonlinear
  derived quantities;
- documented boundary, non-monotone profile, and inner-optimization failure
  fallbacks.

Commands run:

- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- full `devtools::test()`: 139 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.

Known issues:

- profile-likelihood CIs are only a design roadmap item; no API or inference
  code has been implemented yet.

## 2026-05-07: Comparator Smoke Tests

Scope:

- added the first Tier 1 comparator-package tests;
- compared the homoscedastic Gaussian random-intercept overlap with
  `lme4::lmer(..., REML = FALSE)`;
- compared Gaussian ML meta-analysis with known sampling variances to
  `metafor::rma.uni(..., method = "ML")`;
- added `lme4` and `metafor` to `Suggests`;
- documented the implemented comparator tests in the testing strategy.

Commands run:

- interactive smoke comparisons against `lme4` and `metafor`;
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- comparator tests: 9 passed, 0 failed.
- full `devtools::test()`: 148 passed, 0 failed.
- `air format .`: not available locally.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check(error_on = "never")` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`:
  0 errors, 0 warnings, 0 notes.

Known issues:

- `glmmTMB` was available locally but emitted a TMB version mismatch warning, so
  it was not used for comparator tests.
- `gamlss` was not installed locally.
- Comparator tests are deliberately tiny smoke tests; broad comparator sweeps
  remain long-test or scheduled-CI work.
