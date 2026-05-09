# After Phase: Phase 3 Bivariate Gaussian Coscale Closure

## Goal

Close the implemented fixed-effect bivariate Gaussian location-coscale phase
well enough that users, developers, and later agents can see what is fitted now,
what is deliberately planned, and how the residual correlation `rho12` should be
interpreted.

## Implemented

- Marked Phase 3 in `ROADMAP.md` as implemented and closure-audited.
- Added the closure evidence to the roadmap: `rho12()`, `corpairs()`,
  `fitted()`, `sigma()`, `simulate()`, whitened Pearson residuals,
  coefficient-level `vcov()` names, complete-row bivariate known sampling
  covariance, row likelihood weights, composed Gaussian family syntax, and clear
  unsupported-feature guards.
- Added a `corpairs()` regression test for the `mvbind(y1, y2) ~ x` bivariate
  shorthand, checking that residual correlation-pair output keeps the response
  labels `y1` and `y2`.
- Added an at-a-glance family table to the response-family tutorial so users can
  choose among implemented continuous, proportion, count, zero-inflated,
  truncated, hurdle, and bivariate Gaussian paths from the measurement process.
- Updated README wording from "fixed-effect seed" to "implemented fixed-effect"
  for the bivariate location-coscale model.
- Recorded the documentation updates in `NEWS.md`.

## Mathematical Contract

The implemented Phase 3 model is

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
mu1_i = X_mu1[i, ] beta_mu1
mu2_i = X_mu2[i, ] beta_mu2
log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = tanh(eta_rho12_i)
Omega_i[1, 1] = sigma1_i^2
Omega_i[2, 2] = sigma2_i^2
Omega_i[1, 2] = Omega_i[2, 1] = rho12_i * sigma1_i * sigma2_i
```

The C++ implementation uses a tiny guard,
`rho12_i = 0.99999999 * tanh(eta_rho12_i)`, to keep covariance matrices
strictly positive definite near the correlation boundaries. Tutorials show the
clean statistical transform and explain the guard separately.

`rho12` is residual response-response correlation. It is not a group-level,
phylogenetic, spatial, or sampling-covariance correlation. Those future
correlation pairs belong in `corpairs()` with separate levels and labels.

## Files Changed

- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `tests/testthat/test-corpairs.R`
- `vignettes/distribution-families.Rmd`
- `docs/dev-log/after-phase/2026-05-09-phase-3-bivariate-coscale-closure.md`

## Checks Run

- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-corpairs.R')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); testthat::test_file('tests/testthat/test-biv-gaussian.R')"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/distribution-families.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n "At a glance|Start from the measurement process|bivariate Gaussian coscale phase|closure-audited|corpairs keeps response labels|mvbind bivariate shorthand" vignettes/distribution-families.Rmd pkgdown-site/articles/distribution-families.html ROADMAP.md NEWS.md tests/testthat/test-corpairs.R`
- `rg -n "fixed-effect seed|Phase 3.*planned|Random effects remain future work|Bivariate random-effect syntax is planned|rho ~|meta_gaussian\\(|tau ~" README.md ROADMAP.md NEWS.md docs/design vignettes R tests --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/after-phase/**'`

## Results

- `test-corpairs.R`: 37 passed, 0 failed.
- `test-biv-gaussian.R`: 101 passed, 0 failed.
- `devtools::test()`: 1260 passed, 0 failed.
- Direct renders for the distribution-family and bivariate-coscale tutorials:
  passed after loading the local package.
- `pkgdown::build_site()`: passed after rerunning with normal cache/network
  access.
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::check(...)`: 0 errors, 0 warnings, 1 note. The note was local
  macOS temp-directory detritus (`xcrun_db`), not a package failure.
- `git diff --check`: clean.
- Stale wording scan: no old "fixed-effect seed" wording remains. Remaining
  matches are intentional guardrails: bivariate random effects are still planned
  and rejected, and `meta_gaussian()` / `tau ~` appear only in meta-analysis
  guardrail prose.

## Tests Of The Tests

The new `corpairs()` test exercises an adjacent Phase 3 surface that was not
directly covered before: users can fit the same bivariate location formula with
`mvbind(y1, y2) ~ x`, then `corpairs()` still reports `from_response = "y1"` and
`to_response = "y2"`. This checks the extractor path, not only the likelihood.

The existing bivariate tests already cover constant `rho12`,
predictor-dependent `rho12`, near-zero, negative, high positive, and high
negative correlations, complete-row known sampling covariance, residual
correlation distinct from known sampling correlation, complete-row likelihood
weights, missing-row filtering, `mvbind()` expansion, composed Gaussian family
syntax, and unsupported bivariate random-effect syntax.

## Consistency Audit

- `ROADMAP.md` now states that Phase 3 is implemented and closure-audited.
- `README.md`, the bivariate tutorial, the formula grammar, likelihood design,
  correlation-pair design, known limitations, tests, and NEWS all keep `rho12`
  as residual bivariate correlation.
- The response-family tutorial now gives users one quick table that agrees with
  the implemented family status in the roadmap and NEWS.
- The generated pkgdown page contains the new response-family table.

## What Did Not Go Smoothly

Direct `testthat::test_file()` and direct vignette rendering initially failed
because the local package had not been loaded into that standalone R process.
Rerunning with `devtools::load_all(quiet = TRUE)` fixed the local-development
context.

The first `pkgdown::build_site()` attempt failed in the sandbox because pkgdown
tried to write to the user-level sass cache and query CRAN metadata. Rerunning
with normal cache/network access fixed the build.

## Team Learning

- Ada should close phases by auditing the public surface, not by adding one more
  feature.
- Rose's stale-wording scan caught that "fixed-effect seed" had become too weak
  after Phase 3 matured.
- Pat's user-first lens motivated the at-a-glance response-family table: users
  should be able to choose a family before reading every equation.
- Noether's role remains essential: every `rho12` equation must say whether it
  is the clean teaching transform or the guarded implementation transform.

## Known Limitations

- Bivariate random effects, bivariate group-level correlation pairs,
  phylogenetic/spatial bivariate correlations, and mixed-response bivariate
  families remain planned.
- Profile-likelihood confidence intervals for `rho12` are designed but not
  implemented.
- The response-family overview is a choice guide, not a replacement for worked
  tutorials with fitted output.

## Next Actions

1. Start Phase 4/7 hardening for the non-Gaussian family tutorial examples,
   especially count models with exposure and fitted output.
2. Add a Phase 5 structured-effect closure pass for the implemented
   `phylo(1 | species, tree = tree)` path.
3. Begin the first small profile-likelihood API prototype only after target
   naming is checked against current fitted-object names.
