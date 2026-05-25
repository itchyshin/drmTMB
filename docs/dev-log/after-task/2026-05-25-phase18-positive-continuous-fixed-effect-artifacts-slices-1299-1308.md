# After Task: Phase 18 Positive-Continuous Fixed-Effect Artifacts

## Goal

Add the fixed-effect positive-continuous artifact lane after the proportion
lane so `lognormal()` and `Gamma(link = "log")` have Phase 18 DGP, summariser,
smoke, grid-output, first-wave staging, and manual Actions-dispatch artifacts.

## Implemented

The new lane covers positive responses with
`bf(y ~ x, sigma ~ z), family = lognormal()` and
`bf(y ~ x, sigma ~ z), family = Gamma(link = "log")`. It saves aggregate,
replicate, manifest, failure-ledger, fixed-effect Wald interval, and Wald
coverage CSV artifacts beside resumable replicate RDS files. It is also
included in the first-wave summary smoke runner and selectable as the manual
`positive_continuous_fixed_effect` Actions task.

No spawned subagents were running. Ada kept the slice narrow; Fisher checked
the artifact-evidence claim, Boole checked the formula surface, Pat checked the
family interpretation boundary, Grace checked runner/workflow integration, and
Rose checked stale wording and issue overlap.

## Mathematical Contract

For lognormal data, `mu` is the log-response location:

```text
eta_mu_i = beta0 + beta1 * x_i
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
y_i ~ LogNormal(meanlog = eta_mu_i, sdlog = sigma_i)
```

For Gamma data, `mu` is the response mean and public `sigma` is the coefficient
of variation:

```text
mu_i = exp(beta0 + beta1 * x_i)
sigma_i = exp(gamma0 + gamma1 * z_i)
y_i ~ Gamma(shape = 1 / sigma_i^2, scale = mu_i * sigma_i^2)
```

The operating-characteristic rows stay on the modelled coefficient scales for
`mu` and `sigma`.

## Files Changed

- `inst/sim/dgp/sim_dgp_positive_continuous_fixed_effect.R`
- `inst/sim/fit/sim_summarise_positive_continuous_fixed_effect.R`
- `inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R`
- `inst/sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_positive_continuous_fixed_effect_grid.R`
- `tests/testthat/test-phase18-positive-continuous-fixed-effect.R`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `.github/workflows/phase18-simulation-grid.yaml`
- `docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_positive_continuous_fixed_effect.R inst/sim/fit/sim_summarise_positive_continuous_fixed_effect.R inst/sim/run/sim_run_positive_continuous_fixed_effect_smoke.R inst/sim/run/sim_summary_positive_continuous_fixed_effect_smoke.R inst/sim/run/sim_write_positive_continuous_fixed_effect_grid.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-positive-continuous-fixed-effect.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R tests/testthat/test-phase18-actions-runner.R NEWS.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md inst/sim/README.md .github/workflows/phase18-simulation-grid.yaml
Rscript -e "devtools::test(filter = '^phase18-(positive-continuous-fixed-effect|first-wave-summary-smoke-runner|actions-runner)$', reporter = 'summary')"
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/phase18-simulation-grid.yaml
rg -n 'positive-continuous.*(still need|needs).*DGP|lognormal.*still need.*DGP|Gamma.*still need.*DGP|add positive-continuous lognormal/Gamma artifacts' README.md ROADMAP.md NEWS.md docs/design inst/sim tests/testthat -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "positive continuous lognormal Gamma Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
```

All listed checks passed. The stale-wording scan returned no current text
saying the positive-continuous lognormal/Gamma artifact lane still needs DGP,
smoke, or grid files. The issue search returned `[]`.

## Tests Of The Tests

The new tests check that the DGP creates strictly positive lognormal and Gamma
responses, fits both families through the smoke summariser, requires Wald
interval artifacts, exercises the repeatable grid writer and overwrite guard,
and checks malformed family, correlation, sample-size, and output-directory
inputs.

## Consistency Audit

The current docs now say the positive-continuous artifact lane exists. The
stale-wording scan found no current text saying the lognormal and Gamma DGP,
summariser, smoke runner, or grid writer still needs to be added.

## GitHub Issue Maintenance

The overlapping open-issue search for
`"positive continuous lognormal Gamma Phase 18"` returned no issues. No issue
was opened or changed from this dirty tree.

## What Did Not Go Smoothly

The first version of the focused test file missed the final `})` closing a
`test_that()` block. `air format` caught the parse error before tests ran, and
the missing parenthesis was fixed before validation.

## Team Learning

Positive-continuous artifacts need to keep lognormal `mu` and Gamma `mu`
separate: one is log-response location, the other is response mean. The shared
artifact schema can still compare their formula coefficients because both
families expose `mu` and `sigma` on documented link scales.

## Known Limitations

This is a fixed-effect artifact lane only. Tweedie, generalized Gamma,
positive-response random effects, known-covariance positive responses,
structured positive-response effects, and bivariate or mixed-response positive
models remain unsupported or planned.

## Next Actions

After validation, the next core-family artifact lane should be fixed-effect
ordinal unless the team chooses to pause and split/stage the existing dirty tree
for Actions first.
