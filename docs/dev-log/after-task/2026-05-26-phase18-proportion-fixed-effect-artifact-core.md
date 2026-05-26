# After Task: Phase 18 Proportion Fixed-Effect Artifact Core

## Goal

Restore the fixed-effect proportion artifact core on
`codex/phase18-reconcile-small` without replaying the full fixed-effect family
artifact commit.

## Implemented

The slice adds private Phase 18 helpers for strict continuous `beta()` data and
denominator-aware `beta_binomial()` success/failure data:

- DGP and condition helpers;
- fit summariser;
- smoke runner;
- summary helper;
- repeatable grid-output writer;
- focused test coverage.

It deliberately does not add first-wave summary-runner inclusion or a manual
`proportion_fixed_effect` Actions task in this slice.

## Mathematical Contract

The simulated mean uses `logit(mu_i) = beta0 + beta1 * x_i`. The public scale
uses `log(sigma_i) = gamma0 + gamma1 * z_i`, with internal beta precision
`phi_i = 1 / sigma_i^2`.

For strict proportions:

```text
prop_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

For successes out of known trials:

```text
p_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
success_i ~ Binomial(trials_i, p_i)
failure_i = trials_i - success_i
```

Operating-characteristic rows stay on the modelled `mu` and `sigma`
coefficient scales.

## Files Changed

- `inst/sim/dgp/sim_dgp_proportion_fixed_effect.R`
- `inst/sim/fit/sim_summarise_proportion_fixed_effect.R`
- `inst/sim/run/sim_run_proportion_fixed_effect_smoke.R`
- `inst/sim/run/sim_summary_proportion_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_proportion_fixed_effect_grid.R`
- `tests/testthat/test-phase18-proportion-fixed-effect.R`
- `docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_proportion_fixed_effect.R inst/sim/fit/sim_summarise_proportion_fixed_effect.R inst/sim/run/sim_run_proportion_fixed_effect_smoke.R inst/sim/run/sim_summary_proportion_fixed_effect_smoke.R inst/sim/run/sim_write_proportion_fixed_effect_grid.R tests/testthat/test-phase18-proportion-fixed-effect.R ROADMAP.md inst/sim/README.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-26-phase18-proportion-fixed-effect-artifact-core.md
Rscript -e "devtools::test(filter = '^phase18-proportion-fixed-effect$', reporter = 'summary')"
rg -n 'proportion.*(still need|needs).*DGP|beta.*still need.*DGP|beta_binomial.*still need.*DGP|proportion_fixed_effect.*Actions|task = "proportion_fixed_effect"|first-wave.*proportion.*now|bounded-response random effects.*now (fit|implemented)|zoi.*now (fit|implemented)|coi.*now (fit|implemented)' README.md ROADMAP.md NEWS.md docs/design inst/sim tests/testthat -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "proportion beta beta_binomial Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
```

## Tests Of The Tests

The focused tests check seeded DGP shape for both families, smoke-summary row
counts, Wald interval artifacts, repeatable grid output, overwrite protection,
and malformed family, trial-range, and output-directory inputs.

## Consistency Audit

The docs now say the proportion artifact core exists, but do not claim
first-wave report inclusion, manual Actions dispatch, exact 0/1 boundary mass,
`zoi`, `coi`, bounded-response random effects, known-covariance bounded
responses, or mixed-response bounded models.

## GitHub Issue Maintenance

The overlapping open-issue search for `"proportion beta beta_binomial Phase 18"`
returned no direct issue. No issue was opened or changed.

## What Did Not Go Smoothly

The old local commit bundled proportion, positive-continuous, ordinal,
first-wave runner, and Actions changes together, so Ada restored only the
proportion-specific files and rewrote shared docs to match the smaller scope.

## Team Learning

Curie should split artifact lanes from report/Actions integration when
reconciling old local work onto a clean upstream branch.

## Known Limitations

This is a fixed-effect artifact core only. First-wave summary integration and
manual Actions dispatch are still absent. Exact 0/1 boundary mass, `zoi`,
`coi`, bounded-response random effects, structured bounded responses,
bounded-response `meta_V(V = V)`, and mixed-response bounded models remain
planned or unsupported.

## Next Actions

Add first-wave summary and manual Actions integration for
`proportion_fixed_effect`, or move to the fixed-effect positive-continuous
artifact core if keeping report integration separate.
