# After Task: Phase 18 Proportion First-Wave And Actions Integration

## Goal

Wire the fixed-effect proportion artifact lane into first-wave report staging
and manual GitHub Actions dispatch without reopening the larger bundled
positive-continuous or ordinal artifact work.

## Implemented

Ada kept this to one integration follow-up. The first-wave summary smoke runner
now runs the fixed-effect `beta()`/`beta_binomial()` proportion grid beside the
existing Gaussian, meta-analysis, count, Gaussian random-slope, and spatial
smoke surfaces. The manual Phase 18 workflow now exposes
`proportion_fixed_effect` as an opt-in task; `task = "all"` still reaches the
proportion lane through `first_wave_summary` and does not dispatch the
standalone proportion grid separately.

No spawned subagents were running. Curie checked the simulation-runner wiring,
Grace checked the workflow and YAML surface, and Rose checked that the docs
still leave positive-continuous, ordinal, `zoi`, `coi`, and bounded-response
random-effect routes out of this slice.

## Mathematical Contract

This slice does not change the likelihood, parameterization, formula grammar,
or estimands. It reuses the artifact contract from
`docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md`:
`logit(mu) = eta_mu`, `log(sigma) = eta_sigma`, and internal beta precision
`phi = 1 / sigma^2`.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-first-wave-summary-smoke-runner.R`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R tests/testthat/test-phase18-actions-runner.R .github/workflows/phase18-simulation-grid.yaml ROADMAP.md inst/sim/README.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-26-phase18-proportion-first-wave-actions.md
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-smoke-runner|actions-runner)$', reporter = 'summary')"
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/phase18-simulation-grid.yaml
rg -n 'positive_continuous_fixed_effect|ordinal_fixed_effect|bounded-response random effects.*now (fit|implemented)|zoi.*now (fit|implemented)|coi.*now (fit|implemented)|proportion.*still need.*first-wave|proportion.*still need.*Actions|task = "all".*proportion_fixed_effect' .github/workflows/phase18-simulation-grid.yaml inst/sim/run/sim_run_actions_cell.R inst/sim/run/sim_run_first_wave_summary_smoke.R tests/testthat docs/design ROADMAP.md inst/sim/README.md -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "proportion beta beta_binomial Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
```

All listed checks passed. The issue search returned `[]`.

## Tests Of The Tests

The first-wave smoke-runner test now sources the proportion DGP, summariser,
smoke, summary, and grid-writer helpers, requires the extra
`proportion_fixed_effect_grid` parallel-summary row, and checks the expanded
first-wave aggregate and Wald coverage row counts. The Actions-runner test
checks that `--task=proportion_fixed_effect` parses in dry-run mode and that
the workflow exposes the task.

## Consistency Audit

The map, simulation programme, readiness matrix, validation-debt register,
simulation README, roadmap, and proportion design note now say the proportion
artifact lane has first-wave summary and manual Actions integration. The stale
scan returned no hits for positive-continuous artifacts, ordinal artifacts,
`zoi`, `coi`, bounded-response random effects, or duplicate `task = "all"`
proportion dispatch.

## GitHub Issue Maintenance

The overlapping open-issue search for `"proportion beta beta_binomial Phase 18"`
returned no issues. No issue was opened or changed.

## What Did Not Go Smoothly

The old bundled commit contained proportion, positive-continuous, and ordinal
integration together. This slice deliberately hand-applied only the proportion
pieces so the clean branch stays reviewable. The first test run also caught
over-large expected first-wave table row counts; the observed proportion-only
addition is 51 aggregate rows and 27 Wald-coverage rows.

## Team Learning

Rose's useful guard was to treat `task = "all"` as an evidence contract. A
standalone task can be useful for manual dispatch, but if the first-wave summary
already includes the same lane, the workflow should not run it twice by default.

## Known Limitations

This remains fixed-effect proportion evidence only. Exact 0/1 boundary mass,
`zoi` and `coi` formulas, bounded-response random effects, phylogenetic,
spatial, animal, `relmat()`, known-covariance bounded responses, and mixed
bounded-response models remain unsupported or planned.

## Next Actions

The next small slice is the fixed-effect positive-continuous artifact lane for
lognormal and Gamma, kept separate from ordinal and bounded-response random
effects.
