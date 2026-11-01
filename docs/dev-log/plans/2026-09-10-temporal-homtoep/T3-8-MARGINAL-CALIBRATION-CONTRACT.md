# T3-8 — marginal homogeneous Toeplitz mean-effect interval calibration

## Claim under evaluation

This contract evaluates **95% likelihood-profile intervals for the three mean
regression coefficients** in the identified marginal covariance model

\[
y_i \sim N(X_i\beta,\;\sigma_T^2 R),
\qquad R=\operatorname{Toeplitz}(1,r_1,\ldots,r_{K-1}).
\]

It does not evaluate Wald intervals, `sigma_T`, lag correlations, forecasts,
new-data prediction, ordinary-intercept composition, or any latent-process
interpretation. Those quantities stay unavailable after this campaign.

The public interval route to qualify is

```r
confint(fit, parm = c("mu:(Intercept)", "mu:between", "mu:within"),
        method = "profile", profile_engine = "tmbprofile")
```

The current guard remains in place until deterministic profile identities and
the retained campaign both pass.

## Frozen generation and cells

All data use a complete six-occasion panel, `sigma_T = 0.8`, and
`beta = (0, 0.5, 0.5)` for intercept, between-series predictor, and
independently permuted balanced within-series predictor. Errors are generated
by independent dense Cholesky draws of `sigma_T^2 R`.

| Cell | Series x occasions | Correlation | Role |
| --- | ---: | --- | --- |
| P1 | 80 x 6 | AR1-shaped, `r_d = 0.55^d` | Primary restricted-decay reference |
| P2 | 80 x 6 | non-exponential admissible Toeplitz lags | Primary flexible-lag case |
| P3 | 80 x 6 | admissible negative first-lag pattern | Primary signed-correlation case |
| S1 | 20 x 4 | high short-panel persistence | Retained stress result only |

The exact partial-autocorrelation coordinates and the disjoint deterministic
seed streams are committed in the campaign runner before any pilot or campaign
output is created. Primary cells each have 1,000 data sets; S1 also has 1,000
but never determines a nominal-coverage pass.

## Denominators and summaries

For every coefficient-cell pair, the all-attempt denominator is all 1,000
generated data sets. A fit failure, profile failure, missing endpoint, or
non-finite interval counts as unavailable and as uncovered in that denominator.
The report also gives conditional coverage among available intervals, interval
availability, profile endpoint status, coefficient bias, empirical SD, median
width, elapsed time, and warnings. Failures remain in raw per-dataset output;
no seed is replaced or suppressed.

With 1,000 nominal 95% intervals, the coverage Monte Carlo SE is approximately
0.0069. Primary acceptance criteria are:

- interval availability at least 0.99;
- all-attempt coverage within 0.925--0.975;
- absolute coefficient bias no more than 0.10 empirical SD.

S1 is descriptive stress evidence. Its failures must be reported and explained,
not converted into a primary threshold or hidden by a seed change.

## Required sequence and compute boundary

1. Add deterministic profile tests: a fixed coefficient profile must agree with
   an independently constrained marginal likelihood, preserve the full
   covariance-parameter re-optimization, and reject every unsupported target.
2. Run a frozen five-seed-per-cell pre-run. It measures profile runtime,
   endpoint availability, memory, output completeness, and the cost of failed
   fits. The existing point-fit pilot cannot estimate profile cost.
3. Write the measured DRAC/Fir array plan: one data set per task, explicit
   thread cap, durable result path, and Totoro mirror after completion.
4. Obtain separate explicit approval for that measured external campaign.
5. The reverify gate reads immutable results and recomputes every denominator
   and criterion; it never launches a campaign.

No calculation in this document authorizes an external job, a push, or a
public inference claim.
