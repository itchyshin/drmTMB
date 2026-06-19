# Ordinary q2 Covariance Hardening Diagnostic

This artifact deepens the ordinary q2 random-effect covariance diagnostics for
`drmTMB#59`. It is native R/TMB evidence only. It does not change package code,
formula grammar, likelihood parameterization, public API, tests, or examples.

The diagnostic covers three already fitted ordinary q2 covariance routes:

- univariate Gaussian same-response `mu`/`sigma` random-intercept covariance;
- bivariate Gaussian `mu1`/`mu2` random-intercept covariance;
- bivariate Gaussian `sigma1`/`sigma2` random-intercept covariance.

It deliberately excludes structured `spatial()`, `animal()`, and `relmat()`
q2 routes, q4/q8 covariance, intervals, power, random effects in residual
`rho12`, direct Julia, Julia-via-R, release readiness, CRAN readiness, and
non-Gaussian REML/AI-REML.

## Aim

The primary aim is to estimate route-specific status, warning, and fitted
correlation error rates for ordinary q2 covariance routes across negative,
ordinary, positive, and near-boundary true correlations.

The secondary aim is to keep fitted-boundary visibility separate from recovery:
`check_drm()` reports fitted boundary status, so a true high-correlation cell
that does not fit near the boundary should not be counted as a missed warning.

## Data-Generating Mechanisms

The primary grid is complete-data Gaussian only. Each route uses seven true
latent random-effect correlations:

| Cell | True q2 correlation | Purpose |
|---|---:|---|
| `negative_high` | -0.95 | Negative near-boundary stress. |
| `negative_edge` | -0.80 | Strong negative ordinary edge. |
| `zero` | 0.00 | False boundary-warning screen. |
| `moderate` | 0.40 | Ordinary moderate positive correlation. |
| `positive_edge` | 0.80 | Strong positive ordinary edge. |
| `positive_high` | 0.95 | Positive near-boundary stress. |
| `positive_boundary` | 0.98 | Fitted-boundary visibility at the `check_drm()` default threshold. |

Each route-cell has 100 replicates, for 2100 requested primary fits. A separate
three-row missing-response smoke table records complete-case dropping behavior
for one moderate cell per route. Those rows are not included in the primary q2
status or recovery summaries.

## Methods

Each primary fit uses the default native R/TMB optimizer path through
`drm_control(optimizer_preset = "default", multi_start = 1L,
fallback_optimizer = NULL)`. No profile intervals, bootstrap intervals,
manual retries, q4/q8 routes, structured routes, direct Julia checks, or
Julia-via-R checks are requested. Optimizer attempts and retry counts are still
recorded as data.

The runner records route labels, formula labels, family, response encoding,
complete-data status, seeds, true correlations, fitted correlations, component
standard deviations, fitted-boundary distances, convergence, `pdHess`, fixed
gradients, route-specific `check_drm()` rows, warnings, likelihood summaries,
elapsed time, and explicit evidence-lane flags.

## Results

The full run requested and attempted 2100 primary fits. There were 0 fit
errors, 2100 optimizer-converged fits, and 2100 fits with `pdHess = TRUE`.
There were no fallback optimizers, no multi-start runs, no profile intervals,
and no bootstrap intervals.

That clean convergence surface does not make the routes promotion-ready.
Fixed-gradient and route-specific covariance warning patterns remain visible:

| Route | Fits | Gradient-ok | Covariance warnings | Max absolute `rho` error | Minimum boundary distance |
|---|---:|---:|---:|---:|---:|
| `univ_mu_sigma` | 700 | 642 | 261 | 0.999999 | 1.000789e-06 |
| `biv_mu` | 700 | 274 | 100 | 0.561493 | 1.000233e-06 |
| `biv_sigma` | 700 | 360 | 281 | 1.399771 | 1.005328e-06 |

The zero-correlation cells retained covariance-warning rates of 0.05 for
`univ_mu_sigma`, 0.00 for `biv_mu`, and 0.05 for `biv_sigma`. The near-boundary
cells correctly remain route-specific rather than global evidence: for example,
`positive_boundary` warning rates were 0.64 for `univ_mu_sigma`, 0.61 for
`biv_mu`, and 0.71 for `biv_sigma`.

The bivariate scale-side route is the roughest recovery screen. Its
`biv_sigma` zero and moderate cells had large fitted-minus-true correlation
errors in some replicates, and its fixed-gradient ok rate was 0.20 in both
zero and moderate cells. This should remain diagnostic-hold for inference
wording even though all fits converged and had `pdHess = TRUE`.

The separate missing-response smoke rows recorded complete-case dropping for
all three routes. They are executable-path diagnostics only, not missing-data
recovery evidence.

## Tables

- `q2-ordinary-covariance-source-grid.csv`
- `q2-ordinary-covariance-conditions.csv`
- `q2-ordinary-covariance-fit-diagnostics.csv`
- `q2-ordinary-covariance-estimates.csv`
- `q2-ordinary-covariance-recovery-summary.csv`
- `q2-ordinary-covariance-status-summary.csv`
- `q2-ordinary-covariance-check-drm.csv`
- `q2-ordinary-covariance-exposure.csv`
- `q2-ordinary-covariance-failures.csv`
- `q2-ordinary-covariance-missing-factor-smoke.csv`
- `q2-ordinary-covariance-run-summary.csv`
- `session-info.txt`

## Boundaries

This is larger native R/TMB diagnostic evidence for ordinary q2 fitted-boundary
visibility and recovery screening. It does not support interval coverage,
power, structured q2, q4/q8 covariance, random effects in residual `rho12`,
direct Julia parity, Julia-via-R bridge parity, selectable Julia
`engine_control`, release readiness, CRAN readiness, missing-data recovery, or
non-Gaussian REML/AI-REML.
