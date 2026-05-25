# After Task: Phase 18 Ordinal Fixed-Effect Artifacts

## Goal

Add the fixed-effect ordinal artifact lane after the proportion and
positive-continuous lanes so `cumulative_logit()` has Phase 18 DGP, summariser,
smoke, grid-output, first-wave staging, and manual Actions-dispatch artifacts.

## Implemented

The new lane covers ordered responses with
`bf(score ~ x), family = cumulative_logit()`. It saves aggregate, replicate,
manifest, failure-ledger, fixed-effect Wald interval, and Wald coverage CSV
artifacts beside resumable replicate RDS files. The replicate rows also record
cutpoint estimates, cutpoint truth, minimum fitted cutpoint gap, and whether
the fitted cutpoints remain ordered. The lane is included in the first-wave
summary smoke runner and selectable as the manual `ordinal_fixed_effect`
Actions task.

No spawned subagents were running. Ada kept the slice narrow; Boole checked the
formula surface, Fisher checked the Wald and artifact claim, Noether checked
the cutpoint/location identifiability convention, Pat checked the ordered-score
reader boundary, Grace checked runner/workflow integration, and Rose checked
stale wording and issue overlap.

## Mathematical Contract

For ordered categories `1, ..., K`, the fitted and simulated contract is:

```text
mu_i = beta1 * x_i
theta_1 < theta_2 < ... < theta_{K-1}
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
```

The DGP draws category probabilities from adjacent cumulative differences. The
location intercept is not an estimand because the fitted
`cumulative_logit()` path removes it before optimization; free cutpoints and a
free location intercept are not jointly identifiable.

## Files Changed

- `inst/sim/dgp/sim_dgp_ordinal_fixed_effect.R`
- `inst/sim/fit/sim_summarise_ordinal_fixed_effect.R`
- `inst/sim/run/sim_run_ordinal_fixed_effect_smoke.R`
- `inst/sim/run/sim_summary_ordinal_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_ordinal_fixed_effect_grid.R`
- `tests/testthat/test-phase18-ordinal-fixed-effect.R`
- `inst/sim/run/sim_run_first_wave_summary_smoke.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `.github/workflows/phase18-simulation-grid.yaml`
- `docs/design/112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `inst/sim/README.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-25-082709-codex-checkpoint.md`

## Checks Run

```sh
air format inst/sim/dgp/sim_dgp_ordinal_fixed_effect.R inst/sim/fit/sim_summarise_ordinal_fixed_effect.R inst/sim/run/sim_run_ordinal_fixed_effect_smoke.R inst/sim/run/sim_summary_ordinal_fixed_effect_smoke.R inst/sim/run/sim_write_ordinal_fixed_effect_grid.R inst/sim/run/sim_run_first_wave_summary_smoke.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-ordinal-fixed-effect.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R tests/testthat/test-phase18-actions-runner.R NEWS.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md inst/sim/README.md .github/workflows/phase18-simulation-grid.yaml
Rscript -e "devtools::test(filter = '^phase18-ordinal-fixed-effect$', reporter = 'summary')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-smoke-runner|actions-runner)$', reporter = 'summary')"
ruby -e 'require "yaml"; ARGV.each { |f| YAML.load_file(f); puts "ok #{f}" }' .github/workflows/phase18-simulation-grid.yaml
rg -n 'ordinal.*(still need|needs).*DGP|cumulative_logit.*still need.*DGP|fixed-effect ordinal.*(still need|needs).*grid|Promote fixed-effect ordinal artifacts|next.*ordinal artifacts|ordinal.*not.*artifact' README.md ROADMAP.md NEWS.md docs/design inst/sim tests/testthat -g '!*.html'
gh issue list --repo itchyshin/drmTMB --state open --search "ordinal cumulative_logit Phase 18" --limit 20 --json number,title,state,url,labels
git diff --check
Rscript tools/codex-checkpoint.R --goal "Phase 18 ordinal fixed-effect artifacts slices 1309-1318" --next "split or stage the dirty Phase 18 tree into reviewable PR lanes"
```

All listed checks passed. The stale-wording scan returned no current text
saying the ordinal DGP, smoke, or grid lane still needs to be added. The
overlapping open-issue search returned `[]`. The recovery checkpoint was
written to `docs/dev-log/recovery-checkpoints/2026-05-25-082709-codex-checkpoint.md`.

## Tests Of The Tests

The new tests check that the DGP creates ordered factors with stored truth,
fits the smoke grid, returns fixed-effect Wald artifacts, keeps cutpoints
ordered, writes repeatable grid artifacts, rejects overwrite without explicit
permission, and rejects malformed category counts, cutpoint patterns, sample
sizes, and output directories.

## Consistency Audit

`NEWS.md`, `ROADMAP.md`, the Phase 18 programme, the core-family completion
map, and `inst/sim/README.md` now say the fixed-effect ordinal artifact lane
exists. The first-wave summary runner, Actions entrypoint, workflow matrix, and
focused tests all include `ordinal_fixed_effect`.

A static follow-up also updated the ordinal ADEMP sheet, pre-simulation
readiness matrix, validation-debt register, and roadmap wording so they no
longer imply that the fixed-effect ordinal DGP/grid artifacts are future work
or that the fixed-effect ordinal family lacks implementation evidence.

## GitHub Issue Maintenance

The open-issue search for `"ordinal cumulative_logit Phase 18"` returned no
issues. No issue was opened or changed from this dirty tree.

## What Did Not Go Smoothly

The crash left the focused ordinal test file with a missing closing `})`.
After that was fixed, the first DGP test exposed that the shared
`phase18_named_pair()` helper assumes two coefficients. The ordinal lane only
has the identifiable `x` slope, so a small ordinal-specific slope validator now
keeps the no-intercept convention explicit.

## Team Learning

Ordinal artifact code should not borrow two-coefficient helpers from
location-scale lanes. The cumulative-logit intercept/cutpoint identifiability
choice needs a lane-specific helper so future edits do not accidentally add a
free ordinal intercept.

## Known Limitations

This is a fixed-effect location-only artifact lane. Ordinal random effects,
ordinal scale or discrimination formulas, cutpoint-specific predictors,
known-covariance ordinal models, structured ordinal effects, bivariate ordinal
models, and mixed-response ordinal models remain unsupported or planned.

## Next Actions

Split or stage the dirty Phase 18 tree into reviewable PR lanes before adding
new likelihood surfaces. If the team continues the common-family sequence, the
next design decision is whether to run larger formal grids for the existing
non-Gaussian lanes or start the skew-normal implementation gate.
