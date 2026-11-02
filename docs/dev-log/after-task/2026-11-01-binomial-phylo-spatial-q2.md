# After-task report: Binomial phylo q2 and spatial q2 with coefficient SDs

Date: 2026-11-01. Lane: predictor-dependent random-effect SD regression. Engine: native TMB (no Julia route was added or exercised).

## What changed

The Binomial route now admits `phylo(1 + x | id, tree = tree)` and `spatial(1 + x | id, coords = coords)` with a logit link and unweighted 0/1 responses. Each of the two latent fields may carry its own SD formula, selected with `sd(id, level = "phylogenetic" or "spatial", coef = "(Intercept)")` and `coef = "x"`. The formula-free q2 fit (no `sd()` formulas) is also admitted for both providers, as it already was for relmat. The TMB code already supported this per-coefficient SD multiplier, so no C++ change was made.

R changes:

- `R/drmTMB.R`, `drm_build_binomial_spec`: new gates `allow_binomial_phylo_q2_base` and `allow_binomial_spatial_q2_base` (spatial requires coordinate input), folded into the existing structured q2 SD path. The canonical SD name is now built as `sd_<provider>`, and the 0/1 Bernoulli check covers the new routes.
- `R/drmTMB.R`, `validate_binomial_structured_mu_term`: two new arguments admit the intercept-plus-one-slope term for phylo and spatial.
- `R/drmTMB.R`, `make_tmb_data`: the coefficient-SD data gate and the observation-mapping check now include Binomial logit phylo and coordinate-spatial q2. Without this gate the SD formulas were silently ignored, which the first test run exposed.
- `R/methods.R`, `drm_binomial_q2_structured_sd_by_node`: spatial is recognised, and node labels fall back to the structured term when the precision object carries none. This enables marginal simulation for spatial q2.

No existing test pinned the old refusal for these routes, so no test was swapped.

## Evidence (new file `tests/testthat/test-binomial-phylo-spatial-q2-sd.R`)

- Assembly: SD row mapping to both coefficients, package precision inverted against a hand-built tree covariance and a hand-built exponential kernel, formula-free base spec, unmapped-row refusal.
- Oracle: a dense Laplace marginal likelihood written in the test, evaluated at the fitted parameters (64 groups, 30 Bernoulli rows each, 128 latent values). It agrees with the native negative log-likelihood within 1e-4, with linear predictors within 1e-4, with inner gradient below 1e-5, and with finite-difference score and Hessian checks below 1e-5.
- Emulated bugs: swapping the two SD surfaces or reversing the level alignment of either surface moves the oracle negative log-likelihood by more than 0.05 (500 times the tolerance).
- Equivalences: shuffled provider order (reversed tip labels with a re-ordered tree; shuffled coordinate rows) with reversed SD formula order reproduces the fit within 1e-4 in log-likelihood and 1e-3 in coefficients; constant SD formulas reproduce the formula-free fit within 1e-4 in log-likelihood and the base SDs within 1e-3.
- Refusals kept closed, with message patterns: one SD formula only, duplicate selector, bad selector, zero slope predictor, identical constant SD designs, SD predictor varying within a group, response outside 0/1, weights, cbind responses, probit and cloglog links, labelled covariance block, two slopes, an ordinary random intercept alongside, a second structured provider, and a missing-response include.
- Round trip: saved fit predicts identically; conditional simulation returns 0/1; spatial marginal simulation is reproducible and its per-node SDs equal the fitted SD surfaces; phylo marginal simulation stays refused ("does not yet support").

## Not covered

- Non-unit-diagonal K for these providers: drmTMB scales a tree to a correlation matrix and builds the coordinate kernel with unit diagonal (plus a 1e-6 nugget), so both oracles have a unit diagonal. Non-unit-diagonal structured q2 is exercised only by the relmat route (`test-binomial-relmat-q2-sd.R`). The trees are ultrametric because the package requires it.
- Probit and cloglog links, weights, counts of trials above one, mesh spatial q2, labelled blocks, REML, missing responses, additional random effects, and provider pairs remain refused.
- Marginal simulation for phylo q2 (latent values at internal tree nodes are not mapped to per-node SDs).
- Julia bridge for these routes, profile and bootstrap targets, and coverage or calibration of the SD coefficients. No calibration, recovery or parity claim is made; the evidence is agreement with an independent likelihood at one fixture per provider.

## Verification (Totoro, at most 4 cores)

- `test-binomial-phylo-spatial-q2-sd.R`: 127 passed, 0 failed, 0 errors, 0 skipped.
- Neighbours, all 0 failed, 0 errors: `test-binomial-relmat-q2-sd.R` 98, `test-binomial-animal-q2-sd.R` 48, `test-binomial-phylo-slope-sd.R` 17, `test-binomial-spatial-sd-regression.R` 42, `test-binomial-phylo-spatial-sd.R` 60, `test-binomial-phylo-sd-regression.R` 25, `test-binomial-relmat-slope-sd.R` 23, `test-binomial-sd-formula-design.R` 4, `test-beta-phylo-q2-sd-regression.R` 46, `test-gamma-phylo-q2-sd-regression.R` 48, `test-gamma-spatial-q2-sd-regression.R` 47 (passed counts).

## Open items

- The worktree was created at the main commit, not ea2e2aed7; it was moved to ea2e2aed7 with a detached checkout before any edit.
- Mechanism-universe rows for `phylo_`, `relmat_` and `spatial_correlated_block` (gap scout G0) were not touched.
- Documentation pages and NEWS were not updated for this admission.
