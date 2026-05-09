# After Phase: Phase 5 Phylogenetic Structured-Effect Closure

## Goal

Close the first structured-effect phase around the implemented phylogenetic
location model:

```r
drmTMB(
  drm_formula(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ z
  ),
  family = gaussian(),
  data = dat
)
```

The closure goal was not to add spatial fields or phylogenetic slopes. It was to
make sure the implemented intercept-only phylogenetic `mu` path, its equations,
tests, user docs, roadmap, known limitations, and generated site all describe
the same package.

## Implemented

- Marked Phase 5 in `ROADMAP.md` as implemented and closure-audited for the
  first univariate Gaussian phylogenetic location path.
- Added model-level rejection tests for planned spatial syntax with
  `coords = coords`, planned spatial syntax with `mesh = mesh`, spatial terms in
  `sigma`, and bivariate structured-effect syntax.
- Softened `gr()` wording in the phylogenetic/spatial speed design note so it is
  clearly a reserved low-level marker, not a fitted model path.
- Replaced a user-facing `rho12 = 0.99999999 * tanh(...)` equation in the
  phylogenetic/spatial speed note with the clean statistical transform
  `rho12 = tanh(...)`, while documenting the tiny C++ boundary guard separately.
- Tightened bivariate meta-analysis wording across active docs: fitted `rho12`
  is the residual covariance component after known sampling covariance has been
  included, not a study-level correlation unless a study-level random effect is
  fitted.
- Regenerated roxygen documentation for `meta_vcov_bivariate()`.

## Mathematical Contract

The fitted phylogenetic location model is:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + a_species[i]
log(sigma_i) = X_sigma[i, ] beta_sigma
a ~ MVN(0, sigma_phylo^2 A)
```

Here `A` is the tree-derived phylogenetic correlation matrix induced by an
ultrametric branch-length tree. The implementation evaluates this model through
the sparse augmented A-inverse path, not by asking the user to pass a dense
phylogenetic covariance matrix.

For future bivariate location-coscale extensions, the residual correlation
contract remains:

```text
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = tanh(eta_rho12_i)
```

The C++ implementation may use a tiny boundary guard around `tanh()` for
positive definiteness during optimization, but user-facing model equations
should show the clean statistical transform and explain the guard separately
when needed.

## Files Changed

- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `R/meta-vcov.R`
- `man/meta_vcov_bivariate.Rd`
- `tests/testthat/test-gaussian-location-scale.R`
- `vignettes/drmTMB.Rmd`
- `vignettes/testing-likelihoods.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-phase/2026-05-09-phase-5-phylogenetic-structured-effects-closure.md`

## Checks Run

- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-gaussian-location-scale.R')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-package-skeleton.R')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/drmTMB.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/testing-likelihoods.Rmd', output_dir = tempdir(), quiet = TRUE); rmarkdown::render('vignettes/phylogenetic-spatial.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n 'residual or between-study|unknown residual or between-study|between-study coupling|between-study correlation' README.md ROADMAP.md NEWS.md docs/design vignettes R man tests --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**'`
- `rg -n 'rho12_i = 0\\.99999999 \\* tanh|0\\.99999999 \\* tanh\\(eta_rho12_i\\)' vignettes/drmTMB.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/testing-likelihoods.Rmd docs/design/03-likelihoods.md docs/design/09-phylogenetic-and-spatial-speed.md`
- `rg -n 'phylo\\(1 \\+|phylogenetic terms in `sigma`|spatial\\(1 \\||structured-effect syntax is planned|bivariate structured' README.md ROADMAP.md NEWS.md docs/design vignettes R tests --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**'`

## Results

- `test-gaussian-location-scale.R`: 69 passed, 0 failed, 1 skipped on CRAN.
- `test-package-skeleton.R`: 40 passed, 0 failed.
- Direct renders for the main, testing-likelihoods, and phylogenetic-spatial
  vignettes passed after loading the local package.
- `devtools::test()`: 1264 passed, 0 failed.
- `pkgdown::build_site()` passed after rerunning with normal cache/network access
  because the sandbox could not write to the user-level sass cache or resolve
  CRAN metadata.
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::check(...)`: 0 errors, 0 warnings, 1 note. The note was local macOS
  temp-directory detritus (`xcrun_db`), not a package failure.
- `git diff --check`: clean.
- Active-doc stale scan found no remaining "residual or between-study" wording.
- Targeted equation scan found no guarded `rho12` transform in the main,
  testing-likelihoods, phylogenetic-spatial, likelihood, or phylogenetic/spatial
  speed teaching pages.

## Tests Of The Tests

The new rejection tests are intentionally small but close an important user
safety gap. They prove that planned spatial `coords`, planned spatial `mesh`,
spatial-in-`sigma`, bivariate spatial syntax, and bivariate phylogenetic syntax
do not silently fall through into a model matrix or a misleading fixed-effect
fit. Those tests complement the parser tests, which already verify that the
planned markers are captured as structured-effect metadata.

The existing Phase 5 evidence remains stronger than a single parser check:
phylogenetic utility tests compare the sparse augmented precision to dense
Brownian covariance; hidden TMB parity tests compare the C++ prior branch to
R-side algebra; fitted-model tests compare the sparse fitted objective to dense
marginal likelihoods; and the CRAN-safe simulation test checks recovery on a
small ultrametric tree.

## Consistency Audit

- `ROADMAP.md` now says Phase 5 is closure-audited for the first implemented
  phylogenetic location path.
- `NEWS.md`, `README.md`, `vignettes/phylogenetic-spatial.Rmd`,
  `docs/dev-log/known-limitations.md`, and the formula grammar still mark
  spatial fields, phylogenetic slopes, phylogenetic `sigma`, bivariate
  structured effects, and structured `rho12` effects as planned.
- `docs/design/09-phylogenetic-and-spatial-speed.md` no longer implies `gr()` is
  fitted; it is reserved for a later low-level known-covariance group-effect
  path.
- Active bivariate meta-analysis wording no longer labels fitted `rho12` as
  study-level unless a study-level random effect exists.
- Historical after-task notes still contain older status wording by design and
  were not rewritten.

## What Did Not Go Smoothly

The first pkgdown build failed in the sandbox because pkgdown tried to write to
the user-level sass cache and query CRAN metadata. Rerunning with normal
cache/network access fixed the build.

Two stale-wording scans were initially written with shell backticks inside double
quotes, so `zsh` tried to execute fragments such as `gr()` and `sigma`. The
useful scans were rerun with single quotes and exact grep patterns.

## Team Learning

- Chandrasekhar's systems audit found the right closure gaps: a missing
  after-phase report, thin spatial rejection tests, premature `gr()` wording, and
  slightly overbroad "simulation recovery tests" language.
- Rose's process rule worked: closing a phase is partly a consistency task, not
  just another implementation sprint.
- Noether's equation-first rule should remain active for every `rho12` document:
  show the statistical transform first, then explain implementation guards.
- Fisher's caution matters for meta-analysis wording: known sampling covariance,
  residual heterogeneity covariance, and study-level random effects are related
  but not interchangeable.

## Known Limitations

- The fitted structured-effect path remains limited to
  `phylo(1 | species, tree = tree)` in univariate Gaussian `mu`.
- Phylogenetic slopes, phylogenetic `sigma`, bivariate phylogenetic covariance
  blocks, spatial SPDE/GMRF fields, and structured effects in `rho12` remain
  planned.
- The simulation recovery test is deliberately CRAN-safe and small. Larger
  optional simulations are still needed for many species, near-zero
  phylogenetic SD, high residual noise, and combined phylogenetic plus
  non-phylogenetic species effects.
- No comparator against a dedicated phylogenetic mixed-model package has been
  added yet.

## Next Actions

1. Add optional large-tree benchmark scripts for 100k, 500k, 1M, and eventually
   multi-million-row phylogenetic location models.
2. Add a design slice for the first spatial SPDE/GMRF intercept-only `mu` path,
   including the mesh/coords data contract and a dense or low-dimensional
   comparator.
3. Add a design slice for phylogenetic random slopes only after the intercept-only
   path has larger simulation evidence.
