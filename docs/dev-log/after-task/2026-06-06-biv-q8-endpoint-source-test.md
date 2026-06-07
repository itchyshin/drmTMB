# After Task: Bivariate q8 all-endpoint source test

## Goal

Retry the ordinary bivariate Gaussian q8 all-endpoint route as its own narrow
slice, separate from the same-response q2 branch that previously removed q8 as
a scope leak.

## Implemented

`biv_gaussian()` now accepts a matching all-four labelled one-slope endpoint
block when `mu1`, `mu2`, `sigma1`, and `sigma2` all use the same term, for
example `(1 + x | p | id)`. The fitted model reports eight endpoint SDs and 28
latent group-level correlations through the existing covariance-block
extractors and diagnostics.

The Phase 18 registry row `bivariate_gaussian_q8_endpoint` is now
`ready_source_test` with no Actions task. That makes the fitted source surface
visible while keeping dispatch, recovery, coverage, and power claims closed.

## Mathematical Contract

The fitted first slice is:

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

and `u_j ~ MVN(0, Sigma_q8)`. The eight SDs are direct fitted endpoints; the
28 correlations are derived unstructured-correlation rows with unavailable
derived intervals. Residual `rho12` remains a row-level residual coscale, not a
group-level covariance parameter.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-biv-gaussian.R`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `README.md`, `NEWS.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/45-cross-dpar-correlation-gate.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/67-sdstar-p8-poisson-q1.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/151-phase6c-random-slope-tutorial-ledger.md`
- `docs/design/155-bivariate-residual-scale-random-slope-gate.md`
- `docs/design/157-capability-completion-worklist.md`
- `inst/sim/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-06-biv-q8-endpoint-source-test.md`

## Checks Run

- `air format R/drmTMB.R inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-biv-gaussian.R tests/testthat/test-phase18-structured-workflow-registry.R`
  completed without output.
- `Rscript -e "devtools::test(filter = '^biv-gaussian$')"`: 935 passes, no
  failures, warnings, or skips in 55.3s.
- `Rscript -e "devtools::test(filter = 'phase18-structured-workflow-registry')"`:
  322 passes, no failures, warnings, or skips in 2.4s.
- `Rscript -e "devtools::test()"`: 10,033 passes, no failures, warnings, or
  skips in 951.0s.
- `Rscript -e "pkgdown::check_pkgdown()"`: `No problems found`.
- `Rscript -e "pkgdown::build_site()"`: completed successfully and rebuilt
  `pkgdown-site`; it emitted the local environment warning that `glmmTMB` was
  built against TMB 1.9.17 while the current TMB is 1.9.21.
- `Rscript -e "devtools::check()"`: `Status: OK`, 0 errors, 0 warnings,
  0 notes in 8m 58.3s.
- `git diff --check` passed.
- The stale-scope scan recorded in `docs/dev-log/check-log.md` found only
  intended boundary rows for q8 artifact lanes, recovery, coverage, power, or
  non-Gaussian q8.

## Tests Of The Tests

The q8 success test checks the fitted object class, finite objective,
optimizer/diagnostic status, q8 block dimensions, member ordering, SD names,
28 correlation names, `corpairs()`, `summary()$covariance`, derived
`profile_targets()` status, prediction contributions, random-effect storage,
and deterministic simulation output.

The malformed-input tests still reject mismatched all-four coefficient sets and
slope-only all-four endpoint requests. The registry tests now check that q8 is
`ready_source_test`, has no Actions task, and is reported as no-dispatch rather
than accidentally entering the Phase 18 random-slope workflow.

## Consistency Audit

README, NEWS, ROADMAP, formula grammar, the double-hierarchical endpoint note,
the readiness matrix, the validation-debt register, the cross-dpar gate, the
q8 gate, the structured workflow registry docs, the Phase 18 simulation docs,
and the Phase 6c tutorial ledger now separate:

- fitted source-level q8 support;
- direct q8 SD targets;
- derived-unavailable q8 correlation intervals;
- absent q8 dispatch/recovery/coverage/power evidence;
- unsupported q8 neighbours such as structured q8, non-Gaussian q8,
  predictor-dependent q8 `corpair()` regressions, and random `rho12`.

## GitHub Issue Maintenance

Open issue #5 is the direct covariance-block issue for this endpoint. Issue
#491 lists q8 as a local-R work-queue item, and #33 tracks remaining random
slope work. No duplicate issue was opened. The q8 source-test/no-dispatch result
was posted to #5:
<https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4641128537>.

## What Did Not Go Smoothly

The first combined focused test run failed after the bivariate contexts passed
because `test-phase18-structured-workflow-registry.R` had a fixed random-slope
plan count of 16. Moving q8 from `design_only` to `ready_source_test` correctly
made that count 17. The test was updated and the registry context passed on
rerun.

The full pkgdown build completed, but article rendering emitted the local
environment warning that `glmmTMB` was built against TMB 1.9.17 while the
current TMB is 1.9.21. The warning did not become a pkgdown or R CMD check
failure.

## Team Learning

For q8-like endpoint work, the registry status needs to move with the source
code. A fitted source route with no artifact lane should be `ready_source_test`
and no-dispatch, not `design_only`; otherwise the docs force the next audit to
choose between hiding fitted code and overclaiming simulation evidence.

## Known Limitations

This slice is source-tested only. It does not add a Phase 18 Actions task,
smoke grid, recovery grid, coverage result, power result, q8 tutorial example,
structured q8 route, non-Gaussian q8 route, random `rho12`, or
predictor-dependent q8 `corpair()` regression.

`devtools::document()` was not run because no roxygen comments changed.

## Next Actions

Open the q8 smoke/recovery artifact lane, then audit convergence, Hessian,
boundary, interval status, and MCSE before any q8 power-grid or tutorial claim.
