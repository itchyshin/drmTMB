# After Task: Fitted Phylogenetic Gaussian Location Model

## Goal

Wire the tested phylogenetic sparse-precision scaffold into the ordinary
Gaussian likelihood for one user-facing fitted path:

```r
drmTMB(
  bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = gaussian(),
  data = dat
)
```

## Implemented

- Added extraction of an intercept-only `phylo()` marker from the univariate
  Gaussian `mu` formula.
- Kept `phylo()` out of the fixed-effect model matrix and retained the species
  grouping variable for missing-row filtering.
- Evaluated the named tree object from the model-calling environment.
- Built the augmented sparse Brownian precision with
  `drm_phylo_augmented_precision()`.
- Passed `has_phylo_mu`, observation node indices, `Q_phylo`, and
  `log_det_Q_phylo` into the TMB data list.
- Added `u_phylo` as a Laplace-integrated random vector and `log_sd_phylo` as
  the fitted phylogenetic SD parameter.
- Added the phylogenetic latent effect to `mu_i` in the Gaussian likelihood.
- Exposed the phylogenetic SD in `fit$sdpars$mu` and latent node effects in
  `fit$random_effects$phylo_mu`.
- Updated roxygen, NEWS, README, roadmap, known limitations, formula grammar,
  and the phylogenetic/spatial article.

## Mathematical Contract

For observation `i` belonging to species `s[i]`:

```text
y_i | z, beta_mu, beta_sigma ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + z_tip[s[i]]
log(sigma_i) = X_sigma[i, ] beta_sigma
```

The augmented phylogenetic latent vector includes tips and internal nodes, with
the root fixed at zero:

```text
z_aug ~ MVN(0, sigma_phylo^2 A_aug)
Q_A = A_aug^{-1}
sigma_phylo = exp(log_sd_phylo)
```

The TMB prior contribution is:

```text
nll_phylo =
  0.5 * [
    n log(2 pi)
    + 2 n log_sd_phylo
    - logdet(Q_A)
    + exp(-2 log_sd_phylo) z_aug' Q_A z_aug
  ]
```

Because `z_aug` is on the response scale, the predictor adds `z_tip[s[i]]`
directly. It should not multiply by `sigma_phylo` again.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `R/formula-markers.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/test-phylo-utils.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `README.md`
- `ROADMAP.md`
- `NEWS.md`
- `man/drmTMB.Rd`
- `man/phylo.Rd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`
- `docs/design/01-formula-grammar.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phylo')"`: 57 passed.
- `Rscript -e "devtools::document()"`: regenerated `drmTMB.Rd` and
  `phylo.Rd`.
- `git diff --check`: passed.
- `command -v air`: no local `air` executable found.
- `Rscript -e "devtools::test()"`: 477 passed.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`: no problems
  found; site built successfully.
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The new simulation test builds a deterministic ultrametric tree and simulates
  data from the dense Brownian tip covariance implied by that tree.
- The fitted model uses the sparse augmented precision, so the simulation and
  fit use related but independent representations.
- A conditional prediction test checks that `predict(fit, dpar = "mu")` equals
  the fixed-effect predictor plus the fitted tip effect selected by species.
- Missingness tests verify that missing `species` and missing responses are
  filtered before tree/species alignment.
- Rejection tests verify that phylogenetic slopes and phylogenetic `sigma`
  terms still fail clearly.
- Earlier tests still compare the sparse precision to the dense comparator and
  the TMB prior branch to the pure-R algebra helper.

## Consistency Audit

- `NEWS.md` now says the first fitted phylogenetic path is implemented.
- `README.md` and `ROADMAP.md` describe `phylo(1 | species, tree = tree)` as
  implemented for univariate Gaussian `mu`.
- `docs/dev-log/known-limitations.md` no longer says public `phylo()` fitting
  is unavailable.
- `vignettes/formula-grammar.Rmd` and `vignettes/phylogenetic-spatial.Rmd`
  distinguish implemented intercept-only phylogenetic `mu` terms from planned
  slopes, scale effects, bivariate structured effects, and spatial fields.
- `man/phylo.Rd` says `phylo()` is now a fitted marker for the first
  intercept-only path, not only a placeholder.
- Generated pkgdown pages contain the updated `phylo()` reference and current
  project status.
- Stale-wording scans found only intentional historical dev-log entries,
  guardrails against `meta_gaussian()` and `tau ~`, and planned-feature wording
  for still-unsupported slopes, scale terms, bivariate structure, and spatial
  effects.

## What Did Not Go Smoothly

The first fixed-effect recovery tolerance was too tight for a 16-tip CRAN-safe
simulation. The model was fitting and converging, but a small-tree
phylogenetic simulation does not justify a narrow tolerance on every fixed
effect. The test now checks recovery without turning Monte Carlo noise into a
false failure.

The stale-wording scan was also run once with shell backticks interpreted by
`zsh`; that noisy result was discarded and rerun with proper quoting.

## Team Learning

- Noether's equation-first rule prevented a subtle double-scaling mistake: the
  latent effect is already response-scale when the prior includes
  `sigma_phylo`.
- Gauss's earlier hidden TMB parity branch made this fitted path much less
  risky because the C++ prior constant was already checked.
- Curie's simulation test should remain small for CRAN, but larger long-run
  checks should be added later for many species, near-zero phylogenetic SD,
  large residual noise, and simultaneous phylogenetic plus non-phylogenetic
  species effects.
- Rose's after-task audit caught the roadmap wording after the code and main
  docs were already updated.

## Known Limitations

- Only `phylo(1 | species, tree = tree)` in univariate Gaussian `mu` is fitted.
- Phylogenetic slopes, phylogenetic `sigma`, bivariate phylogenetic covariance
  blocks, spatial effects, and structured effects in `rho12` remain planned.
- No large-tree benchmark has been added yet.
- No comparator against a dedicated phylogenetic mixed-model package has been
  added yet.
- New-data prediction currently returns fixed-effect predictions only; it does
  not attach phylogenetic effects to new species rows.

## Next Actions

1. Add comparator smoke tests against a known phylogenetic GLS or mixed-model
   implementation for the intercept-only Gaussian location case.
2. Add a long, optional simulation script for larger phylogenies and boundary
   cases.
3. Add an identifiability diagnostic for species replication before combining
   phylogenetic and non-phylogenetic species effects.
4. Start the spatial SPDE design slice or the phylogenetic random-slope design
   slice only after the fitted intercept-only path passes CI.
