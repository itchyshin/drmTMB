# Gaussian Location-Scale Comparator Result

Date: 2026-05-10

Command:

```sh
Rscript tools/replicate-location-scale-gaussian.R
```

Purpose:

Check the current Gaussian location-scale overlap between `drmTMB` and
`glmmTMB` before moving the `0.1.0` preview-release gate forward. This is a
simulated, paper-shaped comparator, not a real-data replication of every
individual-difference location-scale example.

Current result table:

- `docs/dev-log/comparator-results/gaussian-location-scale-glmmtmb-current.csv`

## Results

| Scenario | Maximum absolute `mu` coefficient difference | Maximum absolute `sigma` coefficient difference | Maximum absolute `mu` random-effect SD difference | Absolute log-likelihood difference | Passed |
| --- | ---: | ---: | ---: | ---: | --- |
| Fixed-effect location-scale | `1.372665e-06` | `1.999083e-06` | `NA` | `3.964260e-10` | yes |
| Random-intercept location-scale | `6.226181e-08` | `6.677708e-06` | `6.810643e-07` | `2.117218e-09` | yes |

All finite differences were below the harness tolerance of `1e-4`.

## Blocked Future Examples

The same command writes blocked rows for richer individual-difference examples
so issue #6 can track evidence and scope in one file.

| Scenario | Status | Blocked by | Scale note |
| --- | --- | --- | --- |
| Shared `mu`/`sigma` covariance block | blocked | Cross-formula labelled covariance blocks are planned in issue #5. | Would compare correlations among individual mean and residual-scale effects. |
| Bivariate group-level covariance block | blocked | Bivariate group-level random effects are planned in issue #5. | Would compare group-level correlations separately from residual `rho12`. |
| Non-Gaussian location-scale random effects | blocked | Non-Gaussian random-effect location-scale paths are not implemented yet. | Would require family-specific random-effect likelihoods before comparators. |

## Scale Contract

The public fitted scale parameter remains `sigma`. Variance-facing summaries
for residual variance, predictability, or malleability should be reported as
derived `sigma^2` values where the scientific target is variance.

## Limitation

This result checks the current Gaussian `mu` and `sigma` implementation against
`glmmTMB` on simulated data. It does not fit future covariance blocks among
personality, plasticity, predictability, and malleability.
