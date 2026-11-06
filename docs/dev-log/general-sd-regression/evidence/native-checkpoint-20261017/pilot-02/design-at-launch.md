# Bernoulli SD-regression feasibility pilot

This ADEMP design separates code qualification and runtime measurement from
production calibration. It follows [Morris, White and Crowther (2019)](https://doi.org/10.1002/sim.8086)
and [Williams et al. (2024)](https://doi.org/10.1111/2041-210X.14415).

## A: Aims

Check that an independent generator, target extraction, diagnostics and profile
interval collection work before timing the corresponding Totoro and DRAC jobs.
The pilot cannot establish coverage. No acceptance tolerance will be selected
from favourable pilot coverage.

## D: Data-generating mechanism

For each of 160 independent groups, generate 16 Bernoulli responses with
`x ~ N(0,1)`, a group predictor equally spaced from -1 to 1, and independent
`u[g] ~ N(0,1)`. Set `log(s[g]) = log(0.8) + a*w[g]` and
`logit(p[i]) = -0.3 + 0.6*x[i] + s[g[i]]*u[g[i]]`.
Use `a` equal to -0.5, 0 and 0.5, with two pilot seeds per condition.
Do not centre the realised random draws. Pilot seeds come from master seed
2026101702 and are disjoint from the deterministic package fixtures.

The first production domain will use at least 1,000 independent seeds per
condition: a nominal coverage of 0.95 has Monte Carlo standard error 0.0069
at 1,000 attempts. These six pilot fits are not those production replicates.
Production source pins, numerical checks and runtime estimates must be frozen
before launch. The programme's ordinary-condition coverage criterion remains
an exact binomial uncertainty interval wholly within 0.925 to 0.975.

## E: Estimands

The primary pilot target is `a`, extracted as `coef(fit, "sd(id)")[["w"]]`.
Its SD ratio across a one-unit increase in `w` is `exp(a)`. Profile endpoints
may be transformed monotonically to that ratio. Joint bootstrap intervals for
more general derived contrasts remain a separate validation obligation.

## M: Methods

Fit native TMB maximum likelihood with a Laplace approximation and the
formula `bf(y ~ x + (1 | id), sd(id) ~ w)`. Collect a named 95% profile
interval for `fixef:sd(id):w`. Check the scalar Laplace objective against
the independent integration-mode/Hessian calculation used in the package
tests. A shared TMB/Julia answer alone is not a numerical oracle. Higher-order
integration sensitivity remains a separate check.

## P: Performance measures

Retain every attempted fit, warnings, errors, convergence code, positive
Hessian flag, coefficient, standard error, profile status/endpoints, elapsed
seconds and objective-oracle difference. Keep the full `check_drm()` table
and largest absolute fixed-parameter gradient. A valid interval requires
optimizer convergence, positive Hessian, gradient below 0.001, no fitted or
profile clamp/boundary flag, successful profile status and finite ordered
endpoints. Report attempted and valid-interval
denominators separately. Failure contributes zero to all-attempt coverage;
conditional coverage is a distinct descriptive measure. Record environment
and source hashes beside raw attempts. Pilot summaries report individual
results and timing, without a calibration claim or significance decision.

## Compute

First run locally, serially, with BLAS threads capped at one; estimate two
to five minutes for six fits plus profiles, based on a 30-second focused
profile test. Stop and report if this bound is exceeded.
Then repeat the qualified workload on Totoro. Use DRAC only through a bounded
SLURM job with account and wall time. Each target gets a measured runtime and
memory receipt before production scheduling. No campaign runs on Actions.
