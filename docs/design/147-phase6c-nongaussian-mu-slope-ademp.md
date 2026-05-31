# Phase 6c Non-Gaussian `mu` Slope ADEMP Sheet

## Purpose

This note is the #441/#446 operating-characteristic design sheet for selected
ordinary non-Gaussian independent `mu` random slopes. It follows the ADEMP
framework of Morris, White, and Crowther (2019) and the Williams et al. (2024)
transparent-reporting checklist for simulation studies.

The sheet covers only the six source-tested families in
`tests/testthat/test-nongaussian-mu-random-slopes.R`: Student-t, lognormal,
Gamma, beta, beta-binomial, and zero-truncated NB2. It does not run grids,
does not promote coverage or power evidence, and does not open correlated
non-Gaussian slopes, labelled covariance, random effects in `sigma`, `nu`,
inflation, hurdle, zero-one beta, or structured dependence.

## A - Aims

Primary aim: estimate when selected ordinary non-Gaussian `mu` independent
numeric random slopes recover fixed `mu` effects and the direct random-slope SD
target without optimizer, Hessian, boundary, or diagnostic failures.

Secondary aim 1: compare the six source-tested family routes without borrowing
evidence across families. Each family keeps its own link scale, support, and
boundary stress conditions.

Secondary aim 2: decide which family groups are ready to move from
source-tested status to an artifact lane, while keeping interval feasibility,
coverage, and power planned until interval provenance and MCSE targets exist.

## D - Data-Generating Mechanism

For group `j` and observation `i`, use one grouping factor and one numeric
within-group predictor:

```text
eta_mu_ij = beta0 + beta1 x_ij + b_j x_ij
b_j ~ Normal(0, sd_slope^2)
```

Family-specific observation models:

```text
Student-t:          y_ij = eta_mu_ij + sigma * t_nu
lognormal:          y_ij ~ Lognormal(meanlog = eta_mu_ij, sdlog = sigma)
Gamma:              y_ij ~ Gamma(mean = exp(eta_mu_ij), cv = sigma)
beta:               y_ij ~ Beta(mu = logit^-1(eta_mu_ij), precision = phi)
beta-binomial:      success_ij ~ BetaBinomial(trials, mu, precision = phi)
zero-truncated NB2: y_ij ~ NB2(mu = exp(eta_mu_ij), sigma), conditional on y_ij > 0
```

The first-wave grid should stay small enough to diagnose family-specific
failure modes:

| Factor | Pilot levels | Why it matters |
| --- | --- | --- |
| family | Student-t, lognormal, Gamma, beta, beta-binomial, zero-truncated NB2 | Keeps family evidence separate. |
| groups | 24, 60 | Random-slope SD recovery is group-count limited. |
| observations per group | 5, 10 | Within-group spread identifies the slope effect. |
| slope SD | 0.20, 0.50 | Checks weak and moderate random-slope signals. |
| covariate spread | narrow, regular | Separates weak design information from weak random effects. |
| boundary stress | family-specific low, moderate | Beta support edges, low beta-binomial trial count, zero-truncation pressure, Gamma/lognormal high `sigma`, and Student-t low `nu` can dominate failure rates. |

Use `n_rep = 200` only for a pilot. A formal interval or power grid should set
replicates from a Monte Carlo standard-error target before dispatch. For
example, 500 replicates gives approximately 1 percentage point MCSE for 95%
coverage; 1000 replicates gives about 0.7 percentage points.

## E - Estimands

Store truth and estimates for:

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Fixed `mu` intercept and slope | `beta0`, `beta1` on the family link scale | `coef(fit, "mu")` rows |
| Random-slope SD | `sd_slope` | `sdpars$mu["(0 + x | id)"]` and `profile_targets()` direct SD row |
| Conditional slope-effect diagnostic | realised `b_j` values | `ranef(fit, "mu")` slope terms and signal/rank correlation with truth, reported as a diagnostic rather than a recovery estimand |
| Scale or shape fixed terms | `sigma`, `nu`, `phi`, trials, or family equivalent where applicable | fixed-effect `sigma`/`nu` summaries or recorded DGP constants |
| Diagnostics | known successful fit status | convergence, `pdHess`, warnings, `check_drm()` rows, boundary flags, elapsed time |

Keep response-scale summaries separate from link-scale `mu` recovery. Link
scale is the primary target because the supported formula is a `mu` predictor
with `(0 + x | id)`.

## M - Methods

Fit only the already source-tested `drmTMB` formulas:

```r
bf(y ~ x + (0 + x | id), sigma ~ 1)
bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1)      # Student-t
bf(cbind(success, failure) ~ x + (0 + x | id), sigma ~ 1)  # beta-binomial
```

Comparators are deferred for the first artifact lane. When power or Type I
error is planned, add a nested no-random-slope `drmTMB` comparator for the same
family and link scale before dispatch. External comparators should stay out
unless #60 defines matched targets. Fixed-effect-only comparators may be useful
for detecting overfit or boundary failure, but they do not estimate the
random-slope SD.

## P - Performance Measures

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(theta_hat - theta_true)` for fixed `mu` coefficients and log-SD or SD targets |
| RMSE | `sqrt(mean((theta_hat - theta_true)^2))` |
| Link-scale accuracy | fixed-effect and random-slope SD errors on the fitted link scale |
| Conditional-signal recovery | correlation and rank correlation between realised `b_j` and estimated slope terms |
| Coverage | planned only until interval-status artifacts identify direct Wald/profile targets and MCSE |
| Interval availability | proportion of direct SD and fixed-effect rows with `ok`, `failed`, or `not_requested` interval status |
| Power or Type I error | planned only until a null/alternative, nested comparator, rejection rule, and MCSE target are named |
| Convergence rate | proportion with optimizer convergence and usable `pdHess` |
| Boundary rate | near-zero slope SD, support-edge failures, warnings, or `check_drm()` non-ok rows |
| Failed-fit retention | failed and warning-heavy replicates remain in manifest/failure artifacts rather than being silently dropped |
| Runtime | median and high quantiles of elapsed fit time |

Every aggregate metric should include an MCSE column or companion MCSE table
before formal reporting.

## Williams 11-Item Self-Audit

| Item | Current status |
| --- | --- |
| 1. Aims | Covered for selected non-Gaussian independent `mu` slope recovery and artifact admission. |
| 2. Data-generating mechanisms | Hierarchy, family-specific observation models, and first-wave condition factors are specified. |
| 3. Estimands | Fixed `mu`, random-slope SD, conditional slope signal, family constants, and diagnostics are named. |
| 4. Methods | Intended `drmTMB` formulas are specified; comparators are deferred with an inclusion rule. |
| 5. Performance measures | Bias, RMSE, signal recovery, diagnostics, runtime, and planned-only coverage/power are specified. |
| 6. Software and computing details | To be recorded by the runner with session info, package versions, seed, and backend. |
| 7. Code availability | To be recorded when a DGP, runner, or grid writer is added under `inst/sim/`. |
| 8. Random-number generation | To be specified in the runner using master and replicate-level seeds. |
| 9. Empirical application | Not required for this planning sheet; tutorials should keep family-specific support boundaries visible. |
| 10. Results reporting | To include aggregate plus replicate-level artifacts, failures, boundary flags, and diagnostic rows. |
| 11. Monte Carlo uncertainty | Pilot uses 200 replicates; formal coverage/power needs an MCSE target before dispatch. |

## Boundary

This sheet does not design correlated non-Gaussian slopes, labelled
covariance, non-Gaussian `sigma` or shape random effects, zero-one beta random
effects, inflation or hurdle random effects, structured non-Gaussian
dependence, or mixed-response bivariate families. Those remain blocked or
design-only until family-specific likelihood, extractor, interval, diagnostic,
and simulation evidence exists.
