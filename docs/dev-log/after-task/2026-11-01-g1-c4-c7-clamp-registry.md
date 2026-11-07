# After-task report: G1 conditions C4 and C7 (clamp-field registry, structured SD draw registry)

Date: 2026-11-01. Lane: predictor-dependent random-effect SD regression. Engine: native TMB. Source: `docs/dev-log/general-sd-regression/g1-joint-contract-review-20261101.md`, conditions C4 and C7 (risk items 1 to 3 of section 4).

## What changed

### C4: one reporting contract and a complete clamp-field registry

Before: `log_sd_mu_group` reported the raw linear predictor, but `log_sd_sigma_group`, `log_sd_phylo_group` and `log_sd_phylo2_group` stored the clamped value in 18 C++ branches, so the R clamp-hit check could never see them leave the band. The R field registry listed only `log_sd_mu_group` and `log_sd_phylo_group`, and `log_sd_sigma_group` and `log_sd_phylo2_group` were absent.

After:

- `src/drmTMB.cpp`: all 18 branches (sigma 7, phylo 10, phylo2 1) now set `log_sd_*_group(g) = eta_sd` and apply `drm_softclamp_log_sd()` where `sd_*_group` is formed, the same shape the mu branches already had. The only readers of these vectors were the next line (the `sd_*_group` assignment), so the likelihood is numerically unchanged. What changes is the value in REPORT and ADREPORT of `log_sd_sigma_group`, `log_sd_phylo_group` and `log_sd_phylo2_group` when the raw predictor lies outside the band (it is now the raw value; inside the band it is identical). The comment above `drm_softclamp_log_sd` now names all four fields.
- `R/drmTMB.R`: new `drm_latent_sd_clamp_fields()` returns the four REPORT names. `drm_active_logsigma_clamp_fields()` adds `log_sd_phylo2_group` when `random_scale$phylo2$n_models > 0` and `log_sd_sigma_group` when `random_scale$sigma$n_models > 0`. The `kind` classification in `drm_logsigma_clamp_active()` uses the helper, so a hit on either new field is reported as a latent random-effect SD, not residual sigma. The start-value check (`drm_warn_if_start_saturates_logsigma_clamp`) now runs for an override of `beta_sd_sigma` as well as `beta_sd_mu`; `drm_direct_sd_logscale_values()` already computed the sigma and phylo2 raw predictors.
- `R/methods.R`: the comment in `predict_random_scale_dpar` cited stale lines (`src/drmTMB.cpp ~2482-2485`, `R/drmTMB.R:23062-23092`). It now cites function names, which do not drift, and states the contract (REPORT raw, clamp inside `sd_*_group`, `predict(type = "link")` clamped).

Side effect worth knowing: because `log_sd_phylo_group` was reported clamped, a structured fit whose phylo SD predictor ran past the upper band was silently invisible to the clamp-hit warning. It is now visible, so such a fit gains a `drmTMB_clamp_active_warning` that it did not have before. That is the intended repair of review item 1, not a new failure mode.

### C7: registry decides whether a structured SD is modelled

`drm_structured_mu_random_effect_draws()` (`R/methods.R`) previously read `object$sdpars[[sd_key]][label]` first and fell into the registry path only if that was empty or `NA`. A constant entry for another endpoint filed under the same key and label would therefore shadow a modelled per-node SD. It now derives `modeled_scale_dpars` from `object$model$random_scale$phylo` first and branches: binomial q2 matrix, else registry path when the endpoint is modelled, else the `sdpars` constant with an explicit refusal if it is absent or `NA`. Messages and the numerical path for a modelled fit are unchanged.

## Tests

New `tests/testthat/test-sd-clamp-fields-registry.R` (tolerances fixed before the first run: 1e-10 for report arithmetic, 1e-12 for draw equalities):

- registry lists all four fields when all four blocks are modelled, drops absent blocks, and classifies the new fields as latent SD;
- Gamma joint mu plus sigma fit (`sd(g, dpar = "sigma") ~ z`, band `c(-2, 2)`): with `beta_sd_sigma` set to `c(4, 0)`, `log_sd_sigma_group` is 4 (raw), `log(sd_sigma_group)` equals `2 + 3 tanh(2/3)` (clamped), `drm_warn_if_clamp_active()` raises `drmTMB_clamp_active_warning` for a latent SD, `check_drm()`'s clamp row is a warning, and the start check warns for `beta_sd_sigma = c(4, 0)` and stays silent for `c(0.5, 0)`;
- Binomial phylo plus coordinate-spatial fit: the second field (`phylo2`) reports raw 4 and clamped `sd_phylo2_group`, the first field stays raw 0, and the fit-time warning, `check_drm()` row and start check fire;
- C7: an NB2 relmat slope-SD fit takes its draw SDs from `predict(fit, dpar = "sd_relmat(id)")` per node; a decoy constant (99) filed under the same `sdpars` key and label does not change the SD passed to the draw, and `simulate(re.form = NA)` is identical with and without the decoy; an unmodelled constant fit still reads `sdpars`, and removing the entry gives the explicit refusal. The decoy test fails on the previous `R/methods.R` (checked: 40 passed, 2 failed) and passes on the new one.

Existing assertions changed (contract change, not loosened): `tests/testthat/test-structured-sd-clamp-report.R` (two tests) and `tests/testthat/test-gamma-phylo-sd-regression.R` asserted that `log_sd_phylo_group` equals the clamped value. They now assert `log_sd_phylo_group == 4` (raw), `log(sd_phylo_group) == 2 + 3 tanh(2/3)` (clamped), and `predict(type = "link") == log(sd_phylo_group)`. Same fixtures, same tolerances (1e-10), no assertion deleted.

The sigma test removes `log_sigma*` from the report passed to the diagnostics: scaling the sigma-effect SD also scales the sigma random effect, so residual `log_sigma` moves out of the band too and would be the reported maximum. This isolates the field under test; the raw/clamped assertions use the full report.

## Not covered

- Julia: no Julia code was touched or run. If the Julia engine reports clamped SD log values for these blocks, the same contract choice applies there and is unchecked.
- A real fit that converges onto the upper clamp for the sigma or phylo2 SD was not constructed; the diagnostics are exercised at perturbed parameters through a stubbed `obj$report`. The fit-time path is therefore verified at the function level, not by a naturally clamped optimum.
- C7 is tested on the q1 relmat route. Marginal simulation for q > 1 structured fits other than Binomial q2 stays refused, so a multi-endpoint "constant for one endpoint, modelled for the other" fit cannot reach this function; the decoy fixture stands in for it.
- Other consumers of the ADREPORT rows `log_sd_sigma_group`, `log_sd_phylo_group`, `log_sd_phylo2_group`: a search of `R/` found none beyond the clamp registry, but external scripts that read these rows will see raw rather than clamped values outside the band.

## Verification (Mac, one R process at a time, `NOT_CRAN=true`)

Passed counts (all 0 failed, 0 errors, 0 skipped):

- New `test-sd-clamp-fields-registry.R`: 42.
- Edited tests: `test-structured-sd-clamp-report.R` 15, `test-gamma-phylo-sd-regression.R` 15.
- Clamp neighbours: `test-arc-d-sd-overflow-guard.R` 13, `test-binomial-sd-clamp.R` 32, `test-clamp-active-guard.R` 38, `test-clamp-extension.R` 16, `test-arc-c-clamp-hardening.R` 9, `test-logsigma-clamp.R` 21.
- Sigma SD and joint routes: `test-gamma-mu-sigma-joint-sd.R` 26, `test-nbinom2-mu-sigma-joint-sd.R` 29, `test-nbinom2-sigma-sd-regression.R` 14, `test-beta-binomial-sigma-sd-regression.R` 35.
- Structured and simulate: `test-nbinom2-structured-slope-marginal-simulate.R` 42, `test-simulate-re-form.R` 22, `test-simulate-re-form-phylo-interaction.R` 13, `test-binomial-phylo-spatial-sd.R` 60, `test-binomial-phylo-spatial-q2-sd.R` 127, `test-gamma-phylo-q2-sd-regression.R` 48, `test-poisson-phylo-sd-regression.R` 6, `test-phylo-gaussian.R` 385, `test-biv-gaussian.R` 948.

Not run: the full suite, `R CMD check`, and the remaining per-family SD regression files (the C++ change touches 18 branches across many families; only the families listed above were exercised, so a full-suite run on Totoro is the right next step before merge).
