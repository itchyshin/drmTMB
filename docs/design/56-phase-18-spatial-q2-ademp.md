# Phase 18 Spatial Q2 ADEMP Sheet

This sheet records the Phase 18 admission gate for the fitted coordinate-spatial
Gaussian q=2 location covariance path. It follows the ADEMP structure of Morris,
White, and Crowther (2019) and the transparent-reporting checklist of Williams
et al. (2024). It admits matching bivariate `mu1`/`mu2`
`spatial(1 | p | site, coords = coords)` terms for small coordinate-spatial
grids. A later first slice now fits constant bivariate spatial q=4
location-scale blocks, but this ADEMP sheet remains the q=2 admission document.
It does not admit mesh/SPDE models, multiple spatial slopes, standalone spatial
`sigma`, direct-SD surfaces, spatial `corpair()` regression, or non-Gaussian
spatial effects.

## A - Aims

Primary aim: estimate bias, RMSE, interval coverage status, convergence rate,
diagnostic rate, and runtime for bivariate Gaussian coordinate-spatial
`mu1`/`mu2` location covariance models.

Secondary aims: measure how site count, observations per site, spatial field
SDs, spatial mean-mean correlation, coordinate geometry, residual scale, and
residual `rho12` affect recovery; keep the spatial mean-mean correlation
reported by `corpairs(level = "spatial")` separate from observation-level
residual correlation `rho12`.

## D - Data-Generating Mechanism

For sites `s = 1, ..., n_site`, generate a coordinate table and a positive
definite spatial covariance matrix `K_space` using the same coordinate
precision helper as the fitted path. For each observation `i`, let
`site_i` index one site.

```text
x_i ~ Normal(0, 1)
S[1, 1] = sd_spatial1^2
S[2, 2] = sd_spatial2^2
S[1, 2] = S[2, 1] = rho_spatial * sd_spatial1 * sd_spatial2
Cov(u_a[s], u_b[t]) = S[a, b] * K_space[s, t]

mu1_i = beta10 + beta11 * x_i + u_1[site_i]
mu2_i = beta20 + beta21 * x_i + u_2[site_i]
Omega[1, 1] = sigma1^2
Omega[2, 2] = sigma2^2
Omega[1, 2] = Omega[2, 1] = rho12 * sigma1 * sigma2
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega)
```

`rho_spatial` is the site-level spatial mean-mean correlation. `rho12` is the
observation-level residual correlation. They are different covariance layers
and must be summarized in different rows.

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n_site` | 12, 36 | Small and moderate coordinate fields for first operating-characteristic grids. |
| `n_each` | 3, 8 | Weak versus stronger replication per site for spatial SD recovery. |
| `sd_spatial1`, `sd_spatial2` | 0.25, 0.55 | Small and moderate spatial signals for each response. |
| `rho_spatial` | 0, 0.45 | Independent versus positively correlated spatial fields. |
| `rho12` | -0.20, 0.20 | Separates residual coscale from spatial mean-mean covariance. |
| coordinate geometry | ring, stretched line, clustered sites | Checks whether recovery changes under simple geometry stress. |

Use 20 replicates per cell for local smoke checks. The first DGP, fit helper,
summarizer, smoke runner, CSV artifact writer, fixed-effect Wald tables, and
profile-status tables now live under `inst/sim/`. Use 500 replicates per cell
for formal fixed-effect coverage and runtime-bounded profile-target coverage.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Response 1 mean coefficients | `beta10`, `beta11` | `coef(fit, dpar = "mu1")` |
| Response 2 mean coefficients | `beta20`, `beta21` | `coef(fit, dpar = "mu2")` |
| Residual scale | public `sigma1`, `sigma2` | `sigma(fit)` |
| Spatial SDs | `sd_spatial1`, `sd_spatial2` | `sdpars$mu` rows for `spatial(1 | p | site)` |
| Spatial q=2 correlation | `rho_spatial` | `corpars$spatial` and `corpairs(fit, level = "spatial")` |
| Residual correlation | `rho12` | `rho12(fit)` and residual-correlation profile targets |
| Coordinate covariance | supplied `coords` and derived `K_space` | no estimator for the input; geometry and conditioning diagnostics only |

Fixed-effect operating-characteristic rows stay on their formula-coefficient
scale. Spatial SD, spatial correlation, and residual `rho12` interval rows must
carry profile or `not_requested` status because Wald intervals on these public
scales are not justified by the current evidence.

## M - Methods

Fit the intended bivariate coordinate-spatial q=2 model:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
    mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  family = biv_gaussian(),
  data = dat
)
```

The current test evidence includes a dense covariance comparator, direct
profile targets for both spatial SDs and the spatial correlation,
`corpairs(level = "spatial")`, `summary(fit)$covariance`, `simulate()`, and
prediction checks. The first `inst/sim/` DGP and smoke runner now exercise the
same public spelling. The artifact writer now records fixed-effect Wald
interval rows, profile or `not_requested` status rows for the spatial SDs,
spatial correlation, residual `rho12`, and residual scales, plus interval
evidence and failure-ledger CSVs before broad coverage reports.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | fixed `mu1` and `mu2` coefficient rows with finite formula-coefficient standard errors |
| Profile coverage | spatial SD, spatial correlation, and residual `rho12` rows only when interval status is `profile` |
| Response-scale error | signed and absolute error for `corpairs(level = "spatial")` and `rho12()` |
| Coordinate diagnostics | site geometry, covariance conditioning, and any dropped or reordered site levels |
| Structured-effect diagnostics | `check_drm()` rows for replication, weak spatial SD, boundary, and Hessian status |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Failure ledger | mesh/SPDE fields, multiple spatial slopes, slope correlations, spatial `sigma`, q=4 spatial blocks, direct-SD surfaces, and spatial `corpair()` regression |

Every aggregate metric should carry an MCSE. Failed, warning-bearing,
boundary, profile-failed, and geometry-stress fits remain in the manifest and
failure ledgers rather than being dropped.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims name the coordinate-spatial q=2 surface and excluded spatial neighbours. |
| 2. DGP | The coordinate covariance, bivariate spatial hierarchy, residual covariance, and varied factors are explicit. |
| 3. Estimands | Fixed effects, residual scales, spatial SDs, spatial correlation, residual `rho12`, and coordinate inputs are separated. |
| 4. Methods | The intended `drmTMB` formula for matching bivariate spatial q=2 terms is stated. |
| 5. Performance measures | Bias, RMSE, Wald/profile coverage, response-scale error, diagnostics, convergence, warnings, runtime, and failure ledgers are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Current fitted-path tests live in `tests/testthat/test-spatial-gaussian.R`; the first Phase 18 DGP, fit helper, summarizer, smoke runner, CSV writer, fixed-effect Wald artifacts, and profile-status artifacts live under `inst/sim/`; broad reports still need larger replicate runs and interpretation. |
| 8. Replicability | Seeded cells, replicate-level seeds, coordinate tables, and generated covariance diagnostics must be saved with each replicate. |
| 9. Real-data motivation | The structural-dependence article supplies the spatial ecology route; formal reports should cite it. |
| 10. Complete results | Manifests, geometry diagnostics, warning/error ledgers, and interval-status tables keep hard cases visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for coefficient-level coverage; profile-target coverage may start with a smaller runtime-bounded grid. |
