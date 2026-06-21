# After Task: Q8 Start Override And glmmTMB Comparator Cleanup

## Goal

Clean up the remaining local foundations after the q8 start-hook preflight and
skew-normal comparator scale map: implement the private q8 start-override
validator, keep the public start API closed, and run the first simple
`glmmTMB` skew-normal comparator smoke.

## Implemented

`drmTMB()` now calls private `drm_apply_start_override()` after
`add_covariance_probe_parameter(spec)` and before `TMB::MakeADFun()`. The call
is a no-op in the ordinary user path, so no public `start =`, `warm_start`, or
`map` argument was added. The helper accepts named internal TMB start blocks,
rejects malformed overrides, preserves mapped slots, and records
`spec$start_override` metadata when an override is supplied.

The skew-normal comparator lane now has one simple external smoke artifact:

```text
docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-glmmtmb-comparator-smoke/
```

On one fixed-effect `sigma ~ 1`, `nu ~ 1` simulated data set,
`glmmTMB::skewnormal()` matched the local `drmTMB` estimates when started with
nonzero `psi` values. The default `glmmTMB` start converged but stayed at the
symmetric shape boundary, with shape about `2e-14`.

## Mathematical Contract

No likelihood parameterization changed. Q8 remains the ordinary bivariate
Gaussian all-endpoint block with eight endpoint SDs and 28 group-level
correlations. Residual `rho12` remains the row-level residual coscale
parameter.

Skew-normal remains the univariate fixed-effect `mu`/`sigma`/`nu` route. Public
`mu` is `E[y]`, public `sigma` is `SD[y]`, and `nu` is the Azzalini slant
parameter. The `glmmTMB` smoke is a same-scale comparator only for the simple
constant-shape cell and only when nonzero shape starts are recorded.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-optimizer-contract.R`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/158-phase-19-comparator-matrix.md`
- `docs/design/165-phase-18-q8-start-hook-preflight.md`
- `docs/design/166-phase-18-skew-normal-comparator-scale-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `inst/sim/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-glmmtmb-comparator-smoke/`

## Checks Run

```sh
air format R/drmTMB.R tests/testthat/test-optimizer-contract.R docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/design/158-phase-19-comparator-matrix.md docs/design/165-phase-18-q8-start-hook-preflight.md docs/design/166-phase-18-skew-normal-comparator-scale-map.md docs/dev-log/known-limitations.md inst/sim/README.md ROADMAP.md
Rscript --vanilla -e 'devtools::test(filter = "optimizer-contract", reporter = "summary")'
Rscript --vanilla -e 'devtools::test(filter = "skew-normal-density-contract|skew-normal-location-scale|optimizer-contract|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
Rscript --vanilla -e 'pkgs <- c("sn", "RTMBdist", "brms", "glmmTMB", "gamlss"); print(data.frame(package = pkgs, available = vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)), row.names = FALSE)'
rg -n 'q8.*(coverage|power|interval).*(ready|passed|complete|supported)|q8.*positive-Hessian|skew_normal.*(random effects|structured effects|bivariate|rho12).*(implemented|supported|ready)|skew-normal.*formal recovery.*(ready|complete|passed)|skew_normal.*external comparator.*(passed|complete|supported)|external comparator fit artifacts exist yet|Q8 still has no start-hook implementation|next q8 task is the internal start-hook implementation' NEWS.md ROADMAP.md README.md docs/design docs/dev-log/known-limitations.md inst/sim vignettes R tests --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!docs/design/archive/**'
find docs/dev-log/simulation-artifacts/2026-06-08-skew-normal-glmmtmb-comparator-smoke -maxdepth 1 -type f -print | sort
git diff --check
```

Both focused test runs passed. Optional package availability was `brms = TRUE`,
`glmmTMB = TRUE`, and `sn = RTMBdist = gamlss = FALSE`. `git diff --check`
passed.

## Tests Of The Tests

The new optimizer-contract tests exercise the private helper directly rather
than only checking that a fit still runs. They cover a no-op override, a valid
partial override with mapped slots, provenance recording, unknown names,
duplicate names, wrong lengths, and non-finite values.

The `glmmTMB` smoke intentionally includes the default start and three nonzero
`psi` starts. That makes the failure mode visible: default-start convergence is
not enough to prove a skew-normal comparator is estimating slant.

## Consistency Audit

The active ledgers now say:

- Q8 has a private start-override foundation, but no q4/q6-to-q8 mapper and no
  paired cold-versus-staged diagnostic evidence.
- Fixed-effect `skew_normal()` has a source-level scale map and one simple
  `glmmTMB` comparator smoke with a nonzero-shape-start caveat, but no formal
  comparator grid.
- Q8 coverage, q8 power, skew-normal formal recovery, skew-normal random
  effects, structured effects, bivariate support, residual `rho12`, and latent
  `skew(id)` remain unsupported.

## GitHub Issue Maintenance

- Q8 issue #5 updated:
  https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4654023341
- Skew-normal issue #3 updated:
  https://github.com/itchyshin/drmTMB/issues/3#issuecomment-4654023355

## What Did Not Go Smoothly

The first comparator probe accidentally hit the installed `drmTMB` package
instead of the dirty source tree. The corrected probe used `devtools::load_all()`
before fitting the local `skew_normal()` route.

The `glmmTMB` default start looked superficially successful because the fit
converged with `pdHess = TRUE`, but it estimated essentially zero shape. The
artifact records that trap so future comparator grids set and report shape
starts.

## Known Limitations

Q8 remains diagnostic-only until the q4/q6-to-q8 mapper and paired
cold-versus-staged diagnostics exist and improve the hard `se = TRUE` rows.

The skew-normal comparator smoke is one simple fixed-effect cell. It is not
formal recovery, calibrated false-positive evidence, heteroscedastic
comparator evidence, predictor-varying shape evidence, or support for random,
structured, bivariate, `rho12`, or latent `skew(id)` routes.

## Next Actions

For q8, implement the q4/q6-to-q8 mapper on top of
`drm_apply_start_override()`, including stable fixed-effect column matching and
q>2 member/pair key tests. Then run paired cold versus staged diagnostics.

For skew-normal, extend the `glmmTMB` comparator smoke into a small formal
comparator grid only after shape-start policy is fixed. Keep `gamlss.dist::SN2`
out of the Azzalini same-density lane.
