# After-task report: Gaussian structured intercept-plus-slope with coefficient SDs

Date: 2026-11-01. Lane: predictor-dependent random-effect SD regression (branch codex/general-sd-regression, base b6629f435). Worked in a private copy, not the lane worktree. Nothing committed or pushed.

## What was admitted

Native Gaussian `mu` with one structured intercept-plus-slope block and one SD formula per coefficient:

```r
bf(
  y ~ x + animal(1 + x | id, A = A),
  sigma ~ 1,
  sd(id, level = "animal", coef = "(Intercept)") ~ w,
  sd(id, level = "animal", coef = "x") ~ v
)
```

Providers: `animal()`, `relmat()` and `phylo()`. Two forms each:

- Unlabelled `1 + x | id`: the two unit-scale fields are independent (rho is 0).
- Labelled `1 + x | p | id`: the fields have prior N(0, R kron K) with R = [[1, rho], [rho, 1]] and rho = 0.999999 tanh(eta_cor_phylo), the same pattern as the Gamma, Poisson and NB2 correlated routes.

A labelled block still requires SD formulas for both coefficients. Without them the old refusal stands.

## What changed

- `src/drmTMB.cpp`, Gaussian structured block: the per-row SD multiplier now honours `phylo_mu_sd_row_coef` when `has_sd_phylo_coef_model` is 1 (as the Gamma block already did). A new first branch applies the correlated R kron K prior when `has_phylo_mu_q2_covariance` is 1. The existing cross-parameter branch is unchanged and the two cannot both fire (this branch is mu and mu only).
- `R/drmTMB.R`:
  - the Gaussian builder permits multiple coefficients in `parse_sd_phylo_entries()` for the three providers, checks that exactly one SD formula selects each coefficient, renames duplicate SD labels by coefficient, and reuses the slope-identifiability check with a Gaussian label;
  - `combine_univariate_structured_terms()` takes `allow_labelled_mu_q2_sd` so a labelled mu block is accepted when structured SD formulas are present;
  - `has_phylo_mu_q2_covariance`, `phylo_mu_sd_row_coef` data and `split_tmb_corpars()` now include Gaussian, so `fit$corpars$<provider>` reports the correlation.
- `tests/testthat/test-gaussian-structured-q2-sd.R`: new file, 64 expectations.
- `tests/testthat/test-phylo-gaussian.R`: one stale refusal pin moved. `phylo(1 + x | species)` with a coefficient-less `sd_phylo(species) ~ x` used to hit "require one structured coefficient". It now hits "must select a coefficient", so the pin was moved to the still-refused spatial intercept-plus-slope route. No assertion was removed or loosened.

## Evidence

The oracle is the exact Gaussian marginal. y ~ N(X beta, sigma^2 I + sum over a, b of R_ab l_a l_b' (elementwise) K_obs), with loadings l_0 = sd0 and l_1 = x sd1, and K indexed by level name. It is dense R code and shares nothing with the template. Tolerances were fixed before the first run and are stated in the test header.

- At the fitted parameters, logLik(fit) equals the dense marginal log-likelihood to 1e-6 relative, for the unlabelled and labelled fits of animal, relmat and phylo.
- An independent L-BFGS-B optimiser on the dense oracle, started from neutral values, reaches the same maximum to 1e-5 relative, for the same six fits.
- Fixtures for animal and relmat: K has a non-unit diagonal (0.7 to 1.8), K rows are in a shuffled order relative to the factor levels, and data rows are shuffled.
- Emulated bugs each move the oracle by more than 1e-3: unit-diagonal conversion of K, positional (not by name) K, swapped SD formulas, a shared SD for both fields, a missing x loading, dropped rho, and flipped rho sign.
- Constant-SD equivalence: both coefficient SDs ~ 1 gives the same logLik as the existing independent structured fit without SD formulas (within 1e-5 absolute). The labelled constant-SD fit is not below it, and matches the oracle.
- Refusals with message patterns: labelled block without SD; one SD formula only (labelled and unlabelled); duplicate coefficient; missing coefficient selector; unknown coefficient; SD aimed at sigma for a mu block; level mismatch; three-coefficient block (parser); spatial q2.

## Commands and counts

One R process at a time, `pkgload::load_all` then `testthat::test_file`.

- New file: 64 passed, 0 failed, 0 errors, 0 skipped.
- Moved pin file `test-phylo-gaussian.R`: 385 passed, 0 failed (it had 1 error before the pin moved).
- Family and structured neighbours, all 0 failed and 0 errors: gaussian-animal-sd-regression 27, gaussian-batch5-sd-regression 103 (2 skipped), gaussian-independent-pair-sd 10, gaussian-mu-sigma-joint-sd 29, gaussian-phylo-interaction-slope-sd 52, gaussian-sd-slope-regression 13, gaussian-sigma-endpoint-mixes-sd 30, gaussian-sigma-sd-regression 15, gaussian-sigma-sd-slope-regression 11, gaussian-sigma-structured-sd 92, gaussian-structured-direct-sd-providers 60, gaussian-correlated-q2-sd 17, animal-relmat-gaussian 479, check-phylo-sd-shared-shift 24, corpairs 116, coefficient-labels 122 (5 skipped), structured-effects 337, structured-re-q12-all-four 16, structured-re-q2-rejections 90, structured-sd-asymmetric-alignment 52, structured-sd-targets 16, structured-sd-nonunit-k-and-missing 53, structured-sd-q-ainv-quickwins 92, sd-level-grammar 40, gamma-animal-q2-correlated-sd 46, gamma-phylo-q2-sd-regression 48, poisson-correlated-q2-sd 13, nbinom2-correlated-q2-sd 12.

## What this does not cover

- Spatial intercept-plus-slope stays refused (kept out on purpose: no test for its range handling).
- phylo() works on the shared-ancestry correlation and needs an ultrametric tree, so the non-unit-diagonal check applies to animal and relmat only. The phylo test pins that the raw covariance is a different model.
- Q, Ainv and pedigree inputs, `sigma` regression beside the block, missing data, REML, aggregation and sparse fixed effects were not exercised with the new route.
- No recovery, coverage or calibration claim. The checks are of the likelihood surface at and around the fitted maximum.
- Marginal `simulate()` for the labelled block gives the existing designed refusal (use `re.form = NULL`). Not changed.
- Julia engine: not exercised, no live Julia in this run.
- Ledger: `required-rows.tsv` has `animal_correlated_block` but no `phylo_`, `relmat_` or `spatial_correlated_block` mechanism rows, and no row for Gaussian unlabelled `1 + x` structured q2. No receipt was attached here.
- Docs: vignettes and the implementation map were not edited in this slice.
