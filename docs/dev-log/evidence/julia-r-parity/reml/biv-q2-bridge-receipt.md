# REML through `engine = "julia"` for the bivariate q = 2 structured routes

Leaf `biv-q2-reml-bridge` (drmTMB #1142 / DRM.jl #470). Every number on this
page was measured in one run on 2026-09-05, on branch
`claude/parity-biv-q2-reml-bridge` off `origin/main` `2e9a358a6`, against the
DRM.jl pin `430ef64ccca5642c5abebd72194e00895314dfc2`
(`DRM_JL_PATH` / `DRM_JL_PHYLO_PATH` =
`/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc`), with
`OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true NOT_CRAN=true` and
`devtools::load_all()` on the worktree. Nothing here is quoted from a prior
run or from an engine docstring.

## What was wrong

The bridge refused `REML = TRUE` on **every** bivariate q = 2 structured cell,
for **every** provider, while both native engines fit them. Two different
R-side branches produced that refusal, and they produced two different
messages:

* `phylo(1 | p | g)` on `mu1`/`mu2` reaches the MAIN bridge payload, because
  `drm_julia_has_structured_term()` deliberately covers only
  relmat/animal/spatial. It was refused by `drm_julia_reml_supported()`
  (`R/julia-bridge.R`), whose `biv_gaussian` branch admitted only
  `drm_julia_biv_phylo_dimension(formula) == "q4"`.
* `relmat` / `animal` / `spatial` reach
  `drmTMB_julia_biv_known_structured_bridge()` and were refused one branch
  earlier by an unconditional
  `drm_julia_refuse_reml_unsupported(REML, "bivariate q2 known-covariance
  structured-effect")`.

Both engines already fit these cells. DRM.jl's q = 2 route dispatches
`fit_coevolution_q2_reml` (`src/reml_q2.jl`) from
`_fit_bivariate_q2_structured()` (`src/gaussian_bivariate.jl`), and its own q2
marker allow-list is `(:phylo, :relmat, :animal)` (`_bivariate_q4_marker()`).
Native `engine = "tmb"` admits the phylo, supplied-`K` relmat and
fixed-covariance spatial q2 location blocks
(`drm_validate_reml_spec_biv()` -> `drm_reml_admits_biv_exact_q2_intercept()`,
`R/drmTMB.R`).

## Fixture

One shared generator, one draw per provider (`seed = 20260905`, 10 groups x 3
replicates = 30 rows), `Sigma_a = [[0.20, 0.06], [0.06, 0.16]]`, residual
`rho12 = 0.20`:

```r
bf(
  mu1 = y1 ~ x + <marker>(1 | p | id, ...),
  mu2 = y2 ~ x + <marker>(1 | p | id, ...),
  sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1
)
```

`mu1` and `mu2` share ONE fixed-effect design (`~ x`) because DRM.jl's q = 2
route requires `X1 == X2`. The committed copy of this generator is
`drm_biv_q2_reml_fixture()` / `drm_biv_q2_reml_formula()` in
`tests/testthat/test-julia-biv-q2-reml.R`.

## RED: the refusals on `origin/main`

Measured before any edit. Verbatim first lines:

* phylo: ``engine = "julia"` cannot fit bivariate Gaussian models by `REML = TRUE`.`
* relmat / animal / spatial: ``engine = "julia"` cannot fit bivariate q2
  known-covariance structured-effect models by `REML = TRUE`.`

The SAME fixture fit on the same commit with `REML = FALSE` through the bridge,
and with `engine = "tmb"` `REML = TRUE`:

| provider | julia ML logLik   | tmb REML logLik   |
|----------|-------------------|-------------------|
| phylo    | -15.216688438363  | -21.314204290229  |
| relmat   | -20.183611311357  | -26.479478039776  |
| spatial  | -16.638951366476  | -22.754177547946  |
| animal   | -17.837397978534  | REFUSED (see below) |

## The qualified provider set: phylo, relmat, spatial

`animal` is **excluded, on measurement**. DRM.jl fits it, but native
`engine = "tmb"` still refuses bivariate animal q2 REML, measured in this run:

> The relatedness exception has the same boundaries and requires matching
> labelled `relmat(1 | p | id, K = K)` intercepts; supplied precision `Q`,
> animal, slopes, q4+, and scale-side bivariate relmat REML routes remain
> deferred.

With no native REML fit there is no same-target comparator, so admitting
`animal` here would be widening on the engine's word alone. drmTMB PR #1200
adds the native route; the widening belongs in the leaf that measures that
receipt. `animal` keeps its original refusal, asserted by a test.

## GREEN: same-target receipt

`engine = "julia"` `REML = TRUE` vs `engine = "tmb"` `REML = TRUE`, same
fixture, both converged on every row:

| provider | max abs d coef | abs d logLik | julia logLik      | tmb logLik        |
|----------|----------------|--------------|-------------------|-------------------|
| phylo    | 5.15226491669e-05 | 1.80259588568e-04 | -21.3143845498 | -21.3142042902 |
| relmat   | 5.29408216814e-05 | 3.70414401374e-07 | -26.4794784102 | -26.4794780398 |
| spatial  | 4.20176415986e-05 | 4.4930100529e-08  | -22.7541775929 | -22.7541775479 |

Coefficient names agree as a SET (7/7 on every provider) but NOT as an ordered
vector: Julia reports `rho12` before `sigma1`/`sigma2`, native reports it last.
The comparison above is name-matched, and the test asserts `expect_setequal`
rather than vector identity, so the ordering difference is recorded rather than
hidden.

Per-coefficient, phylo (the widest provider):

```
mu1.(Intercept)   julia=0.239691640843   tmb=0.239696511186   d=4.87034339439e-06
mu1.x             julia=0.384614426188   tmb=0.384615819128   d=1.39294030899e-06
mu2.(Intercept)   julia=0.139223338969   tmb=0.139224911064   d=1.57209538182e-06
mu2.x             julia=0.283509669754   tmb=0.283512191493   d=2.52173862375e-06
rho12.(Intercept) julia=0.0916849925942  tmb=0.0917304535163  d=4.54609221631e-05
sigma1.(Intercept) julia=-1.42732296124  tmb=-1.42727143859   d=5.15226491669e-05
sigma2.(Intercept) julia=-1.23040679785  tmb=-1.23036153377   d=4.5264077873e-05
```

### The one number outside a flat 1e-4 bar, and what it is not

phylo's `|d logLik| = 1.803e-04` is the only measurement above 1e-4. Two
controls were run, and together they say it is a property of the q2 PHYLO
route, not something REML introduced:

1. **It is not optimiser slack.** Tightening the route's outer-gradient
   tolerance does not close it:

   | g_tol | abs d logLik | max abs d coef |
   |-------|--------------|----------------|
   | 1e-04 | 1.80259588568e-04 | 5.15226491669e-05 |
   | 1e-06 | 1.79898405698e-04 | 9.3714040713e-05 |
   | 1e-08 | 1.79898405698e-04 | 9.3714040713e-05 |

2. **The already-admitted ML fit on the same fixture is WORSE.** The ML route
   here is parity-tested and shipped:

   | provider | ML abs d logLik | ML max abs d coef | REML abs d logLik | REML max abs d coef |
   |----------|-----------------|-------------------|-------------------|---------------------|
   | phylo    | 5.42291297371e-04 | 4.60677558603e-03 | 1.80259588568e-04 | 5.15226491669e-05 |
   | relmat   | 7.33430027822e-09 | 9.65172943151e-06 | 3.70414401374e-07 | 5.29408216814e-05 |
   | spatial  | 2.30621118504e-05 | 3.02348898853e-05 | 4.4930100529e-08  | 4.20176415986e-05 |

   On phylo the REML agreement is about 3x TIGHTER on logLik and about 90x
   tighter on coefficients than the ML agreement this route already ships with.
   relmat and spatial share the REML code path but not the phylo covariance
   construction, and agree to 3.7e-07 and 4.5e-08.

The honest statement: this leaf does not claim `1e-4` on phylo logLik. It
claims the REML route agrees at least as well as the ML route it rides on,
with the residual localised to the phylo covariance construction (DRM.jl builds
an augmented all-node coevolution problem; drmTMB builds `ape::vcv.phylo`), a
question this leaf does not own.

## Estimator honesty (G4)

Read off the fitted objects, not inferred:

| provider | `fit$estimator` | `fit$bridge$estim_method` | `ml_loglik` | `reml_loglik` | gap |
|----------|-----------------|---------------------------|-------------|---------------|-----|
| phylo   | `REML` | `REML` | -15.3038645893 | -21.3143845498 | 6.011 |
| relmat  | `REML` | `REML` | -20.2877104533 | -26.4794784102 | 6.192 |
| spatial | `REML` | `REML` | -17.0618778079 | -22.7541775929 | 5.692 |

The engine's own `estim_method` says `REML` on all three, and the ML/REML
log-likelihoods are ~6 units apart, so the restriction is real rather than a
relabelled ML fit. `new_drmTMB_julia()`'s estimator-authority cross-check
(#1152/#625) runs unconditionally on this path and would have aborted if DRM.jl
had reported `ML`.

## POINT-ONLY: no SE receipt, and why

**No standard-error claim is made on any of these three routes, because none
can be measured.** DRM.jl's q = 2 structured route stores an all-NaN covariance
by construction -- `V = fill(NaN, length(theta_hat), length(theta_hat))` in
`_fit_bivariate_q2_structured` (`src/gaussian_bivariate.jl`) -- and that was
confirmed live rather than read off the source: `sqrt(diag(vcov(fit)))` is
`NaN` in all 7 entries on every provider. Native `engine = "tmb"` reports
finite SEs on the same fits (phylo head:
`0.358118223375, 0.0396947456968, 0.628047959857, 0.0501792367948`), so the
missing side is DRM.jl's, not drmTMB's. Leaf `jl-q2-vcov` owns whether that is
fixable. The test asserts the all-NaN condition so the gap cannot be
quietly closed without someone noticing.

Also NOT claimed: interval coverage, more than one draw per provider, any
non-Gaussian family, q4, scale-side markers, non-intercept markers,
predictor-dependent `sigma1`/`sigma2`/`rho12`, and mismatched `mu1`/`mu2`
designs (DRM.jl requires `X1 == X2` and refuses otherwise).
