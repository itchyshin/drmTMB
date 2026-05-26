# After Task: Phase 18 Proportion Fixed-Effect Artifacts

## Goal

Add the fixed-effect proportion artifact lane after the core family completion
map so `beta()` and `beta_binomial()` have the same Phase 18 DGP, summariser,
smoke, grid-output, first-wave staging, and manual Actions-dispatch discipline
as the other first-wave surfaces.

## Implemented

Ada kept the slice narrow. The new lane covers strict continuous proportions
with `bf(prop ~ x, sigma ~ z), family = beta()` and denominator-aware successes
with `bf(cbind(success, failure) ~ x, sigma ~ z), family = beta_binomial()`.
It saves aggregate, replicate, manifest, failure-ledger, fixed-effect Wald
interval, and Wald coverage CSV artifacts beside resumable replicate RDS files.
It is also included in the first-wave summary smoke runner and selectable as
the manual `proportion_fixed_effect` Actions task.

No spawned subagents were running. Fisher checked the artifact-evidence claim,
Boole checked the formula surface, Pat checked the user boundary, Grace checked
the runner/workflow integration, and Rose checked stale wording and issue
overlap.

## Mathematical Contract

The simulated mean uses `logit(mu_i) = beta0 + beta1 * x_i`. The public scale
uses `log(sigma_i) = gamma0 + gamma1 * z_i`, with internal beta precision
`phi_i = 1 / sigma_i^2`.

For strict proportions, the DGP is:

```text
prop_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

For successes out of known trials, the DGP is:

```text
p_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
success_i ~ Binomial(trials_i, p_i)
failure_i = trials_i - success_i
```

The operating-characteristic rows stay on the modelled coefficient scales for
`mu` and `sigma`. `phi` is a documented internal transform, not a public
estimand.

## Files Changed

- `inst/sim/dgp/sim_dgp_proportion_fixed_effect.R`
- `inst/sim/fit/sim_summarise_proportion_fixed_effect.R`
- `inst/sim/run/sim_run_proportion_fixed_effect_smoke.R`
- `inst/sim/run/sim_summary_proportion_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_proportion_fixed_effect_grid.R`
- `tests/testthat/test-phase18-proportion-fixed-effect.R`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `.github/workflows/phase18-simulation-grid.yaml`
- `docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_proportion_fixed_effect.R inst/sim/fit/sim_summarise_proportion_fixed_effect.R inst/sim/run/sim_run_proportion_fixed_effect_smoke.R inst/sim/run/sim_summary_proportion_fixed_effect_smoke.R inst/sim/run/sim_write_proportion_fixed_effect_grid.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-proportion-fixed-effect.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R tests/testthat/test-phase18-actions-runner.R NEWS.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md inst/sim/README.md .github/workflows/phase18-simulation-grid.yaml
Rscript -e "devtools::test(filter = '^phase18-(proportion-fixed-effect|first-wave-summary-smoke-runner|actions-runner)$', reporter = 'summary')"
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/phase18-simulation-grid.yaml
rg -n 'proportion.*(still need|needs).*DGP|beta.*still need.*DGP|beta_binomial.*still need.*DGP|have not been promoted|Make proportions the next implementation lane' README.md ROADMAP.md NEWS.md docs/design inst/sim tests/testthat -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "proportion beta beta_binomial Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
```

All listed checks passed. The issue search returned `[]`.

## Tests Of The Tests

The new tests check that the DGP creates strict `(0, 1)` beta responses for
`beta()` and two-column success/failure data for `beta_binomial()`. They fit
both families through the smoke summariser, require Wald interval artifacts,
exercise the repeatable grid writer and overwrite guard, and check malformed
family, trial-range, and output-directory inputs.

## Consistency Audit

The current docs now say the proportion artifact lane exists. The prior core
family completion map was updated so it no longer reads as a current missing
artifact claim. The stale-wording scan found no current text saying the
proportion DGP, summariser, smoke runner, or grid writer still needs to be
added.

## GitHub Issue Maintenance

The overlapping open-issue search for `"proportion beta beta_binomial Phase 18"`
returned no issues. No issue was opened or changed from the current dirty tree.

## What Did Not Go Smoothly

The first draft of the new test file was missing a closing parenthesis and
failed to parse before formatting. That was caught immediately by `air format`
and fixed before tests were run.

## Team Learning

Rose's useful check here was to treat `docs/design/109-*` as a living reader
surface even though it started as a planning note. Historical text can remain,
but it should not leave a current user believing an artifact lane is still
missing after the follow-up slice lands.

## Known Limitations

This is a fixed-effect artifact lane only. Exact 0/1 boundary mass, `zoi` and
`coi` formulas, bounded-response random effects, phylogenetic/spatial/animal/
`relmat()` bounded-response effects, bounded-response `meta_V(V = V)`, and
bivariate or mixed-response bounded models remain unsupported or planned.

## Next Actions

The next core-family artifact lane should be positive continuous fixed-effect
lognormal and Gamma. After that, revisit fixed-effect ordinal artifacts before
deciding whether skew-normal implementation is the next shape-family step.
