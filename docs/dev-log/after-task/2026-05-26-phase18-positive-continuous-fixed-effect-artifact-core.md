# After Task: Phase 18 Positive-Continuous Fixed-Effect Artifact Core

## Goal

Restore the fixed-effect positive-continuous artifact core for `lognormal()`
and `Gamma(link = "log")` from the older bundled branch while keeping
first-wave summary, manual Actions dispatch, ordinal artifacts, and
positive-response random-effect work out of this slice.

## Implemented

Ada kept this to the private artifact lane. The new lane covers fixed-effect
lognormal location-scale models and Gamma mean-CV models with
`bf(y ~ x, sigma ~ z)`. It saves aggregate, replicate, manifest,
failure-ledger, fixed-effect Wald interval, and Wald coverage CSV artifacts
beside resumable replicate RDS files.

No spawned subagents were running. Curie checked the DGP, summariser, smoke,
summary, and grid-writer path; Fisher checked that the result is smoke artifact
evidence rather than a formal recovery claim; Grace checked formatting and
focused tests; Rose checked that Tweedie, generalized Gamma, known-covariance
positive responses, structured positive responses, and mixed-response positive
models remain outside this slice.

## Mathematical Contract

For lognormal data, the DGP uses:

```text
eta_mu_i = beta0 + beta1 * x_i
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
y_i ~ LogNormal(meanlog = eta_mu_i, sdlog = sigma_i)
```

For Gamma data, the DGP uses:

```text
eta_mu_i = beta0 + beta1 * x_i
mu_i = exp(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
y_i ~ Gamma(shape = 1 / sigma_i^2, scale = mu_i * sigma_i^2)
```

The artifact rows estimate fixed `mu` and `sigma` coefficients on their
modelled link scales. For lognormal fits, `mu` is log-location and `fitted()`
returns the arithmetic response mean. For Gamma fits, `mu` is the response mean
and public `sigma` is the coefficient of variation.

## Files Changed

- `docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md`
- `inst/sim/dgp/sim_dgp_positive_continuous_fixed_effect.R`
- `inst/sim/fit/sim_summarise_positive_continuous_fixed_effect.R`
- `inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R`
- `inst/sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_positive_continuous_fixed_effect_grid.R`
- `tests/testthat/test-phase18-positive-continuous-fixed-effect.R`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_positive_continuous_fixed_effect.R inst/sim/fit/sim_summarise_positive_continuous_fixed_effect.R inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R inst/sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R inst/sim/run/sim_write_positive_continuous_fixed_effect_grid.R tests/testthat/test-phase18-positive-continuous-fixed-effect.R ROADMAP.md inst/sim/README.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-26-phase18-positive-continuous-fixed-effect-artifact-core.md
Rscript -e "devtools::test(filter = '^phase18-positive-continuous-fixed-effect$', reporter = 'summary')"
rg -n 'positive-continuous.*(still need|needs).*DGP|lognormal.*still need.*DGP|Gamma.*still need.*DGP|task = "positive_continuous_fixed_effect"|first-wave.*positive-continuous.*now|positive-response random effects.*now (fit|implemented)|Tweedie.*now (fit|implemented)|generalized Gamma.*now (fit|implemented)' README.md ROADMAP.md NEWS.md docs/design inst/sim tests/testthat -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "positive continuous lognormal Gamma Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
```

All listed checks passed. The issue search returned `[]`.

## Tests Of The Tests

The focused test checks that the DGP creates positive lognormal and Gamma
responses with the correct link-scale contract, that the smoke summariser
returns Wald interval and Wald coverage artifacts for both families, that the
grid writer creates repeatable CSV artifacts and enforces overwrite protection,
and that malformed family, sample-size, correlation, and output-directory
inputs fail before fitting.

## Consistency Audit

The current docs now say the positive-continuous artifact core exists. The
completion map still keeps first-wave summary and manual Actions integration as
a separate next slice, and no text promotes Tweedie, generalized Gamma,
positive-response random effects, known-covariance positive responses,
structured positive-response effects, or mixed-response positive-continuous
models.

## GitHub Issue Maintenance

The overlapping open-issue search for
`"positive continuous lognormal Gamma Phase 18"` returned no issues. No issue
was opened or changed.

## What Did Not Go Smoothly

The older bundled commit included first-wave/actions wiring and other family
lanes. This slice restored only the positive-continuous core files and then
edited the design note back to a core-only integration boundary.

## Team Learning

Rose's useful guard was to keep "positive-continuous fitted" separate from
"positive-continuous simulation-integrated." The lognormal/Gamma artifact core
is useful evidence, but workflow integration and larger operating
characteristic claims still need their own review slice.

## Known Limitations

This is fixed-effect lognormal/Gamma evidence only. Tweedie, generalized Gamma,
positive-response random effects, positive-response known covariance,
structured positive-response effects, and mixed-response positive-continuous
models remain unsupported or planned.

## Next Actions

The next small slice is positive-continuous first-wave summary and manual
Actions integration only.
