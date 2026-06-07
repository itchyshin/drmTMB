# After Task: Bivariate q8 endpoint artifact lane

## Goal

Promote the ordinary bivariate Gaussian q8 all-endpoint route from
source-test/no-dispatch status to opt-in Phase 18 smoke and diagnostic recovery
artifact dispatch, while keeping q8 coverage, power, and richer q8 variants
closed.

## Implemented

The Phase 18 workflow now has two q8 endpoint tasks:
`biv_gaussian_q8_endpoint` for a smoke grid and
`biv_gaussian_q8_endpoint_recovery` for diagnostic recovery artifacts.

The new artifact stack adds a seeded q8 DGP, fit summariser, smoke runner,
smoke summary, recovery summary, smoke grid writer, and recovery grid writer.
The recovery summary reports bias, RMSE, empirical SE, MCSE, manifests,
failures, Wald interval rows, coverage tables with zero usable intervals, and
interval-evidence diagnostics. Because the q8 runner uses `se = FALSE`, Wald,
profile, and bootstrap intervals are recorded unavailable rather than promoted.

The structured workflow registry now marks `bivariate_gaussian_q8_endpoint` as
`ready_grid` with `existing_actions_task = "biv_gaussian_q8_endpoint"` and adds
`bivariate_gaussian_q8_endpoint_recovery` with
`existing_actions_task = "biv_gaussian_q8_endpoint_recovery"`. The q8
preflight gate now checks artifact readiness, endpoint count, correlation
count, and the supervision boundary.

## Mathematical Contract

The fitted model remains the same first q8 slice:

```r
bf(
  mu1 = y1 ~ x + (1 + x | p | id),
  mu2 = y2 ~ x + (1 + x | p | id),
  sigma1 = ~ x + (1 + x | p | id),
  sigma2 = ~ x + (1 + x | p | id),
  rho12 = ~ 1
)
```

For each group `j`, the latent endpoint vector is:

```text
u_j = [
  mu1:(Intercept), mu1:x,
  mu2:(Intercept), mu2:x,
  sigma1:(Intercept), sigma1:x,
  sigma2:(Intercept), sigma2:x
]'
```

with `u_j ~ MVN(0, Sigma_q8)`. The eight SDs are direct fitted targets. The
28 group-level correlations are derived covariance-block summaries with
unavailable intervals. Residual `rho12` remains a row-level residual coscale,
not a group-level correlation.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `inst/sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R`
- `inst/sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R`
- `inst/sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_q8_endpoint_smoke.R`
- `inst/sim/run/sim_summary_biv_gaussian_q8_endpoint_recovery.R`
- `inst/sim/run/sim_write_biv_gaussian_q8_endpoint_grid.R`
- `inst/sim/run/sim_write_biv_gaussian_q8_endpoint_recovery_grid.R`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R`
- `tests/testthat/test-phase18-biv-gaussian-q8-endpoint-recovery.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `README.md`, `NEWS.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/45-cross-dpar-correlation-gate.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/61-structural-parity-slices-83-140.md`
- `docs/design/63-implementation-map-slices-311-325.md`
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/design/145-phase6c-bivariate-slope-evidence-gate.md`
- `docs/design/148-phase6c-random-slope-simulation-plan.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/151-phase6c-random-slope-tutorial-ledger.md`
- `docs/design/155-bivariate-residual-scale-random-slope-gate.md`
- `docs/design/157-capability-completion-worklist.md`
- `inst/sim/README.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/implementation-map.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-07-biv-q8-endpoint-artifact-lane.md`

## Checks Run

- `air format inst/sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R inst/sim/fit/sim_summarise_biv_gaussian_q8_endpoint.R inst/sim/run/sim_run_biv_gaussian_q8_endpoint_smoke.R inst/sim/run/sim_summary_biv_gaussian_q8_endpoint_smoke.R inst/sim/run/sim_summary_biv_gaussian_q8_endpoint_recovery.R inst/sim/run/sim_write_biv_gaussian_q8_endpoint_grid.R inst/sim/run/sim_write_biv_gaussian_q8_endpoint_recovery_grid.R inst/sim/run/sim_phase18_structured_workflow_registry.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R tests/testthat/test-phase18-biv-gaussian-q8-endpoint-recovery.R tests/testthat/test-phase18-actions-runner.R tests/testthat/test-phase18-structured-workflow-registry.R`
  completed without output.
- `git diff --check` passed.
- `Rscript -e "devtools::test(filter = 'phase18-biv-gaussian-q8-endpoint')"`:
  75 passes, no failures, warnings, or skips in 50.4s.
- `Rscript -e "devtools::test(filter = 'phase18-actions-runner|phase18-structured-workflow-registry')"`:
  578 passes, no failures, warnings, or skips in 19.7s.
- `Rscript -e "devtools::test()"`: 10,139 passes, no failures, warnings, or
  skips in 1107.2s.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: completed
  successfully and rebuilt `pkgdown-site/`. During article rendering it emitted
  the local TMB/glmmTMB version-mismatch warning: `glmmTMB was built with TMB
  package version 1.9.17; current TMB package version is 1.9.21`.
- `Rscript -e "devtools::check()"`: 0 errors, 0 warnings, and 0 notes in 9m
  37.3s.

## Tests Of The Tests

The q8 smoke tests check deterministic DGP output, truth naming, 45 estimand
rows, q8 parameter ordering, manifest output, failure-table output, artifact
overwrite protection, and malformed DGP inputs.

The q8 recovery tests check bias/RMSE/MCSE columns, two successful default-size
replicates, interval unavailability, interval failure ledgers, and multi-table
artifact writing.

The Actions tests check dry-run acceptance, dependency sourcing, writer
dispatch, output RDS metadata, and the new q8 task path lists. The registry
tests check the new 18-row random-slope plan, q8 ready-grid status, recovery
row presence, q8 diagnostic role, and zero missing Actions tasks.

The first recovery test attempt used `n_id = 24`, `n_each = 6`; one of two
replicates failed with `the leading minor of order 8 is not positive`. The test
fixture now uses the default q8 recovery size, `n_id = 48`, `n_each = 10`,
which produced two `ok` replicates and finite MCSE in a direct probe.

## Consistency Audit

The status inventory was updated in README, NEWS, ROADMAP, formula grammar,
double-hierarchical endpoint notes, validation debt, readiness matrix,
cross-dpar gate, q8 gate, structured workflow registry docs, Phase 18
simulation docs, structural slope map, capability worklist, and `inst/sim`
README.

The prose pass used the project-local `prose-style-review` skill. The live
claim is now consistent: q8 is fitted and diagnostic-artifact ready; q8
correlations remain derived-interval-unavailable; q8 coverage, q8 power,
predictor-dependent q8 `corpair()` regressions, random `rho12`, structured q8,
and non-Gaussian q8 remain closed.

The after-task audit found stale public-vignette and design-note wording that
still treated all p8/q8 endpoint covariance as planned. The repaired wording
now says the first ordinary q8 all-endpoint block has diagnostic smoke/recovery
artifacts, while broader p8/q8 variants, q8 coverage, and q8 power remain
planned.

Stale scans:

```sh
rg -n "q8.*(no Actions task|no Phase 18 dispatch|no artifact|no-dispatch|no dispatch|artifact/recovery evidence remains|source tests but no|source-tested but|ready_source_test|held_no_dispatch|no Actions|no artifact lane)|bivariate_gaussian_q8_endpoint.*(ready_source_test|held_no_dispatch|no Actions task|existing_actions_task.*none)" README.md NEWS.md ROADMAP.md docs inst/sim tests R .github vignettes pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'
```

This returned no matches.

```sh
rg -n "q8 artifact/recovery|q8 recovery/coverage|q8 source-tested|source-tested q8|q8 all-endpoint route is source|q8 currently" README.md NEWS.md ROADMAP.md docs inst/sim tests R .github vignettes pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'
```

This returned no matches.

```sh
rg -n "all-four p8/q8|p8/q8 endpoint covariance|p8/q8 all-endpoint|q8 endpoint slopes remain planned|all-four q8 endpoint slopes remain planned|future all-endpoint location-scale slope structures, not a fitted|but no artifact or recovery lane" README.md NEWS.md ROADMAP.md docs inst/sim tests R .github vignettes pkgdown-site --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'
```

This returned only intended current-boundary lines in
`vignettes/implementation-map.Rmd`, its rendered pkgdown article, and
`docs/design/67-sdstar-p8-poisson-q1.md`.

## GitHub Issue Maintenance

Fresh `gh issue view` checks confirmed that #5, #33, and #491 are open.
Issue #5 is the direct covariance-block issue, #33 tracks remaining
random-slope work, and #491 is the local-R work queue.

The GitHub connector could read but not write comments for this repository
(`403 Resource not accessible by integration`). The authenticated `gh` CLI
posted the q8 artifact-lane status to #5:
<https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4642141391>.

## What Did Not Go Smoothly

Two stale registry tests still expected q8 no-dispatch status and fixed counts
from the previous source-test slice. Those expectations were wrong after the
registry gained q8 smoke and recovery rows, so the tests now assert the new
ready-grid state and the 18-row random-slope plan.

The first tiny recovery fixture was too underpowered for stable q8 fitting. It
was useful as a test failure because it showed that the q8 recovery test should
exercise the default diagnostic lane rather than an artificially small cell.

## Team Learning

For q8-style high-dimensional covariance work, the registry should distinguish
three states explicitly: fitted source route, diagnostic artifact route, and
coverage/power evidence. A recovery writer that runs with `se = FALSE` should
emit interval-unavailability tables so later audits do not mistake missing
intervals for omitted bookkeeping.

## Known Limitations

This slice does not provide q8 coverage, q8 power, q8 tutorial examples,
predictor-dependent q8 `corpair()` regressions, random effects in `rho12`,
structured q8, non-Gaussian q8, or validated intervals for the 28 q8
correlations.

`devtools::document()` was not run because no roxygen comments changed.

## Next Actions

Audit a deliberately sized q8 recovery run before any status promotion. The
next useful evidence gate should focus on convergence, Hessian status,
boundary behaviour, runtime, MCSE stability, and whether any interval method is
credible for direct q8 SDs or the 28 derived q8 correlations.
