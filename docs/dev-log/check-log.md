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
