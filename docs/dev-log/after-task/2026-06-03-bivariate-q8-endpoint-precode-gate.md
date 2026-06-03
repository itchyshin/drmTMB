# After Task: Bivariate q8 Endpoint Pre-Code Gate

## Goal

Keep moving after the q6 smoke/artifact lane by making the next q8 endpoint
boundary executable, without opening q8 likelihood support, Actions dispatch,
or fitted-status claims.

## Implemented

The Phase 18 structured workflow registry now has a design-only
`bivariate_gaussian_q8_endpoint` row. It is in the random-slope lane because it
is the planned all-endpoint location-scale slope neighbour, but it has
`existing_actions_task = "none"` and remains excluded from the admitted
random-slope workflow plan.

`phase18_biv_gaussian_q8_endpoint_precode_gate()` returns the registry row, the
endpoint taxonomy, and checks that the row is still design-only with no Actions
task. `phase18_random_slope_registry_preflight()` now keeps design-only rows
visible as `held_no_dispatch` with `audit_focus = "design_required"`.

## Mathematical Contract

The future full q8 endpoint vector is:

```text
mu1:(Intercept), mu1:x,
mu2:(Intercept), mu2:x,
sigma1:(Intercept), sigma1:x,
sigma2:(Intercept), sigma2:x
```

That implies eight SDs and 28 pairwise correlations. This task records those
labels only. It does not add a positive-definite parameterization, TMB
likelihood path, `corpairs()` rows, profile targets, or simulation artifacts.

## Files Changed

- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/design/63-implementation-map-slices-311-325.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R`
  completed without errors.
- `Rscript -e "devtools::test(filter = 'phase18-structured-workflow-registry')"`
  returned 300 passes, no failures, warnings, or skips.
- `Rscript -e "devtools::test(filter = 'phase18-actions-runner|phase18-structured-workflow-registry')"`
  returned 496 passes, no failures, warnings, or skips.
- The unsupported-claim scan for q8/p8 fitted or dispatch-promotion wording
  returned no hits.
- `git diff --check` passed.

`devtools::document()` was not run because no roxygen comments changed. Full
`devtools::test()`, `pkgdown::build_site()`, `pkgdown::check_pkgdown()`, and
`devtools::check()` were not rerun for this source/test/design-only preflight
slice.

## Tests Of The Tests

The focused registry tests now fail if the q8 row becomes admitted, gains an
Actions task, disappears from preflight, or reports a correlation count other
than 28. The workflow-plan tests also confirm that the q8 row does not enter
the admitted random-slope plan.

## Consistency Audit

The registry, dry-run helper, design notes, simulation README, and roadmap all
say the same thing: q8 is visible as a design gate and held from dispatch. The
narrow unsupported-claim scan was:

```sh
rg -n 'q8.*(ready_grid|ready_existing_task|ready_existing|ready task)|p8.*(ready_grid|ready_existing_task|ready_existing|ready task)|q8 (is|are|now) (fitted|implemented|supported)|p8 (is|are|now) (fitted|implemented|supported)|q8.*existing_actions_task.*(biv|first_wave|summary)|bivariate_gaussian_q8_endpoint.*ready' README.md ROADMAP.md docs/design docs/dev-log/known-limitations.md inst/sim tests/testthat -g '!docs/dev-log/after-task/**'
```

It returned no hits.

## GitHub Issue Maintenance

No issue or PR comment was posted for this local stacked slice. PR #478 remains
the active clean q6 smoke/artifact PR; this q8 pre-code gate should be opened
separately if it is pushed for review.

## What Did Not Go Smoothly

The first roadmap edit reused slice number 1834, which was already assigned to
the spatial one-slope Actions task. The q8 gate is now recorded as slice 1840.

## Team Learning

For high-risk endpoint blocks, a registry-visible design row is useful before
implementation. It gives Ada and Grace a machine-readable stop condition and
lets tests catch accidental dispatch promotion.

## Known Limitations

This task does not fit q8, p8, residual-scale bivariate slope covariance,
same-response location-scale slope covariance, random effects in `rho12`, q8
`corpairs()` rows, interval targets, recovery, coverage, power, or timing.

## Next Actions

If q8-adjacent implementation is considered next, start with a smaller q2
scale-slope or same-response location-scale endpoint decision before attempting
the full q8 unstructured block.
