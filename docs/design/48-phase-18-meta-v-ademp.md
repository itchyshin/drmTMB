# Phase 18 Meta-Analysis Known-V ADEMP Sheet

This sheet is the second one-page design unit under the Slice 292 comprehensive
blueprint. It follows the ADEMP structure of Morris, White, and Crowther (2019)
and the transparent-reporting checklist of Williams et al. (2024). It records
the admitted Gaussian meta-analysis lane with additive known sampling covariance
`meta_V(V = V)`.

## A - Aims

Primary aim: estimate bias, RMSE, Wald interval coverage, convergence rate, and
runtime for Gaussian meta-analysis models with known sampling covariance `V`
and fitted residual heterogeneity `sigma`.

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

The current condition helper uses the following design:

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n_study` | 8, 12, 16, 36, 72 | AMENDED 2026-07-21. The original 36/72 grid samples past the regime this sheet most needs to characterise. At K=12 with true `sigma = 0.10` the fitted heterogeneity pins at approximately 1e-6 and `confint()` returns the interval as `[0, Inf]` (reproduced, seeds 4 and 10). A design that never visits small K would run clean and certify a channel that is degenerate exactly where applied meta-analyses live. The small rungs are the point, not an extension. |
| `known_v_type` | vector, dense | Diagonal known variances versus dense known sampling covariance. |
| `sigma` | 0.15, 0.35 | Lower and higher residual heterogeneity on the public `sigma` scale. |
| `sampling_sd` | 0.12, 0.22 | Lower and higher known sampling-error scale. |
| `sampling_rho` | 0, 0.25 | Dense known covariance sensitivity; vector cells use only 0. |
| `beta0`, `beta1` | 0.20, 0.45 | Existing helper defaults for the mean model. |

Use 20 replicates per cell for local smoke checks. Use **1200** replicates per
cell for a formal coverage table.

AMENDED 2026-07-21, replacing 500. MCSE at nominal 0.95 is `sqrt(0.95*0.05/N)`:
0.00975 at N=500 against 0.00629 at N=1200, so 500 is 55% noisier. The decisive
argument is that 500 cannot reproduce this project's own label discrimination —
the precedent labels differ by 0.0058 (mc-0464 at 0.9275 certified, mc-0242 at
0.9333 borderline), which is smaller than one MCSE even at 1200. A decision rule
already operating below its noise floor must not be run on a noisier estimate.
Pay for the increase by cutting cells, not by cutting replicates: the amended
design is cheaper than the original because fewer, better-chosen cells at 1200
beat a broad grid at 500.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Residual heterogeneity, POINT | public `sigma` used in the DGP | `unique(as.numeric(sigma(fit)))` |
| Residual heterogeneity, INTERVAL | public `sigma` used in the DGP | `confint(fit, parm = "sigma")` — AMENDED 2026-07-21. `sigma(fit)` is a POINT extractor and cannot support a coverage row; the original sheet named it in an estimand table whose aims include Wald interval coverage. Any coverage claim for heterogeneity must come from `confint()`, and must record the degenerate `[0, Inf]` returns at small K rather than dropping them — an exclusion correlated with the estimand poisons the clean subset. |
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
| Wald coverage | `mean(conf.low <= truth & truth <= conf.high)` for estimated `mu` and `sigma` rows whose interval status is `wald` |
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
| 5. Performance measures | Bias, RMSE, coverage, convergence, warning rate, runtime, and known-`V` diagnostics are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Existing helpers live under `inst/sim/`; this sheet links their intended use. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | The meta-analysis vignette supplies the reader-facing motivation; a final report should cite it. |
| 10. Complete results | Manifests and warning/error ledgers keep failed fits visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for about 1 percentage point coverage MCSE. |
