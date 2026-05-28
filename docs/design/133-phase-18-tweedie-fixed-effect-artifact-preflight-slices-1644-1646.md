# Phase 18 Tweedie Fixed-Effect Artifact Preflight, Slices 1644-1646

This note prepares the first Phase 18 artifact lane for the fitted fixed-effect
Tweedie route. Its reader is a package contributor who needs to write the DGP,
fit summariser, and grid writer without widening Tweedie support beyond the
evidence that already exists.

## Purpose

The first runnable Tweedie surface is univariate and fixed-effect only:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ 1),
  family = tweedie(),
  data = dat
)
```

The public model keeps `mu` as the unconditional response mean, public `sigma`
as the square root of the Tweedie dispersion `phi`, and `nu` as an
intercept-only power in `(1, 2)`.

Focused tests now cover likelihood recovery, low-zero and high-zero comparator
cells, public-scale `sigma` semantics, unconditional `fitted()` values,
response-scale `nu`, row-weight invariants, missing-row filtering, simulation
shape, exact zeros, seed reproducibility, and unsupported-neighbour errors.
Those tests are not yet Phase 18 operating-characteristic artifacts. This
preflight names the artifact schema before runner code is added.

## Aims

Primary aim: measure fixed-effect recovery for the first Tweedie route across
sample size, zero fraction, baseline scale, power, and predictor-correlation
conditions.

Secondary aim: make the Tweedie artifact tables look like the existing Phase 18
family lanes: replicate summaries, aggregate summaries, artifact manifests,
failure ledgers, Wald interval rows, and Wald coverage rows.

This slice does not add DGP, runner, grid-writer, Actions, or report code.

## Data-Generating Sketch

Each data set has one response and no grouping structure. The mean predictor
`x` and scale predictor `z` are standardized continuous variables with optional
correlation `rho_xz`.

```text
eta_mu_i = beta0 + beta1 * x_i
mu_i = exp(eta_mu_i)

eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
phi_i = sigma_i^2

nu_i = power
y_i ~ Tweedie(mu = mu_i, phi = phi_i, p = nu_i)
```

The planned condition table should include:

| Column | Meaning |
| --- | --- |
| `n` | number of observed rows before ordinary model-frame filtering |
| `beta0`, `beta1` | log-mean intercept and slope |
| `gamma0`, `gamma1` | log-public-`sigma` intercept and slope |
| `power` | intercept-only Tweedie `nu`, kept away from 1 and 2 in the first grid |
| `rho_xz` | correlation between the mean and scale predictors |
| `target_zero_fraction` | approximate exact-zero regime induced by the DGP |
| `seed` | replicate seed |

The future DGP may tune `beta0`, `gamma0`, and `power` to hit low-zero and
high-zero regimes, but zero fraction should be recorded as a condition and an
observed diagnostic, not treated as a fitted parameter.

## Estimands

The first artifact lane estimates fixed formula coefficients and the
intercept-only power:

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Log-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Log-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-public-`sigma` intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-public-`sigma` slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| Power | `power` | `predict(fit, dpar = "nu", type = "response")[1]` or equivalent summary row |

Comparator rows should keep the scale mapping explicit:

```text
phi = sigma^2
log(phi) = 2 * log(sigma)
```

The first artifact lane should not report coverage for derived exact-zero
probabilities. Exact-zero counts and observed zero fraction belong in the
diagnostic columns.

## Summary Tables

Replicate-level output should include one row per replicate, condition, and
estimand with at least:

```text
surface, condition_id, replicate, seed, n, n_used,
target_zero_fraction, observed_zero_fraction,
power, rho_xz, sigma_baseline,
parameter, dpar, term, truth, estimate, error, std_error,
wald_low, wald_high, wald_covers,
converged, pdHess, warning_count, error_message, elapsed_sec
```

Aggregate output should include:

```text
surface, condition_id, n_replicate,
parameter, dpar, term, truth,
bias, bias_mcse, rmse, mae, empirical_sd,
coverage, coverage_mcse,
convergence_rate, pdHess_rate, warning_rate,
median_elapsed_sec
```

The manifest should record every CSV artifact path, existence status, row
count, writer version, and session information. The failure ledger should
record the stage (`simulate`, `fit`, `summarise`, `write`), condition,
replicate, message, convergence, Hessian status, and elapsed time.

## Boundaries

This preflight does not open:

- predictor-dependent Tweedie `nu`;
- Tweedie random effects or `sd(group)` terms;
- structured, phylogenetic, spatial, animal, or `relmat()` Tweedie effects;
- bivariate or mixed-response Tweedie models;
- Tweedie zero-inflation aliases;
- hurdle aliases;
- offset or exposure syntax; or
- an external weighted `glmmTMB` comparator.

Offsets remain outside the first Tweedie artifact lane because current offset
syntax is a count-family `mu` exposure route. Weighted external comparators
wait for a separate weighting-semantics target. The first artifact code should
use unweighted fixed-effect rows.

## Slice Status

| Slice | Status | Evidence |
| --- | --- | --- |
| 1644 | Done locally as preflight | This note names the `tweedie_fixed_effect` artifact lane without adding runner code. |
| 1645 | Done locally as sketch | The DGP sketch names `mu`, public `sigma`, intercept-only `nu`, zero fraction, sample size, and predictor correlation. |
| 1646 | Done locally as sketch | The summariser sketch names replicate, aggregate, manifest, failure-ledger, Wald interval, and coverage fields. |
| 1705-1708 | Done locally as first smoke implementation | `inst/sim/dgp/sim_dgp_tweedie_fixed_effect.R`, `inst/sim/fit/sim_summarise_tweedie_fixed_effect.R`, `inst/sim/run/sim_run_tweedie_fixed_effect_smoke.R`, `inst/sim/run/sim_summary_tweedie_fixed_effect_smoke.R`, and `tests/testthat/test-phase18-tweedie-fixed-effect.R` add the first DGP, summariser, smoke runner, summary reducer, resume check, and Wald artifact smoke test. |

## Next Implementation Gate

The first DGP, summariser, and smoke runner now exist. The next implementation
slice should add a repeatable grid-output writer only after the focused smoke
runner remains green in the package test suite. The grid writer should keep the
same boundary: univariate fixed-effect Tweedie, public `sigma = sqrt(phi)`,
intercept-only `nu`, no offsets, no external weighted comparator, and no
random, structured, or bivariate Tweedie support.
