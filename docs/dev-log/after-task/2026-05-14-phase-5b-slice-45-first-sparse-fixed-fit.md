# After Task: Phase 5b Slice 45 First Sparse Fixed Fit

## Goal

Fit one sparse fixed-effect path end to end without claiming a general sparse
engine.

## Implemented

- Added `drm_control(sparse_fixed = TRUE)`.
- Implemented sparse fixed-effect storage and TMB multiplication for
  univariate Gaussian `mu` fixed effects.
- Kept the first sparse path opt-in and guarded: intercept-only `sigma`, no
  ordinary random effects, no direct-SD formulas, no phylogenetic or spatial
  structured effects, no known covariance, no bivariate models, and no
  non-Gaussian families.
- Rebuilt new-data prediction matrices as sparse when the fitted parameter was
  sparse.
- Updated `check_drm()` so sparse retained designs are reported as sparse.
- Added dense-versus-sparse fit parity tests and unsupported-model snapshots.
- Updated the sparse design note, large-data design note, large-data vignette,
  roadmap, NEWS, known limitations, and `drm_control()` documentation.

## Mathematical Contract

No statistical model changed. The fitted Gaussian location predictor remains

```text
mu_i = X_mu[i, ] beta_mu
```

Only the storage and multiplication route changes:

```text
mu = X_mu beta_mu              dense path
mu = X_mu_sparse beta_mu       sparse path
```

## Files Changed

- `R/control.R`
- `R/drmTMB.R`
- `R/methods.R`
- `R/sparse-fixed.R`
- `R/check.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-sparse-fixed-effects.R`
- `tests/testthat/_snaps/sparse-fixed-effects.md`
- `docs/design/23-large-data-memory.md`
- `docs/design/26-sparse-fixed-effect-matrices.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/large-data.Rmd`
- `ROADMAP.md`
- `NEWS.md`
- `man/drm_control.Rd`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- Manual dense/sparse Gaussian fit parity smoke: passed.
- `Rscript -e 'devtools::test(filter = "sparse-fixed-effects", reporter = "summary")'`:
  passed on rerun after accepting snapshots.
- `Rscript -e 'devtools::document()'`: passed.
- `Rscript -e 'devtools::test(filter = "sparse-fixed-effects|control|check-drm", reporter = "summary")'`:
  passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("large-data", new_process = FALSE)'`:
  passed.
- `PATH=/opt/homebrew/bin:$PATH Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::check_pkgdown()'`:
  passed.
- Stale wording scan for old sparse-planned claims in current docs and
  generated pkgdown output: no current-doc hits.
- `git diff --check`: passed.

## Tests Of The Tests

The new fit test compares a dense and sparse version of the same Gaussian
model, including coefficient estimates, log-likelihood, fitted values,
fitted-row prediction, new-data prediction, residuals, seeded simulation, and
the retained matrix class. The rejection snapshots cover the main first-slice
boundaries: ordinary random effects, non-intercept `sigma`, and non-Gaussian
families.

## Consistency Audit

The source docs now say that sparse fixed effects are implemented only for the
first univariate Gaussian `mu` path. They still mark sparse `sigma`,
random-effect, direct-SD, phylogenetic, spatial, bivariate, and non-Gaussian
paths as planned. The large-data article was rebuilt from the updated source.

## What Did Not Go Smoothly

The first draft tried to add sparse routing after the model specification was
already built. That would have left the dense construction cost in place. Gauss
flagged the correct route: build the sparse `mu` matrix inside the Gaussian
spec builder and pass a parallel sparse matrix into TMB.

## Team Learning

- Ada should keep the sparse implementation path narrow until each family has
  parity tests.
- Boole should keep `sparse_fixed` as an explicit control, not a silent
  automatic heuristic.
- Gauss should continue reviewing TMB data declarations before sparse fields
  are treated as stable.
- Noether should keep the statistical equation unchanged when only storage and
  multiplication change.
- Curie should pair every new sparse route with dense-versus-sparse fit parity
  and unsupported-model snapshots.
- Fisher should treat sparse starts as a possible convergence sensitivity until
  larger benchmark grids exist.
- Pat should see the large-data article name the exact supported scope rather
  than promise general sparse fitting.
- Grace should require targeted tests plus pkgdown article rebuilds for every
  control/API change.
- Rose should watch for stale wording that says sparse fixed effects are only
  planned without naming the implemented Gaussian `mu` exception.

## Known Limitations

- Sparse fixed effects are currently only for univariate Gaussian `mu`.
- Sparse `sigma`, random-effect, direct-SD, known-covariance, phylogenetic,
  spatial, bivariate, and non-Gaussian paths remain planned.
- Large benchmark evidence for `sparse_fixed = TRUE` has not been collected.

## Next Actions

Commit Slice 45. The next Phase 5b implementation slice should add an optional
benchmark scenario for `sparse_fixed = TRUE` before broadening the model scope.
