# Arc 6 direct lognormal `rho12` coverage manifest

**Status:** predeclared; local all-cell smoke passed. The Totoro run is the
first calibration campaign for this direct exact-likelihood interval route. It
does not authorize a staged-eta uncertainty claim.

## Aim and estimand

The target is constant `rho12`, the residual correlation between the two
log-responses in an exact fixed-effect `biv_lognormal()` model. It is neither
the raw-scale correlation of positive responses nor frozen-margin copula
association `eta`.

The campaign compares three 95% intervals:

1. guarded-link Wald interval;
2. direct-likelihood endpoint profile interval;
3. whole-model parametric-bootstrap percentile interval.

The profile is the candidate primary reporting method, conditional on the gates
below. Wald and bootstrap are comparators whose calibration is reported, not
assumed.

## Data-generating mechanism

For each observation, generate `x ~ N(0, 1)` and correlated standard-normal
residuals `(e1, e2)` with constant correlation `rho12`. Then generate

\[
Y_1 = \exp(0.35 + 0.45x + 0.4e_1), \qquad
Y_2 = \exp(-0.15 - 0.30x + 0.7e_2).
\]

Thus the locations are covariate-adjusted and the log-scale standard deviations
are unequal. Every fit uses exactly the matching direct model:

```r
drmTMB(
  bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
  family = biv_lognormal(), data = dat
)
```

## Immutable grid and retained attempts

The grid is `n = {100, 300, 1000}` by `rho12 = {0, 0.5, 0.85}`. The Totoro
campaign will make 300 outer attempts per cell (2,700 fits total), with 199
joint-simulation/full-refit bootstrap attempts for every fitted outer model.
The seed base is `2026072406`; outer and bootstrap seeds are deterministic,
distinct, and written alongside results.

For every outer attempt, retain seed, fit error, convergence, `pdHess`, point
estimate, all three interval statuses/endpoints/messages, and coverage flags.
For every bootstrap attempt, retain outer and bootstrap seeds, refit status,
convergence, target availability, messages, and whether its draw was used. A
failed or unresolved interval remains in the outer-attempt file and is never
deleted.

## Metrics and decision rules

For each method and cell, report point-estimate bias and RMSE, fit convergence,
`pdHess`, interval availability, width, failure reason, and both:

- conditional coverage among finite intervals; and
- conservative all-attempt coverage, where an unavailable interval is counted
  as not covering.

Exact binomial 95% intervals accompany each coverage proportion. At `n = 100`,
the study is exploratory and boundary-sensitive. A profile-primary recommendation
requires, at every `n >= 300` cell: at least 98% converged/PD-Hessian outer
fits, at least 98% finite profile intervals, and a conditional-coverage exact
95% interval that overlaps `[0.925, 0.975]`. It is withheld if any gate fails;
the observed Wald and bootstrap behaviour remains descriptive regardless.

This is a calibration gate only. It does not promote a package-wide capability
ledger cell, establish `biv_student()` inference, permit predictor-varying or
random `rho12`, or validate staged eta inference.

## Execution

Run from the committed source checkout on Totoro with at most 90 outer workers
and `OPENBLAS_NUM_THREADS=1`:

```sh
OPENBLAS_NUM_THREADS=1 NCORES=90 NSIM=300 BOOTSTRAP_R=199 \
  Rscript --no-init-file inst/sim/run/sim_run_biv_lognormal_rho12_coverage.R
```

The local gate command was:

```sh
SMOKE=true NCORES=1 BOOTSTRAP_R=9 \
  Rscript --no-init-file inst/sim/run/sim_run_biv_lognormal_rho12_coverage.R
```

It completed all nine outer fits and retained all 81 bootstrap-refit rows. Its
one replicate per cell is not used for coverage interpretation.
