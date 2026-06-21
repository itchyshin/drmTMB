# After Task: Q8 Diagnostic Presets And Skew-Normal Recovery

## Goal

Complete the next two capability slices after the Q8-1/SN-1 closeout: add a
bounded q8 diagnostic condition grid for the ordinary bivariate Gaussian
all-endpoint route, and add CRAN-safe deterministic recovery and false-positive
source tests for the fixed-effect `skew_normal()` first slice.

## Implemented

`phase18_biv_gaussian_q8_endpoint_diagnostic_conditions()` now returns a
12-row diagnostic grid with replication, endpoint-SD ratio, residual `rho12`,
and latent-correlation preset slices. The corresponding source test checks the
grid shape, stable diagnostic IDs, positive-definite correlation cells,
negative/zero/positive `rho12`, weak/baseline/strong endpoint-SD ordering, and
compatibility with the existing q8 DGP cell runner.

`tests/testthat/test-skew-normal-location-scale.R` now uses deterministic
quasi-random normal scores to test fixed-effect skew-normal recovery without a
Monte Carlo loop. The tests check negative and positive skew recovery, weak and
strong skew separation, factor and correlated scale predictors, `nu ~ w`
direction, and a Gaussian-limit false-positive cell where intercept-only `nu`
stays near zero.

## Mathematical Contract

No likelihood parameterization changed. The skew-normal contract remains public
`mu = E[y]`, public `sigma = SD[y]`, and `nu` as residual slant, transformed
internally to native `xi`, `omega`, and `alpha = nu`. The q8 work only adds
diagnostic condition rows around the existing ordinary Gaussian all-endpoint
covariance block; it does not add coverage, power, or interval claims.

## Files Changed

- `inst/sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R`
- `tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R`
- `tests/testthat/test-skew-normal-location-scale.R`
- `NEWS.md`, `ROADMAP.md`, `docs/design/02-family-registry.md`,
  `docs/design/03-likelihoods.md`,
  `docs/design/37-worked-example-inventory.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`,
  `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`,
  `docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md`,
  `docs/design/157-capability-completion-worklist.md`, and
  `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla -e 'devtools::test(filter = "skew-normal|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
air format inst/sim/dgp/sim_dgp_biv_gaussian_q8_endpoint.R tests/testthat/test-phase18-biv-gaussian-q8-endpoint.R tests/testthat/test-skew-normal-location-scale.R
git diff --check
rg -n 'no fitted skew-family likelihood|Keep skew examples as design-only|Positive and negative skew recovery grids|q8.*coverage.*power.*ready|q8.*power-ready|skew_normal\(\).*random effects.*implemented|skew\(id\).*implemented' NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes/source-map.Rmd --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**'
gh issue list --repo itchyshin/drmTMB --state open --search "skew-normal OR skew_normal OR q8 endpoint diagnostic" --limit 20 --json number,title,state,url,labels
```

The focused test run passed after formatting. `git diff --check` passed. The
stale-status scan returned only intended current-boundary rows: q8
coverage/power remains not ready, and skew-normal random effects remain
unsupported.

## Tests Of The Tests

The q8 diagnostic test exercises malformed-preset rejection and checks that
all latent-correlation preset rows define positive-definite q8 correlation
matrices before they can enter a follow-up diagnostic run.

The skew-normal tests are deterministic and compare fitted estimates with
known generated values on the public `mu`/`sigma`/`nu` scale. They include a
Gaussian false-positive cell so the implemented fixed-effect lane does not
silently use `nu` to explain symmetric residuals in this small source-test
setting.

## Consistency Audit

NEWS, ROADMAP, the likelihood design note, the family registry, the
worked-example inventory, the pre-simulation readiness matrix, the capability
worklist, and known limitations now distinguish source-test evidence from
formal operating-characteristic evidence. The public boundary is still:
`skew_normal()` is fixed-effect and univariate; q8 is diagnostic-only for
coverage and power.

## GitHub Issue Maintenance

The issue scan found existing open coverage in #3 for skew-normal, #5 and #33
for individual-difference covariance and remaining bivariate/structured slopes,
#59 for Phase 18 simulation infrastructure, #61 and #342 for release gates, and
#491 for the broad local-R queue. No new issue or duplicate comment was needed
for this local source-test slice.

## What Did Not Go Smoothly

The global skill path listed by the session was stale for `add-simulation-test`;
the project-local `.agents/skills/add-simulation-test/SKILL.md` path was the
usable one. `tests/testthat/test-skew-normal-location-scale.R` is also still
untracked in this dirty worktree, so ordinary `git diff` does not display its
changes. Future handoffs should mention that file explicitly until it is staged
or committed.

## Team Learning

For skew-normal, deterministic quasi-random source tests are a better CRAN-safe
slice than a small stochastic recovery loop. They give repeatable evidence for
the first fixed-effect lane while leaving formal bias, RMSE, convergence,
Hessian, runtime, and heteroscedasticity false-positive grids for the simulation
programme.

For q8, condition presets are useful only if the docs keep saying diagnostic.
The same grid that helps future stress tests must not be read as power-grid
readiness.

## Known Limitations

Q8 coverage, q8 power, and q8 interval-readiness remain unavailable. The
2026-06-07 q8 audit is still the live evidence boundary: weak convergence,
zero positive-Hessian rate, two leading-minor failures, and no usable Wald
intervals.

`skew_normal()` still has no formal DGP/runner/grid artifacts, external
comparator lane, heteroscedasticity/outlier false-positive programme, random
effects, structured effects, known sampling covariance, bivariate route,
residual `rho12`, or latent `skew(id)` support.

## Next Actions

The next q8 slice should use the diagnostic presets to run a small stress audit
that reports convergence, Hessian, boundary, and correlation-conditioning
rates by preset, not coverage. The next skew-normal slice should add a tiny
diagnostic table or example around `check_drm()` and fitted `nu`, then decide
whether a formal fixed-effect DGP/runner lane is worth opening before external
comparators.
