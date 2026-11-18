# After-task: marginal simulation for structured q2 SD fits

Date: 2026-11-01. Lane: codex/general-sd-regression (PR 1663).

## Inconsistency

`simulate(fit, re.form = NA)` (fresh random effects, lme4 convention) refused
every native structured intercept-plus-slope (q = 2) fit except Binomial
relmat, animal and spatial with independent coefficients. The refusal came
from `drm_binomial_q2_structured_sd_by_node()`, which required the Binomial
family, a provider in relmat, animal or spatial, and no fitted correlation.

Probe on small fixtures (24 groups, 16 rows each; one SD formula per
coefficient), before the change:

| Family | Providers refused | Labelled `(1 + x \| p \| id)` |
|---|---|---|
| Gaussian | animal, relmat, phylo | refused (rho stored in `corpars`) |
| Poisson | animal, relmat, phylo (spatial refuses by the same check; not probed before the change) | not available |
| NB2 | animal, relmat, phylo | not available |
| Gamma | animal, relmat, phylo | animal refused; relmat and phylo refuse a labelled block at fit time |
| Binomial | phylo only (relmat, animal, spatial already worked) | not available |

Beta q2 also refuses, and stays refused (not in scope).

## What was done

- `R/methods.R`, `drm_binomial_q2_structured_sd_by_node()`: admits the
  Gaussian, Poisson, NB2 and Gamma families beside Binomial, and the phylo
  provider. It accepts a fitted correlation only when `corpars` holds exactly
  one entry under the provider's own key with `|rho| <= 1`, and returns that
  value as `attr(, "rho")` (0 for an unlabelled block). For phylo, latent
  nodes with no SD row (internal nodes) get scale 1, as the q1 route already
  does, because no observation reads them. The function name is kept because
  existing tests call it.
- `R/methods.R`, `drm_fresh_structured_mu_values()`: for the node-by-coefficient
  SD matrix, draws two independent `Q^-1` fields and mixes them as
  `f1 <- rho f0 + sqrt(1 - rho^2) f1`, so (f0, f1) ~ N(0, R kron K), then scales
  each coefficient's field by its per-node SD. This matches the stated model in
  `test-gaussian-structured-q2-sd.R` and `test-gamma-animal-q2-correlated-sd.R`.
- Roxygen and `man/simulate.drmTMB.Rd` describe the new routes; the design
  note in `docs/design/03-likelihoods.md` no longer says marginal simulation is
  refused for correlated q2 fits.
- New `tests/testthat/test-q2-sd-marginal-simulate.R` (170 expectations):
  1. Gaussian animal (labelled, fitted rho about 0.7), relmat and phylo
     (unlabelled): 200 simulations against the exact marginal covariance.
     Whitened residuals have mean, variance and off-diagonal statistics within
     fixed bounds, and the per-group OLS coefficient covariance matches
     `D R D kron K + sigma^2 (X'X)^-1` (Frobenius ratio in a fixed window,
     coefficient means within 4 SE). Pooled SD, a unit-diagonal kernel and
     dropped rho each push the ratio above the bound.
  2. Poisson relmat and spatial, NB2 phylo and animal, Gamma animal (labelled),
     relmat and phylo, Binomial phylo: the sampled covariance of the node fields
     (200 draws) against `D_k R kron K D_k` built from the SD coefficients and
     the supplied kernel (never the package's precision), the pooled
     unit-scale variance, and the pooled cross-field covariance against the
     fitted rho. The public `simulate()` path is checked for shape, finite
     values, seed reproducibility and difference from the conditional draw. One
     test checks the row mapping of the fresh fields.
  3. `re.form = NULL` equals `rnorm(fitted, sigma)` (Gaussian) and
     `rpois(fitted)` (Poisson) under the same seed: unchanged.
  4. Refusals pinned: a fitted correlation that is not the structured one, an
     out-of-range rho, and a non-admitted family (`model_type = "beta"` on a
     copy of a fit) all return NULL from the helper, and `simulate()` raises
     "does not yet support". The real Beta q2 fits stay pinned in
     `test-beta-animal-q2-sd-regression.R`, `test-beta-phylo-q2-sd-regression.R`,
     `test-beta-relmat-q2-sd-regression.R` and
     `test-beta-spatial-q2-sd-regression.R`.
- Stale pins swapped to a still-refused route (a fit copy whose `corpars` hold an
  ordinary correlation), same error pattern, no assertion deleted or loosened:
  `test-gamma-phylo-q2-sd-regression.R`, `test-gamma-spatial-q2-sd-regression.R`,
  `test-gamma-relmat-q2-sd-regression.R`, `test-binomial-phylo-spatial-q2-sd.R`
  (the phylo branch also now checks that marginal simulation returns a data
  frame).

## Results

One R process at a time, `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1`, native TMB
only. Passed expectations (0 failures, 0 errors, 0 skips in every file):

- New `test-q2-sd-marginal-simulate.R`: 170.
- Edited pin files: `test-gamma-phylo-q2-sd-regression.R` 48,
  `test-gamma-spatial-q2-sd-regression.R` 47,
  `test-gamma-relmat-q2-sd-regression.R` 42,
  `test-binomial-phylo-spatial-q2-sd.R` 128.
- Neighbours: `test-structured-re-q2-rejections.R` 90,
  `test-simulate-re-form.R` 22, `test-simulate-re-form-phylo-interaction.R` 13,
  `test-nbinom2-structured-slope-marginal-simulate.R` 42, the four Beta q2 files
  58, 46, 64 and 47, `test-binomial-relmat-q2-sd.R` 98,
  `test-binomial-animal-q2-sd.R` 48, `test-gaussian-structured-q2-sd.R` 64,
  `test-count-structured-q2-more-providers-sd.R` 165,
  `test-poisson-structured-q2-sd-regression.R` 45,
  `test-nbinom2-structured-q2-sd-regression.R` 75.

## Findings while fixing

- Bounds were fixed from the Wishart expectation, then the Frobenius windows
  were set after a pilot run on the same seeds (stated in the test header). The
  window for the latent check is wide at the low end (0.35) because the ratio
  is right-skewed for strongly correlated tips.
- A symmetric `x` grid hides the intercept-slope correlation in the variance
  (it cancels over the grid), so the fixtures use an uncentred `x`. Earlier
  drafts with a centred grid could not detect a dropped rho.
- Small fixtures often collapse a coefficient SD towards zero; the fixtures use
  24 groups of 16 rows (40 for Binomial), and the test asserts the SDs stay
  above 0.02.
- `docs/design/03-likelihoods.md` still says NB2 slope-SD marginal simulation is
  refused near the NB2 batch 5 paragraph; `test-nbinom2-structured-slope-marginal-simulate.R`
  shows that route is admitted. Not changed here.

## Not covered

Native TMB only. No Julia route, no Beta, no `corpair` regression, no
multi-trait or bivariate q2, and no q > 2 structured block. Spatial is covered
for Poisson only in the latent check, Binomial spatial by the existing test.
These are moment checks of the sampler against the stated covariance with 200
draws; they make no recovery, calibration or parity claim. The repository
`devtools::document()` was not run (the Rd edit was made by hand to match the
roxygen text), and the full test suite and `R CMD check` were not run.
