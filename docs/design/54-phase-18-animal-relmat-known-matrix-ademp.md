# Phase 18 Animal/Relmat Known-Matrix and Pedigree ADEMP Sheet

This sheet records the Phase 18 design gate for known-matrix Gaussian
`animal()` and `relmat()` models, plus the dense first pedigree spelling for
`animal()`. It follows the ADEMP structure of Morris, White, and Crowther
(2019) and the transparent-reporting checklist of Williams et al. (2024). It is
intentionally narrower than the full structural-dependence roadmap: this sheet
admits the known-matrix `mu` intercept, the dense-pedigree `animal()` intercept,
and matching bivariate q=2 `mu1`/`mu2` covariance lanes. The constant all-four
q=4 location-scale smoke lane is recorded separately in
`docs/design/58-phase-18-animal-relmat-q4-ademp.md`. Sparse large-pedigree
construction, structured slopes, standalone `sigma` structured effects,
direct-SD grammar, and predictor-dependent `corpair()` regressions remain
planned.

## A - Aims

Primary aim: estimate bias, RMSE, interval coverage status, convergence rate,
diagnostic rate, and runtime for Gaussian known-matrix `animal()`/`relmat()`
location random-effect models and the dense first `animal(pedigree = ...)`
route, including matching bivariate q=2 `mu1`/`mu2` covariance blocks.

Secondary aims: compare covariance-input and precision-input spelling
(`A`/`Ainv` for `animal()`, `K`/`Q` for `relmat()`), check the animal-only
`pedigree` spelling against the same additive relationship matrix, measure how
group count, replication, structured-effect SD, structured correlation,
residual correlation `rho12`, and matrix conditioning affect recovery, and keep
latent relatedness covariance separate from known sampling covariance
`meta_V(V = V)` and residual coscale `rho12`.

## D - Data-Generating Mechanism

For group levels `g = 1, ..., n_level`, generate a known positive-definite
relatedness matrix `K_group`. The first helper can use an exponentially
decaying correlation matrix across ordered groups:

```text
K_group[g, h] = matrix_decay^abs(g - h)
diag(K_group) = 1
Q_group = inverse(K_group)
```

The `animal()` lane names this matrix `A` and its precision `Ainv`; the
`relmat()` lane names the same mathematical object `K` and `Q`. The matrix is
an input, not an estimated parameter.

The animal-only pedigree lane builds `K_group` from a deterministic pedigree
table with `id`, `dam`, and `sire` columns, then sends the resulting additive
relationship matrix through the same dense animal-model likelihood. This keeps
the public `animal(1 | p | individual, pedigree = pedigree)` spelling in the
smoke artifacts without claiming sparse large-pedigree construction.

For the univariate intercept lane:

```text
x_i ~ Normal(0, 1)
g_i in {1, ..., n_level}
u ~ MVN(0, sd_struct^2 * K_group)
mu_i = beta0 + beta1 * x_i + u[g_i]
y_i ~ Normal(mu_i, sigma^2)
```

For the matching bivariate q=2 lane:

```text
x_i ~ Normal(0, 1)
g_i in {1, ..., n_level}
S[1, 1] = sd_struct1^2
S[2, 2] = sd_struct2^2
S[1, 2] = S[2, 1] = rho_struct * sd_struct1 * sd_struct2
Cov(u_a[g], u_b[h]) = S[a, b] * K_group[g, h]

mu1_i = beta10 + beta11 * x_i + u_1[g_i]
mu2_i = beta20 + beta21 * x_i + u_2[g_i]
Omega[1, 1] = sigma1^2
Omega[2, 2] = sigma2^2
Omega[1, 2] = Omega[2, 1] = rho12 * sigma1 * sigma2
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega)
```

`rho_struct` is the group-level animal or relatedness correlation reported by
`corpairs(level = "animal")` or `corpairs(level = "relmat")`. `rho12` is the
observation-level residual correlation reported by `rho12()`. They should be
summarised in different rows.

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `surface` | `animal`, `relmat` | Animal-model covariance and lower-level relatedness covariance share the same matrix algebra but use different public syntax. |
| `matrix_argument` | covariance, precision, pedigree | Checks `A` versus `Ainv`, `K` versus `Q`, and the animal-only `pedigree` spelling without changing the estimand. |
| `n_level` | 18, 48 | Small and moderate numbers of related groups or individuals. |
| `n_per_level` | 3, 8 | Weak versus stronger within-level replication for structured-effect SD recovery. |
| `sd_struct` or `sd_struct1`, `sd_struct2` | 0.20, 0.55 | Small and moderate latent relatedness signal. |
| `rho_struct` | 0, 0.45 | Independent versus positively correlated q=2 structured effects. |
| `rho12` | 0, 0.30 | Separates group-level covariance from residual coscale. |
| `matrix_decay` | 0.20, 0.65 | Mild versus stronger relatedness and different precision conditioning. |

Use 20 replicates per cell for local smoke checks. Use 500 replicates per cell
for formal coefficient-level and direct-target coverage tables after the DGP
helper, runner, and summariser write replicate-level manifests.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Mean intercept and slope | `beta0`, `beta1` or response-specific `beta10`, `beta11`, `beta20`, `beta21` | `coef(fit, dpar = "mu")`, `coef(fit, dpar = "mu1")`, and `coef(fit, dpar = "mu2")` |
| Residual scale | public `sigma`, `sigma1`, and `sigma2` | `sigma(fit)` and response-specific scale summaries |
| Structured SD | `sd_struct`, `sd_struct1`, `sd_struct2` | `sdpars$mu` rows for `animal` or `relmat`; direct profile targets when present |
| Structured q=2 correlation | `rho_struct` | `corpars$animal` or `corpars$relmat`; `corpairs(fit, level = "animal")` or `corpairs(fit, level = "relmat")` |
| Residual correlation | `rho12` | `rho12(fit)` and `profile_targets()` rows for residual-correlation targets |
| Known relatedness matrix | supplied `A`, `Ainv`, `K`, `Q`, or dense pedigree-derived `A` | no estimator for the input; matrix diagnostics only |

The primary operating-characteristic rows stay on the fitted link or direct
profile-target scale. Response-scale summaries for structured SDs and
correlations should carry interval-status provenance, because profile and Wald
routes do not have the same interpretation near boundaries.

## M - Methods

Fit the intended univariate known-matrix model:

```r
drmTMB(
  bf(y ~ x + animal(1 | individual, Ainv = Ainv), sigma ~ 1),
  data = dat,
  family = gaussian()
)
```

and the analogous `relmat()` route:

```r
drmTMB(
  bf(y ~ x + relmat(1 | line, Q = Q), sigma ~ 1),
  data = dat,
  family = gaussian()
)
```

Fit the intended bivariate q=2 model with matching labels:

```r
drmTMB(
  drm_formula(
    mu1 = y1 ~ x + animal(1 | p | individual, Ainv = Ainv),
    mu2 = y2 ~ x + animal(1 | p | individual, Ainv = Ainv),
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ 1
  ),
  data = dat,
  family = c(gaussian(), gaussian())
)
```

and mirror it with `relmat(1 | p | line, Q = Q)`. The animal pedigree smoke
cell fits the same q=2 model with
`animal(1 | p | individual, pedigree = pedigree)` in both response formulas.
The first formal grid should not add MCMCglmm, ASReml, sparse
pedigree-to-`Ainv`, or `brms` comparators. A
comparator can be added later only if it targets the same known matrix,
structured SD, structured correlation, residual scale, and residual `rho12`
layers.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | fixed-effect and residual-scale coefficient rows whose interval status is `wald` |
| Profile coverage | structured SD, structured correlation, and residual `rho12` direct-target rows only when interval status is `profile` |
| Response-scale error | absolute and signed error for `corpairs()` and `rho12()` response-scale estimates on constant-truth cells |
| Matrix diagnostics | positive-definiteness, conditioning, dropped or reordered levels, and covariance-versus-precision source |
| Structured-effect diagnostics | `check_drm()` rows for weak structured SD, low replication, Hessian status, and boundary flags |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Failure ledger | sparse large-pedigree construction, structured slopes, standalone `sigma` structured effects outside the fitted all-four q=4 block, predictor-dependent `corpair()` regressions, direct-SD grammar, and non-Gaussian structured effects |

Every aggregate metric should carry an MCSE. Failed, warning-bearing,
boundary, matrix-validation, and interval-failed fits remain in the manifest,
warning/error ledger, and interval-status tables rather than being dropped.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims name the known-matrix `animal()`/`relmat()` surfaces, the dense animal pedigree spelling, and the excluded broader structured-dependence goals. |
| 2. DGP | The known matrix, dense pedigree-derived animal matrix, univariate intercept hierarchy, bivariate q=2 hierarchy, residual covariance, and varied factors are explicit. |
| 3. Estimands | Fixed effects, residual scales, structured SDs, structured correlations, residual `rho12`, and non-estimated matrix inputs are separated. |
| 4. Methods | The intended `drmTMB` formulas for univariate and bivariate q=2 known-matrix fits and the animal-only pedigree smoke cell are stated. |
| 5. Performance measures | Bias, RMSE, Wald/profile coverage, response-scale error, diagnostics, convergence, warnings, runtime, and failure ledgers are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Runnable user examples now live in the structural-dependence article. The q=2 DGP helper, summariser, smoke runner, CSV grid writer, fixed-effect Wald artifacts, opt-in profile-status artifacts, and animal pedigree smoke cell live under `inst/sim/`; the interval-status contract is in `docs/design/55-phase-18-animal-relmat-q2-interval-status.md`. The q=4 smoke DGP, summariser, runner, grid writer, and derived-correlation interval-status check are recorded in `docs/design/58-phase-18-animal-relmat-q4-ademp.md`. |
| 8. Replicability | Seeded cells, replicate-level seeds, generated matrices, matrix arguments, and animal pedigree tables must be saved with each replicate. |
| 9. Real-data motivation | The structural-dependence article supplies the applied animal-model and relatedness-matrix motivation; formal reports should cite it. |
| 10. Complete results | Manifests, matrix diagnostics, warning/error ledgers, and interval-status tables keep hard cases visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for about one percentage point coefficient-coverage MCSE; profile-target coverage may need a smaller first grid if runtime is high. |
