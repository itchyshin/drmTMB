# After Task: Skew-Normal Fixed-Effect Artifact Lane

## Goal

Make the fitted fixed-effect `skew_normal()` slice useful beyond source tests
by adding a repeatable Phase 18 DGP, fit summariser, smoke runner, summary
helper, grid writer, manual Actions task, and focused tests.

## Implemented

The new `skew_normal_fixed_effect` lane fits
`bf(y ~ x, sigma ~ z, nu ~ w), family = skew_normal()` and records
replicate-level coefficient truth, estimates, standard errors, convergence,
Hessian status, warnings, Wald intervals, optional profile intervals, optional
parametric-bootstrap intervals, interval diagnostics, and CSV artifacts. The
default artifact grid uses `n = 720` and `1440` because stochastic recovery of
residual slant is sample-size dependent.

## Mathematical Contract

The DGP uses the public moment parameterization. For each observation,
`mu_i` is the response mean, `sigma_i` is the response standard deviation, and
`nu_i` is residual slant. Internally the DGP computes
`delta_i = nu_i / sqrt(1 + nu_i^2)`, draws
`Z_i = delta_i |U_i| + sqrt(1 - delta_i^2) V_i`, recenters and rescales
`Z_i`, and sets `y_i = mu_i + sigma_i Z_i^*`. This matches the fitted
likelihood contract: users see public `mu`, public `sigma`, and identity-link
`nu`; the native skew-normal `xi`, `omega`, and `alpha = nu` remain internal.

## Files Changed

- `inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R`
- `inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R`
- `inst/sim/run/sim_run_skew_normal_fixed_effect_smoke.R`
- `inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R`
- `inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `.github/workflows/phase18-simulation-grid.yaml`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `tests/testthat/test-phase18-skew-normal-fixed-effect.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `NEWS.md`, `ROADMAP.md`, `inst/sim/README.md`, `docs/design/`, `docs/dev-log/known-limitations.md`, `vignettes/model-map.Rmd`, and `vignettes/robust-student.Rmd`

## Checks Run

```sh
Rscript --vanilla -e 'devtools::test(filter = "phase18-skew-normal-fixed-effect", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "phase18-actions-runner", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "skew-normal|phase18-skew-normal-fixed-effect|phase18-actions-runner", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "phase18-structured-workflow-registry", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "phase18-actions-runner", reporter = "summary")'
Rscript --vanilla -e 'pkgdown::build_article("robust-student"); pkgdown::build_article("model-map"); cat("articles_ok\n")'
Rscript --vanilla -e 'pkgdown::check_pkgdown(); cat("pkgdown_check_ok\n")'
git diff --check
rg -n 'Planned, not fitted yet|Use this planned syntax|not a fitted option today|skew-family likelihood exists|skew-normal.*not yet fitted|skew-normal.*not implemented|skew-normal.*remain design|skew_normal\(\) \(planned\)' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes inst/sim .github --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/check-log.md'
rg -n '^(<<<<<<<|=======|>>>>>>>)' .github/workflows/phase18-simulation-grid.yaml NEWS.md ROADMAP.md docs/design/02-family-registry.md docs/design/123-phase-18-skew-normal-source-map-slices-1519-1538.md docs/design/125-phase-18-next-two-team-slices-1619-1718.md docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md docs/design/157-capability-completion-worklist.md docs/design/158-phase-19-comparator-matrix.md docs/design/34-validation-debt-register.md docs/design/37-worked-example-inventory.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/known-limitations.md inst/sim/README.md inst/sim/registry/phase18_structured_workflow_registry.csv inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-actions-runner.R vignettes/model-map.Rmd vignettes/robust-student.Rmd inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R inst/sim/fit/sim_summarise_skew_normal_fixed_effect.R inst/sim/run/sim_run_skew_normal_fixed_effect_smoke.R inst/sim/run/sim_summary_skew_normal_fixed_effect_smoke.R inst/sim/run/sim_write_skew_normal_fixed_effect_grid.R tests/testthat/test-phase18-skew-normal-fixed-effect.R
```

Results:

- Focused skew-normal artifact tests passed.
- Focused Actions runner tests passed.
- Combined skew-normal source, artifact, and Actions tests passed.
- `pkgdown::build_article()` rendered `robust-student` and `model-map`, and
  rendered scans found the updated skew-normal artifact wording.
- `pkgdown::check_pkgdown()` reported no problems and printed
  `pkgdown_check_ok`.
- `git diff --check` reported no whitespace problems.
- The skew-normal stale-status scan returned only unrelated phylo+spatial
  planned examples.
- The touched-file conflict-marker scan returned no matches.
- PR #517 exposed one registry-validator gap on macOS CI: the fallback
  structured-workflow Actions-task list did not include
  `skew_normal_fixed_effect`. Adding that task and updating the family-surface
  count fixtures made the focused structured-workflow-registry and
  Actions-runner tests pass locally.

## Tests Of The Tests

The new tests check the DGP moment contract by reconstructing the public mean
and SD from native skew-normal parameters, run a real `drmTMB()` fit through the
resumable replicate runner, verify resume behaviour, request profile and
parametric-bootstrap interval artifacts, write and read CSV artifacts, reject a
malformed cell, and exercise the nested-parallel guard. The Actions tests check
both dry-run option parsing and exact source-path dispatch for
`skew_normal_fixed_effect`.

## Consistency Audit

The implemented claim now agrees across the Phase 18 registry, Actions runner,
structured-workflow registry validator, workflow choices, simulation README,
family registry, readiness matrix, capability worklist, comparator matrix,
roadmap, known limitations, NEWS, and the two touched vignettes. Historical
skew-normal design notes now carry supersession text instead of current
planned-only wording.

## GitHub Issue Maintenance

Issue #3 remains open. This slice advances the fixed-effect artifact-depth
part of that issue, but it does not close the larger skew-normal programme:
formal high-replicate operating characteristics, external fitted-model
comparators, random effects, known covariance, structured effects, bivariate
skew-normal models, residual `rho12`, latent `skew(id)`, and alias grammar
remain future work.

## What Did Not Go Smoothly

The first `n = 500` stochastic summary cell produced a weak `nu` estimate and
a profile warning-ledger row. That was not a model-run failure, but it showed
that shape recovery is sample-size dependent. The lane now uses `n = 720` for
focused tests and `n = 720`/`1440` for the default grid, and the tests check
for fit errors separately from warning-ledger rows.

## Team Learning

Skewness evidence should not be judged from very small stochastic cells. For
this family, small tests should check plumbing and moment contracts, while
useful recovery claims need moderate-to-large sample sizes and MCSE-aware
replicate counts.

## Known Limitations

This is repeatable smoke/grid infrastructure, not a formal 500- or
1000-replicate operating-characteristic result. It does not add random effects,
known covariance, structured effects, bivariate skew-normal models, residual
`rho12`, latent `skew(id)`, skew-t, or alias grammar.

## Next Actions

Run a deliberately sized skew-normal formal pilot, likely 200 replicates first
and 500-1000 replicates only after the pilot confirms convergence, Hessian, and
interval behaviour. Then decide whether an external comparator can match the
public moment parameterization honestly enough to include in Phase 19.
