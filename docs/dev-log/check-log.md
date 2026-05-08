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
  random slopes, and labelled covariance blocks;
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
  double-hierarchical correlations among personality, plasticity,
  predictability, and malleability live in group-level covariance blocks;
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

## 2026-05-07: Gaussian Math And Syntax

Scope:

- added symbolic equations beside R syntax for Gaussian location-scale models;
- clarified that residual `sigma` is distinct from group-level random-effect
  standard deviations;
- corrected bivariate teaching examples so fixed-effect syntax is labelled as
  implemented now and double-hierarchical random-intercept/random-slope syntax
  is labelled as planned;
- added `docs/design/13-gaussian-location-scale-math.md` as the
  source-of-truth Gaussian equation note;
- regenerated Rd files after updating the `bf()` examples.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg` consistency searches over README, vignettes, docs, R, and man files.

Results:

- full `devtools::test()`: 148 passed, 0 failed.
- `air format .`: not available locally.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check(error_on = "never")` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`:
  0 errors, 0 warnings, 0 notes.

Known issues:

- `drm_formula()` and `family = c(gaussian(), gaussian())` are still design
  directions, not implemented API.
- double-hierarchical bivariate random slopes are not implemented yet; the docs
  now label them as planned.

## 2026-05-07: GAMLSS Parameter Names

Scope:

- checked the local Rigby and Stasinopoulos (2005) GAMLSS PDF for parameter
  naming;
- added `Rigby2005GAMLSS` to `REFERENCES.bib`;
- added `docs/design/14-gamlss-parameter-names.md`;
- set `mu`, `sigma`, `nu`, and `tau` as the preferred canonical
  distributional-parameter names;
- updated the family registry, distribution roadmap, formula grammar, and
  reference programme so skew-normal uses `nu` rather than canonical `skew`.

Commands run:

- `pdftotext` on the local Rigby and Stasinopoulos PDF;
- `rg` consistency searches for `skew_normal`, `skew_t`, `skew`, `nu`, `tau`,
  `Rigby`, and `GAMLSS`;
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`

Results:

- the PDF source check confirmed the GAMLSS convention of `mu`, `sigma`, `nu`,
  and `tau`;
- full `devtools::test()`: 148 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully.

Known issues:

- `nu` and `tau` are documentation/design policy only until Student-t,
  skew-normal, skew-t, COM-Poisson, or beta families are implemented.
- Alias support for user-friendly names such as `skew` or `df` is deferred.

## 2026-05-07: Location-Coscale Phylogenetic Sources

Scope:

- checked the bivariate location-coscale note, mammalian body mass-litter size
  protocol, and MEE phylogenetic location-scale paper;
- recorded that MEE PLSM is the foundation and location-coscale is the
  extension that models residual correlation;
- added `docs/design/15-location-coscale-phylogenetic-extension.md`;
- updated vision, distribution roadmap, phylogenetic/spatial speed plan,
  reference programme, bivariate coscale vignette, and phylogenetic-spatial
  vignette;
- added local-source bibliography entries for the coscale note and mammal
  protocol.

Commands run:

- `pdfinfo` on the three source PDFs;
- `pdftotext` plus `rg` source searches for coscale, residual correlation,
  phylogenetic correlation, lifestyle, body mass, litter size, and PLSM terms;
- `rg` consistency search over README, vignettes, docs, ROADMAP, and
  `REFERENCES.bib`;
- `git diff --check`;
- `Rscript -e "devtools::test()"`;
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`;
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- full `devtools::test()`: 148 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `air format .`: not available locally;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Known issues:

- phylogenetic location-coscale syntax in the vignette is planned, not
  implemented;
- `rho12 ~ predictors` is implemented only for fixed-effect bivariate Gaussian
  models at this stage.

## 2026-05-07: Phylogenetic And Spatial Common Math

Scope:

- read the local phylogenetic/spatial meta-analysis tutorial;
- added a shared structured-effect design note for phylogeny and space:
  `z ~ MVN(0, sigma_z^2 K)`;
- documented `K = A` for phylogenetic correlation, `K = M` for spatial
  correlation, A-inverse as the phylogenetic speed path, and SPDE/GMRF
  precision as the spatial speed path;
- connected meta-analysis, known sampling covariance `V`, phylogenetic
  structured effects, and spatial structured effects;
- added a `gllvmTMB` source map for future A-inverse and SPDE borrowing;
- replaced casual double-hierarchical shorthand in active docs and vignettes
  with professional wording and a formal citation to O'Dea et al. (2022).
- added Pat, an applied PhD student user tester role, and documented the
  standing review team in `AGENTS.md`.
- added Jason, Curie, Emmy, Grace, and Rose agent configs for landscape
  scouting, literature, pkgdown/course editing, reproducibility, and systems
  auditing.

Sidecar agents used:

- Jason: source-only `gllvmTMB` phylogenetic/SPDE source-map inspection.

Commands run:

- `pdfinfo /Users/z3437171/Downloads/Tutorial___Phylo_spatial_meta_analysis_2.pdf`
- `pdftotext` plus targeted `rg` searches over the local tutorial PDF
- `rg` consistency scans for casual author-name shorthand, package-name
  shorthand, `meta_gaussian`, `tau ~`, and `rho ~`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `gh run view 25498816381 --repo itchyshin/drmTMB --json status,conclusion,jobs`

Results:

- local PDF checks confirmed the tutorial's shared phylogenetic/spatial
  random-effect framing and identifiability warnings;
- full `devtools::test()`: 148 passed, 0 failed;
- `git diff --check`: passed;
- `air format .`: not available locally;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- GitHub R-CMD-check for the previous pushed commit completed successfully on
  macOS, Windows, and Ubuntu.

Known issues:

- this task changed design/docs only; no phylogenetic or spatial fitting code
  has been implemented;
- sparse known covariance, A-inverse phylogeny, and SPDE spatial fields remain
  future work;
- remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails.

## 2026-05-07: General Package Framing

Scope:

- broadened package-level wording so `drmTMB` is not described as belonging to
  only one domain;
- kept ecology, evolution, and environmental science as the main source of
  examples and tutorials;
- renamed the getting-started vignette and several tutorial titles to more
  general headings;
- updated `_pkgdown.yml` navigation to match the new titles;
- updated `docs/design/00-vision.md` with the policy of broad package identity
  and domain-focused examples.

Sidecar agents used:

- Emmy: pkgdown/documentation framing review.

Commands run:

- `rg` stale-heading scans over README, vignettes, docs, and `_pkgdown.yml`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `git diff --check`: passed;
- full `devtools::test()`: 148 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Known issues:

- examples remain ecology/evolution heavy by design, but future broader
  examples may be useful as the package matures.

## 2026-05-07: Equation And Syntax Pairing

Scope:

- expanded the location-scale tutorial so Gaussian equations, R syntax,
  parameter meanings, random-intercept scale components, and meta-analysis
  known variance are shown side by side;
- expanded the bivariate coscale tutorial so the implemented `mu1`, `mu2`,
  `sigma1`, `sigma2`, and `rho12` equations are paired with the exact current
  prototype syntax;
- added future group-level equations to distinguish covariance-block
  correlations from residual `rho12`;
- updated the getting-started article to state that `drmTMB` documentation is
  model-first: equations before API;
- updated design notes so the vignette equations and likelihood specification
  match.

Commands run:

- `git diff --check`
- `rg` stale-syntax scans for `O'Dea-style`, `biological data`,
  `meta_gaussian()`, `tau ~`, `rho ~`, and bivariate prototype mentions
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg` generated-site checks for the new equation headings

Results:

- `git diff --check`: passed;
- full `devtools::test()`: 148 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `air format .`: not available locally;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- generated `pkgdown-site` contains the new location-scale and bivariate
  equation sections.

Known issues:

- this task changed documentation only; it did not implement random slopes,
  bivariate random effects, full known covariance, phylogenetic A-inverse, or
  spatial SPDE code;
- `biv_gaussian()` remains in public examples because it is the implemented
  prototype, while `family = c(gaussian(), gaussian())` remains the design
  direction.

## 2026-05-07: Sharpened Logo And Favicons

Scope:

- replaced the previous logo with a sharper vector-first version based on
  Shinichi's preferred density-curve hex concept;
- exported `man/figures/logo.png` from the SVG for README, pkgdown Open Graph,
  and CRAN-style package assets;
- regenerated pkgdown favicon assets from the same SVG, including SVG, PNG,
  ICO, Apple touch icon, and web-app manifest PNGs;
- updated the web app manifest name and theme/background colour to match the
  logo.

Commands run:

- `rsvg-convert` exports for 1200px logo and favicon PNG sizes
- small R script to rebuild `pkgdown/favicon/favicon.ico`
- visual inspection with `view_image` for the full logo and 96px favicon
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- generated-site asset checks with `file` and `rg`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- full logo renders as a 1200 by 1200 RGBA PNG;
- pkgdown copies the new `logo.svg`, favicon files, and Open Graph logo into
  `pkgdown-site`;
- `git diff --check`: passed;
- full `devtools::test()`: 148 passed, 0 failed;
- `air format .`: not available locally;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully, including favicons;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Known issues:

- the 96px favicon is readable as a hex and density-curve logo, but the text is
  necessarily small at favicon size;
- future refinements can simplify the favicon-specific SVG further if browser
  tabs need stronger small-size legibility.

## 2026-05-07: Dense `meta_known_V()` Gaussian Meta-Analysis

Scope:

- extended Gaussian meta-analysis from vector/diagonal known sampling variance
  to dense full known sampling covariance via `meta_known_V(V = V)`;
- kept meta-analysis as `family = gaussian()`, with unknown extra heterogeneity
  still modelled by `sigma ~ ...`;
- added dense MVN likelihood support in the TMB template;
- added simulation, Pearson residual, and observation-covariance handling for
  dense known `V`;
- added tests for full-covariance log-likelihood agreement against a base R MVN
  calculation, row/column subsetting after missing data, invalid covariance
  rejection, and full known `V` combined with a `mu` random intercept;
- added a regression test for full-`V` missing covariance entries in rows already
  removed by model missingness, after Jason's review flagged possible
  over-dropping;
- created the project-local `after-task-audit` skill and aligned the standing
  team table in `AGENTS.md`.

Commands run:

- `Rscript -e "devtools::test(filter = 'meta-known-v')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check()"`
- stale-wording `rg` scans for full/block covariance rejection, `meta_gaussian`,
  `tau ~`, `rho ~`, and malformed `meta_known_V()` examples

Results:

- targeted `meta-known-v` tests: 36 passed, 0 failed;
- full `devtools::test()`: 166 passed, 0 failed;
- `devtools::document()`: completed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `air format .`: not available locally.

Known issues:

- dense full `V` is appropriate for modest meta-analysis examples; sparse
  covariance storage remains planned for large phylogenetic and spatial
  workloads;
- bivariate known sampling covariance is still not implemented;
- historical after-task notes from the earlier diagonal-only implementation still
  describe the state at the time they were written.

Team learning:

- created Rose's project-local `after-task-audit` skill;
- updated the after-task protocol so future reports include what did not go
  smoothly and which team/process capability should improve next;
- added Williams et al. (2026), "Meta-analysis with the glmmTMB R package", as
  a meta-analysis comparator reference for `glmmTMB::equalto()`;
- noted that `air format .` is unavailable locally and should either be
  installed later or replaced with a documented formatter.

## 2026-05-07: Gaussian `mu` Random Slopes

Scope:

- extended univariate Gaussian `mu` random effects from random intercepts to
  random slopes with one numeric predictor per random-slope term, written as
  `(0 + x | id)`;
- added a random-effect design-value matrix so TMB evaluates
  `mu_i = X_mu beta_mu + sum_j z_j[i] sd_j u_j[g[i]]`;
- preserved the existing non-centered Laplace parameterization and the
  existing random-intercept path as the `z_j[i] = 1` special case;
- allowed independent random intercept and slope terms through separate syntax:
  `(1 | id) + (0 + x | id)`;
- deliberately kept `(1 + x | id)` and `(1 + x | p | id)` reserved for the
  later correlated covariance-block implementation;
- updated the Gaussian equations, formula grammar, random-effect design note,
  likelihood note, README, roadmap, NEWS, vignette text, and known limitations.

Commands run:

- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "pkgdown::build_site()"`
- `git diff --check`
- stale-wording `rg` scans for random-slope and random-intercept-only wording
- `air --version`

Results:

- targeted random-effect tests: 44 passed, 0 failed;
- full `devtools::test()`: 186 passed, 0 failed;
- `devtools::document()`: completed and updated `man/drmTMB.Rd`;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()`: 0 errors, 0 warnings, 1 system-clock note;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed;
- `air --version`: not available locally.

Known issues:

- `(1 + x | id)` is not implemented because it implies an intercept-slope
  covariance block that the current TMB parameterization does not yet estimate;
- random slopes are restricted to a single numeric predictor, so factor and
  multi-column slope terms are rejected;
- random effects in `sigma`, `mu1`, `mu2`, phylogenetic/spatial structured
  effects, and random-effect scale formulas remain planned.

Team learning:

- Boole: formula messages must protect users from accidentally assuming
  correlated random effects when the implementation is currently independent.
- Noether: the symbolic equation needed the design multiplier `z_j[i]`; without
  it, the R formula and TMB implementation would not be auditable.
- Curie: random-slope tests should cover recovery, missingness, unsupported
  correlated syntax, and non-numeric slope rejection in one pass.
- Rose: stale wording tends to persist in vignettes after implementation
  changes, so after-task scans should include articles as well as design docs.

Follow-up design clarification:

- ordinary grouped random effects may have several separate independent numeric
  random slopes in the current implementation, for example
  `(0 + x1 | id) + (0 + x2 | id)`;
- random interaction slopes are currently supported only by precomputing the
  interaction column before fitting;
- future correlated blocks such as `(1 + x1 + x2 + x1:x2 | id)` should be
  supported only with explicit covariance-block parameterization and simulation
  checks;
- phylogenetic and spatial random slopes should be staged more conservatively:
  intercept-only first, then one structured slope in `mu`, then only a small
  number of slopes or interaction slopes after strong recovery evidence.

## 2026-05-07: Random-Slope Comparator Smoke Test

Scope:

- added an `lme4` comparator smoke test for the currently implemented
  independent Gaussian random-intercept plus random-slope model;
- compared fixed effects, random-effect SDs, residual SD, and log-likelihood
  against `lme4::lmer(..., REML = FALSE)`;
- kept the test skipped when `lme4` is not installed;
- updated the testing strategy to distinguish implemented independent
  random-slope comparator tests from future correlated-block comparator tests.

Commands run:

- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- targeted comparator tests: 14 passed, 0 failed in the local environment;
  comparator tests skip where optional comparator packages are unavailable.
- full `devtools::test()`: 191 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed.

Known issues:

- this comparator covers independent random-effect terms written as
  `(1 | id) + (0 + x | id)`;
- correlated blocks such as `(1 + x | id)` are still planned and need a
  separate comparator once implemented.

Team learning:

- Fisher: comparator tests are useful only when covariance semantics match
  exactly; independent and correlated random slopes should not share the same
  comparator claim.

## 2026-05-07: Parallel Correlated Random-Block Design

Scope:

- ran four parallel read-only side agents for the next correlated random-effect
  block phase:
  - Jason: related package landscape and source map;
  - Gauss: TMB parameterization and data-structure design;
  - Curie: simulation and comparator test plan;
  - Rose: systems audit for stale wording and consistency gaps;
- created `docs/design/17-correlated-random-effect-blocks.md`;
- fixed Rose's wording findings around `rho12`, future grammar, random-slope
  scope, random-effect SD naming, phylogenetic/spatial slope staging, and
  optional comparator wording.

Commands run:

- stale-wording `rg` scans for generic `rho`, `X_rho`, future grammar wording,
  random-slope scope, and comparator claims.
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- the next implementation target is ordinary Gaussian `mu`
  `(1 + x | id)` with a non-centered `q = 2` covariance block;
- current independent syntax `(1 | id) + (0 + x | id)` remains unchanged;
- labelled `(1 + x | p | id)` blocks remain planned after ordinary unlabelled
  blocks work and pass comparator/recovery tests.
- `git diff --check`: passed;
- stale-wording scans: remaining hits are confined to audit/check-log text that
  records the wording issues rather than active guidance;
- `devtools::test()`: 191 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

Known issues:

- this task changed design documentation only; it did not implement correlated
  random-effect covariance blocks.

Team learning:

- parallel agents are useful for read-only scouting, design review, simulation
  planning, and systems audit;
- implementation remains safer through one integrator unless file ownership is
  explicitly split;
- future spawn requests should avoid combining full-history forking with named
  specialist agents.

## 2026-05-07: Ordinary Correlated Gaussian `mu` Random-Effect Blocks

Scope:

- implemented ordinary unlabelled correlated Gaussian `mu` random
  intercept-slope blocks written as `(1 + x | id)` or `(x | id)`;
- kept independent syntax `(1 | id) + (0 + x | id)` unchanged;
- added `eta_cor_mu` in the TMB parameter vector and exposed transformed
  group-level correlations as `corpars$mu`;
- kept labelled blocks such as `(1 + x | p | id)` rejected for the later
  cross-formula covariance phase;
- updated README, NEWS, pkgdown Open Graph image config, design docs,
  location-scale docs, known limitations, roadmap, and generated reference docs;
- added a repo-facing `man/figures/drmTMB-logo.png` asset so the GitHub README
  page can refresh the hex logo without relying on the older filename cache.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- local browser preview at `http://127.0.0.1:4187/index.html`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `devtools::test(filter = 'gaussian-random-intercepts')`: 93 passed, 0
  failed;
- `devtools::test(filter = 'comparators')`: 20 passed, 0 failed;
- full `devtools::test()`: 246 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- local browser preview showed the updated home page wording and visible hex
  logo;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

Tests of the tests:

- the existing independent random-slope `lme4` comparator failed during the
  first implementation attempt because the new block layout accidentally
  treated independent slope values as intercept-like values; this caught a real
  regression and was fixed before merging;
- the new correlated-block comparator checks fixed effects, random-effect SDs,
  intercept-slope correlation, residual SD, and marginal log-likelihood against
  `lme4::lmer(..., REML = FALSE)`;
- simulation tests cover positive, near-zero, negative, high-correlation,
  weak-slope-SD, factor-fixed-effect, missingness, and malformed-syntax cases.

Known issues:

- only ordinary unlabelled `q = 2` Gaussian `mu` blocks are implemented;
- factor or multi-column random slopes, `q > 2` blocks, labelled
  `(1 + x | p | id)` blocks, scale-formula random effects, bivariate
  group-level covariance blocks, phylogenetic/spatial slope blocks, and
  non-Gaussian random-effect blocks remain planned.

Team learning:

- comparator tests are not just reassurance; they caught a real design-matrix
  regression in the first implementation pass;
- README and pkgdown can drift visually, so repo-facing assets should be
  checked alongside the built site after logo or status changes;
- keep group-level correlation extraction under `corpars`, not under residual
  `rho12`.

## 2026-05-07: Logo Blue-Density Fit Adjustment

Scope:

- adjusted the rightmost blue distribution in the hex logo so its tail fits
  inside the hex boundary rather than being clipped;
- synchronized the source SVGs, rendered README/pkgdown PNGs, and favicon
  assets.

Commands run:

- `rsvg-convert` renders for `man/figures/*.png` and `pkgdown/favicon/*.png`
- Node-based PNG-in-ICO wrapper for `pkgdown/favicon/favicon.ico`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- file-type checks for the rendered PNG and ICO assets
- `rg` checks for the updated blue-curve path in source and built-site SVGs

Results:

- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- the main logo remains 1200 x 1200 RGBA PNG;
- favicon PNG and ICO assets were regenerated from the same corrected SVG;
- visual inspection confirmed the blue density now fits inside the hex.

Known issues:

- this was a visual asset-only task; no R code, likelihood, documentation
  prose, or model examples changed.

Team learning:

- small visual regressions should still pass through the same asset
  synchronization loop: SVG source, rendered PNGs, favicon derivatives,
  pkgdown build, and after-task note.

## 2026-05-07: Labelled Gaussian `mu` Random-Effect Blocks

Scope:

- implemented labelled Gaussian `mu` random intercepts and labelled correlated
  numeric random intercept-slope blocks, written as `(1 | p | id)` and
  `(1 + x | p | id)`;
- kept the current likelihood deliberately identical to the corresponding
  unlabelled block, with the middle name retained as a covariance-block label
  in fitted object names;
- kept group-level correlations separate from residual bivariate correlation:
  labelled block correlations are returned under `corpars$mu`, while residual
  response-response correlation remains `rho12`;
- updated README, NEWS, roadmap, known limitations, formula grammar, likelihood
  notes, random-effect design notes, Gaussian math notes, bivariate-coscale
  caveats, vignettes, generated Rd, and pkgdown pages;
- left cross-formula/cross-parameter labelled covariance sharing for a later
  design phase.

Commands run:

- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted Gaussian random-effect tests: 141 passed, 0 failed;
- targeted comparator tests: 26 passed, 0 failed;
- targeted Gaussian location-scale tests: 40 passed, 0 failed;
- full `devtools::test()`: 299 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- after a read-only reviewer found two P1 issues, reserved distributional
  parameter names were rejected as covariance-block labels and the formula
  grammar vignette was split into current fixed-effect bivariate syntax versus
  future bivariate random-effect syntax; the full package check was rerun after
  those fixes and remained at 0 errors, 0 warnings, and 0 notes.

Tests of the tests:

- the labelled correlated-block test compares fixed effects, residual scale,
  random-effect standard deviations, group-level correlation, and log-likelihood
  against the same unlabelled block, because labels are metadata in the current
  implementation;
- the new `lme4` comparator checks that labelled `(1 + x | p | ID)` has the
  same mixed-model semantics as `lme4::lmer(y ~ x + f + (1 + x | ID), REML =
  FALSE)`;
- malformed-input tests cover non-symbol labels, factor random slopes, `q > 2`
  labelled blocks, duplicate covariance terms, labelled/unlabelled overlap, and
  unsupported `sigma ~ (1 | p | id)`;
- malformed-input tests now also reject misleading reserved labels such as
  `(1 + x | rho12 | id)`;
- recovery and stability tests cover moderate covariance, near-zero
  correlation, high positive/negative correlation, small residual scale, large
  residual scale, and missingness.

Known issues:

- the middle label is currently a namespace for output names and future
  matching; it does not yet tie covariance blocks across `mu1`, `mu2`, `sigma`,
  or other distributional parameters;
- random effects in `sigma`, bivariate response formulas, phylogenetic
  A-inverse effects, spatial SPDE effects, factor slopes, and `q > 2`
  correlated blocks remain planned;
- finite-sample recovery of variance components is noisy at very small residual
  scales, so CRAN-safe stability checks use tolerances that reflect this.

Team learning:

- Boole's grammar rule is now explicit: the middle term in `(1 + x | p | id)`
  is a simple label, not a data variable and not residual `rho12`;
- Gauss confirmed no TMB likelihood change was needed because labelled and
  unlabelled blocks share the same non-centered `q = 2` Gaussian machinery;
- Curie's tests should keep combining comparator checks, simulation recovery,
  and malformed-input checks for every mixed-model grammar change;
- Rose's audit caught that pkgdown, README, NEWS, roadmap, known limitations,
  and equation notes all needed synchronized wording.

## 2026-05-07: Gaussian Residual-Scale Random Intercepts

Scope:

- implemented residual-scale random intercepts in the univariate Gaussian
  `sigma` formula, written as `sigma ~ z + (1 | id)`;
- kept the first slice narrow: no labelled `sigma` blocks, no residual-scale
  random slopes, no bivariate `sigma1`/`sigma2` random effects, and no
  `sd(id) ~ x` random-effect scale models yet;
- added TMB data and parameters for `u_sigma` and `log_sd_sigma`, with
  non-centered standard-normal residual-scale random effects added to
  `log(sigma_i)`;
- updated conditional fitted-data prediction so `predict(fit, dpar = "sigma")`,
  `sigma(fit)`, residuals, and simulation include fitted `sigma` random-effect
  modes;
- updated README, NEWS, roadmap, likelihood notes, formula grammar, random
  effects notes, Gaussian math notes, testing strategy, vignettes, known
  limitations, and generated Rd.

Commands run:

- `Rscript -e "devtools::load_all(quiet = FALSE)"`
- manual smoke fit for `bf(y ~ x, sigma ~ z + (1 | id))`
- manual smoke fit for `bf(y ~ x + (1 | id), sigma ~ z + (1 | id))`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- targeted Gaussian random-effect tests: 169 passed, 0 failed;
- targeted Gaussian location-scale tests: 39 passed, 0 failed;
- full `devtools::test()`: 326 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed.

Tests of the tests:

- simulation tests cover moderate residual-scale random-intercept recovery,
  near-zero residual-scale heterogeneity, large residual-scale heterogeneity,
  missingness in `sigma` random-effect variables, and coexistence of independent
  `mu` and `sigma` random intercepts on the same grouping factor;
- malformed-input tests still reject labelled `sigma` blocks and residual-scale
  random slopes, preserving the intended narrow phase boundary;
- manual smoke fits checked that fitted `sigma` predictions are positive and
  that `sdpars$sigma` and `random_effects$sigma` are populated.

Known issues:

- residual-scale random slopes are not implemented;
- labelled covariance blocks in `sigma` are not implemented;
- `sd(id) ~ x` random-effect scale models remain a separate future
  double-hierarchical phase;
- bivariate `sigma1` and `sigma2` random effects remain future work.

Team learning:

- Bacon and Leibniz emphasized that `sigma ~ (1 | id)` and `sd(id) ~ x` are
  different likelihoods and need different tests;
- Arendt recommended this narrow residual-scale random-intercept slice before
  the broader `sd(id) ~ x` grammar because it extends the current Laplace path
  without introducing group-level scale-model matching yet;
- Ada should keep the phrase "residual-scale random intercept" visible in docs
  to avoid collapsing all scale concepts into the single word `sigma`.

## 2026-05-08: Random-Effect Scale Design And Equation Pairing

Scope:

- created the design contract for future `sd(id) ~ x_group` random-effect
  scale models in `docs/design/18-random-effect-scale-models.md`;
- added the pkgdown tutorial `vignettes/which-scale.Rmd`, pairing symbolic
  equations with R syntax for residual `sigma`, residual-scale random
  intercepts, future among-group `sd(id)`, random-slope correlations, and
  residual bivariate `rho12`;
- updated `_pkgdown.yml` so the new tutorial appears in the Tutorials menu and
  article index;
- fixed live stale wording from the previous phase: `sigma` random-effect
  eligibility, Gaussian family status, Gaussian math implementation mapping,
  phylo/spatial baseline status, location-scale vignette opening, and
  `bf()` examples;
- updated `CLAUDE.md` so Claude Code sees implemented bivariate fixed-effect
  syntax separately from future bivariate random-effect syntax;
- expanded the correlation roadmap beyond residual `rho12`, adding future
  phylogenetic, non-phylogenetic species, spatial, study/site, and other
  group-level correlations as separate covariance summaries;
- broadened the after-task stale-wording scan to catch underreported
  implementation status such as `sigma.*Later` and `currently.*only.*mu`.

Commands run:

- `gh run list --branch main --limit 6`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "pkgdown::build_site()"`
- stale-wording `rg` scans for `simple.*mu random`, `sigma.*Later`,
  `currently.*only.*mu`, `optional simple.*location`, `meta_gaussian`,
  `tau ~`, `rho ~`, `sd(id) ~ x`, and generated-site article/navigation text.

Results:

- remote GitHub Actions for commit `44e86be` completed successfully for both
  R-CMD-check and pkgdown;
- full `devtools::test()`: 326 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and rendered
  `articles/which-scale.html`;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

Tests of the tests:

- this was a design/documentation phase, so no new model tests were added;
- the full test suite and package check protect existing implemented behavior
  while the new design files remain non-executable;
- generated Rd and pkgdown pages were rebuilt to check that the roxygen example
  correction and tutorial navigation are reflected in rendered documentation.

Known issues:

- `sd(id) ~ x_group` remains planned, not implemented;
- future structured correlations need exact public extractor naming before
  implementation;
- the previous after-task report for residual-scale random intercepts
  overstated the stale-wording audit: Rose found live docs that still
  underreported implemented `sigma` random intercepts. This phase corrected
  those files and updated the protocol to make the miss less likely.

Team learning:

- Pat and Noether converged on the same requirement as Shinichi: every
  important syntax example should be paired with symbolic equations;
- Rose's systems audit caught a real process weakness in stale-wording scans;
- Ada should run the broader status-pattern scan before writing the
  consistency-audit claim, not after.

## 2026-05-08: Gaussian Random-Effect Scale MVP

Scope:

- implemented the first `sd(group) ~ x_group` random-effect scale model for
  univariate Gaussian fits;
- the implemented target is exactly one unlabelled `mu` random intercept, for
  example `bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w)`;
- added group-level design matrix construction for `sd(id)`, with predictors
  checked for constancy within group after missing-row filtering;
- added TMB likelihood support through `beta_sd_mu`, `X_sd_mu`, and
  group-specific `sd_mu_group = exp(W alpha)` while keeping standardized
  `u_mu` as the Laplace-integrated random effect;
- mapped out the replaced scalar `log_sd_mu` entry when `sd(id)` is active;
- updated coefficient, prediction, random-effect, and `sdpars` extraction so
  `coef(fit, "sd(id)")`, `predict(fit, dpar = "sd(id)")`, and
  `sdpars$sd(id)` agree with the fitted model;
- documented the symbolic model and R syntax in the likelihood, formula,
  random-effect, Gaussian math, testing, roadmap, README, NEWS, and vignette
  files;
- kept the correlation roadmap separate from this feature: residual `rho12` is
  still distinct from phylogenetic, non-phylogenetic species, spatial,
  study/site, and other group-level covariance correlations.

Commands run:

- `gh run list --branch main --limit 6`
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale|comparators')"`
- manual smoke fit for `bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w)`
- manual mapping smoke fit for `bf(y ~ x + (1 + x | site) + (1 | id), sigma ~ z, sd(id) ~ w)`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)"`
- stale-wording `rg` scans over README, NEWS, ROADMAP, docs, vignettes, R, man,
  tests, and generated pkgdown output for old `sd(id)` planned/future wording.

Results:

- prior remote GitHub Actions for commit `bd91b61` completed successfully for
  both R-CMD-check and pkgdown;
- targeted `gaussian-random-effect-scale|comparators` tests: 78 passed, 0
  failed, 0 warnings, 0 skipped;
- full `devtools::test()`: 378 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and rebuilt the reference,
  README, NEWS, and tutorials;
- the first `devtools::check()` pass had one NOTE from an unqualified
  `setNames()` call; this was fixed by using `stats::setNames()`;
- rerun `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)`:
  0 errors, 0 warnings, 0 notes.

Tests of the tests:

- simulation recovery checks estimate `mu`, `sigma`, and `sd(id)` coefficients
  from generated data;
- zero-slope tests check reduction toward a constant random-intercept scale;
- factor-RHS and missingness tests check model-matrix and retained-row handling;
- malformed-input tests cover absent targets, wrong groups, ambiguous slopes,
  labelled targets, duplicate `sd()` formulae, within-group-varying predictors,
  bivariate rejection, and unsupported non-Gaussian family rejection;
- comparator tests check the `sd(id) ~ 1` overlap against
  `lme4::lmer(..., REML = FALSE)`;
- a regression test checks that `sd(id)` still targets the correct expanded
  coefficient when a preceding correlated random-effect block is present;
- summary/vcov tests check finite aligned coefficient SEs for `sd(id)`.

Review findings addressed:

- Gauss/Fisher found no P0/P1 likelihood issues and requested a summary/vcov
  alignment test for `sd(id)`; added.
- Rose found a blocking expanded-coefficient indexing bug when another
  multi-coefficient `mu` block preceded the `sd(id)` target; fixed by carrying
  `target_coef` separately from the original random-term index and adding a
  regression test.
- Rose also found stale vignette and known-limitation wording; updated.

Known limitations:

- only one `sd(group)` formula is supported;
- the target must be one unlabelled univariate Gaussian `mu` random intercept;
- group-level predictors in `sd(group)` must be constant within the group after
  missing-row filtering;
- slope-specific, labelled-block, residual-scale, bivariate, phylogenetic,
  spatial, and non-Gaussian random-effect scale models remain future work;
- `sdpars$sd(id)` names include both the dpar and group level, while
  `predict(fit, dpar = "sd(id)")` names values by group level only. This is
  not blocking but should be revisited when extractor APIs mature.

Team learning:

- the code needed the same distinction as the mathematical notation: original
  random-effect term index and expanded covariance coefficient index are not
  the same object;
- Rose's systems audit caught both a numerical wiring risk and stale wording,
  so the after-task-audit skill is paying for itself;
- future likelihood changes should include an explicit "preceding block" test
  whenever parser terms are expanded into internal coefficient blocks.

## 2026-05-08: Formula Constructor and Composed Gaussian Family API

Scope:

- made `drm_formula()` the primary public formula constructor while keeping
  `bf()` as a short alias;
- routed `family = c(gaussian(), gaussian())` and
  `family = list(gaussian(), gaussian())` to the implemented bivariate
  Gaussian location-coscale likelihood;
- kept mixed-response bivariate families as planned future work with a clear
  error path;
- added an explicit one-response/two-response scope guard for composed
  families with more than two entries.

Commands run:

- `if command -v air >/dev/null 2>&1; then air format .; else echo 'air not installed'; fi`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'package-skeleton|biv-gaussian')"`
- manual smoke fit for `drm_formula(mu1 = y1 ~ x, mu2 = y2 ~ x)` with
  `family = c(gaussian(), gaussian())`
- manual smoke rejection for `family = c(gaussian(), poisson())`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)"`
- stale-wording `rg` scans over source, man pages, vignettes, and generated
  `pkgdown-site` for old `bf()`-primary wording, `biv_gaussian()` prototype
  wording, and obsolete composed-family future wording.

Results:

- `air` was not installed locally, so no formatter was run;
- targeted `package-skeleton|biv-gaussian` tests: 67 passed, 0 failed, 0
  warnings, 0 skipped;
- full `devtools::test()`: 389 passed, 0 failed, 0 warnings, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and regenerated
  `pkgdown-site`;
- generated-site audit confirmed `reference/bf.html` is a redirect to
  `reference/drm_formula.html`, and generated docs describe
  `drm_formula()`/`bf()` and both all-Gaussian composed-family spellings;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)`:
  0 errors, 0 warnings, 0 notes.

Tests of the tests:

- acceptance tests fit the same bivariate Gaussian likelihood through both
  `c(gaussian(), gaussian())` and `list(gaussian(), gaussian())`;
- malformed-family tests reject `c(gaussian(), poisson())`;
- new scope tests reject three-response composed families through both `c()`
  and `list()` spellings;
- constructor tests verify that `drm_formula()` captures distributional
  formula entries and that `bf()` remains a working alias.

Review findings addressed:

- Franklin found no P0/P1 issues and flagged the under-documented
  `list(gaussian(), gaussian())` spelling plus the missing three-response
  composed-family guard; both were fixed and tested.
- Jason/Rose flagged generated pkgdown lag and missing closure notes; the site
  was rebuilt, generated pages were scanned, and this check-log plus an
  after-task report now supersede earlier design-only notes.

Known limitations:

- only all-Gaussian composed bivariate families are implemented;
- mixed bivariate families such as `c(gaussian(), poisson())` still require a
  designed joint likelihood and interpretation of `rho12`;
- bivariate random effects and `mvbind()` shorthand remain future work.

Team learning:

- if code tolerates an input spelling and tests rely on it, the docs should
  either bless it or the tests should remove it;
- generated pkgdown output must be part of the phase gate whenever public API
  wording changes;
- Rose-style audits are best run before the final commit, not after, because
  small naming/API inconsistencies are cheap to fix early.

## 2026-05-08: Project-Local Prose Style Review Skill

Scope:

- read `yzhao062/agent-style` and adapted its relevant writing principles into
  a compact project-local `prose-style-review` skill;
- updated `AGENTS.md`, `CLAUDE.md`, `docs/design/10-after-task-protocol.md`,
  and Pat/Rose/documentation/pkgdown agent configs so the team can apply the
  standard consistently;
- updated `after-task-audit` so prose-heavy tasks actually trigger the prose
  gate before closing;
- recorded provenance: no files or text were copied from `yzhao062/agent-style`;
  this is a local adaptation of review principles, and `agent-style` is not a
  package dependency.

Commands run:

- browsed `https://github.com/yzhao062/agent-style` and
  `https://github.com/yzhao062/agent-style/blob/main/RULES.md`;
- `python3` TOML parse check over `.codex/agents/*.toml`;
- `git diff --check`;
- `rg` scans for dependency-wording drift, pkgdown role names,
  `skew`, and `tau`.

Results:

- TOML parse check: passed;
- `git diff --check`: passed;
- no package metadata, namespace, compiled code, tests, or likelihood code
  changed;
- Pat found no blocking confusion and requested clearer `tau`, `coscale`, and
  error-recovery wording; incorporated;
- Rose found no dependency addition and requested updating `after-task-audit`,
  normalizing dependency wording, recording provenance, and removing pkgdown
  role drift; incorporated.

Known limitations:

- this is a prose-process change only; it does not run an automatic prose
  linter;
- external links to `agent-style` are inspiration and citation context, not a
  package dependency.

Team learning:

- adding a rule to a design protocol is not enough; the operational skill that
  agents actually invoke must carry the same gate;
- Pat's user-focused review caught terminology drift before it became a docs
  habit;
- Rose's provenance check helped keep the repository lightweight and clear
  about what was adapted versus copied.

## 2026-05-08: Multiple Random-Effect Scale Formulae

Scope:

- generalized Gaussian random-effect scale formulas from one `sd(group) ~ ...`
  target to one or more distinct unlabelled `mu` random-intercept targets;
- kept `sigma ~ ...` as residual or within-observation scale and
  `sd(group) ~ ...` as random-effect SD scale;
- added a two-target simulation helper and recovery test for
  `sd(id) ~ w_id` plus `sd(site) ~ w_site`;
- updated formula grammar, likelihood, random-effect, testing, roadmap,
  vignette, README, NEWS, and known-limitations text;
- added a planning design note for future phylogenetic location-scale-shape
  models and linked shape/skewness/kurtosis papers into the reference
  programme.

Commands run:

- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale')"`
- `Rscript -e "devtools::test(filter = 'package-skeleton')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `air format .`

Results:

- targeted random-effect scale tests: 60 passed, 0 failed.
- package skeleton tests: 20 passed, 0 failed.
- comparator tests: 31 passed, 0 failed.
- full `devtools::test()`: 403 passed, 0 failed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- standard `devtools::check(error_on = "never")`: 0 errors, 0 warnings,
  1 local current-time verification note.
- check with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: passed.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- multiple `sd(group) ~ ...` formulas are still limited to distinct unlabelled
  Gaussian `mu` random intercepts. Slope-specific, labelled-block, bivariate,
  phylogenetic, spatial, and non-Gaussian scale targets remain future work.

Team learning:

- the C++ likelihood could stay simple by stacking block-diagonal
  random-effect scale design matrices on the R side;
- the old single-target assumption was scattered across extractors, prediction,
  docs, tests, and vignettes, so Rose-style stale-wording scans were essential;
- Feynman and Confucius clarified that `sd(group) ~ ...` is a bridge toward
  phylogenetic/spatial random-factor scale models, while shape/skewness should
  remain a later, more heavily tested extension.

## 2026-05-08: GitHub Actions Node 24 Opt-In

Scope:

- opted both GitHub Actions workflows into Node.js 24 for JavaScript actions
  using `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`;
- addressed the deprecation annotation emitted by GitHub Actions after the
  multiple random-effect scale formula push.

Commands run:

- `git diff --check`

Results:

- `git diff --check`: passed.

Known limitations:

- This is workflow hygiene only; package tests were not rerun locally because
  no R, C++, documentation, or package metadata changed.

## 2026-05-08: Staggered Documentation And Structured-Effect Grammar Audit

Scope:

- ran a staggered read-only team pass: Jason/Goodall mapped `gllvmTMB`
  phylogenetic/SPDE source patterns, Curie/Zeno designed the next phylogenetic
  simulation tests, and Pat/Dirac audited current docs from an applied-user
  perspective;
- clarified implemented-versus-planned sections in README and the getting
  started vignette;
- added explicit Gaussian notation convention: `Normal(a, b)` uses variance as
  the second argument;
- added a runnable `sd(population) ~ habitat` tutorial example and a three-scale
  equation block for residual `sigma`, `sd(population)`, and `sd(site)`;
- defined "coscale" at first use as residual covariance structure represented
  by `rho12` in the bivariate Gaussian seed;
- updated public phylogenetic grammar direction from dense `Cphy` examples to
  `phylo(1 | species, tree = tree)`, requiring an ultrametric tree with branch
  lengths and the Hadfield plus Nakagawa A-inverse sparse-precision path;
- aligned planned spatial grammar with the same structured random-effect shape:
  `spatial(1 | site, coords = coords)` or later
  `spatial(1 + x | site, coords = coords)`;
- separated planned structured-effect markers in pkgdown reference navigation.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); ..."` for the new
  `sd(population) ~ habitat` example;
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- stale-wording `rg` scans for inconsistent Normal notation, `Cphy`,
  `phylo(species)`, old spatial placeholders, `O'Dea-style`, and
  `biological data`;
- `git diff --check`.

Results:

- new tutorial example converged with `fit$opt$convergence == 0`, positive
  `habitatopen` coefficient for `sd(population)`, and positive predicted
  random-effect SDs;
- full `devtools::test()`: 403 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- stale-wording scans found no public `Cphy`, bare `phylo(species)`, old
  `spatial(easting, northing)`, inconsistent `Normal(..., sqrt(...))`, or
  `O'Dea-style` wording;
- `git diff --check`: passed.

Known limitations:

- this task changed design and documentation only; no phylogenetic or spatial
  likelihood code was implemented;
- the public `phylo()` and `spatial()` functions are still planned markers and
  should reject or remain inert until parser, A-inverse/SPDE, and simulation
  tests are implemented.

Team learning:

- staggered parallel work was effective: Pat found user-facing confusion while
  Jason and Curie worked ahead on the next implementation gate;
- public phylogenetic syntax should require a real ultrametric branch-length
  tree, not a user-supplied dense `Cphy`;
- phylogenetic and spatial syntax should share the same structured
  random-effect grammar, while their speed paths differ internally.

## 2026-05-08: Planned Structured-Effect Parser Markers

Scope:

- added parser metadata for planned structured-effect markers in
  `drm_formula()`;
- locked the public planned grammar for
  `phylo(1 | species, tree = tree)`,
  `phylo(1 + x | species, tree = tree)`,
  `spatial(1 | site, coords = coords)`, and
  `spatial(1 | site, mesh = mesh)`;
- added grammar validation for malformed marker calls, nested marker calls,
  multiple spatial structure inputs, and oversized structured-slope forms;
- changed `drmTMB()` unsupported-structured errors from generic formula-term
  errors to explicit "planned, not implemented" messages;
- updated formula-grammar documentation, NEWS, known limitations, and Rd
  examples.

Commands run:

- `Rscript -e 'devtools::load_all(quiet = TRUE); ...'` to inspect parsed
  structured metadata;
- `Rscript -e "devtools::test(filter = 'package-skeleton')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- stale-wording `rg` scan for old bare `phylo(species)`, `Cphy`,
  `spatial(x, y)`, and generic public unsupported-status wording;
- `git diff --check`.

Results:

- interactive parser inspection stored `type`, `group`, `tree`/`coords`, and
  one-slope coefficient metadata without evaluating external objects;
- focused parser test: 35 passed, 0 failed;
- full `devtools::test()`: 420 passed, 0 failed;
- Rose's systems audit found no blockers; the non-blocking mesh metadata test
  gap and after-task role-name wording were resolved before commit;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- stale-wording scan found only expected historical after-task notes, parser
  failure tests, and still-valid generic unsupported-term tests for unrelated
  syntax;
- `git diff --check`: passed.

Known limitations:

- `phylo()` and `spatial()` are still planned markers; no TMB likelihood,
  A-inverse construction, tree validation, SPDE mesh construction, or
  structured-effect simulation recovery was implemented in this task;
- the first fitting target remains univariate Gaussian `mu` with an
  intercept-only phylogenetic structured effect from an ultrametric
  branch-length tree.

Team learning:

- parser-recognized planned syntax is useful because it lets docs and tests
  stabilize the public API before numerical implementation;
- the current parser can safely avoid evaluating `tree`, `coords`, and `mesh`
  while still detecting invalid grammar early;
- `rho12` remains reserved for residual bivariate response correlation, not
  phylogenetic or spatial structured-effect covariance.

## 2026-05-08: Phylogenetic Tree Validation Scaffold

Scope:

- added internal validation for tiny ultrametric `phylo` objects with branch
  lengths, unique tip labels, one root, connected node structure, and observed
  species matching;
- added an internal dense Brownian shared-history covariance/correlation
  comparator for exact tiny-tree tests;
- documented the comparator math as a test and teaching tool, not the
  user-facing large-tree phylogeny API;
- updated known limitations to distinguish the internal validator from fitted
  `phylo()` model support.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic utility tests: 18 passed, 0 failed;
- full `devtools::test()`: 438 passed, 0 failed;
- `git diff --check`: passed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- The dense Brownian comparator is internal and test-oriented. It does not fit
  `phylo()` model terms and should not replace the planned sparse A-inverse
  path.

Team learning:

- tiny algebraic trees are a good bridge between Noether's symbolic checks and
  Gauss's future sparse-precision implementation;
- Zeno's simulation plan and Goodall's `gllvmTMB` source map both support using
  dense tree comparators only as validation scaffolding before the A-inverse
  likelihood path;
- public docs must continue to say that `phylo(1 | species, tree = tree)` is
  planned, even though internal tree checks now exist.

## 2026-05-08: Phylogenetic Augmented Precision Scaffold

Scope:

- added an internal sparse augmented Brownian precision helper for ultrametric
  `phylo` trees with positive branch lengths;
- fixed the root state at zero and excluded it from the latent vector;
- defaulted the precision to the phylogenetic correlation scale used by
  `z ~ MVN(0, sigma_phylo^2 A)`;
- tested sparse augmented precision against the existing dense Brownian
  comparator by marginalizing the augmented covariance back to tips;
- added species-to-tip and species-to-augmented-node mapping metadata for the
  future `phylo(1 | species, tree = tree)` likelihood path.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic utility tests: 39 passed, 0 failed.
- full `devtools::test()`: 459 passed, 0 failed.
- `git diff --check`: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- no fitted `phylo()` model term or TMB likelihood was changed in this slice;
- zero-length branches are rejected by the precision helper, even though the
  tree validator can still validate a zero-length ultrametric tree;

Team learning:

- Locke caught the key numerical distinction: the tip block of a precision
  matrix is not the marginal tip precision; tests must solve the augmented
  system and then select tip rows;
- Pasteur's test plan helped pin exact log-determinants, edge-order
  invariance, species mapping, and malformed-input paths;
- this helper is the bridge from symbolic Brownian increments to the eventual
  TMB sparse prior block.

## 2026-05-08: Phylogenetic Prior NLL Algebra Helper

Scope:

- added an internal pure-R Gaussian prior contribution helper for augmented
  phylogenetic effects;
- matched the helper to the sparse augmented precision, log determinant, and
  structured-effect SD parameterization that the future TMB block should use;
- added tests comparing the helper with the explicit Gaussian precision-density
  formula and the edge-increment quadratic form.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic utility tests: 43 passed, 0 failed.
- full `devtools::test()`: 463 passed, 0 failed.
- `git diff --check`: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- no TMB likelihood or fitted `phylo()` model term was changed in this slice;

Team learning:

- the Gaussian prior constant must use `-logdet(Q_A)` in the NLL expression
  because `Q_A` is the precision for the correlation matrix;
- testing the edge-increment quadratic and the precision-density formula in
  the same test gives Noether and Gauss the same contract before C++ work.

## 2026-05-08: Hidden TMB Phylogenetic Prior Parity Branch

Scope:

- added a hidden `model_type == 99` TMB branch for the augmented phylogenetic
  Gaussian prior contribution only;
- added dummy TMB data and mapped dummy parameters so existing Gaussian and
  bivariate Gaussian fits are unaffected;
- added a test comparing the TMB objective value with the pure-R prior NLL
  helper on the exact tiny tree.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic utility tests: 45 passed, 0 failed.
- full `devtools::test()`: 465 passed, 0 failed.
- `git diff --check`: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- `air` is not installed locally, so formatting could not be run.
- this is a parity-test branch, not fitted `phylo()` model support;

Team learning:

- adding a C++ parity branch before model-builder plumbing is a useful
  low-risk bridge from R algebra to TMB implementation;
- this protects the next fitting slice from simultaneously debugging formula
  parsing, sparse precision construction, and C++ prior constants.
