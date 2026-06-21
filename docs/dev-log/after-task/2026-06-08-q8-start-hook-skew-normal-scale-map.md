# After Task: Q8 Start-Hook And Skew-Normal Scale Map

## Goal

Finish the next recommended slice after the q8 Hessian rescue and skew-normal
Hessian pilot: specify the q8 start-hook implementation boundary, add a
dependency-free skew-normal comparator scale map, synchronize active status
docs, and update the issue ledgers.

## Implemented

The q8 lane now has a concrete preflight note:

- `docs/design/165-phase-18-q8-start-hook-preflight.md`

The note keeps public `start`, `warm_start`, and `map`-like controls reserved.
It locates the first implementation hook after
`add_covariance_probe_parameter(spec)` and before `TMB::MakeADFun()`, then
limits the first staged-start rescue to validated named `spec$start` overrides.
It also records why q8 `theta_re_cov` should stay at zero unless a tested
pair-key and packed-theta mapping helper exists.

The skew-normal lane now has a comparator scale-map note:

- `docs/design/166-phase-18-skew-normal-comparator-scale-map.md`

The note maps public moment parameters `mu`, `sigma`, and `nu` to native
Azzalini `xi`, `omega`, and `alpha`. It keeps `sn::dsn()` and
`RTMBdist::dskewnorm()` on the native scale, keeps
`RTMBdist::dskewnorm2()`, `brms::skew_normal()`, and
`glmmTMB::skewnormal()` on the public moment scale, and marks
`gamlss.dist::SN2` as a different two-piece family rather than a same-density
comparator.

## Mathematical Contract

No formula grammar or likelihood parameterization changed. Q8 remains the
ordinary bivariate Gaussian all-endpoint block with eight group-level endpoint
SDs and 28 group-level endpoint correlations. Residual `rho12` remains a
row-level residual coscale parameter, not a group-level q8 correlation.

Skew-normal remains the univariate fixed-effect `mu`/`sigma`/`nu` route. Public
`mu` is `E[y]`, public `sigma` is `SD[y]`, and `nu` is residual slant. The
source-level comparator helper checks the already documented Azzalini transform;
it does not run or claim external fitted-comparator evidence.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/03-likelihoods.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/157-capability-completion-worklist.md`
- `docs/design/158-phase-19-comparator-matrix.md`
- `docs/design/163-phase-18-q8-hessian-start-rescue.md`
- `docs/design/164-phase-18-skew-normal-hessian-comparator-pilot.md`
- `docs/design/165-phase-18-q8-start-hook-preflight.md`
- `docs/design/166-phase-18-skew-normal-comparator-scale-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `inst/sim/README.md`
- `tests/testthat/helper-skew-normal-density.R`
- `tests/testthat/test-skew-normal-density-contract.R`

## Checks Run

```sh
air format NEWS.md ROADMAP.md docs/design/03-likelihoods.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/157-capability-completion-worklist.md docs/design/158-phase-19-comparator-matrix.md docs/design/163-phase-18-q8-hessian-start-rescue.md docs/design/164-phase-18-skew-normal-hessian-comparator-pilot.md docs/design/165-phase-18-q8-start-hook-preflight.md docs/design/166-phase-18-skew-normal-comparator-scale-map.md docs/dev-log/known-limitations.md inst/sim/README.md tests/testthat/helper-skew-normal-density.R tests/testthat/test-skew-normal-density-contract.R
Rscript --vanilla -e 'devtools::test(filter = "skew-normal-density-contract|skew-normal-location-scale|optimizer-contract|phase18-biv-gaussian-q8-endpoint", reporter = "summary")'
rg -n 'q8.*(coverage|power|interval).*(ready|passed|complete|supported)|q8.*positive-Hessian|skew_normal.*(random effects|structured effects|bivariate|rho12).*(implemented|supported|ready)|skew-normal.*formal recovery.*(ready|complete|passed)|skew_normal.*external comparator.*(passed|complete|supported)|comparator scale mapping and recovery evidence remain future|gamlss.*same-density comparator' NEWS.md ROADMAP.md README.md docs/design docs/dev-log/known-limitations.md inst/sim vignettes R tests --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/recovery-checkpoints/**' --glob '!docs/design/archive/**'
git diff --check
```

The focused test run passed. `git diff --check` passed. The stale-claim scan
returned intended boundary rows only: q8 remains closed for coverage, power, and
interval readiness; skew-normal random or structured effects remain unsupported;
and external fitted-comparator evidence remains future work.

## Tests Of The Tests

The new skew-normal tests do not require `sn`, `RTMBdist`, `brms`, `glmmTMB`, or
`gamlss`. They fail if the helper stops reconstructing public `mu` and `sigma`
from native `xi`, `omega`, and `alpha`, if the native density no longer matches
the public reference density after conversion, or if `gamlss.dist::SN2` is
incorrectly marked as a same-density comparator.

The q8 source tests were not changed. The focused run included
`optimizer-contract` and `phase18-biv-gaussian-q8-endpoint` to keep the reserved
start-control boundary and nearby q8 route covered while this slice stayed in
preflight/design mode.

## Consistency Audit

The active status docs now say the same thing:

- Q8 is fitted and diagnostic-artifact ready only; q8 coverage, power, and
  interval readiness remain closed until a start/Hessian rescue passes.
- Fixed-effect `skew_normal()` has source-level comparator scale mapping, but
  no completed formal recovery grid, calibrated false-positive evidence, or
  external fitted-comparator artifacts.
- `gamlss.dist::SN2` is not a same-density Azzalini comparator for this first
  slice.

## GitHub Issue Maintenance

- Q8 issue #5 updated:
  https://github.com/itchyshin/drmTMB/issues/5#issuecomment-4653762360
- Skew-normal issue #3 updated:
  https://github.com/itchyshin/drmTMB/issues/3#issuecomment-4653762363

## What Did Not Go Smoothly

The q8 piece stayed as a preflight because the current package has no reviewed
internal start override. That is the correct boundary for now: adding a public
`start =` or copying packed q8 correlation parameters by position would create a
bigger API and numerical contract than this slice can validate.

The skew-normal piece closed scale mapping, not fitted external comparison. The
previous local library did not have `sn` or `gamlss`; this slice deliberately
keeps optional package availability out of the CRAN-safe source tests.

## Known Limitations

Q8 still lacks a staged-start implementation and paired cold-versus-staged
evidence. It remains diagnostic-only.

Fixed-effect `skew_normal()` still lacks formal recovery, calibrated
false-positive rates, external fitted-comparator artifacts, random effects,
structured effects, known sampling covariance, bivariate support, residual
`rho12`, and latent `skew(id)`.

## Next Actions

For q8, implement the private start-override helper and source tests listed in
`docs/design/165-phase-18-q8-start-hook-preflight.md`, then rerun paired cold
and staged q8 diagnostics.

For skew-normal, run the first external comparator fits against `sn`,
`RTMBdist`, `brms`, or `glmmTMB` only after recording package versions and model
settings. Keep `gamlss.dist::SN2` out of the same-density comparator lane.
