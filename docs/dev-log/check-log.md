# Check Log

Record meaningful development checks here.

## 2026-05-08: Implemented Source Map

Scope:

- added a developer source-map article that links implemented model paths to
  their R builders, TMB `model_type` branches, tests, and docs;
- added the article to the pkgdown Developer Notes menu and articles index;
- fixed stale location-scale wording so `sd(id) ~ x_group` is described as an
  implemented double-hierarchical random-effect scale path rather than future
  work;
- recorded the known follow-up that Gaussian known-covariance meta-analysis
  with `sd(group) ~ predictors` needs targeted validation before routine
  tutorial use.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n 'Later double-hierarchical|This developer article will|current planning reference|model_type = 99|meta_gaussian|tau ~|rho ~|c\\(gaussian\\(\\), poisson\\(\\)\\)|skew_normal\\(\\)' vignettes/source-map.Rmd vignettes/location-scale.Rmd _pkgdown.yml docs/design/08-meta-analysis.md`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct source-map render: passed;
- direct source-map and location-scale render after stale-wording fix: passed;
- `git diff --check`: clean;
- stale/unsupported-syntax scan: no old placeholder text and no stale "Later
  double-hierarchical" wording remained. Remaining hits were intentional:
  `model_type = 99` is documented as internal, `c(gaussian(), poisson())` is in
  an unsupported-feature list, and `meta_gaussian()` / `tau ~` are in the
  meta-analysis guardrail design note;
- `pkgdown::check_pkgdown()`: no problems found;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- no package code changed; this task mapped existing tests to implemented paths;
- the source map was checked against Jason's source-only scan and against
  rendered pkgdown navigation.

Notes:

- Jason identified the stale location-scale sentence and the missing central
  model-type table. The new source-map article closes the model-type table gap;
  the location-scale wording was updated.
- Jason also identified that `meta_known_V()` plus `sd(group) ~ predictors`
  needs targeted validation. The source map now names that as a follow-up rather
  than teaching it as routine syntax.
- the already-pushed `fe0cd04` adding-families commit passed GitHub pkgdown and
  R-CMD-check on macOS, Ubuntu, and Windows; only GitHub runner deprecation
  notices were reported.

## 2026-05-08: Adding Families Developer Guide

Scope:

- replaced the placeholder `adding-families` pkgdown article with a practical
  developer guide for adding a family to `drmTMB`;
- paired symbolic equations, R syntax, registry fields, TMB likelihood mapping,
  simulation support, tests, documentation, pkgdown, and after-task closure;
- used implemented Student-t and bivariate Gaussian patterns as the worked
  examples rather than presenting unsupported families as runnable code;
- kept the one-response/two-response boundary, canonical `mu`/`sigma`/`nu`/
  `tau` naming, and canonical residual `rho12` wording explicit.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n 'This developer article will|rho ~|tau ~|meta_gaussian|family = c\\(gaussian\\(\\), poisson\\(\\)\\)|skew_normal\\(\\)|bivariate random effects|bivariate Student-t|sparse known covariance|not implemented|planned' vignettes/adding-families.Rmd`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct vignette render: passed;
- `git diff --check`: clean;
- prose-style review: passed with no follow-up edits needed; the article names
  contributors as the reader, leads with the family contract, and pairs
  equations with supported syntax;
- stale/unsupported-syntax scan: no old placeholder text, no `rho ~`, no
  `tau ~`, no `meta_gaussian`, no mixed composed-family runnable example, and
  no skew-normal runnable example. Remaining hits are intentional planned-syntax
  or rejection-message wording;
- `pkgdown::check_pkgdown()`: no problems found;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- no package code changed; the article points contributors to already
  implemented test patterns: Student-t independent likelihood checks,
  simulation recovery, method checks, rejection tests, and comparator tests.

Notes:

- the documentation-writer sidecar provided the outline and flagged the main
  stale-wording risks before drafting;
- `R CMD check` emitted only the standard installed-size INFO for compiled TMB
  code; the final status was still 0/0/0.

## 2026-05-08: Testing Likelihoods Developer Guide

Scope:

- replaced the placeholder `testing-likelihoods` pkgdown article with a
  developer guide for likelihood validation;
- paired symbolic equations with `drmTMB` syntax for Gaussian location-scale,
  Gaussian random-intercept comparators, dense known-`V` meta-analysis,
  Student-t location-scale-shape, and bivariate `rho12` models;
- documented the two-tier testing pattern: comparator checks against established
  packages and simulation/independent-likelihood checks;
- clarified that `glmmTMB::equalto()` is a planned comparator, not currently in
  routine tests;
- labelled planned skew-normal syntax as future-only in the GAMLSS parameter
  naming design note;
- synchronized the collaboration/team table with the current standing review
  roles in `AGENTS.md`.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/testing-likelihoods.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n "This developer article will|will document simulation recovery|current planning reference|skew_normal\\(\\)|glmmTMB::equalto\\(\\)|Current Agent Team|Testing likelihoods" vignettes docs/design README.md ROADMAP.md NEWS.md`
- `rg -n 'location means|complete-row `2n`|per-study list|This developer article will|will document simulation recovery|glmmTMB::equalto\\(\\)|skew_normal\\(\\)' vignettes/testing-likelihoods.Rmd docs/design/05-testing-strategy.md docs/design/08-meta-analysis.md docs/design/11-reference-programme.md docs/design/14-gamlss-parameter-names.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-08-testing-likelihoods-developer-guide.md`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct vignette render: passed;
- `git diff --check`: clean;
- stale-wording scan: no old `testing-likelihoods` placeholder text remained in
  the article; remaining `skew_normal()` and `glmmTMB::equalto()` hits are
  planned-feature references;
- post-audit scan: found the new location/scale/shape/coscale definition, the
  row-paired `2n` by `2n` wording, and only intentional planned-feature
  references;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- no package code changed, so this task used the existing full test suite plus
  vignette rendering and pkgdown checks;
- the new article points contributors to test patterns that already exist:
  independent likelihood checks, comparator checks, rejection tests, and
  bivariate sampling-versus-residual covariance checks.

Notes:

- Pat reviewed the placeholder article and identified that pkgdown exposed a
  two-sentence page where contributors expected a practical recipe; this task
  fixes that gap.
- Rose caught two P2 wording issues after the first draft: the article needed to
  define location, scale, shape, and coscale at first use, and the bivariate
  known-`V` wording needed to say that the implemented input is a complete-row
  `2n` by `2n` row-paired matrix rather than a per-study list of `S_i` blocks.
- one post-audit `rg` scan failed because shell backticks in the pattern were
  not quoted safely; the successful scan used single quotes and is recorded
  above.
- `R CMD check` emitted only the standard installed-size INFO for compiled TMB
  code; the final status was still 0/0/0.

## 2026-05-08: Dense Known-`V` `metafor::rma.mv()` Comparator

Scope:

- added a comparator smoke test for dense full known sampling covariance in
  Gaussian meta-analysis;
- compared `drmTMB` against `metafor::rma.mv(..., random = ~ 1 | obs,
  method = "ML")` for the overlapping case where the unknown residual
  heterogeneity is a constant observation-level variance component;
- updated the testing strategy so this comparator is listed as implemented
  rather than planned.

Commands run:

- ad hoc `drmTMB` versus `metafor::rma.mv()` smoke comparison for fixed effects,
  heterogeneity variance, and log-likelihood;
- `Rscript -e "devtools::test(filter = 'comparators|meta-known-v')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n 'rma\\.mv|dense known sampling covariance|metafor::rma\\.mv' docs/design/05-testing-strategy.md tests/testthat/test-comparators.R docs/dev-log/check-log.md`

Results:

- targeted comparator and meta-known-`V` tests: 73 passed, 0 failed;
- full `devtools::test()`: 642 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt successfully;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the comparator checks fixed-effect coefficients, the estimated residual
  heterogeneity variance, and the full ML log-likelihood against independent
  `metafor` output;
- the dense `V` matrix has off-diagonal sampling covariance, so it is not just
  a diagonal-known-variance repeat.

Notes:

- the first source scan command failed because shell backticks in the pattern
  were not quoted safely; the successful recorded `rg` command uses single
  quotes.

## 2026-05-08: Student-t Status Inventory Cleanup

Scope:

- fixed status-inventory drift after the Student-t implementation;
- updated README current status, ROADMAP, known limitations, formula grammar
  maps, family docs, and affected tutorials to list the implemented
  fixed-effect univariate Student-t path;
- clarified that `family = c(gaussian(), poisson())` is planned, not runnable
  implemented syntax;
- replaced active Student-t "tail weight" wording with "tail shape" or
  degrees-of-freedom language where larger `nu` could otherwise be read
  backwards;
- updated the after-task protocol and project-local `after-task-audit` skill so
  future family, grammar, diagnostic, and implemented-scope changes must check
  the status inventory explicitly.

Commands run:

- `Rscript -e "devtools::load_all(quiet=TRUE); for (f in c('vignettes/distribution-families.Rmd','vignettes/formula-grammar.Rmd','vignettes/robust-student.Rmd','vignettes/model-workflow.Rmd')) rmarkdown::render(f, output_format = rmarkdown::html_vignette(), output_file = tempfile(fileext = '.html'), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Status-inventory and stale-wording scans:

- `rg -n "tail weight|tail-weight|heavy-tail parameter|all non-Gaussian families are planned|Add Student-t|fitted Gaussian likelihood path" README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R man NEWS.md tests pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n "family = c\\(gaussian\\(\\), poisson\\(\\)\\)" README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes tests pkgdown-site --glob '!pkgdown-site/search.json'`

Results:

- standalone renders for the four touched vignettes passed;
- full `devtools::test()`: 638 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the affected articles, home page, roadmap,
  and search index;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean;
- the first stale-wording scan returned no active hits;
- the mixed-family scan returns only planned/future-work text or the deliberate
  unsupported-syntax test.

Tests of the tests:

- no new unit tests were added because this was a documentation and process
  consistency task;
- full tests and R CMD check were run to ensure the vignette/status edits did
  not break examples or package checks.

Notes:

- Pat caught the runnable-looking mixed-family code block in the family article;
- Rose caught the stale known-limitations and formula-status maps;
- the after-task protocol now requires exact status-inventory scans for this
  class of change.

## 2026-05-08: Student-t Scale Terminology Audit

Scope:

- clarified package-level README wording so `sigma` is the general residual
  scale parameter, with Gaussian residual SD as a special case;
- clarified `sigma.drmTMB()` documentation so Student-t `sigma` is described
  as the Student-t scale parameter;
- documented the residual standard deviation conversion
  `sigma * sqrt(nu / (nu - 2))` when `nu > 2`.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'student-location-scale')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg` scans for Student-t `sigma` and residual-standard-deviation wording.

Results:

- roxygen rebuilt `man/sigma.drmTMB.Rd`;
- targeted Student-t tests: 21 passed, 0 failed;
- full `devtools::test()`: 638 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the home page and `sigma.drmTMB()`
  reference page with the revised scale wording;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- this was a documentation terminology task, so no new unit tests were added;
- targeted Student-t tests were rerun to check that no documentation edit
  accidentally accompanied a behaviour change.

Notes:

- Gaussian-specific tutorials still correctly describe `sigma` as residual
  standard deviation because `Normal(mu_i, sigma_i^2)` uses `sigma_i` that way;
- Student-t tutorials and extractor documentation now explicitly distinguish
  scale from residual SD.
- no helper currently returns Student-t residual SD directly; users can compute
  it from `sigma()` and `predict(..., dpar = "nu")` when `nu > 2`.

## 2026-05-08: Robust Student-t Tutorial

Scope:

- added `vignettes/robust-student.Rmd` as a user-facing tutorial for
  fixed-effect Student-t location-scale-shape models;
- paired the symbolic Student-t equation with matching `drmTMB` syntax;
- used a seedling growth example with ambient and dry treatments;
- documented the distinction between Student-t `sigma` as a scale parameter
  and the residual standard deviation `sigma * sqrt(nu / (nu - 2))`;
- explained `check_drm()` `student_nu` output and next steps for near-boundary
  tail estimates;
- added the tutorial to the pkgdown Tutorials menu and article index;
- linked the tutorial from the response-family article.

Commands run:

- `Rscript -e "devtools::load_all(quiet=TRUE); rmarkdown::render('vignettes/robust-student.Rmd', output_format = rmarkdown::html_vignette(), output_file = tempfile(fileext = '.html'), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'student-location-scale|check-drm')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- generated-site scans for `robust-student.html`, Student-t scale wording,
  `dry_i`, navigation, and near-boundary `nu` guidance.
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- standalone vignette render with `devtools::load_all()`: passed;
- targeted Student-t and `check_drm()` tests: 74 passed, 0 failed;
- full `devtools::test()`: 638 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: built `articles/robust-student.html` and updated
  article indexes and navigation.
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.

Tests of the tests:

- Volta reviewed the tutorial from an applied-user perspective and caught that
  early prose incorrectly described Student-t `sigma` as residual standard
  deviation;
- Dewey caught that the first draft underclaimed implemented fixed-effect
  `nu ~ predictors` syntax and lacked protocol closure.

Notes:

- the first direct `rmarkdown::render()` failed because the vignette calls
  `library(drmTMB)` before the package is installed; the successful local
  render used `devtools::load_all()`, and pkgdown installs the package before
  rendering.

## 2026-05-08: `check_drm()` Student-t `nu` Diagnostics

Scope:

- added a `student_nu` row to `check_drm()` for Student-t fits;
- report an error for non-finite `nu` values or values not above 2;
- report a warning when fitted `nu` is very close to the finite-variance
  boundary at 2;
- report a note when fitted `nu` is large enough that the fitted tail behaviour
  may be close to Gaussian;
- synchronized the `check_drm()` diagnostic summaries in README, vignettes,
  NEWS, roxygen, and the phylogenetic/spatial design note.

Commands run:

- `Rscript -e "devtools::test(filter = 'check-drm|student-location-scale')"`
  before fixing the test fixture: failed because the fitted Student-t fixture
  legitimately landed near the `nu = 2` boundary;
- `Rscript -e "devtools::test(filter = 'check-drm|student-location-scale')"`
  after fixture and coverage updates;
- `Rscript -e "devtools::document()"`
- `air format .` (failed: `air` is not installed);
- Rawls read-only reviewer pass over implementation, tests, and docs;
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- stale-wording scans for `check_drm()` diagnostic lists and Student-t `nu`
  wording;
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- targeted `check_drm()` plus Student-t tests: 74 passed, 0 failed;
- full `devtools::test()`: 638 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the `check_drm()` reference page, overview
  article, model-workflow article, home page, and changelog;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the first targeted test run failed because the ordinary Student-t fixture was
  too heavy-tailed and correctly triggered a boundary warning;
- the revised test uses controlled coefficient mutations to exercise the ok,
  warning, note, and error branches independently of optimizer behaviour;
- a separate predictor-varying `nu ~ x` test checks that `check_drm()` reports
  a fitted `nu` range rather than only an intercept-only value.

Notes:

- large `nu` is a `note`, not a warning, because it can be a scientifically
  useful result: the robust model may simply be close to Gaussian;
- near-boundary `nu` is a `warning` because the finite-variance lower bound can
  be influential for inference and should be inspected.

## 2026-05-08: Student-t Fixed-Effect Location-Scale-Shape

Scope:

- added `student()` as a one-response robust continuous family with
  `mu`, `sigma`, and `nu` formulas;
- implemented the Student-t likelihood in TMB with
  `nu_i = 2 + exp(eta_nu_i)` and all normalizing constants;
- added prediction, simulation, residual, summary, and scale-extractor support
  through the existing S3 methods;
- added simulation-recovery, independent R likelihood comparison, method, and
  unsupported-term tests;
- updated family registry, likelihood, distribution-roadmap, shape-planning,
  README, NEWS, roxygen, pkgdown reference, and distribution-family vignette
  documentation.

Commands run:

- `Rscript -e "devtools::load_all()"`
- ad hoc Student-t fit, coefficient, prediction, and simulation smoke test;
- `Rscript -e "devtools::test(filter = 'student-location-scale')"`
- targeted regression slice:
  `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|meta-known-v|phylo-gaussian')"`
- `Rscript -e "devtools::document()"` twice, rerunning after the new
  `student()` topic existed;
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- generated-site and stale-wording scans for Student-t claims;
- `air format .` (failed: `air` is not installed);
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

Results:

- final targeted Student-t tests: 21 passed, 0 failed;
- targeted Gaussian/bivariate/meta/phylo regression slice: 196 passed,
  0 failed;
- full `devtools::test()`: 623 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the `student()` reference page,
  distribution-family article, home page, and changelog;
- final `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the Student-t objective is compared against an independent base-R likelihood
  using `dt((y - mu) / sigma, df = nu, log = TRUE) - log(sigma)`;
- the recovery test uses deterministic Student-t quantiles to keep CRAN tests
  stable while checking `mu`, `sigma`, and tail `nu`;
- unsupported early-phase terms test random effects, `meta_known_V(V = V)`,
  and `sd(group)` rejection for Student-t fits.

Notes:

- the first full test run failed because the direct TMB phylogenetic-prior test
  constructs its own data list and needed the new dummy `X_nu` and `beta_nu`
  entries; the helper was updated and the full test suite then passed;
- `student()` is fixed-effect only for now: no random effects, known sampling
  covariance, phylogenetic terms, or bivariate Student-t likelihood yet;
- `nu` is the canonical first shape parameter here and means Student-t degrees
  of freedom/tail shape, not skewness.

## 2026-05-08: Main Documentation Known-`V` Equation Pairing

Scope:

- paired the public bivariate Gaussian meta-analysis syntax with the symbolic
  row-paired model equation in the README and main overview vignette;
- defined `y_stack = (y1_1, y2_1, ..., y1_n, y2_n)'` before the
  `V + Omega_stack` likelihood;
- clarified that the long-term bivariate random-effect example in the formula
  grammar is not the current implemented bivariate random-effects surface.

Commands run:

- `git diff --check`
- stale-wording scans for old bivariate known-`V` and unsupported-syntax text
  in README, vignettes, design docs, and selected generated pages;
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `git diff --check`: clean;
- `pkgdown::check_pkgdown()`: no problems found;
- targeted bivariate test: 84 passed, 0 failed;
- `pkgdown::build_site()`: rebuilt the home page and main overview article;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- generated pages now include the new row-paired `y_stack` equation and
  matching `meta_vcov_bivariate()` syntax.

Notes:

- no implementation changed in this task;
- old dev-log entries that mention earlier rejected full/block known
  covariance behaviour were left intact as historical records;
- remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails.

## 2026-05-08: Bivariate Gaussian Known Sampling Covariance Likelihood

Scope:

- implemented complete-row bivariate Gaussian known-`V` fitting, where
  `meta_known_V(V = V)` supplies a dense row-paired `2n` by `2n` sampling
  covariance matrix;
- added the known sampling covariance to the fitted residual covariance from
  `sigma1`, `sigma2`, and `rho12` before evaluating the TMB multivariate
  normal likelihood;
- updated bivariate `simulate()` and Pearson residuals to use the full
  row-paired observation covariance when known `V` is present;
- added likelihood-comparison, residual-`rho12` recovery, missing-row, and
  malformed-input tests;
- updated README, formula grammar, likelihood, distribution-roadmap,
  meta-analysis vignette, NEWS, and generated roxygen documentation.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- stale-wording scans for planned bivariate known-`V` text, stale diagonal/full
  covariance claims, informal author-style shorthand, and active-doc
  `meta_gaussian()` / `tau ~` guardrails.

Results:

- targeted bivariate test: 84 passed, 0 failed;
- full `devtools::test()`: 602 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt meta-analysis, formula grammar, NEWS,
  `simulate()`, and `residuals()` pages;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Notes:

- active docs and generated pages no longer describe bivariate known `V` as a
  planned likelihood task;
- remaining `planned, not implemented` matches are for structured
  phylogenetic/spatial slopes and other intentionally planned features;
- remaining `meta_gaussian()` and `tau ~` matches are guardrails against
  unwanted meta-analysis syntax.

## 2026-05-08: Bivariate Meta-Analysis Covariance Helper

Scope:

- implemented `meta_vcov_bivariate()` as a user-facing constructor for
  row-paired dense known sampling covariance matrices;
- added tests for covariance construction from `cov12`, construction from
  `cor12`, independent-sampling defaults, and malformed input rejection;
- updated meta-analysis documentation to distinguish the implemented helper
  from the still-planned bivariate known-`V` likelihood.

Commands run:

- `Rscript -e "devtools::load_all(); V <- meta_vcov_bivariate(c(0.04, 0.03), c(0.05, 0.02), cor12 = c(0.4, 0.2)); stopifnot(all(dim(V) == c(4, 4))); print(V)"`
- `Rscript -e "testthat::test_file('tests/testthat/test-meta-vcov.R')"` (failed because this direct call did not load the package namespace)
- `Rscript -e "devtools::test(filter = 'meta-vcov')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- stale-wording and generated-site scans for `meta_vcov_bivariate()`, planned
  bivariate known-`V` wording, `meta_gaussian()`, `tau ~`, and malformed
  `meta_known_V()` markers.

Results:

- targeted `devtools::test(filter = 'meta-vcov')`: 17 passed, 0 failed;
- full `devtools::test()`: 589 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: rebuilt the helper reference page and meta-analysis
  article;
- `devtools::check(...)`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

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

## 2026-05-08: Fitted Univariate Gaussian Phylogenetic Location Model

Scope:

- implemented the first public fitted phylogenetic model path:
  `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z)` with
  `family = gaussian()`;
- removed the `phylo()` marker from the fixed-effect `mu` formula before model
  matrix construction and routed an intercept-only phylogenetic structured
  effect into the Gaussian TMB branch;
- passed the sparse augmented Brownian precision, log determinant, and
  observation-to-tip mapping into TMB;
- added fitted-model tests, prediction algebra tests, missingness tests, and
  rejection tests for unsupported phylogenetic slopes and `sigma` terms;
- updated NEWS, README, formula grammar, phylogenetic/spatial math notes,
  known limitations, roxygen documentation, ROADMAP, and pkgdown site output.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo')"`
- `Rscript -e "devtools::document()"`
- `git diff --check`
- `command -v air`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted phylogenetic tests: 57 passed, 0 failed.
- full `devtools::test()`: 477 passed, 0 failed.
- `devtools::document()`: regenerated `man/drmTMB.Rd` and `man/phylo.Rd`.
- `git diff --check`: passed.
- `command -v air`: no local `air` executable found.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: site built successfully.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- fitted phylogenetic support is limited to intercept-only univariate Gaussian
  `mu` terms;
- phylogenetic random slopes, phylogenetic `sigma` terms, bivariate
  structured covariance, spatial fields, and structured effects in `rho12`
  remain planned;
- simulation recovery is CRAN-safe and intentionally modest, so larger
  long-run recovery and comparator studies are still needed.

Team learning:

- the latent phylogenetic effect is already on the response scale because the
  prior is `z ~ MVN(0, sigma_phylo^2 A)`; the `mu` predictor adds `z_tip`
  directly rather than multiplying by `sigma_phylo` a second time;
- the fitted path became much safer because the R-side prior helper and hidden
  TMB parity branch already fixed the sparse precision and log-determinant
  contract;
- one fixed-effect recovery tolerance had to be relaxed for a 16-tip CRAN-safe
  simulation, reminding us that phylogenetic SD recovery tests should avoid
  pretending small trees provide large-sample certainty.

## 2026-05-08: Equation-Syntax Documentation Consistency Pass

Scope:

- strengthened the get-started vignette so implemented Gaussian
  location-scale, residual-scale, `sd(group)`, bivariate `rho12`,
  `meta_known_V(V = V)`, and phylogenetic `mu` examples pair R syntax with
  symbolic equations;
- added compact equation context to the README for bivariate residual
  covariance, known sampling covariance, and phylogenetic location effects;
- corrected formula-grammar status wording for bivariate random effects,
  `mvbind()` shorthand, and implemented intercept-only `phylo()` support;
- corrected roadmap wording so `sd(group)` support is consistently described
  as one or more distinct unlabelled univariate Gaussian `mu` random-intercept
  targets;
- updated pkgdown navigation wording for structured-effect markers;
- clarified that phylogenetic residual-scale terms remain planned while
  intercept-only phylogenetic `mu` is implemented.

Commands run:

- `rg` stale-status scans for bivariate random-effect, `mvbind()`,
  intercept-only `phylo()`, `sd(group)`, old person-name shorthand, and
  biology-only wording;
- `git diff --check`;
- `Rscript -e "pkgdown::check_pkgdown()"`;
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`;
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`.

Results:

- targeted stale-status scan: no remaining matches for the exact status
  problems reported by Pat and Rose, except historical check-log and
  after-task notes that were true when written;
- `git diff --check`: passed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- this was a documentation and consistency pass, not new model-fitting code;
- shape, zero inflation, mixed bivariate families, `mvbind()` shorthand,
  bivariate random effects, phylogenetic slopes, phylogenetic `sigma`, and
  spatial terms remain planned;
- rendered pkgdown search text still includes historical changelog entries and
  old after-task notes, which should not be mechanically rewritten.

Team learning:

- Pat was right that the first public page needed an applied question before
  equations; users should see why they are fitting the model before they see
  symbols;
- Rose caught that status drift, rather than terminology drift, was the main
  risk in this phase;
- shell searches containing backticks must be single-quoted so zsh does not
  try to execute fragments such as `mu`.

## 2026-05-08: Dense Comparator For Fitted Phylogenetic Gaussian Objective

Scope:

- added a CRAN-safe fitted-model comparator test for the intercept-only
  univariate Gaussian phylogenetic `mu` path;
- the test fits `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)` on a
  four-tip ultrametric tree and compares the TMB/Laplace objective to an
  independent dense marginal Gaussian negative log likelihood;
- a second comparator fits
  `bf(y ~ x + (1 | species) + phylo(1 | species, tree = tree), sigma ~ 1)`
  and checks the marginal covariance with both non-phylogenetic and
  phylogenetic species intercepts;
- a third comparator fits Gaussian meta-analysis with known sampling variance
  and a phylogenetic `mu` intercept, checking
  `Sigma = V_known + sigma^2 I + sd_phylo^2 A_obs`;
- the dense comparator uses
  `Sigma = sigma^2 I + sd_phylo^2 A[species, species]`, where `A` is built by
  the dense Brownian tip-covariance helper, and extends to
  `Sigma = sigma^2 I + sd_species^2 I_species + sd_phylo^2 A_obs` for the
  combined species model, and to
  `Sigma = V_known + sigma^2 I + sd_phylo^2 A_obs` for the known-variance
  meta-analytic model;
- this strengthens the bridge between the public equation,
  `a ~ MVN(0, sigma_phylo^2 A)`, and the sparse augmented A-inverse
  implementation.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `Rscript -e "devtools::test(filter = 'phylo')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `phylo-gaussian` tests: 18 passed, 0 failed;
- targeted phylogenetic tests: 63 passed, 0 failed;
- full `devtools::test()`: 483 passed, 0 failed.
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- the comparators use tiny dense covariance matrices for testing; this is not
  the large-tree fitting route;
- this validates the fitted marginal objective at the fitted parameter values,
  not long-run parameter-recovery coverage across many tree shapes.

Team learning:

- Curie's read-only review identified the right next gap: utility tests already
  checked sparse algebra, but the fitted model needed an end-to-end marginal
  likelihood comparator;
- a dense comparator is a compact way to test the sparse A-inverse route
  without turning CRAN tests into long simulations.

## 2026-05-08: Formula Grammar Status Map And Stale-Status Cleanup

Scope:

- added a current-status map to the formula grammar vignette so users can
  distinguish implemented, reserved, and planned syntax before copying code;
- marked planned phylogenetic slope, spatial, and bivariate random-effect
  examples as planned-only in visible docs;
- corrected stale active-doc wording that still treated intercept-only
  `phylo(1 | species, tree = tree)` and random-intercept meta-regression as
  wholly future;
- updated the `drmTMB()` help page to mention implemented
  `meta_known_V(V = V)` support;
- regenerated roxygen documentation and rebuilt the pkgdown site.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "planned|not implemented|future|Reserved|roadmap|Current planned" README.md vignettes docs/design R man | rg "phylo\\(1 \\||meta_known_V|sd\\(group\\)|mvbind|rho12|spatial|A-inverse|random-intercept meta"`

Results:

- full `devtools::test()`: 483 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- GitHub Actions for commit `48a9085` completed successfully for both
  `R-CMD-check` and `pkgdown`;
- remaining stale-status grep hits were manually classified as appropriate
  planned-feature or roadmap wording, not contradictions with implemented
  support.

Known limitations:

- this was a documentation/status-consistency pass, not new fitting code;
- historical after-task notes and changelog entries may describe older states
  and should not be mechanically rewritten;
- spatial fields, phylogenetic slopes, phylogenetic `sigma`, bivariate
  structured effects, `mvbind()` shorthand, and mixed bivariate families remain
  planned.

Team learning:

- Pat found that visible planned examples need inline comments, not only
  surrounding prose;
- Rose found that stale status wording now needs a standard close-out grep
  whenever an implemented feature crosses from roadmap to current support.

## 2026-05-08: Dense Full-V Plus Phylogenetic And Study Comparators

Scope:

- added a CRAN-safe likelihood comparator for Gaussian known-covariance
  meta-analysis combined with the intercept-only phylogenetic `mu` effect;
- the test fits
  `bf(yi ~ x + meta_known_V(V = V) + phylo(1 | species, tree = tree), sigma ~ 1)`
  with a dense full sampling covariance matrix;
- a second test adds an ordinary `mu` study random intercept to the same
  dense known-`V` plus phylogenetic model;
- the independent comparator checks the fitted objective against
  `Sigma = V_known + sigma^2 I + sd_phylo^2 A_obs`, and against
  `Sigma = V_known + sigma^2 I + sd_study^2 J_study + sd_phylo^2 A_obs`
  for the study-intercept model.

Commands run:

- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `phylo-gaussian` tests: 25 passed, 0 failed;
- full `devtools::test()`: 490 passed, 0 failed;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Known limitations:

- the test uses a small dense covariance matrix to keep CRAN checks fast;
- it validates the marginal objective at fitted values, not long-run
  simulation recovery for large full-`V` phylogenetic meta-analyses.

Team learning:

- combining two already-tested covariance paths is still worth an explicit
  comparator because row order, covariance addition, and Laplace integration
  can drift independently.

## 2026-05-08: Fixed And Random Effect Extractors

Scope:

- added exported `fixef()` and `ranef()` generics plus `drmTMB` methods;
- `fixef()` is a mixed-model-friendly alias for distributional fixed-effect
  coefficient blocks returned by `coef()`;
- `ranef()` returns stored conditional random-effect blocks, currently
  including ordinary `mu`, residual-scale `sigma`, and `phylo_mu` blocks when
  those effects are present;
- added extractor documentation, pkgdown reference entries, NEWS bullets, and
  tests for fixed-effect-only, ordinary random-effect, residual-scale random
  effect, and phylogenetic random-effect paths.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `gaussian-location-scale` tests: 43 passed, 0 failed;
- targeted `gaussian-random-intercepts` tests: 173 passed, 0 failed after
  recording the new `ranef()` error snapshot;
- targeted `phylo-gaussian` tests: 26 passed, 0 failed;
- full `devtools::test()`: 498 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully with `fixef()` and
  `ranef()` reference pages;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `air format .` could not run because `air` is not installed on this machine.

Known limitations:

- `ranef()` intentionally returns the current structural `drmTMB` random-effect
  block format rather than an `lme4`-style data frame;
- `ranef(dpar = "phylo_mu")` is an exact block selector for the current
  phylogenetic effect storage name, not yet a polished public alias system for
  all future structured effects.

Team learning:

- familiar extractor names help users coming from mixed-model software, but the
  documentation should be explicit when the returned object shape is still a
  `drmTMB` structure.

## 2026-05-08: rho12 Residual Correlation Extractor

Scope:

- added exported `rho12()` and `rho12.drmTMB()`;
- `rho12(fit)` returns response-scale residual correlations for bivariate
  Gaussian location-coscale fits;
- `rho12(fit, type = "link")` returns the atanh-scale linear predictor;
- `rho12(fit, newdata = dat)` delegates to the existing prediction matrix
  machinery;
- updated README, the getting-started article, the bivariate-coscale article,
  the which-scale tutorial, NEWS, pkgdown reference navigation, tests, and
  roxygen documentation.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg 'predict\(fit, dpar = "rho12"\)' vignettes README.md pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/which-scale.html pkgdown-site/news/index.html`
- `rg "rho12\\(fit\\)|rho12\\(object|S3method\\(rho12|export\\(rho12|reference/rho12" NAMESPACE README.md R man tests vignettes _pkgdown.yml NEWS.md pkgdown-site/reference/index.html pkgdown-site/reference/rho12.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/which-scale.html`

Results:

- targeted `biv-gaussian` tests: 52 passed, 0 failed;
- targeted `gaussian-location-scale` tests: 44 passed, 0 failed after
  recording the new non-bivariate `rho12()` error snapshot;
- full `devtools::test()`: 502 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully with the `rho12()`
  reference page and updated tutorials;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- stale teaching search found no remaining `predict(fit, dpar = "rho12")`
  examples in active vignettes, README, or rebuilt article pages;
- `air format .` could not run because `air` is not installed on this machine.

Known limitations:

- `rho12()` is currently defined only for the implemented bivariate Gaussian
  residual correlation;
- other correlation levels, such as phylogenetic, species, site, or spatial
  covariance correlations, remain separate future extractors or summaries.

Team learning:

- when a flagship parameter gets a dedicated extractor, the teaching prose
  should immediately move to that extractor so equations, syntax, and examples
  reinforce one another.

## 2026-05-08: Fitted Mean Extractor

Scope:

- added exported `fitted.drmTMB()`;
- `fitted(fit)` returns fitted `mu` values for univariate Gaussian models;
- `fitted(fit)` returns a two-column `mu1`/`mu2` matrix for bivariate Gaussian
  models;
- the extractor delegates to the existing `predict()` path, so fitted training
  values include current conditional `mu` random-effect contributions;
- updated the location-scale and bivariate-coscale tutorials so symbolic mean
  quantities map directly to `fitted(fit)`.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "fitted\\(fit\\)|fitted\\.drmTMB|reference/fitted|mu1_i.*fitted|mu_i.*fitted" R tests vignettes README.md NEWS.md man _pkgdown.yml pkgdown-site/reference pkgdown-site/articles pkgdown-site/news`

Results:

- targeted `gaussian-location-scale` tests: 45 passed, 0 failed;
- targeted `gaussian-random-intercepts` tests: 174 passed, 0 failed;
- targeted `biv-gaussian` tests: 56 passed, 0 failed;
- full `devtools::test()`: 508 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully with
  `reference/fitted.drmTMB.html`;
- `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Known limitations:

- `fitted()` is intentionally limited to fitted training rows; users should use
  `predict()` for `newdata` or non-location distributional parameters;
- future composed-response families may need family-specific fitted-value
  shapes beyond the current vector or two-column matrix.

Team learning:

- familiar base-R extractors reduce friction, but the tutorials still need the
  math-to-R mapping so users know exactly which model quantity is being
  returned.

## 2026-05-08: Standard Model-Fit Extractors

Scope:

- added S3 methods for `nobs()`, `df.residual()`, and `deviance()`;
- documented that `deviance()` is `-2 * logLik` for these likelihood-based
  distributional models, not a saturated-model GLM deviance;
- added a pkgdown reference page for the standard model-fit extractor methods;
- added tests for complete-case row counts, residual degrees of freedom,
  deviance algebra, AIC algebra, and AIC/BIC agreement with `lme4` on an
  overlapping Gaussian mixed model.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::load_all(); fit <- drmTMB(bf(y ~ x), data = data.frame(y = rnorm(20), x = rnorm(20)), family = gaussian()); stopifnot(stats::nobs(fit) == 20L, is.numeric(stats::df.residual(fit)), is.numeric(stats::deviance(fit))); cat('namespace smoke ok\\n')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "model-fit-extractors|nobs\\(|df\\.residual\\(|deviance\\(|AIC\\(|BIC\\(" R tests vignettes README.md NEWS.md man _pkgdown.yml pkgdown-site/reference pkgdown-site/news`

Results:

- targeted `gaussian-location-scale` tests: 50 passed, 0 failed;
- targeted `biv-gaussian` tests: 59 passed, 0 failed;
- targeted `comparators` tests: 33 passed, 0 failed;
- namespace smoke test for `nobs()`, `df.residual()`, and `deviance()` passed;
- full `devtools::test()`: 518 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully with
  `reference/model-fit-extractors.html`;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

What did not go smoothly:

- The first `devtools::check()` run failed with namespace-load warnings because
  `nobs`, `df.residual`, and `deviance` were registered as S3 methods before
  their `stats` generics were imported.
- Adding the missing `@importFrom stats nobs df.residual deviance` entries and
  regenerating `NAMESPACE` fixed the issue.

Known limitations:

- `df.residual()` uses the current `nobs - df` convention where `df` is the
  number of optimized top-level parameters in `logLik()`;
- future penalized or constrained models may need more explicit documentation
  if effective degrees of freedom differ from this simple count.

Team learning:

- base-R S3 methods for `stats` generics need both the S3 method registration
  and the generic import; `devtools::test()` alone did not catch this, but
  `devtools::check()` did.

## 2026-05-08: Equation Syntax Documentation Alignment

Scope:

- split the main overview and README examples so fixed-effect Gaussian
  location-scale equations are paired with fixed-effect syntax, and random
  effects are introduced with their own matching equations;
- added a formula-grammar status map to the design contract, using
  implemented/reserved/planned consistently;
- clarified planned spatial `coords` versus `mesh` inputs in the
  phylogenetic/spatial vignette and speed design note;
- tightened the package `DESCRIPTION` so generated pkgdown metadata describes
  the current implementation first and the shape/zero-inflation roadmap as
  staged future work;
- updated `NEWS.md` for the documentation alignment.

Commands run:

- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "current implementation focuses|Public documentation now pairs|For a fixed-effect Gaussian location-scale model|spatial\\(1 \\| site, mesh = mesh\\)|Current Status Map|O.Dea-style|rho ~|tau ~|meta_gaussian" DESCRIPTION NEWS.md README.md vignettes docs/design pkgdown-site/index.html pkgdown-site/news/index.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/articles/formula-grammar.html`

Results:

- full `devtools::test()`: 518 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully and rebuilt the home page,
  `articles/drmTMB.html`, `articles/phylogenetic-spatial.html`, and
  `news/index.html`;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Consistency audit:

- `pkgdown-site/articles/drmTMB.html` now contains the fixed-effect Gaussian
  location-scale equation/syntax pairing;
- `pkgdown-site/index.html` metadata now says the current implementation
  focuses on Gaussian location-scale, known sampling covariance, phylogenetic
  location effects, random-effect scale models, and bivariate residual
  correlation before mentioning staged future families;
- `pkgdown-site/news/index.html` contains the new documentation-alignment
  NEWS item;
- remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails in
  meta-analysis docs and after-task protocol, not promoted syntax.

What did not go smoothly:

- reviewer-style scans caught that the overview vignette had paired a
  fixed-effect symbolic equation with a random-effect syntax example. Splitting
  those examples fixed the mismatch.
- the pkgdown metadata inherited a broader DESCRIPTION than the current
  implementation warranted, so DESCRIPTION was tightened and site/checks were
  rerun.

Team learning:

- equation/syntax pairing should be treated as a testable documentation
  contract: the equation immediately before a code block must describe exactly
  the model fitted by that code block.

## 2026-05-08: `check_drm()` Fit Diagnostics

Scope:

- added exported `check_drm()` generic and `check_drm.drmTMB()` method;
- added a `drm_check` print method and programmatic `attr(x, "ok")` flag;
- diagnostics now cover optimizer convergence, finite objective/log-likelihood,
  fixed-parameter gradients, Hessian status, dropped rows, positive fitted
  scale values, bivariate residual `rho12` boundary checks, known sampling
  covariance summaries, ordinary random-effect replication, ordinary
  random-slope design variation, and phylogenetic species replication;
- added `check_drm()` examples to the getting-started, location-scale, and
  bivariate-coscale vignettes;
- added the reference page to `_pkgdown.yml`, updated `NEWS.md`, README, and
  the structured-effect diagnostics design note.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'check-drm')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `rg -n "check_drm|known sampling covariance summaries|weak random-slope|drmTMB-logo|favicon" pkgdown-site/index.html pkgdown-site/reference/index.html pkgdown-site/reference/check_drm.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/location-scale.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/news/index.html`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `check-drm` tests: 38 passed, 0 failed;
- full `devtools::test()`: 556 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: site built successfully, including
  `reference/check_drm.html`;
- generated-site search found `check_drm()` on the home page, reference index,
  reference page, getting-started article, location-scale article,
  bivariate-coscale article, and changelog;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Tests of the tests:

- tests mutate a fitted object to exercise nonzero optimizer convergence,
  non-finite objective, gradient evaluation failure, non-finite gradients,
  non-positive-definite Hessian status, and scale-extraction failure;
- tests cover dropped-row notes, `rho12` boundary warnings, random-effect
  singleton notes, weak random-slope design notes, dense known sampling
  covariance summaries, phylogenetic replication notes, and unused `...`
  rejection;
- the print test now captures output instead of leaking the full diagnostic
  table into the test log.

Consistency audit:

- `NAMESPACE` exports `check_drm` and registers `check_drm.drmTMB` plus
  `print.drm_check`;
- `man/check_drm.Rd`, `_pkgdown.yml`, README, `NEWS.md`, and vignettes all
  describe the same first-pass diagnostic surface;
- the design note
  `docs/design/16-phylo-spatial-common-math.md` now records which diagnostics
  are implemented and which separability checks remain future work.

What did not go smoothly:

- the first test version treated dropped-row `note`s as a failed model; that
  was corrected so `attr(x, "ok")` is false only for `warning` or `error`
  statuses;
- the first print test used `expect_output()` but `cli` output and
  `print.data.frame()` output did not land in the same stream, so the test was
  changed to capture both streams;
- reviewer/auditor passes caught that vignettes and generated pkgdown pages
  initially lagged behind the new exported function;
- the known sampling covariance and random-slope checks were initially too
  thin, so matrix rank/conditioning summaries and within-group design checks
  were added before closing the task.

Known limitations:

- `check_drm()` is a first-pass diagnostic, not a formal identifiability proof;
- future phylogenetic plus non-phylogenetic, spatial plus site/study, and
  cross-formula covariance models still need separability diagnostics;
- gradient and Hessian checks are based on the current TMB object and
  `sdreport()` status, not profile-likelihood or bootstrap uncertainty checks.

Team learning:

- diagnostic functions need tests that deliberately break fitted-object
  components, not only tests on successful models;
- `note`, `warning`, and `error` semantics should be documented from the first
  exported version because applied users will otherwise over- or under-react to
  diagnostic rows;
- pkgdown freshness must be verified with generated-site searches, not only
  `pkgdown::check_pkgdown()`.

## 2026-05-08: `mvbind()` Bivariate Location Shorthand

Scope:

- implemented `mvbind(y1, y2) ~ x` as shorthand for identical bivariate
  Gaussian location formulas;
- the shorthand expands internally to `mu1 = y1 ~ x` and `mu2 = y2 ~ x`;
- explicit `mu1` and `mu2` formulas remain the preferred syntax whenever the
  two responses need different location predictors;
- added validation for malformed, named, repeated, or mixed explicit-plus-
  shorthand `mvbind()` inputs;
- updated README, ROADMAP, formula grammar documentation, likelihood/family
  design notes, bivariate and formula-grammar vignettes, NEWS, tests, and
  roxygen documentation.

Commands run:

- `Rscript -e "devtools::test(filter = 'biv-gaussian|package-skeleton')"`
- `Rscript -e "devtools::document()"`
- `rg -n "mvbind.*Reserved|mvbind.*planned|mvbind.*not implemented|not implemented.*mvbind|future work.*mvbind|Reserved \\| Planned shorthand" README.md ROADMAP.md NEWS.md docs/design vignettes R tests man`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `rg -n "mvbind|identical bivariate location|shorthand for identical" pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/reference/drmTMB.html pkgdown-site/reference/drm_formula.html pkgdown-site/articles/bivariate-coscale.html pkgdown-site/articles/formula-grammar.html pkgdown-site/news/index.html`
- `air format .`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted tests: 110 passed, 0 failed;
- full `devtools::test()`: 572 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- generated-site search found the shorthand on the home page, roadmap,
  `drmTMB()` reference, `drm_formula()` reference, bivariate coscale article,
  formula grammar article, and changelog;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Tests of the tests:

- the equivalence test fits both the explicit and `mvbind()` forms to the same
  simulated data and checks equal log-likelihood and equal `mu1`/`mu2`
  coefficients;
- failure-path tests reject `mvbind()` with a univariate Gaussian family,
  three responses, named `mvbind()` formulas, and mixing `mvbind()` with
  explicit `mu1` or `mu2` formulas;
- a parser-level test checks that `drm_formula()` captures `mvbind()` as an
  unnamed location formula before model building expands it.

Consistency audit:

- the formula grammar status table now marks `mvbind(y1, y2) ~ x` as
  implemented shorthand, not planned syntax;
- README, ROADMAP, vignettes, design notes, NEWS, roxygen Rd files, and
  generated pkgdown pages all use the same contract: shorthand only for
  identical bivariate location predictors;
- stale wording searches found no remaining current-document claims that
  `mvbind()` is reserved, planned, or not implemented.

What did not go smoothly:

- `mvbind()` had to remain a deliberately narrow shorthand, because the
  project still prefers explicit `mu1` and `mu2` formulas for scientific
  clarity when predictors differ;
- the generated site had to be rebuilt and searched directly because
  `pkgdown::check_pkgdown()` alone does not prove freshness;
- local formatting through `air` is still unavailable on this machine.

Known limitations:

- `mvbind()` is implemented only for the all-Gaussian two-response engine;
- mixed composed families such as `family = c(gaussian(), poisson())` remain
  planned until a coherent joint likelihood is implemented;
- bivariate random effects remain planned, so `mvbind()` currently expands
  only fixed-effect location formulas.

Team learning:

- Boole's formula lens was useful here: shorthand is helpful only when it
  reduces repetition without hiding different scientific predictors.
- Rose's stale-wording audit prevented the formula grammar, roadmap, and
  rendered pkgdown site from drifting out of sync after the parser changed.

## 2026-05-08: Public Model-Method Documentation

Scope:

- added roxygen documentation for existing public S3 methods:
  `predict.drmTMB()`, `simulate.drmTMB()`, `residuals.drmTMB()`,
  `sigma.drmTMB()`, and `summary.drmTMB()`;
- listed these methods explicitly in the pkgdown reference index;
- clarified that `predict(..., newdata = ...)` returns fixed-effect,
  population-level predictions, while fitted-row predictions include currently
  implemented random-effect contributions;
- clarified that `sigma(fit)` returns the modelled residual scale, and that
  simulations and Pearson residuals combine known sampling covariance with
  residual scale when relevant.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `air format .`
- `rg -n "Predict distributional parameters|Extract fitted residual scale|Simulate from a fitted model|Extract model residuals|Summarize a fitted model|meta_known_V\\(V = V\\)" pkgdown-site/reference/index.html pkgdown-site/reference/predict.drmTMB.html pkgdown-site/reference/sigma.drmTMB.html pkgdown-site/reference/simulate.drmTMB.html pkgdown-site/reference/residuals.drmTMB.html pkgdown-site/reference/summary.drmTMB.html`

Results:

- `devtools::document()` generated five new Rd files;
- full `devtools::test()`: 572 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and built the five new
  reference pages;
- generated-site search found all new reference-page headings and the
  `meta_known_V(V = V)` residual-scale clarification;
- final `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .` could not run because `air` is not installed on this machine.

Tests of the tests:

- this was a documentation task, so no unit tests were added;
- the new examples were exercised by the full R CMD check examples stage;
- pkgdown was built and the generated reference index/pages were searched
  directly to check that the new documentation is visible.

Consistency audit:

- `_pkgdown.yml` now lists each documented S3 method explicitly;
- `NAMESPACE` already registered the S3 methods, so this task added missing
  user documentation rather than new API behaviour;
- no NEWS bullet was added because this was documentation coverage for existing
  behaviour, not a user-visible behaviour change.

What did not go smoothly:

- the first attempt to launch a documentation-review agent was blocked because
  the current thread had already reached the agent limit;
- this made the local after-task audit more important than usual;
- local formatting through `air` remains unavailable.

Known limitations:

- the examples are deliberately minimal and synthetic;
- richer ecological/evolutionary examples for prediction, simulation, and
  residual checking should live in tutorials rather than method Rd pages;
- `predict(..., newdata = ...)` still gives fixed-effect population-level
  predictions only; conditional prediction for new group levels remains a
  later design decision.

Team learning:

- method documentation should be added as soon as a method becomes useful,
  even if the method was created in an earlier implementation slice;
- `sigma()` documentation must keep the residual-scale versus observation-scale
  distinction explicit, especially for meta-analysis users.

## 2026-05-08: Post-Fit Model Workflow Tutorial

Scope:

- added `vignettes/model-workflow.Rmd`, a tutorial that walks from a fitted
  Gaussian location-scale model through diagnostics, coefficients, prediction,
  residuals, and simulation;
- paired the symbolic Gaussian location-scale equations with matching
  `drmTMB()` syntax and parameter interpretation;
- added the tutorial to the pkgdown Tutorials menu and article index;
- documented how the same post-fit loop applies to meta-analytic Gaussian
  models with `meta_known_V(V = V)` and to bivariate Pearson residuals using
  `sigma1`, `sigma2`, and `rho12`.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/model-workflow.Rmd', quiet = TRUE)"`
- `Rscript -e "pkgdown::build_article('model-workflow')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `air format .`
- `rg -n "Checking and using fitted models|post-fit loop|meta_known_V\\(V = V\\)|simulate\\(fit|residuals\\(fit|check_drm\\(fit\\)" pkgdown-site/articles/model-workflow.html pkgdown-site/articles/index.html pkgdown-site/index.html`
- `rg -n "meta_gaussian|tau ~|rho ~|biv_gaussian|biological data|O.Dea-style|O'Dea-style" vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html docs README.md vignettes _pkgdown.yml`

Results:

- full `devtools::test()`: 572 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and generated
  `articles/model-workflow.html`;
- generated-site search found the new tutorial title, navbar entry,
  `meta_known_V(V = V)` note, `check_drm(fit)`, `residuals(fit, type =
  "pearson")`, and `simulate(fit)` workflow text;
- full `devtools::check()` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean;
- direct standalone `rmarkdown::render()` and `pkgdown::build_article()` failed
  in a plain session because the package was not installed there, but the full
  pkgdown site build and R CMD check both installed the package first and built
  the vignette successfully;
- `air format .` could not run because `air` is not installed on this machine.

Tests of the tests:

- this was a tutorial/documentation task, so no unit tests were added;
- the vignette chunks were exercised by both full pkgdown build and R CMD check
  vignette rebuild;
- the generated HTML was searched directly to verify that navigation and the
  central workflow text reached the site.

Consistency audit:

- the tutorial uses implemented syntax only: `bf(growth ~ ..., sigma ~ ...)`,
  `family = gaussian()`, `check_drm()`, `coef()`, `summary()`, `predict()`,
  `sigma()`, `residuals()`, and `simulate()`;
- the tutorial keeps `sigma` as the residual standard deviation parameter and
  uses `rho12` only for the bivariate residual-correlation note;
- no NEWS bullet was added because this was a new learning-path article, not a
  new fitting feature or API change;
- no roadmap or likelihood design update was needed because no model behaviour
  changed.

What did not go smoothly:

- direct article rendering outside an installed-package context was misleading;
  full pkgdown/R CMD check was the correct verification route for this package;
- local formatting through `air` remains unavailable.

Known limitations:

- the example is intentionally compact and synthetic;
- richer ecology/evolution examples should be added later with real or
  package-data-style workflows;
- the tutorial explains current post-fit tools but does not yet cover profile
  likelihood intervals or conditional prediction for new random-effect levels.

Team learning:

- post-fit tutorials are a good place to pair equations, syntax, and
  interpretation without overloading the main getting-started article;
- docs-heavy tasks still need generated-site checks because pkgdown navigation
  is part of the user-facing behaviour.

## 2026-05-08: Bivariate Meta-Analysis Known-Covariance Design

Scope:

- recorded the planned bivariate meta-analysis likelihood that separates known
  within-study sampling covariance from unknown residual or between-study
  covariance;
- clarified that `meta_known_V(V = V)` supplies `S_i` or stacked `V`, while
  fitted `rho12` remains the residual or heterogeneity correlation;
- added row-paired stacking order for a `2n` by `2n` known covariance matrix;
- added planned helper names for constructing bivariate block-diagonal
  sampling covariance matrices from `v1`, `v2`, and either `cov12` or `cor12`;
- added a testing requirement that recovery tests must distinguish sampling
  correlation in `V` from fitted residual `rho12`;
- added Mavridis and Salanti (2013) to `REFERENCES.bib`.

Commands run:

- `rg -n "meta_known_V|known V|sampling covariance|bivariate|rho12" R docs/design vignettes tests README.md NEWS.md`
- `pdfinfo '/Users/z3437171/Downloads/mavridis-salanti-2012-a-practical-introduction-to-multivariate-meta-analysis.pdf'`
- `pdftotext '/Users/z3437171/Downloads/mavridis-salanti-2012-a-practical-introduction-to-multivariate-meta-analysis.pdf' - | rg -n -i "within-study|within study|correlation|covariance|bivariate|multivariate|known|variance" -C 2`
- `rg -n "Mavridis|Salanti|multivariate meta-analysis|Riley|Jackson" REFERENCES.bib docs/design/11-reference-programme.md vignettes docs`
- `rg -n "Planned Bivariate Meta|Mavridis|row-paired|meta_vcov_bivariate|S_i|Omega_i|within-study" docs/design REFERENCES.bib`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n 'meta_gaussian\\(\\)|tau ~|rho ~|Planned Bivariate Meta|row-paired|meta_vcov_bivariate|sampling correlation|residual' docs/design docs/dev-log REFERENCES.bib`

Results:

- confirmed that current bivariate Gaussian code still rejects
  `meta_known_V()`, so this task was design-only;
- confirmed from the Mavridis and Salanti PDF that multivariate meta-analysis
  needs effect-size vectors plus their within-study variance-covariance
  matrices;
- design docs now state that known sampling covariance and fitted residual
  `rho12` are different quantities;
- roadmap and testing strategy now include bivariate known-covariance
  meta-analysis as a distinct future implementation target.
- `devtools::test()`: 572 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean;
- stale-wording scan found the new design targets plus older intentional
  guardrails for `meta_gaussian()`, `tau ~`, and `rho ~`.

Tests of the tests:

- no unit tests were added because no implementation changed;
- the testing strategy now specifies the future simulation target: data
  generated with known sampling covariance in `V` and separate residual
  `rho12` should recover the residual correlation, not the sampling
  correlation.

Consistency audit:

- no `meta_gaussian()` family or `tau ~` grammar was introduced;
- `sigma1`, `sigma2`, and `rho12` remain the names for unknown bivariate
  residual or heterogeneity components;
- `V` remains the known sampling covariance input;
- planned syntax uses `family = c(gaussian(), gaussian())`, consistent with
  the current family-composition direction.

What did not go smoothly:

- the natural bivariate syntax still has an awkward design point: the
  `meta_known_V(V = V)` marker is model-level, but current grammar attaches it
  inside a location formula. The design records that duplicate markers should
  be rejected, and this may need a cleaner parser representation later.

Known limitations:

- no bivariate known-covariance likelihood has been implemented yet;
- missing outcome handling is deliberately deferred;
- unknown within-study correlations should be handled by sensitivity analysis
  before any automatic estimation is attempted.

Team learning:

- Noether's rule is useful here: write the covariance equation before touching
  the parser;
- Fisher's rule is to test sampling correlation and residual correlation as
  separate recovery targets;
- Boole should revisit whether model-level formula markers need a cleaner
  grammar before bivariate meta-analysis is implemented.

## 2026-05-08: Known-V Random-Effect Scale Validation

Scope:

- added a targeted validation test for univariate Gaussian
  `meta_known_V(V = vi)` models combined with a `mu` random intercept and a
  random-effect scale formula, `sd(id) ~ w`;
- updated the meta-analysis design note to state that this implemented
  combination is supported and covered by an independent dense
  marginal-likelihood test;
- updated the source map, roadmap, and NEWS so the implemented-status wording
  matches the test coverage.

Commands run:

- `Rscript -e "devtools::test(filter = '^meta-known-v$')"`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `rg -n 'meta_gaussian\\(\\)|tau ~|still need explicit validation|still needs validation|routine tutorial syntax|planned.*implemented|only diagonal' README.md ROADMAP.md NEWS.md docs vignettes tests`
- `rg -n 'meta_known_V|sd\\(id\\)|sd\\(group\\)|known-covariance|known sampling' NEWS.md ROADMAP.md docs/design/08-meta-analysis.md vignettes/source-map.Rmd docs/dev-log/known-limitations.md`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- targeted `meta-known-v` tests: 40 passed, 0 failed;
- full test suite: 646 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean;
- stale-wording scan found no active obsolete "still needs validation" caveat;
  remaining `meta_gaussian()`, `tau ~`, and planned-feature hits are
  intentional guardrails or historical after-task/check-log records;
- `pkgdown::build_site()`: completed successfully and rebuilt
  `articles/source-map.html`, NEWS, and site metadata;
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Tests of the tests:

- the new test compares `logLik(fit)` with an independent dense marginal
  Gaussian likelihood calculation using
  `diag(V_known + sigma^2) + Z diag(sd(id)^2) Z'`;
- the fitted `sd(id)` values are checked at the group level, making the test
  exercise the intended `sd(group) ~ predictor` path rather than only ordinary
  residual `sigma`.

Consistency audit:

- no `meta_gaussian()` family or `tau ~` formula was introduced;
- `sigma` remains the residual heterogeneity parameter, while `sd(id)` is the
  group-level random-effect scale;
- the source map still warns that this should not become a headline tutorial
  example until the interpretation is written carefully.

What did not go smoothly:

- the implemented pieces were already routable, but the source map correctly
  exposed that the specific combination lacked a direct likelihood-comparator
  test;
- the project needed status wording updates in several places so users would
  not see an obsolete "still needs validation" caveat.

Known limitations:

- this validates the univariate Gaussian known-variance vector path with
  `sd(id) ~ w`; sparse known covariance and bivariate known-covariance
  meta-analysis remain separate future targets;
- the test is a dense marginal-likelihood comparator, so it is intentionally
  small and not a performance benchmark.

Team learning:

- Jason's source-map role caught a real validation gap without changing code;
- Rose's after-task checklist is useful for turning "implemented somewhere"
  into "implemented, tested, documented, and consistently described."

## 2026-05-08: Meta-Analysis Scale Tutorial Clarification

Scope:

- added a public tutorial section pairing R syntax and symbolic equations for
  known sampling covariance plus group-level random-effect scale models;
- corrected stale design wording that still described `sd(study) ~ x1` in
  known-covariance meta-analysis as awaiting validation;
- clarified that the `sigma` slope multiplies only unknown residual
  heterogeneity, not the known sampling variance;
- updated the source map to say the combination now has both a targeted
  validation test and tutorial explanation.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/meta-analysis.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `rg -n 'remain a separate validation task|still needs validation|after adding the known sampling variance|after adding known sampling|sampling error that is known|The$|Normal\\(a, b\\) again' vignettes/meta-analysis.Rmd docs/design/08-meta-analysis.md vignettes/source-map.Rmd NEWS.md ROADMAP.md docs/dev-log/known-limitations.md`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- direct meta-analysis and source-map renders: passed;
- stale-wording scan: no active hits;
- `git diff --check`: clean;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::test()`: 646 passed, 0 failed;
- `pkgdown::build_site()`: completed successfully and rebuilt
  `articles/meta-analysis.html` and `articles/source-map.html`;
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes;
- GitHub Actions for commit `a33ea96`: pkgdown and R CMD check succeeded,
  including macOS, Ubuntu, and Windows.

Tests of the tests:

- no new model code or unit tests were added;
- the documentation now points back to the existing dense marginal-likelihood
  comparator for `meta_known_V(V = vi)` plus `sd(id) ~ w`;
- Pat and Fisher/Noether both identified the stale status contradiction before
  the documentation update, and the follow-up scan now finds no active copy of
  that contradiction.

Consistency audit:

- no `meta_gaussian()` family or `tau ~` syntax was introduced;
- the vignette separates `meta_known_V(V = V)`, `sigma`, and `sd(study)` as
  known sampling covariance, residual heterogeneity, and group-level
  random-effect heterogeneity;
- the design note now includes the marginal covariance
  `V + diag(sigma_i^2) + Z diag(omega_j^2) Z'`.

What did not go smoothly:

- the validation checkpoint fixed the test gap but left one stale sentence in
  the design note; Pat and Noether caught the user-facing consequence quickly.

Known limitations:

- this is a documentation and consistency pass only;
- sparse known covariance and bivariate known-covariance random-effect scale
  models remain future implementation targets.

Team learning:

- Pat should review tutorials before we promote a newly validated combination
  from "source-map status" to "headline example";
- Noether's equation-first review should explicitly check the marginal
  covariance whenever known `V`, residual `sigma`, and random-effect scales are
  combined.

## 2026-05-08: Profile-Likelihood Target Design Clarification

Scope:

- clarified that profile-likelihood confidence intervals are planned, not yet
  implemented;
- introduced a user-facing profile target namespace for fixed effects,
  random-effect SDs, group-level correlations, residual-correlation fixed
  effects, and derived quantities;
- replaced the stale `sd_id` example with target names such as
  `sd:mu:(1 | id)` and `fixef:rho12:(Intercept)`;
- documented boundary control flow, correlation search guards, and the
  distinction between direct TMB parameters, linear combinations, and nonlinear
  derived quantities.

Commands run:

- `git diff --check`
- `rg -n 'sd_id|dpar:rho12|two threshold crossings|confint\\(fit, parm = "sd_id"|O.Dea-style|O.De[aA]-style|biological data' docs/design/12-profile-likelihood-cis.md NEWS.md ROADMAP.md README.md docs vignettes`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`

Results:

- Fermat review P1/P2/P3 findings were addressed in
  `docs/design/12-profile-likelihood-cis.md`;
- `git diff --check`: clean;
- stale-pattern scan: no active `sd_id`, `dpar:rho12`, or old profile-CI
  example in the profile design, NEWS, roadmap, README, or current vignettes;
  remaining hits were historical logs or intentional symbolic notation in the
  random-effect scale design note;
- direct source-map render: passed;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::test()`: 646 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully.
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Tests of the tests:

- no model code or unit tests were added;
- the design now lists the future tests required before profile-likelihood
  support can be called implemented, including boundary SDs, group-level
  correlations, unsupported target errors, and comparison against a diagnostic
  grid.

Consistency audit:

- `rho12` remains the residual bivariate correlation parameter;
- `fixef:rho12:(Intercept)` now follows the same fixed-effect namespace as
  `fixef:mu:x` and `fixef:sigma:x`;
- profile targets for `phylo()` use fitted-object labels while the document
  still states that the original model syntax must supply `tree = tree`.

What did not go smoothly:

- the first draft mixed target namespaces and kept an old `sd_id` example;
  reviewer feedback caught this before the design became a user-facing promise.

Known limitations:

- `confint.drmTMB(method = "profile")` is still not implemented;
- nonlinear derived profiles for ICCs, repeatability, phylogenetic signal, and
  covariance-matrix correlations remain design targets.

Team learning:

- profile-CI design should always start from fitted-object target names before
  discussing TMB parameter names;
- Rose's stale-wording scan should include old API examples as well as old
  status claims.

## 2026-05-08: Likelihood Routing Table

Scope:

- added a central `model_type` routing table to
  `docs/design/03-likelihoods.md`;
- documented that `model_type = 99` is a hidden phylogenetic precision-prior
  parity branch used by tests, not a public family;
- aligned the source map and likelihood design with
  `family = list(gaussian(), gaussian())`;
- corrected bivariate `rho12` documentation to use the same guarded transform
  as the TMB template: `rho12 = 0.99999999 * tanh(eta_rho12)`.

Commands run:

- `git diff --check`
- `rg -n 'list\\(gaussian\\(\\), gaussian\\(\\)\\)|rho12 = tanh|atanh\\(rho12|0\\.99999999|fallthrough|model_type = 2' docs/design/03-likelihoods.md vignettes/source-map.Rmd R/drmTMB.R src/drmTMB.cpp`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`

Results:

- Rose/Wegener found three consistency issues before commit:
  `list(gaussian(), gaussian())` was missing from routing docs, bivariate
  `model_type = 2` is a validated fallthrough in `make_tmb_data()`, and
  `rho12` prose omitted the numerical guard;
- all three issues were patched in `docs/design/03-likelihoods.md` and
  `vignettes/source-map.Rmd`;
- `git diff --check`: clean;
- direct source-map render: passed;
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::test()`: 646 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Tests of the tests:

- no likelihood code or unit tests were added;
- the routing table was checked against `R/drmTMB.R`, `src/drmTMB.cpp`, and
  the implemented source map.

Consistency audit:

- `model_type = 1`, `2`, `3`, and hidden `99` are now documented in both the
  developer source map and the likelihood design;
- `family = c(gaussian(), gaussian())` and
  `family = list(gaussian(), gaussian())` are documented as equivalent routes
  to the bivariate Gaussian builder;
- public phylogenetic fits remain `model_type = 1`; the hidden branch is test
  machinery only.

What did not go smoothly:

- the first routing-table draft was too confident about `make_tmb_data()` and
  missed one supported composed-family spelling.

Known limitations:

- the bivariate route still falls through after Gaussian and Student-t checks;
  this is documented, but a future implementation could make it explicit if
  new model families make the fallthrough fragile.

Team learning:

- when documenting routing, Rose should compare the docs against both the
  family-normalization route and the final TMB data mapper.

## 2026-05-08: Explicit TMB Data Model-Type Guard

Scope:

- changed `make_tmb_data()` so `"biv_gaussian"` is an explicit route to
  `model_type = 2L` instead of an implicit fallthrough;
- added an internal regression test that unknown model labels fail before they
  can reach the TMB template;
- updated the likelihood design and previous routing after-task note so they
  describe the explicit guard.

Commands run:

- `git diff --check`
- `Rscript -e "devtools::test(filter = '^package-skeleton$')"`
- `Rscript -e "devtools::test(filter = '^biv-gaussian$')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`

Results:

- `git diff --check`: clean;
- package-skeleton targeted tests: 40 passed, 0 failed;
- bivariate Gaussian targeted tests: 84 passed, 0 failed.
- Hooke/Emmy read-only review: no P1/P2 findings; one stale after-task P3
  sentence was corrected;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::test()`: 647 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully.
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.

Tests of the tests:

- the new package-skeleton test calls `drmTMB:::make_tmb_data()` with
  `model_type = "broken"` and checks for a clear internal error;
- the bivariate targeted tests confirm the explicit `"biv_gaussian"` branch
  still supports the existing bivariate Gaussian fit paths.

Consistency audit:

- the likelihood design now says unknown labels are rejected;
- the previous routing-table after-task note no longer records the fallthrough
  as a known limitation.

What did not go smoothly:

- Rose first found the fallthrough while reviewing documentation, which shows
  that architecture docs can expose useful code-hardening work.

Known limitations:

- this is an internal guard only; it does not add new model families or user
  syntax.

Team learning:

- when a design note describes a routing contract, the code should enforce the
  same contract rather than rely on upstream validation alone.

## 2026-05-08: Lognormal Location-Scale Family

Scope:

- added exported `lognormal()` for fixed-effect univariate positive continuous
  responses;
- routed lognormal fits through `drm_build_lognormal_ls_spec()` and
  `model_type = 4`;
- implemented the TMB lognormal likelihood with the log-Jacobian term;
- added `fitted()`, `simulate()`, `residuals()`, and `sigma()` handling for
  lognormal fits;
- updated family, likelihood, distribution-roadmap, README, pkgdown source-map,
  known-limitation, and testing-strategy documentation.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = '^lognormal-location-scale$')"`
- `Rscript -e "devtools::test(filter = '^package-skeleton$')"`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "Sys.setenv('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'); devtools::check(document = FALSE, manual = FALSE, args = c('--no-manual'))"`
- `rg -n 'starts with Gaussian and Student-t|Here mu is the expected response|before adding lognormal|three implemented builders' README.md ROADMAP.md NEWS.md docs vignettes R man pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/articles/source-map.html pkgdown-site/articles/distribution-families.html pkgdown-site/reference/fitted.drmTMB.html`
- `rg -n 'lognormal\\(\\)|model_type = 4|dlnorm|arithmetic response mean|positive finite' README.md ROADMAP.md NEWS.md _pkgdown.yml docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site/index.html pkgdown-site/reference/lognormal.html pkgdown-site/articles/source-map.html pkgdown-site/articles/distribution-families.html pkgdown-site/news/index.html`
- `rg -n 'meta_gaussian|tau ~|rho ~|family = meta' README.md ROADMAP.md NEWS.md docs/design vignettes R tests`

Results:

- `devtools::document()`: regenerated `NAMESPACE`, `man/lognormal.Rd`, and
  updated method docs; second run completed without roxygen warnings.
- Lognormal targeted tests: 39 passed, 0 failed.
- Package-skeleton targeted tests: 40 passed, 0 failed.
- `git diff --check`: clean.
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::test()`: 686 passed, 0 failed, 0 warnings, 0 skips.
- `pkgdown::build_site()`: completed successfully and generated the
  `reference/lognormal.html` page.
- First `devtools::check(...)`: 0 errors, 0 warnings, 1 note for an
  unqualified `fitted()` call in `residuals.drmTMB()`.
- After changing that call to `stats::fitted(object)`, final
  `devtools::check(...)`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- `tests/testthat/test-lognormal-location-scale.R` checks parameter recovery,
  the fitted response mean formula, and an independent likelihood calculation
  against `stats::dlnorm()`.
- Reviewer-requested tests now cover factor predictors, small and large
  `sigma`, missing-row filtering before positivity checks, `mvbind()`
  rejection, `sd(group)` rejection, duplicate `sigma` formulas, missing
  response, and no-complete-observation errors.

Consistency audit:

- Boole read-only review found no likelihood or parameter-scale issues and one
  closure-artifact gap, now addressed by this check-log and after-task report.
- Bohr read-only review found missing edge-test coverage; the requested cases
  were added before broad checks.
- Stale wording scan found no old "Gaussian and Student-t only",
  "mu is the expected response", "before adding lognormal", or "three
  implemented builders" wording in active docs or generated pages.
- Guardrail scan found only intentional `meta_gaussian()` and `tau ~` warnings
  in meta-analysis design/tutorial docs and the after-task protocol.

What did not go smoothly:

- the first documentation patch missed several files because the README context
  had changed;
- the first R CMD check found the bare `fitted()` call, which is now fixed;
- Bohr's review showed the first test set was too happy-path oriented.

Known limitations:

- `lognormal()` is fixed-effect and univariate only;
- no lognormal random effects, known sampling covariance, phylogenetic or
  spatial structured effects, bivariate lognormal, or mixed lognormal composed
  family is implemented yet.

Team learning:

- for every new family, Curie should check edge cases from the project testing
  contract before broad checks, not after the first reviewer pass;
- Rose should search generated pkgdown pages for old status claims after every
  family status change.

## 2026-05-08: Family Link and Response-Scale Contract

Scope:

- added `docs/design/19-family-link-contract.md`;
- updated the family registry to require native parameter meaning,
  fitted-response rule, and variance rule;
- clarified that future Gamma, count, beta, and ordinal families need explicit
  link and `fitted()` contracts before likelihood code;
- updated the adding-families tutorial, distribution roadmap, and project-local
  add-family skill.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE); cat('rendered adding-families\\n')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `sed -n '1,180p' .agents/skills/add-family/SKILL.md`

Results:

- adding-families vignette rendered successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- `git diff --check`: clean;
- Hegel read-only review: no P0/P1 findings; P2/P3 wording and consistency
  findings were fixed before commit.

Tests of the tests:

- this design-only slice added no R likelihood tests;
- the contributor vignette render verifies the new prose and equations parse.

Consistency audit:

- the family registry now lists the same future contract fields as the new
  design note;
- the adding-families `rho12` equation uses the implemented guarded transform
  `0.99999999 * tanh(eta_rho12)`;
- the beta roadmap now says scale or precision naming is undecided, matching
  the new design note.
- the add-family skill now asks for native parameter meaning, fitted response
  rule, variance rule, and prediction/fitted tests.

What did not go smoothly:

- the first draft left the older family-registry required-fields list too
  small and used unguarded bivariate `rho12` in one contributor equation.

Known limitations:

- this is a design contract only; no Gamma, count, beta, or ordinal likelihood
  was implemented.

Team learning:

- when a design note introduces future required fields, Emmy should check that
  all existing contributor checklists, skills, and registry docs name the same
  fields.

## 2026-05-08: Implement Family Link Helpers

Scope:

- moved `predict()` response-scale transforms to internal helpers:
  `drm_dpar_link()` and `drm_inverse_link()`;
- moved `fitted()` response summaries to `drm_fitted_response()`;
- added tests for implemented link mappings, inverse links, family-specific
  fitted responses, and unsupported internal routing;
- updated the family-link contract note, source-map article, roadmap wording,
  and generated `predict()` documentation.

Commands run:

- `Rscript -e "devtools::test(filter = 'family-link-contract')"`
- `Rscript -e "devtools::test(filter = 'family-link-contract|gaussian-location-scale|student-location-scale|lognormal-location-scale|biv-gaussian')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-manual')"`
- `git diff --check`
- `rg -n "Implement the family-link contract before|hard-coded.*dpar|dpar == \"mu\"|response scale\\. For positive|Post-fit response-scale transforms|distributional parameter" README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site/reference/predict.drmTMB.html pkgdown-site/articles/source-map.html --glob '!pkgdown-site/search.json'`

Results:

- targeted link-helper tests: 14 passed;
- targeted neighbouring model tests: 208 passed;
- full `devtools::test()`: 700 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and refreshed local pages;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean;
- GitHub Actions for the preceding family-link contract commit were green
  before this slice was closed.

Tests of the tests:

- `test-family-link-contract.R` checks both successful mappings and malformed
  internal routing;
- the lognormal fitted-response test would fail if `fitted()` returned `mu`
  instead of the arithmetic response mean;
- the Student-t `nu` inverse-link test would fail if the `2 + exp(eta)`
  finite-variance transform drifted.

Consistency audit:

- `ROADMAP.md` now says the implemented helper table must be extended before
  new families are added, rather than saying the whole family-link contract is
  still unimplemented;
- `docs/design/19-family-link-contract.md` names the implemented helpers and
  keeps future Gamma/count/beta/ordinal work behind explicit link and fitted
  rules;
- `vignettes/source-map.Rmd` points contributors to the helper route in
  `R/methods.R`;
- local pkgdown pages contain both the updated `predict()` wording and the new
  source-map paragraph.

What did not go smoothly:

- `air format` is not installed in this environment, so formatting was kept
  manual and checked with `git diff --check`;
- Rose's review caught that closure artifacts and roadmap wording had not yet
  been updated.

Known limitations:

- the link table is internal and small; it records only implemented Gaussian,
  Student-t, lognormal, and bivariate Gaussian paths;
- family objects do not yet expose the full registry contract programmatically.

Team learning:

- Rose's after-task audit should run before any "small internal refactor" is
  treated as complete, because internal changes still create doc and roadmap
  consistency obligations;
- future add-family work should start by extending the link table and fitted
  response helper, then adding tests before touching the TMB likelihood.

## 2026-05-08: Align rho12 Equations and Interpretation

Scope:

- aligned active `rho12` equations with the implemented guarded transform:
  `rho12 = 0.99999999 * tanh(eta_rho12)`;
- updated bivariate interpretation prose so users read `coef(fit, "rho12")`
  as linear-predictor-scale coefficients and `rho12(fit)` as response-scale
  residual correlations;
- changed the `biv_gaussian()` family metadata to `rho12 = "atanh_guarded"`;
- clarified that `tau` is future second-shape syntax, not current formula
  grammar and not meta-analytic heterogeneity syntax;
- moved the bivariate phylogenetic aspirational warning before unsupported
  example code in the location-coscale extension note.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'family-link-contract|biv-gaussian')"`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/testing-likelihoods.Rmd', output_dir = tempdir(), quiet = TRUE); cat('rendered selected vignettes\\n')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-manual')"`
- `rg -n 'atanh\\(rho12|rho12_i = tanh|rho12 = tanh|rho12 = "atanh"|atanh-scale|atanh link internally|`nu`, `tau`|tau ~|explicit parameter names such as `mu`, `sigma`, `nu`, `tau`' README.md R man tests vignettes docs/design --glob '!docs/dev-log/**'`

Results:

- targeted bivariate and family-link tests: 99 passed;
- full `devtools::test()`: 701 passed, 0 failed, 0 skipped;
- selected vignettes rendered successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- `test-family-link-contract.R` now checks that the public `biv_gaussian()`
  object and internal post-fit helper agree on `rho12 = "atanh_guarded"`;
- the bivariate regression tests still exercise `rho12(fit)`,
  `rho12(fit, type = "link")`, and `predict(..., dpar = "rho12")` after the
  metadata change.

Consistency audit:

- README, main vignette, bivariate-coscale vignette, scale-choice vignette,
  testing-likelihoods vignette, and design notes now use `eta_rho12` plus the
  guarded response transform;
- no active non-dev-log text remains with `rho12_i = tanh(...)`,
  `atanh(rho12_i) = ...`, `rho12 = "atanh"`, or `atanh-scale`;
- formula grammar now treats `tau` as future second-shape syntax only.

What did not go smoothly:

- the first documentation wording followed the simpler mathematical transform
  rather than the implemented guarded transform;
- a mechanical replacement temporarily created a multiline markdown table cell,
  which was fixed before rendering checks.

Known limitations:

- `rho12` uses a small guard for numerical stability; docs now state this, but
  papers may still present the idealized `tanh()` transform with an explanatory
  implementation note;
- `tau` remains design vocabulary for future shape families, not implemented
  formula syntax.

Team learning:

- Noether/Fisher should review symbolic equations against C++ and R helper
  transforms before public examples are expanded;
- Pat's interpretation request improved the tutorial: extraction examples need
  a sentence saying what the coefficient and response-scale value mean.

## 2026-05-08: Add Gamma Mean-CV Family

Scope:

- added fixed-effect univariate Gamma mean-CV models through
  `family = Gamma(link = "log")`;
- used `mu` as the response mean and `sigma` as the coefficient of variation,
  with `shape = 1 / sigma^2` and `scale = mu * sigma^2`;
- fixed the positive-continuous parameter map so unused `beta_nu` is fixed in
  lognormal and Gamma fits rather than counted as a free parameter;
- deliberately did not export a lowercase `gamma()` helper because
  `base::gamma()` is already the gamma special function;
- rejected non-log Gamma links, random effects, `sd(group)` scale formulae,
  `meta_known_V(V = V)`, `mvbind()`, and composed Gamma or mixed response
  families until those paths have explicit likelihood designs;
- updated formula grammar docs so the implemented Gamma route appears in the
  supported syntax map.

Commands run:

- `Rscript -e "devtools::test(filter = 'gamma-location-scale|family-link-contract')"`
- `Rscript -e "devtools::test(filter = 'gamma-location-scale|lognormal-location-scale|family-link-contract')"`
- `command -v air >/dev/null 2>&1 && air format . || true`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check()"`
- `git diff --check`
- `rg -n "future Gamma|Candidate Positive|Before implementing Gamma|additional non-Gaussian families beyond the first Student-t and lognormal|Gamma family may instead|gamma\\(\\) helper" README.md ROADMAP.md NEWS.md R man tests vignettes docs/design docs/dev-log/known-limitations.md pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n "stats::Gamma\\(\\)|Gamma\\(link = \\\"log\\\"\\)|model_type = 5|Gamma mean-CV|coefficient of variation|base::gamma\\(\\)" README.md ROADMAP.md NEWS.md R man tests vignettes docs/design docs/dev-log/known-limitations.md pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n "atanh\\(rho12|rho12_i = tanh|rho12 = tanh|rho12 = \\\"atanh\\\"|atanh-scale|atanh link internally|meta_gaussian|tau ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md R man tests vignettes docs/design docs/dev-log/known-limitations.md pkgdown-site --glob '!docs/dev-log/after-task/**'`

Results:

- initial targeted Gamma and family-link tests: 55 passed;
- targeted Gamma, lognormal, and family-link tests after reviewer fixes:
  114 passed;
- full `devtools::test()` after reviewer fixes: 761 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the Gamma likelihood test compares the fitted log-likelihood with an
  independent `stats::dgamma()` calculation at the fitted coefficients;
- Gamma and lognormal tests check `fit$sdr$pdHess` and `fit$df` against the
  number of reported fixed-effect coefficients, protecting against unused free
  TMB parameters;
- the prediction tests check that response-scale `mu` equals
  `exp(link-scale mu)`, that `newdata` prediction uses the log links for both
  `mu` and `sigma`, and that `fitted()` returns the response mean;
- the method tests check `sigma()` as coefficient of variation, Pearson
  residuals as `(y - mu) / (mu * sigma)`, and positive simulations;
- the failure-path tests reject the default inverse-link `stats::Gamma()`,
  `base::gamma`, non-positive responses, unsupported distributional
  parameters, random effects, known sampling covariance, `sd(group)`, and
  bivariate or composed Gamma families;
- the edge-case test fits both small and large coefficient-of-variation cases;
- Gamma complete-case filtering and default intercept-only `sigma` are tested.

Consistency audit:

- `README.md`, `ROADMAP.md`, `NEWS.md`, generated Rd files, formula grammar
  docs,
  `vignettes/distribution-families.Rmd`, `vignettes/adding-families.Rmd`,
  `vignettes/source-map.Rmd`, and family/likelihood/link design notes now
  describe the same Gamma mean-CV contract;
- `docs/dev-log/known-limitations.md` now lists Gamma as implemented but keeps
  random effects, known sampling covariance, phylogenetic terms, and bivariate
  or mixed Gamma models as future work;
- generated pkgdown pages contain the new Gamma source-map row and method
  documentation;
- remaining `meta_gaussian()` and `tau ~` hits are intentional guardrails, and
  remaining `gamma()` hits explain why no lowercase helper is exported.

What did not go smoothly:

- the first composed `Gamma/Gamma` failure-path test expected a narrower
  message, but the actual router correctly used the general mixed-response
  rejection. The test was updated to check the intended rejection path;
- the source map and adding-families vignette initially lagged behind the code
  and were caught by the stale-wording scan before closure;
- reviewer pass found that Gamma inherited a lognormal map that left unused
  `beta_nu` free. The fix also hardened lognormal by fixing `beta_nu` there.

Known limitations:

- Gamma models are fixed-effect and univariate only;
- `sigma` is a coefficient of variation in Gamma models, not a residual
  standard deviation. Docs state the residual SD as `mu * sigma`;
- bivariate Gamma, mixed composed families, Gamma meta-analysis,
  phylogenetic/spatial Gamma terms, and Gamma random effects remain future
  design work.

Team learning:

- Jason's landscape note was useful: use `stats::Gamma(link = "log")` rather
  than adding a `gamma()` helper that would collide with `base::gamma()`;
- future add-family tasks should begin with the family-link table, fitted
  response rule, and independent likelihood test before extending examples.

## 2026-05-08: Add Gamma GLM Comparator

Scope:

- added a two-tier comparator test for the overlapping Gamma mean-regression
  case against base R `stats::glm(..., family = Gamma(link = "log"))`;
- documented why the comparator checks `mu` coefficients rather than residual
  scale: base GLM and `drmTMB` estimate the Gamma dispersion on different
  routes.

Commands run:

- `Rscript -e "devtools::test(filter = 'comparators|gamma-location-scale')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check()"`

Results:

- targeted comparator and Gamma tests: 94 passed;
- full `devtools::test()`: 764 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- the comparator would fail if the Gamma `mu` log-link design matrix or
  coefficient extraction drifted from the base GLM overlap case;
- the test also checks optimizer convergence and positive-definite Hessian for
  the fitted `drmTMB` model.

Consistency audit:

- `docs/design/05-testing-strategy.md` now lists the base GLM Gamma comparator
  alongside the independent `stats::dgamma()` likelihood check;
- no user-facing syntax changed.

What did not go smoothly:

- comparing Gamma residual scale directly to `glm()` would be misleading
  because the base GLM dispersion estimate is not the same object as
  `drmTMB`'s ML coefficient-of-variation parameter. The comparator was kept to
  the overlapping mean coefficients.

Known limitations:

- this is a mean-model comparator only; `sigma ~ predictors` still relies on
  simulation and independent likelihood tests.

Team learning:

- comparator tests should state exactly which parameterization overlaps with
  the external package. A loose "compare to glm" label would have hidden an
  avoidable scale-parameter mismatch.

## 2026-05-09: Add Fixed-Effect Poisson Mean Family

Scope:

- added a fixed-effect univariate Poisson mean path with
  `family = poisson(link = "log")`;
- kept the model deliberately narrow: `mu` only, no fitted `sigma`, no random
  effects, no `meta_known_V()`, no zero inflation, no overdispersion, and no
  bivariate count model;
- updated methods so `predict(dpar = "mu")`, `fitted()`, `simulate()`,
  `residuals()`, `sigma()`, `logLik()`, and coefficient extraction work for
  the implemented Poisson path;
- updated formula grammar, likelihood, family registry, testing strategy,
  distribution roadmap, family-link contract, README, NEWS, known limitations,
  source map, distribution-family vignette, formula grammar vignette, and
  generated Rd files.

Commands run:

- `R -q -e 'devtools::test(filter = "poisson|family-link-contract")'`
- reviewer pass by Euler over the uncommitted Poisson slice
- `R -q -e 'devtools::test(filter = "gaussian-location-scale|gaussian-random-effect-scale|poisson-mean|family-link-contract")'`
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `rg -n 'Poisson.*planned|poisson.*unsupported|supported families|count models would|Candidate Count|before implementing count|first count family should|model_type = 6|dpois|drm_build_poisson_spec' README.md ROADMAP.md NEWS.md docs vignettes tests R src man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n 'poisson\\(link = "log"\\)|Poisson mean|non-negative integer|unit dispersion|fixed unit dispersion|no fitted `sigma`' README.md ROADMAP.md NEWS.md docs vignettes tests R man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n 'Student-t, lognormal, and Gamma|first Student-t, lognormal, and Gamma|Gamma paths|count, beta' README.md ROADMAP.md NEWS.md docs vignettes pkgdown-site --glob '!pkgdown-site/search.json'`

Results:

- first targeted Poisson/link tests: 61 passed;
- stale-test regression pass after Euler review: 171 passed;
- full `devtools::test()`: 806 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- independent likelihood test compares fitted log-likelihood to
  `sum(dpois(y, lambda = mu, log = TRUE))`;
- external comparator checks Poisson coefficients and log-likelihood against
  `stats::glm(..., family = poisson(link = "log"))`;
- malformed-input tests reject non-log links, `sigma` formulas, missing
  responses, negative counts, non-integer counts, random effects,
  `meta_known_V()`, `sd(id)`, and `mvbind()`;
- complete-case test confirms invalid count rows are ignored only when removed
  by missingness in model predictors.

Consistency audit:

- symbolic equations and R syntax are paired in the README,
  `docs/design/03-likelihoods.md`, `docs/design/19-family-link-contract.md`,
  and `vignettes/distribution-families.Rmd`;
- `docs/design/01-formula-grammar.md` and `vignettes/formula-grammar.Rmd`
  now list Poisson as implemented;
- generated pkgdown pages include the new Poisson wording after site build;
- historical after-task notes were left unchanged where they were true when
  written.

What did not go smoothly:

- two older tests still expected `poisson()` to be unsupported. Euler caught
  this before closure; the tests now check the new Poisson-specific rejection
  paths;
- roxygen-generated Rd files were stale until `devtools::document()` was run;
- `sigma(fit)` for Poisson needed an explicit interpretation. The package
  returns a fixed unit dispersion vector for base-R compatibility, and docs
  state that this is not a fitted distributional `sigma`.

Known limitations:

- Poisson models are fixed-effect, univariate, and `mu`-only;
- no overdispersion, zero inflation, hurdle component, random effects, known
  sampling covariance, phylogenetic/spatial effects, or bivariate count path is
  implemented yet;
- ecological count data with extra-Poisson variation will usually need the
  planned negative binomial or COM-Poisson paths.

Team learning:

- count-family work should start with the family-link table, because `mu` is
  no longer identity-linked;
- stale "unsupported family" tests are a predictable failure mode when planned
  families become implemented;
- Rose's after-task audit should always include generated pkgdown pages, not
  only source R Markdown and design docs.

## 2026-05-09: Add Fixed-Effect NB2 Mean-Dispersion Family

Scope:

- added `nbinom2()` as a fixed-effect univariate negative-binomial 2 family for
  overdispersed counts;
- defined the contract as `log(mu) = X_mu beta_mu`,
  `log(sigma) = X_sigma beta_sigma`, `size = 1 / sigma^2`, and
  `Var(y) = mu + sigma^2 * mu^2`;
- kept the first implementation narrow: no random effects, no `meta_known_V()`,
  no zero inflation, no hurdle component, no phylogenetic/spatial terms, and no
  bivariate or mixed count model;
- updated methods, tests, generated docs, pkgdown navigation, README, NEWS,
  ROADMAP, family registry, likelihood docs, testing strategy, distribution
  roadmap, family-link contract, known limitations, formula grammar, source
  map, and distribution-family vignette.

Commands run:

- Euclid landscape pass over NB2 conventions and sigma/size mapping
- `R -q -e 'devtools::test(filter = "nbinom2|family-link-contract")'`
- `R -q -e 'devtools::test(filter = "nbinom2|poisson|family-link-contract")'`
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `rg -n 'nbinom2.*planned|negative binomial.*planned|planned negative binomial|Candidate negative binomial|before implementing.*nbinom2|Use this contract before implementing `gamma\\(\\)`|model_type = 7|dnbinom|drm_build_nbinom2_spec' README.md ROADMAP.md NEWS.md DESCRIPTION _pkgdown.yml R src tests docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n 'sigma.*overdispersion|size = 1 / sigma\\^2|Var\\(y\\) = mu \\+ sigma\\^2|negative-binomial 2|Negative-binomial 2|nbinom2\\(\\)' README.md ROADMAP.md NEWS.md docs vignettes R tests man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n 'Poisson mean, and negative-binomial|Poisson paths|Poisson and negative-binomial|count-response families|COM-Poisson' README.md ROADMAP.md NEWS.md DESCRIPTION docs vignettes pkgdown-site --glob '!pkgdown-site/search.json'`
- `git diff --check`

Results:

- narrow NB2 and link-contract tests: 76 passed after replacing a fragile
  tiny-data link-contract fit and adding direct Poisson-limit objective checks;
- targeted count/link tests: 115 passed;
- full `devtools::test()`: 860 passed, 0 failed, 0 skipped;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully and produced the `nbinom2`
  reference page;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- independent likelihood test compares fitted log-likelihood to
  `sum(dnbinom(y, mu = mu, size = 1 / sigma^2, log = TRUE))`;
- simulation tests use `stats::rnbinom()` with the same `size = 1 / sigma^2`
  mapping;
- Poisson-limit test checks that the NB2 likelihood approaches `dpois()` as
  `sigma` approaches zero and directly evaluates the TMB objective at very
  small `sigma` values;
- malformed-input tests reject unsupported `nu`, missing response, duplicated
  `sigma`, negative and non-integer counts, random effects, `meta_known_V()`,
  `sd(id)`, and `mvbind()`.

Consistency audit:

- symbolic equations and R syntax now match in the README,
  `docs/design/03-likelihoods.md`, `docs/design/19-family-link-contract.md`,
  and `vignettes/distribution-families.Rmd`;
- `docs/design/01-formula-grammar.md` and `vignettes/formula-grammar.Rmd`
  now list NB2 as implemented;
- generated pkgdown pages include `reference/nbinom2.html`;
- historical after-task notes that called NB2 future work were left unchanged
  where they were true when written.

What did not go smoothly:

- the first link-contract smoke fit used six toy observations and produced
  `sdreport()` NaN warnings. The test was changed to a modest simulated NB2
  example so it exercises fitted-response routing without making the Hessian
  fragile;
- NB2 naming is easy to confuse with size/precision conventions in other
  packages. The docs now state explicitly that `sigma` maps to
  `size = 1 / sigma^2` and larger `sigma` means more overdispersion.
- Darwin's review caught a numerical fragility in the first algebraically
  correct C++ density near the Poisson limit. The TMB template now uses an
  equivalent log-likelihood written in terms of `alpha = sigma^2`, avoiding
  direct computation of very large `size = 1 / sigma^2`.

Known limitations:

- NB2 models are fixed-effect, univariate, and complete-case only;
- no random effects, zero inflation, hurdle component, known sampling
  covariance, phylogenetic/spatial structured effects, bivariate count model,
  or mixed composed count model is implemented yet;
- no external `glmmTMB` or GAMLSS comparator is in the CRAN-safe test path yet.

Team learning:

- Euclid's landscape pass was valuable before coding because it clarified
  sigma direction and avoided accidentally copying a precision-parameter
  convention;
- small "smoke" fits can be numerically worse than moderate simulated examples
  for overdispersed count models;
- future count families should include an explicit map to any base-R density
  parameters before code is written.

## 2026-05-09 — Zero-Inflated Poisson Distributional Parameter

Task: implement fixed-effect zero-inflated Poisson models without adding a
public `zi_poisson()` constructor.

Implemented:

- extended the existing `family = poisson(link = "log")` route so
  `drm_formula(count ~ x, zi ~ z)` fits a fixed-effect zero-inflated Poisson
  likelihood;
- added TMB `model_type = 8` with conditional `mu = exp(X_mu beta_mu)` and
  structural-zero probability `zi = logit^{-1}(X_zi beta_zi)`;
- made `predict(dpar = "mu")` return the conditional Poisson mean,
  `predict(dpar = "zi")` return the structural-zero probability, and
  `fitted()` return `(1 - zi) * mu`;
- added `simulate()`, `residuals()`, `sigma()`, link-helper, and print-method
  support for the zero-inflated Poisson path;
- rejected unsupported `offset()` terms rather than letting `model.matrix()`
  silently drop them;
- rejected zero-column `zi` formulae such as `zi ~ 0`;
- updated README, ROADMAP, NEWS, formula grammar, family registry,
  likelihood, family-link, distribution-family, source-map, and known-limits
  documentation.

Review:

- Beauvoir reviewed simulation coverage and recommended adding `zi`-RHS
  unsupported-term coverage plus a high-`zi` boundary check;
- Poincare reviewed likelihood/plumbing and found the offset-silencing risk,
  the `zi ~ 0` start-length edge case, and stale fitted-response wording.

Commands run:

- `R -q -e 'devtools::load_all(recompile = TRUE)'`
- `R -q -e 'devtools::test(filter = "zi-poisson|family-link-contract")'`
- `R -q -e 'devtools::test(filter = "zi-poisson|poisson-mean|family-link-contract")'`
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `git diff --check`
- `rg -n 'zi_poisson\\(\\)|Poisson.*zero inflation.*later|mu-only|Only mu|No overdispersion, zero inflation|no zero inflation' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`

Results:

- targeted ZIP/link tests: 78 passed before review additions;
- targeted count/link tests after review additions: 120 passed;
- full `devtools::test()`: 912 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- recovery test simulates from known `mu` and `zi` coefficients with a factor
  predictor;
- likelihood test compares the fitted objective to an independent ZIP
  log-likelihood calculation;
- boundary tests check both `zi -> 0` Poisson convergence and `zi -> 1`
  log-space mixture stability;
- malformed-input tests cover duplicate `zi`, two-sided `zi`, unsupported
  random terms inside `mu` and `zi`, offsets, `zi ~ 0`, `meta_known_V()`,
  `sd(id)`, `mvbind()`, and non-integer counts.

Consistency audit:

- public examples use `family = poisson(link = "log")` plus `zi ~ ...`;
- no public `zi_poisson()` constructor was added;
- generated Rd files and pkgdown pages now describe zero-inflated Poisson
  fitted-response semantics;
- old historical after-task notes that correctly described Poisson as
  `mu`-only when written were left unchanged.

Known limitations:

- fixed-effect and univariate only;
- no random effects, overdispersion, hurdle component, known sampling
  covariance, phylogenetic/spatial structured effects, bivariate count model,
  or mixed composed count model yet;
- offsets are rejected rather than implemented.

Team learning:

- adding one TMB parameter vector requires updating all direct `MakeADFun()`
  test helpers with dummy data and parameters;
- count-family offset handling should be decided early for every new count
  family because base R can drop offsets from model matrices silently;
- stable log-space tests are needed at mixture boundaries, because naive
  probability-scale comparators lose precision near `zi = 1`.

## 2026-05-09 — Zero-Inflated NB2 Distributional Parameter

Task: implement fixed-effect zero-inflated negative-binomial 2 models through
the existing `nbinom2()` family route.

Implemented:

- extended `family = nbinom2()` so `drm_formula(count ~ x, sigma ~ z, zi ~ w)`
  fits a fixed-effect zero-inflated NB2 likelihood;
- added TMB `model_type = 9` with conditional `mu = exp(X_mu beta_mu)`,
  overdispersion scale `sigma = exp(X_sigma beta_sigma)`, and
  structural-zero probability `zi = logit^{-1}(X_zi beta_zi)`;
- kept plain NB2 semantics unchanged: `sigma` is an overdispersion scale with
  count-component `Var(y) = mu + sigma^2 * mu^2`;
- made `predict(dpar = "mu")` and `sigma()` describe the conditional count
  component, `predict(dpar = "zi")` return structural-zero probability, and
  `fitted()` return `(1 - zi) * mu`;
- added `simulate()`, response and Pearson residuals, link-helper, coefficient
  splitting, and print-method support for the zero-inflated NB2 path;
- added simulation recovery, independent likelihood, boundary, complete-case,
  and malformed-input tests;
- updated README, ROADMAP, NEWS, formula grammar, family registry, likelihood,
  family-link, distribution-family, source-map, and known-limits
  documentation.

Review:

- Kepler reviewed simulation-test design and recommended direct NB2-mixture
  likelihood comparison, `zi -> 0` and `zi -> 1` boundary tests, and malformed
  input coverage;
- Copernicus reviewed the implementation and flagged stale roxygen/public-doc
  wording plus the untracked test file before closeout.

Commands run:

- `air format .` (failed: `air` is not installed locally)
- `R -q -e 'devtools::document()'`
- `R -q -e 'devtools::test(filter = "zi-nbinom2|nbinom2|family-link-contract")'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `git diff --check`
- `rg -n "zero inflation.*NB2|zero inflation.*negative|zero-inflated NB2.*planned|NB2.*zero inflation.*not|zero-inflated negative|zi_nbinom2\\(\\)" README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`
- `rg -n "model_type = 8|model_type = 9|zi_nbinom2|zi_poisson|X_zi|beta_zi" R src tests docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'`

Results:

- targeted ZINB2/NB2/link tests: 135 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 966 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- recovery test simulates from known `mu`, `sigma`, and `zi` coefficients with
  factor predictors;
- likelihood test compares the fitted objective to an independent
  zero-inflated NB2 log-likelihood using `stats::dnbinom()`;
- boundary tests check both `zi -> 0` NB2 convergence and `zi -> 1` log-space
  mixture stability;
- complete-case test checks that rows missing from the `zi` formula are
  filtered consistently;
- malformed-input tests cover duplicate `zi`, two-sided `zi`, unsupported
  random terms, offsets, `zi ~ 0`, `meta_known_V()`, `sd(id)`, `mvbind()`, and
  non-integer counts.

Consistency audit:

- public examples use `family = nbinom2()` plus `zi ~ ...`;
- no public `zi_nbinom2()` constructor was added;
- generated Rd files and pkgdown pages describe zero-inflated NB2 fitted,
  simulation, residual, and `sigma()` semantics;
- known limitations now distinguish implemented count zero-inflation from
  future count zero-inflation with random or structured effects;
- remaining `zi_nbinom2()` hits are intentional statements that no public
  constructor exists, and historical after-task notes were left unchanged where
  they were true when written.

Known limitations:

- fixed-effect and univariate only;
- no random effects, hurdle component, known sampling covariance,
  phylogenetic/spatial structured effects, bivariate count model, or mixed
  composed count model yet;
- offsets are rejected rather than implemented.

Team learning:

- documenting plain NB2 and zero-inflated NB2 in the same route reduces API
  clutter but requires extra stale-wording scans because `nbinom2()` now has
  two implemented behaviours;
- count-mixture families should always carry an independent density-comparison
  test plus boundary tests at both mixture extremes;
- local formatter availability should be checked when a new repo skill says to
  run a formatter that may not be installed.

## 2026-05-09 — NB2 MASS Comparator

Task: add a Tier 1 comparator check for the implemented negative-binomial 2
constant-dispersion overlap.

Implemented:

- added `MASS` to `Suggests`;
- added a `tests/testthat/test-comparators.R` smoke test comparing
  `drmTMB(family = nbinom2(), sigma ~ 1)` with `MASS::glm.nb()`;
- compared `mu` coefficients, `sigma = 1 / sqrt(theta)`, and `logLik()`;
- updated the testing-strategy design note, the testing-likelihoods vignette,
  and the implemented source map.

Commands run:

- `R -q -e 'packageVersion("MASS")'`
- ad hoc `drmTMB()` versus `MASS::glm.nb()` smoke comparison
- `R -q -e 'devtools::test(filter = "comparators|nbinom2")'`
- `R -q -e 'devtools::test()'`
- `R -q -e 'pkgdown::check_pkgdown()'`
- `R -q -e 'pkgdown::build_site()'`
- `R -q -e 'devtools::check()'`
- `air format .` (failed: `air` is not installed locally)
- `git diff --check`
- `rg -n "MASS::glm.nb|glm.nb|MASS,|Negative-binomial 2 mean coefficients|test-comparators\\.R" DESCRIPTION tests docs/design/05-testing-strategy.md vignettes/testing-likelihoods.Rmd vignettes/source-map.Rmd docs/dev-log/check-log.md docs/dev-log/after-task --glob '!docs/dev-log/after-task/2026-05-09-nb2-mass-comparator.md'`

Results:

- targeted comparator/NB2 tests: 139 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 971 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the comparator would fail if `drmTMB` used the wrong NB2 scale direction,
  because it checks `sigma = 1 / sqrt(theta)`;
- the comparator also checks log-likelihood, so equal coefficients cannot hide
  missing constants or a mismatched variance function.

Consistency audit:

- the testing strategy now lists the MASS NB2 comparator as implemented;
- the testing-likelihoods vignette teaches the exact scale translation;
- the source map now records `tests/testthat/test-comparators.R` as an NB2
  test file.

Known limitations:

- this comparator covers only the constant-dispersion NB2 overlap;
- NB2 models with `sigma ~ predictors` and zero-inflated NB2 models still rely
  on simulation and independent likelihood tests rather than an external
  package comparator.

Team learning:

- comparator tests should name the exact overlapping submodel, not the whole
  family, because `MASS::glm.nb()` cannot check distributional `sigma`
  predictors.

## 2026-05-09 — High `rho12` Recovery and Site Consistency

Task: harden the package-defining bivariate residual-correlation path and clean
up drift found by Rose's systems audit.

Implemented:

- added bivariate Gaussian recovery coverage for high positive and high
  negative residual correlations near `rho12 = +/-0.8`;
- updated the testing strategy and testing-likelihoods vignette so high
  `rho12` is part of the required bivariate test surface;
- refreshed DESCRIPTION and overview-vignette wording so zero-inflated
  Poisson and zero-inflated NB2 are no longer described as later work;
- added lognormal rows and syntax to the formula-grammar design note and
  vignette;
- changed placeholder wording in the distribution-family vignette to
  present-tense documentation;
- added `tools/fix-pkgdown-favicon-mime.R` and wired it into the pkgdown
  workflow to correct the smart-quote favicon MIME string introduced by the
  installed pkgdown template;
- added a count-family after-phase roll-up that supersedes older Poisson/NB2
  task-note limitations with the current Poisson, ZIP, NB2, and ZINB2 surface.

Commands run:

- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test()"`
- `air format .` (failed: `air` is not installed locally)
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check()"`
- `rg -n 'type="”|later .*zero-inflation|zero-inflation, and additional|This article will help|current planning reference' DESCRIPTION vignettes docs/design pkgdown-site/index.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/distribution-families.html pkgdown-site/articles/formula-grammar.html pkgdown-site/articles/testing-likelihoods.html`
- `rg -n 'lognormal\(\).*Implemented|family = lognormal\(\)|high positive and high negative|\+/-0\.8|drmTMB-logo\.png|man/figures/logo\.png' docs/design/01-formula-grammar.md docs/design/05-testing-strategy.md vignettes/formula-grammar.Rmd vignettes/testing-likelihoods.Rmd README.md _pkgdown.yml pkgdown-site/index.html pkgdown-site/articles/formula-grammar.html pkgdown-site/articles/testing-likelihoods.html`

Results:

- targeted bivariate tests: 94 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 981 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- favicon post-processing removed all malformed smart-quote favicon MIME hits
  from the generated local site;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.

Tests of the tests:

- the new recovery test checks both `rho12 = 0.8` and `rho12 = -0.8`;
- it checks optimizer convergence, positive-definite Hessian status,
  response-scale recovery, and the guarded response transform staying inside
  the correlation boundary.

Consistency audit:

- active docs now mention fixed-effect ZIP/ZINB2 as implemented rather than
  future work;
- formula-grammar docs and vignette now include `lognormal()`;
- README and `_pkgdown.yml` both point to `man/figures/drmTMB-logo.png`;
- historical after-task reports with older logo and count-family limitations
  were left unchanged, because they were accurate when written.

Known limitations:

- the new `rho12` edge test is still fixed-effect bivariate Gaussian only;
- pkgdown 2.1.3 contains the upstream smart-quote favicon template, so the
  project-side fixer remains necessary until that template is corrected
  upstream or the package uses a newer fixed pkgdown release.

Team learning:

- Rose's audit caught wording and generated-site details that ordinary model
  tests cannot see;
- site-generation quirks should be checked as artifacts, not assumed correct
  because `pkgdown::check_pkgdown()` passed.

## 2026-05-09 — Beta, Truncated Count, Hurdle, and Ordinal Roadmap Contract

Task: lock down the next-family roadmap before implementing another likelihood.

Implemented:

- made `beta()` the next planned family for strict continuous proportions, with
  public `sigma` and internal precision `phi = 1 / sigma^2`;
- reordered the count roadmap so `truncated_nbinom2()` comes before hurdle NB2,
  and hurdle NB2 uses `hu ~ predictors` as the hurdle-zero probability;
- clarified that beta-binomial denominator syntax is not settled yet, with
  `cbind(successes, failures)` recorded as one candidate;
- recorded first-pass ordinal scope as univariate cumulative-logit syntax with
  cutpoints;
- synchronized `ROADMAP.md`, the formula-grammar design note and vignette, the
  distribution-family article, and the family-link contract;
- added explicit implemented-contract rows for ZIP/ZINB2 `zi`.

Commands run:

- `Rscript -e "rmarkdown::render('vignettes/distribution-families.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `git diff --check`
- `rg -n 'public naming is still undecided|scale/precision parameterization needs|Priority order after the Poisson.*compois|planned COM-Poisson path|Var\\[y_i\\)|structural zero or hurdle-crossing|Implemented continuous families|Planned syntax candidate|hurdle-crossing probability' docs/design/06-distribution-roadmap.md docs/design/19-family-link-contract.md docs/design/01-formula-grammar.md vignettes/distribution-families.Rmd vignettes/formula-grammar.Rmd ROADMAP.md`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `air format .` (failed: `air` is not installed locally)
- `Rscript -e "pkgdown::build_site()" && Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check()"`
- `rg -n 'public naming is still undecided|scale/precision parameterization needs|Priority order after the Poisson.*compois|planned COM-Poisson path|Var\\[y_i\\)|structural zero or hurdle-crossing|hurdle-crossing probability|Implemented continuous families|Planned syntax candidate|type="”' ROADMAP.md docs/design vignettes pkgdown-site/articles/distribution-families.html pkgdown-site/articles/formula-grammar.html --glob '!docs/dev-log/**'`
- `rg -n 'roadmap syntax|hurdle-zero probability|Zero-inflated Poisson.*zi|beta\\(\\).*Planned|truncated_nbinom2\\(\\).*Planned|cumulative_logit\\(\\).*Planned|Implemented univariate families' docs/design/01-formula-grammar.md docs/design/06-distribution-roadmap.md docs/design/19-family-link-contract.md vignettes/distribution-families.Rmd vignettes/formula-grammar.Rmd pkgdown-site/articles/distribution-families.html pkgdown-site/articles/formula-grammar.html`

Results:

- direct renders for the distribution-family and formula-grammar vignettes:
  passed;
- `git diff --check`: clean;
- stale-wording scan: no hits for the old undecided beta precision wording,
  old COM-Poisson priority, old `Implemented continuous families` heading,
  malformed variance bracket, `hurdle-crossing probability`, malformed favicon
  MIME, or planned-status wording drift;
- positive consistency scan found the planned family rows, hurdle-zero wording,
  `zi` contract row, roadmap-syntax warning, and generated pkgdown pages;
- `pkgdown::check_pkgdown()`: no problems found;
- full `devtools::test()`: 981 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- no model code changed, so the test surface was consistency-focused rather
  than a new likelihood-recovery test;
- Pat's user-test review caught planned examples that looked runnable,
  denominator-syntax ambiguity, and the missing `zi` versus `hu` contrast;
- Rose's systems audit caught the missing formula-grammar source-of-truth
  update, missing implemented `zi` rows, and stale vignette heading.

Known limitations:

- `beta()`, `beta_binomial()`, `truncated_nbinom2()`, `hu`, and
  `cumulative_logit()` remain planned syntax, not fitted paths;
- beta-binomial denominator syntax is intentionally unresolved;
- the next implementation should start with strict fixed-effect `beta()` and
  add simulation plus comparator tests before any zero-inflated or
  beta-binomial extension.

Team learning:

- planned syntax should be added to the formula-grammar source of truth in the
  same patch as any roadmap article;
- user-facing planned examples need an explicit non-runnable warning when they
  look like ordinary `drmTMB()` calls.

## 2026-05-09 — Fixed-Effect Beta Mean-Scale Family

Task: implement the strict continuous-proportion `beta()` family with `mu` and
public `sigma` formulas.

Implemented:

- added exported `beta()` family constructor with `dpars = c("mu", "sigma")`
  and links `mu = "logit"`, `sigma = "log"`;
- added `drm_build_beta_ls_spec()` for fixed-effect univariate beta models,
  including strict `(0, 1)` response validation after missing-row filtering,
  default `sigma ~ 1`, starting values, and unsupported-grammar checks;
- added TMB `model_type = 10` beta likelihood with
  `phi = 1 / sigma^2`, `alpha = mu * phi`, and
  `beta_shape = (1 - mu) * phi`;
- updated `predict()`, `fitted()`, `sigma()`, `simulate()`, `residuals()`,
  `print()`, and the internal family-link table for beta models;
- added simulation recovery, independent `stats::dbeta()` likelihood,
  response-scale method, complete-case, factor-predictor, edge-scale, and
  unsupported-input tests;
- synchronized README, NEWS, pkgdown reference, formula grammar, family
  registry, likelihood design, family-link contract, source map, response
  family article, testing guide, and roadmap.

Commands run:

- `Rscript -e "parse('R/drmTMB.R'); parse('R/methods.R')"`
- `Rscript -e "devtools::load_all()"` (first run failed on `log1p()` in the
  TMB beta branch; rerun passed after replacing it with AD-safe `log(1 - y)`)
- `Rscript -e "devtools::test(filter = 'beta|family-link-contract')"` (first
  run caught an exact-boundary beta quantile in an edge test and a parser-level
  unsupported-parameter error message; rerun passed)
- `Rscript -e "devtools::test(filter = 'gamma-location-scale')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `air format .` (failed: `air` is not installed locally)
- `Rscript -e "devtools::test()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check()"`
- `rg -n 'future beta|planned beta|Candidate Beta|beta\(\).*Planned|Next family sequence: `beta\(\)`|before adding beta|not supported fitting paths.*beta|Once implemented.*beta|beta\(\).*roadmap syntax' README.md ROADMAP.md NEWS.md docs vignettes R tests pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`
- `rg -n 'Beta mean-scale|model_type = 10|family = beta\(\)|strict continuous proportions|phi = 1 / sigma\^2' README.md ROADMAP.md NEWS.md DESCRIPTION _pkgdown.yml docs/design vignettes pkgdown-site/articles pkgdown-site/reference/beta.html pkgdown-site/news/index.html R tests/testthat --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`
- `rg -n 'type="”|drmTMB_v25|trancated|lue distribution|old hex|man/figures/logo.png' README.md docs vignettes pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`

Results:

- targeted beta and family-link tests: 103 passed, 0 failed, 0 warnings,
  0 skips;
- post-documentation-refresh targeted beta and family-link tests: 103 passed,
  0 failed, 0 warnings, 0 skips;
- Gamma neighbour regression test: 54 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1043 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- favicon post-processing completed successfully;
- post-documentation-refresh `pkgdown::check_pkgdown()`: no problems found;
- post-documentation-refresh `devtools::check()`: 0 errors, 0 warnings,
  0 notes;
- `git diff --check`: clean;
- stale-wording scan found no active non-dev-log docs still describing
  `beta()` as planned, future, or roadmap-only;
- positive consistency scan found beta implemented wording in the README,
  NEWS, ROADMAP, design docs, vignettes, generated pkgdown article pages,
  `reference/beta.html`, and `news/index.html`;
- logo/favicon stale scan found no old-logo or malformed favicon wording hits.

Tests of the tests:

- independent likelihood test compares fitted `logLik()` to
  `stats::dbeta()` using the documented transform `phi = 1 / sigma^2`;
- complete-case test verifies boundary 0/1 rows are dropped before strict beta
  response validation when their predictors are missing;
- unsupported-input tests check boundary responses, `phi ~`, `nu ~`, duplicate
  `sigma`, response-less formulas, random effects, `sd(id)`, `meta_known_V()`,
  `mvbind()`, and `cbind(successes, failures)` denominator syntax;
- the first beta edge test failed before correction because deterministic
  quantiles for a very diffuse beta case reached exact machine boundaries.

Known limitations:

- beta models are fixed-effect, univariate, and strict `(0, 1)` only;
- random effects, known sampling covariance, phylogenetic/spatial terms,
  bivariate or mixed beta responses, zero/one inflation, ordered beta, and
  beta-binomial denominator syntax remain later phases;
- the C++ likelihood uses `log(1 - y)` rather than `log1p(-y)` because the
  local TMB autodiff type did not compile with plain `log1p()`.

Team learning:

- Curie's likelihood checklist caught the exact parameter transform and dummy
  TMB-data requirements before implementation;
- Meitner's test plan caught the most important boundary and method paths;
- Rose's after-task audit should keep checking generated pkgdown pages, not
  only source docs, because reference and news pages are where stale status
  often survives.

## 2026-05-09 — Fixed-Effect Zero-Truncated NB2 Family

Task: implement `truncated_nbinom2()` for fixed-effect positive-count
negative-binomial 2 distributional regression.

Implemented:

- added exported `truncated_nbinom2()` family constructor with
  `dpars = c("mu", "sigma")` and links `mu = "log"`, `sigma = "log"`;
- added `drm_build_truncated_nbinom2_spec()` for fixed-effect univariate
  positive-count models, including default `sigma ~ 1`, complete-case
  filtering before response validation, positive-integer checks, and clear
  rejections for `zi`, `hu`, random effects, `sd(group)`, `meta_known_V()`,
  `mvbind()`, and `cbind()` denominator syntax;
- added TMB `model_type = 11` with an NB2 log density minus the
  zero-truncation normalising constant `log(1 - Pr_NB2(0))`;
- updated `predict()`, `fitted()`, `sigma()`, `simulate()`, `residuals()`,
  `print()`, and the internal family-link table for zero-truncated NB2;
- added simulation recovery, independent `stats::dnbinom()` likelihood,
  response-scale method, complete-case, Poisson-limit, factor-predictor,
  scale-edge, and unsupported-input tests;
- synchronized README, NEWS, DESCRIPTION, pkgdown reference, formula grammar,
  family registry, likelihood design, testing strategy, distribution roadmap,
  family-link contract, source map, response-family article, testing guide,
  and known limitations.

Commands run:

- `Rscript -e "parse('R/drmTMB.R'); parse('R/methods.R'); parse('R/family.R'); parse('tests/testthat/test-truncated-nbinom2-location-scale.R')"`
- `Rscript -e "devtools::load_all()"`
- `Rscript -e "devtools::document()"` (first run warned because the new
  `truncated_nbinom2` Rd topic did not exist yet; rerun after generation was
  clean)
- `Rscript -e "devtools::test(filter = 'truncated-nbinom2|family-link-contract')"`
- `Rscript -e "devtools::test(filter = 'nbinom2|zi-nbinom2')"`
- `air format .` (failed: `air` is not installed locally)
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- ``rg -n 'truncated_nbinom2\(\).*planned|planned.*truncated_nbinom2|implement `truncated_nbinom2|practical next-family order is `truncated_nbinom2|Hurdle, truncated|truncated.*staged|Positive-count models should come before|zero-truncated.*planned' README.md ROADMAP.md NEWS.md DESCRIPTION docs vignettes R tests man --glob '!docs/dev-log/**'``
- `rg -n 'model_type = 11|family = truncated_nbinom2\(\)|Zero-truncated negative|zero-truncated NB2|truncated_nbinom2\(\).*fits|fitted\(\).*Pr_NB2\(0\)' README.md ROADMAP.md NEWS.md DESCRIPTION _pkgdown.yml docs/design vignettes man R tests/testthat --glob '!docs/dev-log/after-task/**'`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- ``rg -n 'truncated_nbinom2\(\).*planned|planned.*truncated_nbinom2|implement `truncated_nbinom2|practical next-family order is `truncated_nbinom2|Hurdle, truncated|truncated.*staged|zero-truncated.*planned' README.md ROADMAP.md NEWS.md DESCRIPTION docs vignettes man pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!pkgdown-site/search.json'``
- `rg -n 'Zero-truncated negative|zero-truncated NB2|truncated_nbinom2|model_type = 11|positive-count mean' pkgdown-site/articles pkgdown-site/reference pkgdown-site/news pkgdown-site/index.html pkgdown-site/ROADMAP.html --glob '!pkgdown-site/search.json'`
- `Rscript -e "devtools::check()"`

Results:

- targeted truncated-NB2 and family-link tests: 109 passed, 0 failed, 0
  warnings, 0 skips;
- neighbouring NB2, zero-inflated NB2, and truncated-NB2 tests: 148 passed, 0
  failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1104 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully and generated
  `reference/truncated_nbinom2.html`;
- favicon post-processing completed successfully;
- `git diff --check`: clean;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- stale-wording scan found no active source docs still describing
  `truncated_nbinom2()` as planned; the generated pkgdown meta description
  matched the broader pattern `truncated.*staged` only because it correctly
  says zero-truncated count models are implemented and hurdle/skewness models
  are staged later.

Tests of the tests:

- independent likelihood test compares fitted `logLik()` to
  `stats::dnbinom(y, mu, size) - log(1 - Pr_NB2(0))`;
- Poisson-limit test fixes `sigma` near zero and compares the objective to a
  hand-coded zero-truncated Poisson likelihood;
- complete-case test verifies invalid positive-count responses are dropped
  before validation when their predictors are missing;
- unsupported-input tests cover `nu`, `zi`, planned `hu`, duplicate `sigma`,
  missing response, zero/noninteger/negative/all-missing responses, random
  effects, `meta_known_V()`, `sd(id)`, `mvbind()`, and `cbind()`.

Known limitations:

- `truncated_nbinom2()` is fixed-effect and univariate only;
- `mu` and `sigma` describe the untruncated NB2 component; users should use
  `fitted()` for the expected observed positive count;
- hurdle models with `hu ~ predictors`, random effects, known sampling
  covariance, phylogenetic/spatial terms, bivariate count models, and mixed
  composed count families remain later phases.

Team learning:

- zero-truncated and hurdle models need sharply separated language because
  they share the truncated count kernel but answer different data-generating
  questions;
- extractor semantics must be checked whenever `predict(mu)` is not the same
  quantity as `fitted()`;
- generated pkgdown meta descriptions can trigger broad stale-wording scans,
  so future audits should classify those hits rather than blindly rewrite
  correct summaries.

## 2026-05-09 — Fixed-Effect Hurdle NB2 Family Component

Task: implement fixed-effect hurdle negative-binomial 2 models by adding
`hu ~ predictors` to the existing `truncated_nbinom2()` family route.

Implemented:

- extended `drm_build_truncated_nbinom2_spec()` so `hu` is an optional
  one-sided hurdle-zero formula;
- kept plain `truncated_nbinom2()` positive-only, while
  `truncated_nbinom2()` plus `hu ~ ...` accepts non-negative integer counts
  with at least one positive count;
- added TMB `model_type = 12` with
  `Pr(y = 0) = hu` and
  `Pr(y = k > 0) = (1 - hu) Pr_NB2(k) / (1 - Pr_NB2(0))`;
- exposed public coefficients and predictions as `hu`, while keeping
  `predict(fit, dpar = "mu")` as the untruncated NB2 component mean;
- updated `fitted()`, `simulate()`, `residuals()`, `sigma()`, `print()`, and
  the family-link helper for hurdle NB2;
- added simulation recovery, independent likelihood, method, complete-case,
  Poisson-limit, and malformed-input tests;
- synchronized DESCRIPTION, NEWS, README, ROADMAP, formula grammar, family
  registry, likelihood design, testing strategy, distribution roadmap,
  family-link contract, source map, response-family vignette, testing guide,
  known limitations, and generated Rd files.

Commands run:

- `Rscript -e "devtools::document(); devtools::test(filter = 'hurdle-nbinom2|truncated-nbinom2|family-link-contract')"`
- `air format .` (failed: `air` is not installed locally)
- `Rscript -e "devtools::test(filter = 'nbinom2|zi-nbinom2')"`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- ``rg -n 'hurdle NB2.*planned|hu ~.*Planned|Hurdle syntax.*planned|hurdle components.*later|hurdle count models.*planned|Next family sequence: hurdle|add hurdle NB2|hurdle models using .*remain|hurdle.*later phase|rejects `hu`' README.md ROADMAP.md NEWS.md DESCRIPTION docs/design vignettes R tests man``
- `rg -n 'model_type = 12|hu ~|hurdle-zero|hurdle_nbinom2|Hurdle NB2 models are implemented' pkgdown-site/articles pkgdown-site/reference pkgdown-site/index.html pkgdown-site/news/index.html`
- `Rscript -e "devtools::check()"`

Results:

- targeted hurdle/truncated/family-link tests: 166 passed, 0 failed, 0
  warnings, 0 skips;
- neighbouring NB2/zero-inflated/truncated/hurdle tests: 198 passed, 0 failed,
  0 warnings, 0 skips;
- full `devtools::test()`: 1161 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `git diff --check`: clean;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- stale-wording scan found no active source docs still describing hurdle NB2
  as planned. A broad generated-site scan matched only the correct DESCRIPTION
  sentence saying hurdle count models are implemented and skewness/additional
  response families are later phases.

Tests of the tests:

- independent likelihood test compares `logLik()` to a hand calculation using
  `log(hu)` for zeros and `log(1 - hu) + log Pr_NB2(y) -
  log(1 - Pr_NB2(0))` for positive counts;
- Poisson-limit test fixes `sigma` near zero and compares the objective to a
  hand-coded hurdle zero-truncated Poisson likelihood;
- method tests check that `predict(mu)` remains the untruncated NB2 component
  mean while `fitted()` returns `(1 - hu) * mu / (1 - Pr_NB2(0))`;
- malformed-input tests cover simultaneous `zi` and `hu`, duplicate `hu`,
  two-sided `hu`, zero-column `hu`, random effects, `sd(id)`, `meta_known_V()`,
  negative/noninteger/all-zero responses, `mvbind()`, and `cbind()`.

Known limitations:

- hurdle NB2 is fixed-effect and univariate only;
- random effects, known sampling covariance, phylogenetic/spatial terms,
  bivariate count models, and mixed composed count families remain later
  phases for this count route;
- there is no separate `hurdle_nbinom2()` constructor by design.

Team learning:

- Rose's after-task audit paid off again: the main risk was stale status text,
  not only likelihood code;
- Noether's math/R pairing rule kept the `predict(mu)` versus `fitted()`
  distinction explicit in docs and tests;
- the next skill improvement should be a small local formatting helper or
  installing `air`, because the desired formatter is still absent.

## 2026-05-09 — Bivariate Correlation-Pair and Ordinal Guard Design

Goal:

- clarify that bivariate double-hierarchical random-effect covariance blocks
  remain planned, separate from residual `rho12`;
- create a dedicated coscale correlation-pair design note before implementing
  complex pair extraction or likelihoods;
- fold Ortega et al. (2026) nest-success ordinal location-scale motivation
  into the distribution roadmap and family-link contract.

Changes:

- added `docs/design/20-coscale-correlation-pairs.md`;
- updated bivariate unsupported random-effect errors so `(1 | id)` and
  `(1 + x | p | id)` in `mu1`/`mu2` point users to the planned bivariate
  covariance-block path instead of a generic unsupported-term message;
- added bivariate guard tests in `tests/testthat/test-biv-gaussian.R`;
- updated the distribution roadmap, family-link contract, random-effects note,
  location-coscale phylogenetic note, formula-grammar vignette, response-family
  vignette, README, ROADMAP, reference programme, and known limitations;
- added `Ortega2026SeabirdPredictability` to `REFERENCES.bib`.

Commands run:

- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'formula-grammar|gaussian-random-intercepts|gaussian-random-effect-scale')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check()"`
- `git diff --check`
- `air format .` (failed: `air` is not installed locally)
- `rg -n "Bivariate random-effect syntax is planned|correlation-pair|corpairs|zeta|cumulative_logit|O.Dea-style|O'Dea-style|biological data|rho ~|tau ~|meta_gaussian" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests REFERENCES.bib`
- `rg -n "Bivariate random-effect syntax is planned|correlation-pair|corpairs|zeta|cumulative_logit|O.Dea-style|O'Dea-style|biological data|rho ~|tau ~|meta_gaussian" pkgdown-site README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes R tests REFERENCES.bib`

Results:

- targeted bivariate Gaussian tests: 95 passed, 0 failed, 0 warnings, 0 skips;
- neighbouring formula/random-effect tests: 234 passed, 0 failed, 0 warnings,
  0 skips;
- full `devtools::test()`: 1162 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `git diff --check`: clean;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- stale-wording scans found expected planned ordinal/correlation-pair text and
  existing meta-analysis policy text; no `O'Dea-style` or "biological data"
  framing remained in the scanned source files.

Tests of the tests:

- new bivariate tests check malformed future syntax with both unlabelled and
  labelled bivariate random-effect blocks;
- the labelled-block test verifies that the user-facing error mentions planned
  labelled group-level covariance blocks rather than residual `rho12`.

Known limitations:

- this is a guard/design phase, not a new bivariate random-effect likelihood;
- `corpairs()` is a proposed extractor name, not an exported function;
- ordinal cumulative-logit location-scale models remain planned, and the
  `sigma` versus `zeta` public naming decision must be revisited before coding.

Team learning:

- Boole and Emmy should use the new pair table as the syntax/API constraint for
  future bivariate covariance work;
- Noether should require every future pair class to have symbolic equations
  paired with R syntax and extractor output;
- Rose should check that future docs do not use `rho12` for phylogenetic,
  spatial, or group-level correlations;
- Pat should review the ordinal nest-success explanation for whether an
  applied user understands the direction of `sigma` versus `zeta`.

## 2026-05-09 — Correlation-Pair Extractor and Tutorial Weight Clarification

Goal:

- export a first `corpairs()` helper for correlations that are already fitted;
- improve the bivariate coscale tutorial so symbolic equations, R syntax,
  model output, and interpretation are paired for applied users;
- clarify that the internal `0.99999999 * tanh()` residual-correlation guard
  is a numerical detail, not the biological model;
- record a first design contract for future `weights =` support.

Changes:

- added exported `corpairs()` and `corpairs.drmTMB()` methods;
- added `tests/testthat/test-corpairs.R`;
- added `man/corpairs.Rd` through `devtools::document()`;
- added `docs/design/21-tutorial-style.md`;
- added `docs/design/22-likelihood-weights.md`;
- added `docs/design/23-large-data-memory.md`;
- revised `vignettes/bivariate-coscale.Rmd` with LaTeX equations, a runnable
  ecological example, `summary(fit)`, `coef(fit, "rho12")`, `rho12(fit)`,
  `corpairs(fit)`, and a response-scale interpretation table;
- updated `vignettes/which-scale.Rmd` and
  `docs/design/03-likelihoods.md` to separate teaching notation
  `rho12_i = tanh(eta_rho12_i)` from the exact guarded implementation;
- updated `vignettes/formula-grammar.Rmd`, `_pkgdown.yml`, `README.md`,
  `ROADMAP.md`, `NEWS.md`, `docs/design/20-coscale-correlation-pairs.md`, and
  `docs/dev-log/known-limitations.md`;
- replaced remaining current-source `flagship` wording in roadmap/design prose
  with more professional terms such as `signature`, `core`, or
  `central example`;
- recorded that top-level `weights =` is planned for ordinary likelihood row
  weights and should remain distinct from `meta_known_V(V = V)`.
- recorded that the sparse phylogenetic A-inverse path and the million-row
  R-memory path are separate scaling problems.

Commands run:

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'corpairs|biv-gaussian|gaussian-random-intercepts')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/formula-grammar.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `air format .`
- `rg -n 'Fisher-z/atanh scale|flagship|selling point|O.Dea-style|O\\x27Dea-style|biological data' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n 'weights|meta_known_V\\(V = V\\)|rho12_i = tanh|0\\.99999999 \\* tanh|corpairs|Goodall|Russell|Confucius' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man pkgdown-site --glob '!docs/dev-log/after-task/**'`

Results:

- targeted tests: 299 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1192 passed, 0 failed, 0 warnings, 0 skips;
- direct vignette renders completed for formula grammar, bivariate coscale,
  which-scale, and phylogenetic-spatial pages;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean;
- `air format .`: failed because `air` is not installed locally;
- stale-wording scans found no current-source `flagship`, `selling point`,
  `O'Dea-style`, or narrow "biological data" framing outside historical
  after-task notes.

Tests of the tests:

- `corpairs()` tests cover a predictor-dependent residual `rho12`, an ordinary
  labelled group-level `mu` random intercept-slope correlation, and the empty
  no-correlation case;
- the group-level test checks parsed covariance-block labels, coefficient
  names, response names, class labels, and the guarded correlation link;
- the bivariate residual test checks both response-scale and link-scale
  summaries against `rho12(fit)` and `predict(..., dpar = "rho12")`.

Known limitations:

- `corpairs()` only reports correlations already fitted by current likelihoods:
  residual bivariate `rho12` and ordinary univariate Gaussian `mu`
  random-effect correlations;
- bivariate group-level, phylogenetic, spatial, study-level, and cross-parameter
  correlation pairs remain planned;
- `weights =` remains a design note, not an implemented `drmTMB()` argument;
- large-data memory controls, sparse fixed-effect model matrices, and
  sufficient-statistic aggregation are planned but not implemented;
- `air` remains unavailable in the local toolchain.

Team learning:

- Ada should keep using stable team names in reports; temporary app nicknames
  should not appear in user-facing logs;
- Pat and Darwin pushed the bivariate tutorial toward real output and
  interpretation rather than syntax-only examples;
- Rose caught that tutorial notation and implementation notation need different
  jobs: readable model equations first, exact numerical guard in implementation
  notes;
- Fisher should require large-data benchmarks before the 10,000-tip,
  5-million-row phylogenetic path is called production-ready;
- Boole and Emmy should treat `weights =` as top-level fit syntax, not formula
  syntax.
- Grace should treat large-data readiness as a benchmarked release criterion,
  not a claim inferred from ordinary unit tests.

## 2026-05-09 — Likelihood Row Weights

Goal:

- implement top-level `weights =` as ordinary row log-likelihood multipliers;
- keep `weights =` separate from known sampling variance/covariance through
  `meta_known_V(V = V)`;
- expose processed model-row weights through `weights(fit)`.

Changes:

- added `weights = NULL` to `drmTMB()`;
- added internal `evaluate_likelihood_weights_arg()` and
  `subset_likelihood_weights()` helpers;
- stored processed weights in `fit$model$weights` and passed them to TMB as
  `DATA_VECTOR(weights)`;
- multiplied independent-row TMB likelihood contributions by `weights(i)`;
- used one complete-row weight per bivariate Gaussian response pair;
- rejected non-unit weights with full dense `meta_known_V(V = V)` covariance
  matrices because those paths are joint MVN likelihood blocks;
- added `weights.drmTMB()` documentation and pkgdown reference entry;
- updated `README.md`, `NEWS.md`, `docs/design/01-formula-grammar.md`,
  `docs/design/03-likelihoods.md`, `docs/design/22-likelihood-weights.md`,
  `docs/design/23-large-data-memory.md`, and `vignettes/source-map.Rmd`;
- recorded Andrew Gelman, Paul-Christian Buerkner, Jarrod Hadfield, David
  Fletcher, and Shun-ichi Amari in the reference programme as statistical
  computing and inference influences.

Commands run:

- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'phylo-utils')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|phylo-utils')"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n "S3method\\(weights|weights.drmTMB|@param weights|weights =" NAMESPACE man R tests docs/design vignettes/source-map.Rmd README.md NEWS.md _pkgdown.yml`
- `rg -n 'weights.*not yet|does not yet have.*weights|planned.*weights|weights.*planned|Status: planned' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml pkgdown-site --glob '!docs/dev-log/after-task/**'`
- `rg -n 'David \\[surname|Buerkner|Bürkner|Hadfield|Amari|Gelman|Fletcher' README.md ROADMAP.md NEWS.md docs/design docs/dev-log vignettes R tests man _pkgdown.yml`

Results:

- targeted Gaussian location-scale tests: 67 passed, 0 failed, 0 warnings,
  0 skips;
- targeted bivariate Gaussian tests: 101 passed, 0 failed, 0 warnings,
  0 skips;
- targeted phylo-utils tests: 45 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- combined targeted rerun after namespace repair: 213 passed, 0 failed,
  0 warnings, 0 skips;
- source-map vignette rendered successfully;
- `devtools::document()` updated `NAMESPACE`, `man/drmTMB.Rd`, and
  `man/weights.drmTMB.Rd`;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- first `devtools::check()` attempt exposed a missing `stats::weights`
  namespace import for the new S3 method;
- after adding `@importFrom stats weights`, final `devtools::check()`: 0 errors,
  0 warnings, 0 notes;
- `git diff --check`: clean.
- stale-wording scans found no stale current-source `weights planned` wording;
  the remaining `Status: planned` hit is the unrelated Phase 5b large-data
  memory strategy.

Tests of the tests:

- constant Gaussian weights check that parameter estimates are stable and
  `logLik` doubles;
- integer Gaussian weights check equivalence with explicit row duplication,
  including zero weights;
- malformed Gaussian weights check wrong length, negative values, missing or
  non-finite values, all-zero weights, and matrix input;
- bivariate Gaussian weights check complete-row weighting by doubling the
  row-paired likelihood;
- the full dense known-covariance rejection test protects the
  `meta_known_V(V = V)` distinction.

Known limitations:

- `weights =` are ordinary likelihood multipliers, not a memory-saving
  aggregation path;
- dense full known-covariance meta-analysis cannot yet be combined with
  non-unit weights;
- response-specific bivariate weights are not implemented;
- sufficient-statistic aggregation for very large Gaussian data remains a
  separate planned scaling feature.

Team learning:

- Boole and Emmy should keep `weights =` out of formula grammar;
- Fisher should require comparator checks before documenting weights as
  frequency weights beyond independent likelihoods;
- Grace should watch dense known-covariance and weight interactions in CI;
- Rose should continue checking for stale `weights planned` wording after
  pkgdown builds.
- Ada should treat namespace imports for new S3 generics as part of the
  implementation checklist, not only as a `devtools::check()` cleanup item.

## 2026-05-09 — Scale Tutorial Output Upgrade

Goal:

- improve the "Which scale are you modelling?" tutorial so readers see
  symbolic equations, matching R syntax, fitted output, and interpretation for
  the main scale-like quantities;
- remove the tiny `rho12` numerical guard from user-facing symbolic equations
  where it distracts from the statistical model.

Changes:

- added a copy-run scale audit to `vignettes/which-scale.Rmd`;
- added executed examples and fitted output for `sigma ~ temperature`,
  `weights = reliability`, `meta_known_V(V = vi)`, `sd(population) ~ habitat`,
  and bivariate `rho12 ~ treatment`;
- added LaTeX equations for the residual scale, known sampling variance,
  random-effect scale, and residual coscale examples;
- revised the `rho12` side-by-side guide to show the teaching equation
  `rho12_i = tanh(eta_rho12_i)` and moved the exact numerical guard into an
  implementation-detail note;
- made the same teaching-notation change in the README bivariate equation;
- made matching teaching-notation updates in `vignettes/drmTMB.Rmd` and
  `vignettes/adding-families.Rmd`;
- recorded the tutorial upgrade in `NEWS.md`.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|meta-known-v|random-effect-scale')"`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/adding-families.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n '0\\.99999999 \\* tanh|rho12_i = 0\\.99999999|tiny guard|scale audit|weights = reliability|meta_known_V\\(V = vi\\)' README.md vignettes pkgdown-site/index.html pkgdown-site/articles/which-scale.html docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-09-scale-tutorial-output-upgrade.md`

Results:

- changed tutorial rendered successfully;
- getting-started and adding-families vignettes rendered successfully after
  the additional guard-notation cleanup;
- targeted neighbouring tests: 268 passed, 0 failed, 0 warnings, 0 skips;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::check_pkgdown()`: no problems found before and after site build;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- final `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- final post-cleanup `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- `git diff --check`: clean.
- stale-guard scan found no exact `0.99999999 * tanh()` guard in `README.md`,
  `vignettes/which-scale.Rmd`, `pkgdown-site/index.html`, or the rendered
  `which-scale` article; remaining hits are in historical check-log entries,
  the new after-task note, and implementation/developer vignettes where the
  guard is part of source or likelihood review.

Tests of the tests:

- the tutorial now executes model fits for the same likelihood paths checked by
  the targeted tests: Gaussian location-scale, known-`V` Gaussian
  meta-analysis, random-effect scale models, and bivariate Gaussian `rho12`;
- the rendered output checks that examples show actual `summary()`, `coef()`,
  `sigma()`, `weights()`, `predict(..., dpar = "sd(population)")`, and
  `rho12()` output rather than syntax-only blocks.
- the final `devtools::check()` rebuilt all vignettes after the extra README
  and article guard-notation cleanup.

Known limitations:

- the tutorial examples are simulated and deliberately compact; they do not yet
  include plots or a full biological data-analysis narrative;
- the exact `0.99999999 * tanh()` guard remains documented in implementation
  design notes, NEWS, and source-oriented pages where numerical details matter.

Team learning:

- Pat and Darwin should keep asking whether a tutorial shows fitted output and
  an interpretation, not only a valid formula;
- Noether should treat the readable equation and the exact guarded
  implementation as two linked but differently scoped objects;
- Rose should search both articles and README pages for user-facing numerical
  implementation details that belong in footnotes or implementation notes.

## 2026-05-09 — Location-Scale Tutorial Teaching Upgrade

Goal:

- make the Gaussian location-scale tutorial feel like a worked applied
  tutorial rather than only an API grammar page;
- answer Shinichi's request for symbolic equations paired with R syntax,
  fitted output, and biological interpretation.

Changes:

- added a fish-growth style worked example to `vignettes/location-scale.Rmd`;
- added executable simulation, model fit, `check_drm()`, `summary()`,
  response-scale `sigma` interpretation, and a fitted mean/residual-SD table;
- rewrote the opening of the article around the biological question of mean
  growth versus growth predictability;
- corrected `sd(site)_i` to group-level `sd(site)_k`;
- narrowed stale caveat wording from all non-Gaussian families to
  non-Gaussian random effects in this Gaussian tutorial;
- softened the future `corpairs()` wording in `vignettes/bivariate-coscale.Rmd`
  so planned correlation levels are not presented as current implementation;
- added a tutorial sentence clarifying that dense full `meta_known_V(V = V)`
  paths currently reject non-unit likelihood weights;
- recorded the tutorial upgrade in `NEWS.md`.

Commands run so far:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|gaussian-random-effect-scale|gaussian-random-intercepts')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/location-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/which-scale.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `rg -n "first implemented|planned but not implemented|weights.*not implemented|non-Gaussian families|rho ~|tau ~|will also use|sd\\(site\\)_i" README.md vignettes docs/design docs/dev-log/known-limitations.md NEWS.md`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results so far:

- `vignettes/location-scale.Rmd`, `vignettes/which-scale.Rmd`, and
  `vignettes/bivariate-coscale.Rmd` render successfully;
- targeted Gaussian neighbouring tests: 301 passed, 0 failed, 0 warnings,
  0 skips;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `git diff --check`: clean;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes;
- stale-status scan found no remaining `sd(site)_i`, no `will also use`, and
  no user-facing `non-Gaussian families` stale claim in changed vignettes;
  remaining hits are current planned-feature caveats or design-log patterns.

Tests of the tests:

- the rendered location-scale vignette now executes the exact Gaussian
  location-scale path exercised by `test-gaussian-location-scale.R`;
- the targeted tests also covered neighbouring random-intercept and
  random-effect-scale paths that the same vignette documents.

Known limitations:

- this pass adds a response-scale table but not a full plot; a future tutorial
  polish pass should add a small visual summary and possibly a real dataset;
- the example remains simulated to keep the vignette fast and deterministic.

Team learning:

- Pat's usability review correctly identified that `location-scale` was still
  too abstract compared with `which-scale` and `bivariate-coscale`;
- Rose's systems audit caught stale status wording and one observation-level
  index that should have been group-level;
- Ada should keep using staggered review during tutorial work: edit locally
  while Pat checks user comprehension and Rose checks cross-document drift.

## 2026-05-09 — Bivariate Coscale Tutorial Teaching Upgrade

Goal:

- make the bivariate location-coscale article teach residual `rho12` with
  biological variables, symbolic equations, fitted output, and response-scale
  interpretation;
- continue the tutorial style used in the location-scale upgrade.

Changes:

- renamed the runnable example section to a worked behaviour-coupling example;
- added activity-boldness model equations with `food`, `temperature`, and
  `disturbance` as biological predictors;
- clarified that `rho12` is not the raw activity-boldness correlation, but the
  residual correlation after response-specific mean and residual-SD models;
- added a "How to read this output" block after `summary(fit_biv)`;
- added a response-scale `rho12` curve along the disturbance gradient;
- added a concise reporting sentence for the fitted residual-correlation
  result;
- recorded the tutorial upgrade in `NEWS.md`.

Commands run so far:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian|corpairs|check-drm')"`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results so far:

- `vignettes/bivariate-coscale.Rmd` renders successfully;
- targeted bivariate/correlation diagnostics tests: 184 passed, 0 failed,
  0 warnings, 0 skips.
- `git diff --check`: clean;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- the rendered vignette executes the same fixed-effect bivariate Gaussian
  `rho12` path tested by `test-biv-gaussian.R`;
- the targeted test command also exercises `corpairs()` and `check_drm()`,
  which the edited tutorial prints.

Known limitations:

- the example is still simulated rather than a real behaviour dataset;
- the curve is a teaching plot, not an uncertainty interval;
- bivariate random effects and group-level bivariate covariance blocks remain
  planned and are explicitly separated from residual `rho12`.

Team learning:

- Noether's equation/syntax pairing should continue to use actual variables in
  user tutorials;
- Darwin and Pat's style preference is now clear: show the output row, explain
  the link scale, then translate to the biological question;
- Rose should continue watching for future-correlation wording that sounds
  implemented before the TMB likelihood exists.

## 2026-05-09 — Meta-Analysis Tutorial Teaching Upgrade

Goal:

- turn the meta-analysis article from a design scaffold into a teaching
  tutorial with equations, executable R syntax, fitted output, response-scale
  interpretation, and a clear `weights =` versus `meta_known_V(V = V)`
  distinction;
- keep meta-analysis framed as Gaussian regression with known sampling
  covariance, not a separate family or `tau ~` grammar.

Changes:

- retitled the article to "Mean effects and residual heterogeneity in
  meta-analysis";
- added univariate diagonal-`V` equations and full-`V` equations;
- added a worked ecological restoration example with `habitat`, `duration`,
  known sampling variance `vi`, `summary(fit_meta)`, response-scale `sigma`,
  and `check_drm(fit_meta)`;
- clarified that `weights = 1 / vi` is not equivalent to
  `meta_known_V(V = vi)`;
- made the repeated-study `sd(study)` example explicitly schematic and tied it
  to `dat_repeated`, avoiding confusion with the one-row-per-study simulated
  example;
- clarified that bivariate `rho12` is estimated residual correlation after
  known within-study sampling covariance, and only becomes a between-study
  residual correlation when the residual component represents between-study
  heterogeneity;
- updated `docs/design/08-meta-analysis.md` with the same `rho12` wording and
  moved the `0.99999999` boundary guard out of the symbolic transform and into
  implementation prose;
- recorded the tutorial upgrade in `NEWS.md`.

Commands run so far:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/meta-analysis.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'meta')"`
- `rg -n "residual or between-study|heterogeneous heterogeneity|rho12_i = 0\\.99999999|0\\.99999999 \\* tanh|O.Dea-style|O'Dea-style|meta_gaussian|tau ~" vignettes/meta-analysis.Rmd docs/design/08-meta-analysis.md NEWS.md README.md ROADMAP.md docs/dev-log/known-limitations.md`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "Mean effects and residual heterogeneity|restoration|weights = 1 / vi|coscale means|between-study residual correlation|0\\.99999999" pkgdown-site/articles/meta-analysis.html pkgdown-site/news/index.html`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results so far:

- `vignettes/meta-analysis.Rmd` renders successfully after `devtools::load_all()`;
- targeted meta-analysis tests: 57 passed, 0 failed, 0 warnings, 0 skips;
- `git diff --check`: clean;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully and wrote the updated
  `articles/meta-analysis.html`;
- favicon MIME post-processing completed successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- generated HTML contains the new title, restoration example, weights
  clarification, coscale definition, and corrected between-study residual
  correlation wording;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- the rendered tutorial executes the implemented univariate Gaussian
  `meta_known_V(V = vi)` path and prints `summary()`, `sigma()`, and
  `check_drm()` output;
- targeted tests exercise diagonal and dense known-`V` paths, malformed
  covariance input, row filtering, random-effect scale combinations, and the
  bivariate `meta_vcov_bivariate()` helper.

Known limitations:

- the worked restoration example is simulated to keep the vignette
  deterministic and fast;
- the repeated-study `sd(study)` example remains schematic rather than
  executable in this article;
- bivariate known-`V` fitting remains dense, complete-row, and without sparse
  storage or missing-single-outcome support.

Team learning:

- Pat caught that "multiple effect sizes per study" conflicted with the
  earlier one-row-per-study simulation, so tutorial sections should say clearly
  when they are executable versus schematic;
- Noether's equation pass should keep public equations clean and move numerical
  guards such as `0.99999999` into implementation notes;
- Rose's stale-wording scan should include design docs, not only vignettes,
  because ambiguous tutorial wording can hide in design notes too.

## 2026-05-09 — Phylogenetic-Spatial Tutorial Teaching Upgrade

Goal:

- make the structured-dependence article teach the implemented
  `phylo(1 | species, tree = tree)` path with a concrete ecology/evolution
  example, equations, fitted output, interpretation, and failure-recovery
  guidance;
- keep planned spatial syntax visibly marked as planned before any spatial
  code block appears.

Changes:

- retitled the article to "Structured dependence: implemented phylogeny and
  planned spatial models";
- added a worked thermal-tolerance example where body size predicts species
  trait means after accounting for shared ancestry;
- added LaTeX equations for the structured-effect bridge and the implemented
  Gaussian phylogenetic location model;
- added fitted `summary(fit_phylo)` output, response-scale residual SD, fitted
  phylogenetic SD, and `check_drm(fit_phylo)`;
- added a practical tree/species recovery checklist covering `phylo` class,
  tip labels, name matching, positive branch lengths, ultrametricity, and the
  currently implemented intercept-only Gaussian `mu` syntax;
- changed the spatial section heading and lead sentence so users see
  "planned, not implemented" before the code block;
- clarified in `README.md` that `sigma_phylo` is the among-species
  phylogenetic SD in the mean, while `sigma` remains the residual
  within-observation SD;
- clarified in `ROADMAP.md` that future sparse known-covariance infrastructure
  is beyond the current phylogenetic A-inverse path.

Commands run so far:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'phylo|check-drm')"`
- `git diff --check`
- `rg -n "spatial fields|spatial\\(1 \\| site|planned, not implemented|Hadfield and Nakagawa|A-inverse path internally|sigma_phylo|thermal tolerance|species names" vignettes/phylogenetic-spatial.Rmd README.md ROADMAP.md NEWS.md`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "Structured dependence: implemented phylogeny|thermal tolerance|body size predicts|tree object has class|spatial likelihood is not implemented|setup code creates|sigma_phylo|Hadfield and Nakagawa|A-inverse path internally" pkgdown-site/articles/phylogenetic-spatial.html pkgdown-site/index.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results so far:

- `vignettes/phylogenetic-spatial.Rmd` renders successfully;
- targeted phylogenetic/check tests: 124 passed, 0 failed, 0 warnings, 0 skips;
- `git diff --check`: clean;
- full `devtools::test()`: 1215 passed, 0 failed, 0 warnings, 0 skips;
- `pkgdown::build_site()`: completed successfully;
- favicon MIME post-processing completed successfully;
- `pkgdown::check_pkgdown()`: no problems found;
- generated HTML contains the new title, thermal-tolerance example,
  tree/species checklist, explicit spatial-not-implemented wording, and
  `sigma_phylo` explanation;
- `devtools::check()`: 0 errors, 0 warnings, 0 notes.

Tests of the tests:

- the rendered tutorial executes the implemented univariate Gaussian
  phylogenetic `mu` likelihood and prints `summary()`, `check_drm()`, residual
  SD, and phylogenetic SD output;
- targeted tests exercise the phylogenetic Gaussian objective, dense marginal
  likelihood comparators, meta-analysis composition, conditional prediction,
  missing-row handling, and planned-feature errors for phylogenetic slopes and
  phylogenetic `sigma`.

Known limitations:

- the worked thermal-tolerance dataset is simulated so the vignette remains
  deterministic and fast;
- the tree helper is a toy setup helper, not a recommended phylogenetic data
  workflow;
- spatial random effects, phylogenetic slopes, phylogenetic `sigma`, and
  bivariate structured covariance blocks remain planned.

Team learning:

- Socrates caught that a roadmap article still needs a concrete scientific
  question before syntax;
- applied users need recovery guidance immediately after implemented
  structured syntax, especially tree-tip and species-name checks;
- Ada should keep planned spatial syntax in clearly labelled "not implemented"
  sections until the likelihood and recovery tests exist;
- Ada should treat token and context efficiency as a project skill: use
  targeted reads, concise updates, and fewer agents unless parallel review
  clearly reduces risk.

## 2026-05-09 — Tutorial Learning Path Navigation

Goal:

- make the pkgdown tutorial navigation and get-started article point users to
  the right tutorial from their scientific or statistical question;
- keep the pass small and efficient after the larger tutorial upgrades.

Changes:

- added a "Learning path" table to `vignettes/drmTMB.Rmd`;
- updated pkgdown tutorial menu labels for meta-analysis and
  phylogenetic-spatial tutorials;
- recorded the navigation change in `NEWS.md`.

Commands run:

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `rg -n "Learning path|Start with the question|Mean effects and heterogeneous heterogeneity|Implemented phylogeny and planned space|Mean effects and residual heterogeneity|Structured dependence$" pkgdown-site/articles/drmTMB.html pkgdown-site/articles/index.html pkgdown-site/news/index.html pkgdown-site/pkgdown.yml _pkgdown.yml vignettes/drmTMB.Rmd NEWS.md`
- `git diff --check`

Results:

- get-started article render: passed;
- pkgdown build: passed;
- pkgdown check: no problems found;
- generated HTML contains the learning path and updated tutorial menu labels;
- no stale generated-site hit remains for the old meta-analysis menu label.

Tests of the tests:

- this was a documentation-navigation change only; no likelihood or parser path
  changed;
- the rendered get-started article and generated pkgdown HTML verify that the
  user-facing learning path is present.

Known limitations:

- this pass does not add new model examples;
- the learning path is compact and should be revisited after real datasets are
  added to the tutorials.

Team learning:

- Good planning reduces token and compute waste: this phase used targeted reads,
  no extra agents, and documentation-specific checks rather than a broad test
  sweep.
