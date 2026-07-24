# Phase 18 Meta-Analysis Known-V ADEMP Sheet

This sheet is the second one-page design unit under the Slice 292 comprehensive
blueprint. It follows the ADEMP structure of Morris, White, and Crowther (2019)
and the transparent-reporting checklist of Williams et al. (2024). It records
the admitted Gaussian meta-analysis lane with additive known sampling covariance
`meta_V(V = V)`.

## A - Aims

Primary aim: estimate recovery conditional on an obtained estimate, the rate of
obtaining a finite usable Wald interval, conditional finite-interval coverage,
convergence rate, and runtime for Gaussian meta-analysis models with known
sampling covariance `V` and fitted residual heterogeneity `sigma`.

Secondary aims: compare vector and dense known-`V` inputs, measure how
sampling-error scale and residual heterogeneity affect recovery of fixed
effects and public residual `sigma`, and keep known sampling covariance separate
from latent relatedness, animal models, and proportional sampling-variance
models.

## D - Data-Generating Mechanism

For study or effect-size rows `i = 1, ..., n_study`, generate:

```text
x_i ~ Normal(0, 1)
mu_i = beta0 + beta1 * x_i
e ~ MVN(0, V)
u_i ~ Normal(0, sigma^2)
yi_i = mu_i + e_i + u_i
```

For vector known-`V` cells, `V` is the supplied vector of known sampling
variances and `sampling_rho = 0`. For dense known-`V` cells, `V` is a dense
sampling covariance matrix with exponentially decaying correlation controlled
by `sampling_rho`. The current helper `phase18_dgp_meta_v()` already implements
this DGP and stores `V` as an attribute on the simulated data.

`phase18_meta_v_conditions()` supplies the broad factor menu. The formal B3
campaign must instead use the frozen, explicit 14-cell design returned by
`phase18_meta_v_b3_conditions()`:

| Design component | Fixed cells | Reason |
| --- | --- | --- |
| Boundary ladder | `K = {8, 12, 16, 36, 72}`, vector `V`, `sigma = 0.10`, `sampling_sd = 0.12`, `sampling_rho = 0` | The original 36/72 grid samples past the regime this sheet most needs to characterise. At `K = 12`, true `sigma = 0.10`, the fitted heterogeneity pins near 1e-6 and public `confint(..., method = "wald")` returns `[0, Inf]` (reproduced with seeds 4 and 10). |
| Known-`V` stress | `K = 12`, `sigma = 0.10`, `sampling_sd = {0.12, 0.22}`, vector `V` with `rho = 0`, and dense `V` with `rho = {0, 0.25}` | Tests whether the boundary signature changes with sampling-error scale or known-covariance representation. One vector/0.12 cell overlaps the ladder. |
| Interior controls | `K = {12, 36}`, `sigma = 0.35`, `sampling_sd = 0.12`, vector `V` with `rho = 0`, and dense `V` with `rho = 0.25` | Separates the near-boundary operating characteristic from an interior heterogeneity regime. |
| Mean model | `beta0 = 0.20`, `beta1 = 0.45` | Existing DGP values. |

Use 20 replicates per cell for local smoke checks. Use **1200** replicates per
cell for the formal operating-characteristic table: `14 × 1200 = 16,800`
attempts. This is an intentional reduction from the implicit 60-cell factorial,
not a reduction in Monte Carlo precision.

AMENDED 2026-07-21, replacing 500. MCSE at nominal 0.95 is `sqrt(0.95*0.05/N)`:
0.00975 at N=500 against 0.00629 at N=1200, so 500 is 55% noisier. The decisive
argument is that 500 cannot reproduce this project's own label discrimination —
the precedent labels differ by 0.0058 (mc-0464 at 0.9275 certified, mc-0242 at
0.9333 borderline), which is smaller than one MCSE even at 1200. A decision rule
already operating below its noise floor must not be run on a noisier estimate.
The focused 14-cell design costs more than the original 24-cell × 500 plan, but
it replaces an uninformative high-K grid with the boundary conditions the lane
exists to diagnose. The cell reduction keeps that increase bounded; it does not
make the formal campaign cheaper.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Residual heterogeneity, POINT | public `sigma` used in the DGP | `unique(as.numeric(sigma(fit)))` |
| Residual heterogeneity, INTERVAL | public `sigma` used in the DGP | `confint(fit, parm = "sigma", method = "wald")`. `sigma(fit)` is a POINT extractor and cannot support a coverage row. Retain public endpoints, `conf.status`, and every degenerate `[0, Inf]` return rather than dropping them — an exclusion correlated with the estimand poisons the clean subset. |
| Known sampling covariance | supplied `V` | no estimator; `V` is input data and must not receive interval coverage |

The existing summariser stores `mu` coefficients and public residual `sigma`.
It deliberately does not create truth or coverage rows for known sampling
covariance `V`.

## M - Methods

Fit the intended model:

```r
V <- attr(dat, "V", exact = TRUE)
drmTMB(
  bf(yi ~ x + meta_V(V = V), sigma ~ 1),
  family = gaussian(),
  data = dat
)
```

The first formal grid should not add proportional sampling-variance models,
animal models, or user-supplied latent relatedness comparators. A later
comparator sheet can add a conventional meta-analysis route only if it targets
the same fixed effects and residual heterogeneity scale honestly.

This ADEMP sheet validates the constant-extra-heterogeneity route
`sigma ~ 1`. It does not validate predictor-dependent extra heterogeneity such
as `bf(yi ~ x + meta_V(V = V), sigma ~ x)`, which currently needs a separate
Hessian, profile, or bootstrap gate before its Wald SEs or intervals are treated
as reliable.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Interval artifact | Use public `confint()` output for `sigma`; retain endpoints, `conf.status`, and a distinct `degenerate_zero_infinite` status for `[0, Inf]`. Fixed-effect intervals may use the ordinary Wald helper. |
| Primary interval accounting | Every scheduled attempt is retained. Report the rate of obtaining a **finite, usable, truth-covering interval** over all attempts, alongside the finite-interval rate and every fit, convergence, and degenerate-interval count. A returned `[0, Inf]` interval contains a positive true `sigma`, but is not a finite usable interval and must not be silently treated as ordinary coverage. |
| Conditional finite-interval coverage | `mean(conf.low <= truth & truth <= conf.high)` only among finite, status-`ok` intervals; report it as conditional set coverage beside, never instead of, all-attempt finite-usable-interval accounting. |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Known-`V` diagnostics | dense-`V` size, rank, conditioning, and storage status from `check_drm()` where available |

Every aggregate metric should carry an MCSE. Failed or warning-bearing fits
remain in the manifest and warning/error ledger. Dense known-`V` failures should
be interpreted as storage or conditioning failures, not as residual
heterogeneity estimates.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | Mean model, residual heterogeneity, and vector/dense known `V` generation are explicit. |
| 3. Estimands | Mean coefficients, public residual `sigma`, and non-estimated `V` status are named. |
| 4. Methods | The intended `drmTMB` model is stated; comparator scope is limited. |
| 5. Performance measures | Estimate-conditional bias/RMSE, finite-usable-interval and conditional-coverage measures, convergence, warning rate, runtime, and known-`V` diagnostics are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Existing helpers live under `inst/sim/`; this sheet links their intended use. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | The meta-analysis vignette supplies the reader-facing motivation; a final report should cite it. |
| 10. Complete results | Manifests and warning/error ledgers keep failed fits visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 1200 replicates per cell; at nominal 0.95, the binomial coverage MCSE is 0.00629. |
