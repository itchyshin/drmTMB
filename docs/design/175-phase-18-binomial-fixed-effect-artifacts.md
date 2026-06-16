# Phase 18 Binomial Fixed-Effect Artifact Lane

This note records the first Phase 18 evidence lane for the native
`stats::binomial(link = "logit")` response family added in #569/#585. The
reader is a contributor preparing pilot or promotion artifacts after the fixed
effect likelihood has already landed.

## Aim

Check that `drmTMB` recovers fixed-effect binomial logit coefficients for the
two public response encodings and matches `stats::glm()` on the overlapping
likelihood. This lane is not evidence for random effects, structured effects,
bivariate binomial models, Julia bridge support, speed, or calibrated interval
claims.

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

## Boundaries

This lane keeps the #569 constraints:

- no `bernoulli()` alias;
- no proportions plus `weights`;
- no weights-as-trials route;
- no non-logit link;
- no `sigma`, `rho12`, `nu`, `zi`, `zoi`, or `coi`;
- no random effects, structured effects, bivariate response, or mixed response;
- no `engine = "julia"` claim.
