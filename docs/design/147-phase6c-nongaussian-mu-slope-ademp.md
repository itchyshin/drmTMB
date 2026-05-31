# Phase 6c Non-Gaussian `mu` Slope Admission Gate

This note records the #441 admission decision for ordinary independent
non-Gaussian `mu` slopes before #446 designs the larger recovery, accuracy,
coverage, and power grids.

## Gate Result

Selected non-Gaussian independent `mu` slopes are admitted as family-specific
first slices, not as broad non-Gaussian random-effect parity.

| Family route | Admission status | Evidence now | Held from |
| --- | --- | --- | --- |
| Ordinary Poisson `mu` | `ready_grid` | `tests/testthat/test-poisson-mean.R` covers fitting, prediction, extraction, profile targets, diagnostics, and weak-SD checks. The registry maps `poisson_mu_random_effects` to `first_wave_summary`. | Zero-inflated Poisson random effects, correlated slopes, labelled covariance, structured slopes, and bivariate/mixed count models. |
| Ordinary NB2 `mu` | `ready_grid` | `tests/testthat/test-nbinom2-location-scale.R` covers fitting, prediction, extraction, profile targets, diagnostics, and weak-SD checks. The registry maps `nbinom2_mu_random_effects` to `first_wave_summary`. | Zero-inflated or hurdle random effects, correlated slopes, labelled covariance, NB2 `sigma` slopes, structured slopes, and bivariate/mixed count models. |
| Student-t `mu` | `ready_source_test` | `tests/testthat/test-nongaussian-mu-random-slopes.R` fits `(0 + x | id)` and checks convergence, `pdHess`, design values, `sdpars$mu`, `ranef()`, prediction, `profile_targets()`, and `check_drm()`. The registry maps `student_mu_random_effects` to the random-intercept artifact route while slope evidence remains source-tested. | Student-t `sigma` or `nu` random effects, correlated slopes, labelled covariance, structured effects, and bivariate Student-t. |
| Lognormal `mu` | `ready_source_test` | The shared non-Gaussian slope source test covers fitting, extraction, prediction, profile-target discovery, and diagnostics. The registry maps `positive_continuous_mu_random_effects` to the random-intercept artifact route while slope evidence remains source-tested. | Lognormal `sigma` random effects, correlated slopes, labelled covariance, known covariance, structured effects, and bivariate/mixed lognormal models. |
| Gamma `mu` | `ready_source_test` | The shared non-Gaussian slope source test covers fitting, extraction, prediction, profile-target discovery, and diagnostics. The registry maps `positive_continuous_mu_random_effects` to the random-intercept artifact route while slope evidence remains source-tested. | Gamma `sigma` random effects, correlated slopes, labelled covariance, non-log links, known covariance, structured effects, and bivariate/mixed Gamma models. |
| Beta `mu` | `ready_source_test` | The shared non-Gaussian slope source test covers strict `(0, 1)` responses, fitting, extraction, prediction, profile-target discovery, and diagnostics. The registry maps `bounded_mu_random_effects` to the random-intercept artifact route while slope evidence remains source-tested. | Beta `sigma` random effects, exact-boundary mass, correlated slopes, labelled covariance, structured effects, and bivariate/mixed beta models. |
| Beta-binomial `mu` | `ready_source_test` | The shared non-Gaussian slope source test covers counted successes out of known trials, fitting, extraction, prediction, profile-target discovery, and diagnostics. The registry maps `bounded_mu_random_effects` to the random-intercept artifact route while slope evidence remains source-tested. | Beta-binomial `sigma` random effects, zero-one inflation, correlated slopes, labelled covariance, structured effects, and bivariate/mixed beta-binomial models. |
| Zero-truncated NB2 `mu` | `ready_source_test` | The shared non-Gaussian slope source test covers positive counts, fitting, extraction, prediction, profile-target discovery, and diagnostics. The registry maps `truncated_nbinom2_mu_random_effects` to the random-intercept artifact route while slope evidence remains source-tested. | Correlated truncated-NB2 slopes, hurdle-side random effects, `sigma` random effects, structured effects, and bivariate/mixed truncated count models. |

Tweedie, zero-one beta, hurdle or zero-inflated count random effects, ordinal
random effects, shape random effects, non-Gaussian `sigma` random effects
outside the narrow NB2 random-intercept gate, correlated slopes, labelled
non-Gaussian covariance, structured non-Gaussian slopes, and mixed-response
bivariate models remain planned or blocked.

## ADEMP Sketch For #446

Aim: quantify when the source-tested independent `mu` slope rows recover
random-slope SDs and fixed effects well enough for public simulation and
tutorial claims.

Data-generating mechanisms: one ordinary grouping factor, one centered numeric
predictor, one independent random slope `(0 + x | id)`, and family-specific
response generation for Student-t, lognormal, Gamma, beta, beta-binomial, and
zero-truncated NB2. Count Poisson and NB2 rows can use the existing
`first_wave_summary` route as the stronger starting point.

Estimands: fixed `mu` coefficients, random-slope SDs on the link scale,
response-scale predictions, convergence, Hessian status, and direct
`log_sd_mu` profile-target availability.

Methods: fit the implemented `drmTMB` route for each family and keep all
neighbouring unsupported syntax out of the grid. Do not use fixed-effect-only
comparators as evidence for random-slope recovery unless #60 defines matched
targets.

Performance measures: bias and RMSE for fixed effects and random-slope SDs,
empirical interval coverage where a direct interval route is available,
convergence and `pdHess` rates, boundary-SD rates, warning/error counts, and
runtime. Report attempted fits, converged fits, usable interval counts, and
Monte Carlo SE for simulation summaries.

Reporting: every table should name the family, link, dpar, grouping factor,
random-effect term, artifact grain, and whether the row is `ready_grid`,
`ready_source_test`, `blocked`, or `design_only`.

## Follow-Up Routing

No new extractor or parser issue is needed for #441. #446 owns the
slope-specific recovery, coverage, power, convergence, and report-design work.
#59 owns the broader Phase 18 simulation programme, and #128 remains the wider
random-effect slope-capacity ledger.
