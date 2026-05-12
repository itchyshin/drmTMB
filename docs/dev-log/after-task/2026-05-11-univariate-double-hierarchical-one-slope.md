# After Task: Univariate Double-Hierarchical One-Slope Block

## Goal

Finish the first labelled univariate double-hierarchical Gaussian block:
matching labelled `mu` and `sigma` random intercepts or one-slope blocks should
fit one shared group-level covariance block, while bivariate residual-scale and
structured covariance remain planned.

## Implemented

- Added matching labelled `mu`/`sigma` one-slope support for syntax such as
  `bf(y ~ x + (1 + x | p | id), sigma ~ x + (1 + x | p | id))`.
- Kept the existing intercept-only syntax
  `bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id))`.
- Built one shared labelled covariance block across `mu` intercept, `mu` slope,
  `sigma` intercept, and `sigma` slope when the labelled terms match.
- Parameterized the full block through a positive-definite partial-correlation
  Cholesky factor instead of independent pairwise `tanh()` correlations.
- Reported the derived pairwise correlations in `corpars$mu_sigma` and
  `corpairs()`, including mean-slope, mean-scale, slope-scale, and scale-slope
  rows.
- Marked full-block `mu_sigma` correlations in `profile_targets()` as derived
  `cor_cholesky` summaries rather than direct profile-likelihood targets.
- Updated README, NEWS, roadmap, design notes, known limitations, vignettes,
  and generated reference docs to describe the implemented boundary.

## Mathematical Contract

For group `g`, the one-slope labelled block is:

```text
mu_i = X_mu[i, ] beta_mu + b_0g + x_i b_1g
log(sigma_i) = X_sigma[i, ] beta_sigma + a_0g + x_i a_1g

[b_0g, b_1g, a_0g, a_1g]' =
  diag(sd_mu0, sd_mu1, sd_sigma0, sd_sigma1) L_corr z_g
z_g ~ Normal(0, I)
```

`L_corr` is constructed from partial-correlation parameters so the implied
correlation matrix is positive definite. The pairwise correlations reported to
users are functions of that matrix. They are group-level random-effect
correlations, not residual bivariate `rho12`.

## Files Changed

- `R/drmTMB.R`, `R/methods.R`, `R/profile.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-gaussian-random-intercepts.R`,
  `tests/testthat/test-corpairs.R`, and
  `tests/testthat/test-profile-targets.R`
- `NEWS.md`, `README.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
  `docs/design/04-random-effects.md`,
  `docs/design/12-profile-likelihood-cis.md`,
  `docs/design/13-gaussian-location-scale-math.md`,
  `docs/design/17-correlated-random-effect-blocks.md`,
  `docs/design/20-coscale-correlation-pairs.md`, and
  `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/known-limitations.md` and `docs/dev-log/check-log.md`
- `vignettes/drmTMB.Rmd`, `vignettes/formula-grammar.Rmd`,
  `vignettes/location-scale.Rmd`, `vignettes/source-map.Rmd`, and
  `vignettes/which-scale.Rmd`
- generated `man/drmTMB.Rd` and `man/corpairs.Rd`

## Checks Run

- `air format R/drmTMB.R R/methods.R R/profile.R src/drmTMB.cpp tests/testthat/test-gaussian-random-intercepts.R NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/04-random-effects.md docs/design/12-profile-likelihood-cis.md docs/design/13-gaussian-location-scale-math.md docs/design/17-correlated-random-effect-blocks.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/drmTMB.Rmd vignettes/formula-grammar.Rmd vignettes/location-scale.Rmd vignettes/which-scale.Rmd`:
  passed.
- `air format docs/design/04-random-effects.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-11-univariate-double-hierarchical-one-slope.md vignettes/drmTMB.Rmd vignettes/source-map.Rmd vignettes/which-scale.Rmd`:
  passed after the final stale-wording cleanup.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drmTMB.Rd` and `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|corpairs|profile-targets')"`:
  passed with 545 expectations.
- `Rscript -e "devtools::test()"`: passed with 1926 expectations.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `rg -n 'labelled residual-scale random slopes remain planned|Slope-level cross-formula covariance remains planned|matching labelled random intercepts in `mu` and `sigma`|first fitted mean-scale covariance slice|matching labelled `mu` and `sigma` random intercepts such as' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man --glob '!docs/dev-log/after-task/**'`:
  returned no matches after the final prose pass.
- `rg -n 'rho ~|meta_gaussian|tau ~|meta_known_V\([^V]|planned.*implemented|implemented.*planned' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests man _pkgdown.yml --glob '!docs/dev-log/after-task/**'`:
  found only intentional guardrails and planned-feature boundaries.

## Tests Of The Tests

The new recovery test simulates a labelled Gaussian `mu`/`sigma` one-slope
block, fits the matching model, and checks convergence, SD recovery, positive
fitted `sigma`, expected correlation signs, `corpars$mu_sigma` labels,
`corpairs()` classes, and derived `profile_targets()` metadata. Existing
intercept-only tests continue to check direct `eta_cor_mu_sigma` profile
targets. Error-path checks cover unsupported labelled residual-scale structures
that do not have matching labelled `mu` terms.

## Consistency Audit

README, NEWS, roadmap, formula grammar, likelihood notes, random-effect notes,
profile-target notes, correlation-pair notes, known limitations, vignettes, and
generated help now agree on the current boundary: one univariate labelled
`mu`/`sigma` intercept-only or one-slope block is implemented; bivariate
residual-scale random effects, bivariate random slopes, and structured
phylogenetic or spatial covariance layers remain planned.

## What Did Not Go Smoothly

The first implementation path could have left independent pairwise
correlations that were not guaranteed positive definite. The final
implementation instead builds the full block through a Cholesky factor and
reports derived correlations. A few docs still described the feature as
intercept-only after the code moved forward; Rose's stale-wording scan caught
those before closeout.

## Team Learning

- Ada kept the deliverable small enough to finish: one univariate labelled
  block, not the full bivariate covariance system.
- Boole checked that the public syntax stayed memorable and matched the
  formula grammar.
- Gauss and Noether pushed the covariance contract toward a positive-definite
  Cholesky block with equations, R syntax, and TMB code aligned.
- Curie tied the change to recovery, extractor, and profile-target tests.
- Pat and Darwin kept the user question visible: do higher-mean or steeper
  individuals also show different residual variability?
- Emmy kept reporting inside existing `sdpars`, `corpars`, `corpairs()`, and
  `profile_targets()` surfaces.
- Grace verified tests, roxygen, pkgdown, and package check.
- Rose found stale status wording after the implementation moved.

## Known Limitations

- Only one shared labelled univariate `mu`/`sigma` block is supported.
- The full block currently supports one numeric slope per formula.
- Full-block pairwise correlations are derived summaries, not direct
  profile-likelihood targets.
- Bivariate `sigma1`/`sigma2` random effects, bivariate random slopes,
  phylogenetic residual-scale covariance, and spatial structured covariance
  remain planned.

## Next Actions

1. Add identifiability diagnostics for weak full-block correlations and near
   zero random-effect SDs.
2. Extend the bivariate covariance design separately, starting from labelled
   `mu1`/`mu2` slopes before adding residual-scale random effects.
3. Keep `corpairs()` as the common reporting surface for residual `rho12`,
   group-level covariance, and future structured covariance layers.
