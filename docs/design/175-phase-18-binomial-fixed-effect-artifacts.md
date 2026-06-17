# Phase 18 Binomial Fixed-Effect Artifact Lane

This note records the first Phase 18 evidence lane for the native
`stats::binomial(link = "logit")` response family added in #569/#585. The
reader is a contributor preparing pilot or promotion artifacts after the fixed
effect likelihood has already landed.

## Aim

Check that `drmTMB` recovers fixed-effect binomial logit coefficients for the
two public response encodings and matches `stats::glm()` on the overlapping
likelihood. This lane is not evidence for random effects, structured effects,
bivariate binomial models, Julia bridge support, speed, or broad calibrated
interval claims.

## Data-Generating Mechanism

For each row,

```text
Y_i ~ Binomial(n_i, mu_i)
logit(mu_i) = beta_0 + beta_1 x_i
x_i ~ Normal(0, 1)
```

The `binary` encoding uses `n_i = 1` and stores the response as a 0/1 column.
The `cbind` encoding samples integer trial totals from a row-specific trial
band and stores successes and failures as `cbind(success, failure)`.

## Estimands

The lane estimates only the fixed `mu` coefficients:

- `mu:(Intercept)`;
- `mu:x`.

The truth is the DGP coefficient on the logit scale. The main estimator is the
`drmTMB` coefficient from `coef(fit, dpar = "mu")`; the comparator estimator is
the matching `stats::glm()` coefficient.

## Methods

The runner fits one `drmTMB` model and one `stats::glm()` comparator per
replicate:

```r
drmTMB(bf(y01 ~ x), family = stats::binomial(), data = dat)
glm(y01 ~ x, family = stats::binomial(), data = dat)

drmTMB(bf(cbind(success, failure) ~ x), family = stats::binomial(), data = dat)
glm(cbind(success, failure) ~ x, family = stats::binomial(), data = dat)
```

The comparator is deliberately `stats::glm()` rather than a broader package
survey. Later comparator work can add other packages only when the likelihood
and response encoding are matched.

## Performance Measures

Routine artifacts report bias, RMSE, bias MCSE, RMSE MCSE, convergence,
`pdHess`, warning rate, elapsed time, Wald intervals, and Wald coverage for the
`drmTMB` fixed coefficients. A separate comparator parity table reports maximum
absolute coefficient, standard-error, `logLik`, AIC, and BIC differences
between `drmTMB` and `stats::glm()`.

Pilot artifacts should use 25-100 replicates per condition and be labelled as
pilot evidence. Promotion artifacts need enough replicates to report MCSE for
coverage and failure rates before public interval-calibration language is used.

## Executed Artifacts

The first MCSE-backed interval-calibration artifact is:

```text
docs/dev-log/simulation-artifacts/2026-06-17-binomial-fe-interval-calibration/
```

It uses six cells, 500 replicates per cell, master seed `20260617`, and the two
public response encodings. The run attempted 3,000 fits and produced 6,000
coefficient rows. All 3,000 fits returned `ok`, the failure table is
header-only, the minimum convergence rate was 1.000, the minimum `pdHess` rate
was 1.000, and the maximum warning rate was 0.000.

Wald coverage across the 12 cell-by-parameter summaries ranged from 0.946 to
0.964, each with 500 intervals. The maximum coverage MCSE was 0.01010782. The
same run kept `stats::glm()` parity tight: maximum absolute coefficient
difference `1.502857e-08`, maximum absolute standard-error difference
`1.545213e-05`, maximum absolute `logLik` difference `1.750777e-11`, and
maximum absolute AIC/BIC difference `3.501555e-11`.

This artifact is a promotion-candidate evidence bundle for fixed-effect Wald
intervals in these audited cells. It is not evidence for random-effect
binomial models, structured binomial models, bivariate or mixed-response
binomial models, profile/bootstrap intervals, Julia bridge support, speed, or
release readiness.

## Boundaries

This lane keeps the #569 constraints:

- no `bernoulli()` alias;
- no proportions plus `weights`;
- no weights-as-trials route;
- no non-logit link;
- no `sigma`, `rho12`, `nu`, `zi`, `zoi`, or `coi`;
- no random effects, structured effects, bivariate response, or mixed response;
- no `engine = "julia"` claim.
