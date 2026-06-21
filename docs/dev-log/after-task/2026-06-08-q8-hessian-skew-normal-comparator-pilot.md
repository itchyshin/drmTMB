# After Task: Q8 Hessian And Skew-Normal Comparator Pilot

## Goal

Finish the next evidence slice after the q8 stress audit and fixed-effect
skew-normal pilot: check whether q8 can support Hessian-based inference in the
hard rows, check whether simple fixed-effect skew-normal fits can produce
positive Hessians, synchronize active status docs, and update the issue ledgers.

## Implemented

The q8 lane now has three local Hessian artifacts:

- `docs/dev-log/simulation-artifacts/2026-06-08-q8-hessian-probe/`
- `docs/dev-log/simulation-artifacts/2026-06-08-q8-hessian-probe-careful/`
- `docs/dev-log/simulation-artifacts/2026-06-08-q8-hessian-probe-comparison/`

The q8 probe reran the two diagnostic stress rows that had converged under
`se = FALSE`: the high latent-correlation row and the weak endpoint-SD-ratio
row. Both `se = TRUE` strategies, baseline and `optimizer_preset = "careful"`,
made both rows nonconverged, reported `pdHess = FALSE`, emitted
`NaNs produced`, and produced ill-conditioned q8 correlation matrices.

The skew-normal lane now has a fixed-effect Hessian/comparator pilot artifact:

- `docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-hessian-comparator-pilot/`

The pilot fit eight deliberately simple fixed-effect models with `se = TRUE`
and `optimizer_preset = "careful"`: constant-scale left/symmetric/right cells,
heteroscedastic left/symmetric/right cells, and a predictor-varying true-slant
cell fit as both `nu ~ 1` and `nu ~ w`. All 8 fits converged with
`pdHess = TRUE`.

Two new design notes record the decisions:

- `docs/design/163-phase-18-q8-hessian-start-rescue.md`
- `docs/design/164-phase-18-skew-normal-hessian-comparator-pilot.md`

## Mathematical Contract

No formula grammar or likelihood parameterization changed. Q8 remains the
ordinary bivariate Gaussian all-endpoint block with matching
`(1 + x | p | id)` terms in `mu1`, `mu2`, `sigma1`, and `sigma2`; residual
`rho12` remains a separate row-level residual coscale parameter.

Skew-normal remains the univariate fixed-effect `mu`/`sigma`/`nu` route. Public
`mu` is `E[y]`, public `sigma` is `SD[y]`, and `nu` is residual slant.
Random effects, structured effects, known sampling covariance, bivariate
skew-normal, residual `rho12`, skew-t, and latent `skew(id)` remain outside the
admitted surface.

## Evidence

The q8 `se = TRUE` diagnostic summaries reported 0/2 convergence, 0/2
positive-Hessian fits, warning rate 1, and optimizer-ok rate 0 under both the
baseline 800-iteration strategy and the careful 1000-iteration strategy. The
high latent-correlation row had maximum fitted absolute correlation about
0.965 and condition number about 2.38e10. The weak-SD-ratio row had maximum
fitted absolute correlation about 0.982 and condition number about 2.60e9.

This also corrects the interpretation of the earlier stress audit: that run
used `se = FALSE`, so a `pdHess_rate` of zero means Hessian evidence was not
computed, not that `TMB::sdreport()` necessarily computed a failed Hessian.

The skew-normal Hessian pilot reported 8/8 convergence, 8/8 `pdHess = TRUE`,
and no warnings. The estimates still support caution: symmetric cells fit
nonzero slant, and the `nu ~ w` cell recovered the sign of the true slope but
under-recovered its magnitude. The local library did not have `sn` or
`gamlss`, so external comparator fits were not run.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/163-phase-18-q8-hessian-start-rescue.md`
- `docs/design/164-phase-18-skew-normal-hessian-comparator-pilot.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `inst/sim/README.md`

## Checks Run

```sh
air format NEWS.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/design/163-phase-18-q8-hessian-start-rescue.md docs/design/164-phase-18-skew-normal-hessian-comparator-pilot.md docs/dev-log/known-limitations.md inst/sim/README.md
air format README.md docs/design/34-validation-debt-register.md
Rscript --vanilla -e 'devtools::test(filter = "phase18-skew-normal-fixed-effect|skew-normal-location-scale|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
rg -n 'q8.*(coverage|power|interval).*(ready|passed|complete|supported)|q8.*positive-Hessian|0/5 positive-Hessian|0/9 positive-Hessian|skew_normal.*(random effects|structured effects|bivariate|rho12).*(implemented|supported|ready)|skew-normal.*formal recovery.*(ready|complete|passed)|skew_normal.*external comparator.*(passed|complete|supported)' NEWS.md ROADMAP.md README.md docs/design docs/dev-log/known-limitations.md inst/sim vignettes R tests --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!docs/design/archive/**'
git diff --check
```

The focused test run passed. `git diff --check` passed. The stale-claim scan
returned intended boundary rows only: q8 remains closed for coverage, power,
and interval readiness; skew-normal random or structured effects remain
unsupported; and the remaining positive-Hessian wording is either same-response
q2 history or the new simple fixed-effect skew-normal Hessian evidence.

## GitHub Issue Maintenance

- Q8 issue #5 updated:
  https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4653465280
- Skew-normal issue #3 updated:
  https://github.com/itchyshin/drmTMB/issues/3#issuecomment-4653465303

## What Did Not Go Smoothly

The q8 `se = TRUE` result closed off the tempting quick path. A careful
optimizer alone did not rescue the hard q8 rows, so the next q8 task needs an
actual start hook or internal start-mapping path rather than another larger
grid.

The skew-normal comparator part could only check local package availability.
Neither `sn` nor `gamlss` was installed, so the next comparator slice must start
with scale mapping and optional dependency setup before fitting external
models.

## Known Limitations

Q8 remains fitted and diagnostic-artifact ready only. It is not interval-ready,
coverage-ready, or power-ready.

Fixed-effect `skew_normal()` has a better working-status signal now because
simple `se = TRUE` fits can return `pdHess = TRUE`. It still lacks a completed
formal recovery grid, calibrated false-positive rates, external comparator
evidence, examples, runtime grids, random effects, structured effects,
bivariate support, residual `rho12`, and latent `skew(id)`.

## Next Actions

For q8, implement a start/Hessian rescue gate: either a public/internal start
contract or a q8-specific staged-start helper that maps q4/q6 fits into q8
starts and compares cold versus staged fits on identical seeds.

For skew-normal, write the comparator scale map for `sn` and `gamlss`, then
run a formal grid that starts with simple `sigma ~ 1`, `nu ~ 1` cells before
adding heteroscedastic and predictor-varying slant stress tiers.
