# After Task: Phase 18 Tweedie Fixed-Effect Smoke Artifacts

Date: 2026-05-28

## Goal

Use one duplicated Team A lane, rather than two active teams, to start the
first runnable `tweedie_fixed_effect` artifact implementation after the
Tweedie density fixture merged.

## Implemented

Added the first Phase 18 smoke artifact path for fitted univariate fixed-effect
Tweedie models:

- `inst/sim/dgp/sim_dgp_tweedie_fixed_effect.R` generates low- and high-zero
  semicontinuous data from `bf(y ~ x, sigma ~ z, nu ~ 1)` with public
  `sigma = sqrt(phi)` and intercept-only `nu`.
- `inst/sim/fit/sim_summarise_tweedie_fixed_effect.R` summarises link-scale
  `mu`, public-`sigma`, and `nu` coefficients, and carries response-scale
  power plus observed-zero diagnostics.
- `inst/sim/run/sim_run_tweedie_fixed_effect_smoke.R` wires the DGP, fit, and
  summariser through the Phase 18 replicate runner with saved-result resume
  support.
- `inst/sim/run/sim_summary_tweedie_fixed_effect_smoke.R` returns aggregate,
  replicate, manifest, failure-ledger, Wald interval, and Wald coverage
  artifacts.
- `tests/testthat/test-phase18-tweedie-fixed-effect.R` covers the DGP,
  summary artifacts, saved-result resume behaviour, and malformed inputs.

## Mathematical Contract

The artifact lane keeps the fitted Tweedie contract unchanged:

```text
log(mu_i) = beta0 + beta1 * x_i
log(sigma_i) = gamma0 + gamma1 * z_i
phi_i = sigma_i^2
nu_i = 1 + plogis(eta_nu)
E[y_i] = mu_i
Var(y_i) = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

The summary table records the formula-scale `nu:(Intercept)` truth as
`qlogis(power - 1)`, while `power` and `power_estimate` keep the
response-scale Tweedie power visible for diagnostics.

## Validation

```sh
air format inst/sim/dgp/sim_dgp_tweedie_fixed_effect.R inst/sim/fit/sim_summarise_tweedie_fixed_effect.R inst/sim/run/sim_run_tweedie_fixed_effect_smoke.R inst/sim/run/sim_summary_tweedie_fixed_effect_smoke.R tests/testthat/test-phase18-tweedie-fixed-effect.R
Rscript --vanilla -e "devtools::test(filter = '^phase18-tweedie-fixed-effect$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^(phase18-tweedie-fixed-effect|tweedie-location-scale|family-link-contract)$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'manual `tweedie_fixed_effect`|phase18_write_tweedie|Tweedie.*ready for.*coverage|tweedie_fixed_effect.*coverage grid|tweedie_fixed_effect.*Actions|predictor-dependent Tweedie `nu`.*(implemented|supported|admitted)|Tweedie random effects.*(implemented|supported|admitted)|bivariate Tweedie.*(implemented|supported|admitted)|zero-inflation alias.*(implemented|supported|admitted)|hurdle alias.*(implemented|supported|admitted)' README.md NEWS.md ROADMAP.md docs/design inst/sim R src NAMESPACE man tests/testthat --glob '!docs/dev-log/**' --glob '!docs/reference/**' --glob '!docs/articles/**'
git diff --check
```

Results: the focused `phase18-tweedie-fixed-effect` tests passed; the combined
Tweedie artifact, fitted Tweedie, and family-link focused tests passed; full
`devtools::test()` passed; `pkgdown::check_pkgdown()` reported no problems; the
false-claim scan returned only the intended new ROADMAP boundary row; and
`git diff --check` was clean.

## Boundary

This slice does not add a grid writer, manual Actions task, coverage table,
predictor-dependent `nu`, random effects, structured effects, bivariate
Tweedie route, offset/exposure route, zero-inflation alias, hurdle alias, or
weighted external comparator.

## Team Review

Ada kept one lane active and integrated serially. Curie owned the deterministic
DGP and smoke tests. Fisher kept the estimands on formula scales while carrying
response-scale power diagnostics. Grace ran the focused test gate. Boole,
Gauss, and Noether kept syntax, public scale, and likelihood boundaries aligned
with the fitted Tweedie contract. Rose recorded the single-lane duplicated-team
process lesson in `docs/dev-log/team-improvements.md`.

No spawned subagents were running.

## Next Actions

The next narrow Team A slice can add a repeatable grid-output writer for
`tweedie_fixed_effect`, then wire it into the usual artifact-manifest checks if
the focused smoke runner remains green.
