# After Task: Relmat Sigma K/Q One-Slope Native Cell

## Goal

Complete the first Gaussian structured residual-scale one-slope tranche by
opening the lower-level relatedness cell:

`relmat(1 + x | id, K = K)` and `relmat(1 + x | id, Q = Q)` in Gaussian
`sigma`, ML, sigma-only, native TMB route, point-fit and extractor evidence.

## Implemented

- Relaxed the univariate sigma-only structured-term gate so `relmat()` joins
  the already opened `phylo()`, fixed-covariance `spatial()`, and A-matrix
  `animal()` residual-scale one-slope cells.
- Added a known-relatedness sigma-slope DGP helper in
  `tests/testthat/test-animal-relmat-gaussian.R`.
- Added a positive runtime test that fits both covariance-input `K` and
  precision-input `Q` `relmat()` sigma-slope models to the same target.
- Kept matched `mu+sigma` structured slope cells blocked by the
  location-scale intercept-only validator.
- Promoted the exact q-series support-cell row from planned to native
  point-fit/extractor evidence, while leaving bridge, intervals, and coverage
  planned.
- Updated the mission-control validator, conversion contract, support-cell TSV,
  q-series map, structural-slope map, NEWS, README, ROADMAP, formula grammar,
  pre-simulation matrix, worked-example inventory, common phylo/spatial math
  note, family registry, and validation-debt register so live status prose does
  not say the whole residual-scale structured slope class is still planned.

## Mathematical Contract

For one structured residual-scale slope, the fitted log-sigma linear predictor
contains two independent latent fields for the same relatedness provider:

```text
eta_sigma_i = x_i beta_sigma + u_0[id_i] + x_i u_x[id_i]
u_0 ~ N(0, sd_0^2 K)
u_x ~ N(0, sd_x^2 K)
Cov(u_0, u_x) = 0
```

When the user supplies `Q`, the fitted target is the same covariance implied by
`K = solve(Q)`, up to numerical tolerance. This slice does not estimate a
structured intercept-slope correlation and does not create a matched
location-scale covariance block.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-animal-relmat-gaussian.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `tools/validate-mission-control.py`
- `NEWS.md`, `README.md`, `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/design/218-structured-q-series-completion-map.md`

## Checks Run

```sh
air format R/drmTMB.R tests/testthat/test-animal-relmat-gaussian.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

Results:

- `animal-relmat-gaussian` passed with 245 assertions.
- `structured-re-conversion-contracts` passed with 1491 assertions.
- `python3 tools/validate-mission-control.py` passed with 69 structured RE
  q-series cells.
- `git diff --check` passed.

## Tests Of The Tests

The relmat runtime test compares two neighbouring input routes, `K` and `Q`, on
the same synthetic target. It checks convergence, endpoint metadata, q = 2
coefficient identity, `sdpars$sigma`, `ranef("relmat_mu")`, profile-target
names, finite log likelihood, prediction decomposition on the log-sigma scale,
and K/Q parity for log likelihood, fixed sigma coefficients, and structured SDs.
The conversion-contract test separately requires the q-series cell to be
`native_tmb`, `point_fit`, `extractor_ready`, and still planned for bridge,
interval, and coverage status.

## Consistency Audit

The support-cell row now names the exact cell
`qseries_relmat_q1_sigma_one_slope`. The validator and conversion contract both
require the four provider rows for first sigma-only one-slope support:
`phylo`, fixed-covariance `spatial`, A-matrix `animal`, and K/Q `relmat`.

Stale-wording search:

```sh
rg -n 'residual-scale structured slopes|structured scale slopes|residual-scale.*remain planned|residual-scale.*planned' README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/16-phylo-spatial-common-math.md docs/design/34-validation-debt-register.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/59-structural-slope-and-non-gaussian-map.md docs/design/218-structured-q-series-completion-map.md
```

The live README, formula grammar, q-series map, pre-simulation matrix,
structural-slope map, and debt register now distinguish opened sigma-only
one-slope cells from still-planned matched `mu+sigma` structured slope cells.
Remaining hits in ROADMAP are older slice/history rows or ordinary correlated
residual-scale slope boundaries, not the current q-series support-cell truth.

## GitHub Issue Maintenance

Checked for a direct duplicate with:

```sh
gh issue list --repo itchyshin/drmTMB --search "relmat sigma structured slope q-series" --limit 20 --json number,title,state,url,labels
```

The query returned `[]`, so no issue was updated or opened for this narrow
implementation slice.

## What Did Not Go Smoothly

The first consistency scan exposed drift outside the files originally planned
for the relmat runtime slice. README, ROADMAP, formula grammar, pre-simulation,
debt-register, and design notes still used older "residual-scale structured
slopes remain planned" wording. The fix was to patch current-status documents
instead of rewriting historical NEWS and older slice notes.

## Team Learning

The support-cell row did its job: once the exact relmat sigma row moved, the
stale prose became visible. Future q-series slices should update the support
cell first, then scan for class-level planned wording before calling a runtime
cell complete.

## Known Limitations

- No matched `mu+sigma` structured slope cells.
- No labelled structured slope covariance.
- No structured q4/q6/q8 slope support.
- No broad bridge support, interval reliability, or coverage.
- No q4 REML, native-TMB q4 REML, q4 AI-REML, HSquared AI-REML, or
  non-Gaussian REML.
- No DRAC execution and no SR150 evidence.

## Next Actions

1. Add bridge fixture rows for the exact sigma one-slope cells only after each
   provider has a deterministic same-target fixture.
2. Start matched `mu+sigma` slope diagnostics after endpoint identity metadata
   is strong enough to prevent q1 plus q1 from being mistaken for q2.
3. Keep intervals and coverage planned until denominator and MCSE-calibrated
   coverage evidence exist.
