# After Task: Q8 Stress Audit And Skew-Normal False-Positive Design

## Goal

Finish the recommended two-hour slice after the q8 diagnostic-summary and
skew-normal smoke-artifact work: add a small q8 diagnostic stress-audit artifact
route, add a symmetric fixed-effect skew-normal false-positive artifact route,
and record the formal fixed-effect skew-normal recovery design gate.

## Implemented

`phase18_biv_gaussian_q8_endpoint_diagnostic_audit_conditions()` now selects a
five-row q8 stress subset from the existing diagnostic presets: low
replication, weak endpoint SDs, negative residual `rho12`, positive residual
`rho12`, and high latent q8 correlation. The new
`phase18_write_biv_gaussian_q8_endpoint_diagnostic_grid_outputs()` writer emits
aggregate, replicate, manifest, failure, and diagnostic-summary CSV artifacts
for that subset. The writer is an artifact route only; it does not run or
promote q8 coverage or power.

`phase18_skew_normal_fe_false_positive_conditions()` now creates symmetric
`nu = 0` fixed-effect skew-normal conditions across sample size, scale
heterogeneity, and location/scale predictor correlation. The new
`phase18_summarise_skew_normal_fe_false_positive_smoke()` wrapper and
`phase18_write_skew_normal_fe_false_positive_grid_outputs()` writer record
fitted-`nu` threshold rates and `check_drm()` large-slant note rates beside the
ordinary smoke artifacts.

`docs/design/162-phase-18-skew-normal-fixed-effect-formal-recovery-design.md`
defines the first formal recovery grid for univariate fixed-effect
`skew_normal()`: the admitted formulas, condition grid, estimands,
false-positive summaries, stop rules, and non-goals.

## Mathematical Contract

No formula grammar or likelihood parameterization changed. Q8 remains the
ordinary Gaussian all-endpoint block with residual `rho12` separate from
group-level q8 covariance. The new q8 writer only packages diagnostic-preset
artifact tables.

Skew-normal remains public `mu = E[y]`, public `sigma = SD[y]`, and `nu` as
residual slant. The false-positive lane fixes true `nu = 0` and asks whether
the fitted first-slice model invents large slant under symmetric data. It is a
diagnostic guard, not a calibrated hypothesis test.

## Files Changed

- `inst/sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R`
- `inst/sim/run/sim_write_biv_gaussian_q8_endpoint_diagnostic_grid.R`
- `tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R`
- `inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R`
- `inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R`
- `inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R`
- `tests/testthat/test-phase18-skew-normal-fixed-effect.R`
- `docs/design/162-phase-18-skew-normal-fixed-effect-formal-recovery-design.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/dev-log/known-limitations.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla -e 'devtools::test(filter = "phase18-skew-normal-fixed-effect|skew-normal-location-scale|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
air format inst/sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R inst/sim/run/sim_write_biv_gaussian_q8_endpoint_diagnostic_grid.R tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R tests/testthat/test-phase18-skew-normal-fixed-effect.R docs/design/162-phase-18-skew-normal-fixed-effect-formal-recovery-design.md docs/design/41-phase-18-simulation-programme.md docs/design/157-capability-completion-worklist.md docs/dev-log/known-limitations.md inst/sim/README.md ROADMAP.md NEWS.md docs/design/46-pre-simulation-readiness-matrix.md
git diff --check
rg -n 'skew_normal.*formal artifact grids|formal artifact.*skew_normal|skew-normal.*formal artifact|skew-family recovery grids|q8.*(coverage|power).*(ready|passed|complete)|skew_normal.*(random effects|structured effects|bivariate|rho12).*(implemented|supported|ready)|skew-normal.*formal recovery.*(ready|complete|passed)' NEWS.md ROADMAP.md README.md docs/design docs/dev-log/known-limitations.md inst/sim vignettes R tests --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/design/archive/**'
gh issue list --repo itchyshin/drmTMB --state open --search "skew-normal OR skew_normal OR q8 diagnostic OR q8 endpoint" --limit 20 --json number,title,state,url,labels
```

The focused test run passed after correcting the q8 audit subset from the
nonexistent `correlation:strong` level to the existing `correlation:high`
level. `git diff --check` passed. The stale-claim scan returned only intended
boundary rows.

## Tests Of The Tests

The q8 diagnostic writer test stubs the expensive q8 summariser and checks the
CSV output contract, including the extra diagnostic-summary artifact. The
existing q8 test file still exercises the real q8 fit path elsewhere, so the
new writer test does not add another slow TMB fit.

The skew-normal false-positive tests include one real symmetric smoke run and a
synthetic replicate table that checks the threshold-rate calculation exactly.
Malformed threshold and output-directory paths are rejected.

## Consistency Audit

`inst/sim/README.md`, `docs/design/41-phase-18-simulation-programme.md`,
`docs/design/46-pre-simulation-readiness-matrix.md`,
`docs/design/157-capability-completion-worklist.md`,
`docs/dev-log/known-limitations.md`, `ROADMAP.md`, and `NEWS.md` now distinguish
three separate states: q8 diagnostic artifacts, skew-normal smoke and
false-positive artifacts, and skew-normal formal recovery still not run.

## GitHub Issue Maintenance

The issue scan found existing coverage in #3 for skew-normal, #5 and #33 for
individual-difference/q8 covariance boundaries, #59 for Phase 18 simulation
infrastructure, #491 for the broad local-R queue, and #61/#342 for release
gates. No duplicate issue or comment was needed.

## What Did Not Go Smoothly

The first focused test run caught a real vocabulary mismatch: I wrote the q8
stress subset against `correlation:strong`, but the existing diagnostic preset
uses `correlation:high`. The helper and test were corrected, and the focused
suite passed afterward.

## Team Learning

For q8, a small stress-audit subset is useful only if it remains visibly
diagnostic. The writer should make the failure modes easier to classify, not
move q8 into a power grid.

For skew-normal, the false-positive lane should travel beside formal recovery.
The symmetric `nu = 0` rows are the guardrail against a model that always finds
skewness when heteroscedasticity or predictor correlation is present.

## Known Limitations

No q8 diagnostic stress audit was run in this slice. The writer and tests now
exist, but q8 remains at `hold_diagnostic` with no coverage, power, or interval
promotion.

No formal skew-normal recovery grid was run. The false-positive lane is a
diagnostic artifact route only, and external comparators, predictor-varying
`nu` grids, random effects, structured effects, bivariate support, residual
`rho12`, and latent `skew(id)` remain future work.

## Next Actions

Run the q8 diagnostic writer on the stress subset with a tiny local replicate
count and inspect the diagnostic-summary CSV. Then run the skew-normal formal
recovery design at a pilot replicate count, using the false-positive rows as a
first stop-rule gate before any larger grid.
