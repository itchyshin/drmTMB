# Release Audit: 0.1.0 Family Coverage

## Goal

Check whether every model family intended for the `0.1.0` preview has enough
test evidence to be user-facing: simulation or recovery, an independent
likelihood or comparator, boundary or malformed-input checks, and basic method
coverage where relevant.

## Scope Decision

This audit treats the implemented fixed-effect and already-tested random-effect
paths as in scope for `0.1.0`. It does not require new double-hierarchical
covariance blocks, ordinal scale or discrimination formulae, denominator
response aliases, skew-normal, spatial effects, or phylogenetic scale effects.
Those remain post-`0.1.0` roadmap work.

## Coverage Table

| Implemented path | Main evidence | Release judgement |
| --- | --- | --- |
| Gaussian location-scale fixed effects | `tests/testthat/test-gaussian-location-scale.R` checks fixed effects, complete-case filtering, prediction, transformations, likelihood weights, default `sigma`, and unsupported syntax. | Covered for preview. |
| Gaussian `mu` random effects and residual-scale random intercepts | `tests/testthat/test-gaussian-random-intercepts.R` covers `mu` random intercepts, numeric random slopes, correlated blocks, labelled blocks, residual-scale random intercepts, missingness, boundary cases, and unsupported terms. | Covered for preview. |
| Gaussian random-effect scale formulae | `tests/testthat/test-gaussian-random-effect-scale.R` checks recovery for `sd(id) ~`, multiple scale formulae, zero slopes, factor predictors, missingness, and ambiguous-target errors. | Covered for preview. |
| Gaussian known sampling variance or covariance | `tests/testthat/test-meta-known-v.R` checks diagonal and full known `V`, base R MVN likelihood agreement, random intercepts, random-effect scale formulae, near-zero heterogeneity starts, row filtering, and invalid covariance matrices. | Covered for preview. |
| Bivariate Gaussian location-coscale | `tests/testthat/test-biv-gaussian.R` checks constant and predictor-dependent `rho12`, `mvbind()` shorthand, composed Gaussian family syntax, known `V`, likelihood weights, residual `rho12` versus sampling correlation, simulation, and unsupported syntax. | Covered for preview. |
| Student-t location-scale-shape | `tests/testthat/test-student-location-scale.R` checks recovery-like fitting, an independent R likelihood, simulation, residuals, and clear rejection of unsupported early-phase terms. | Covered for preview. |
| Lognormal location-scale | `tests/testthat/test-lognormal-location-scale.R` checks fitting, independent `dlnorm()` likelihood agreement, methods and simulation, factor and scale edge cases, complete-case filtering, and invalid inputs. | Covered for preview. |
| Gamma mean-CV | `tests/testthat/test-gamma-location-scale.R` checks fitting, independent `dgamma()` likelihood agreement, method scales, simulation, coefficient-of-variation edge cases, complete-case filtering, and invalid inputs. | Covered for preview. |
| Beta mean-scale | `tests/testthat/test-beta-location-scale.R` checks fitting, independent `dbeta()` likelihood agreement, public `sigma` methods, simulation, scale edge cases, complete-case filtering, boundary rejection, and unsupported terms. | Covered for preview. |
| Beta-binomial | `tests/testthat/test-beta-binomial.R` checks fitting, independent beta-binomial likelihood agreement, probability and overdispersion methods, likelihood weights, simulation, complete-case filtering, boundary count patterns, and malformed inputs. | Covered for preview. |
| Cumulative-logit ordinal | `tests/testthat/test-cumulative-logit.R` checks fitting, independent category probabilities, weights, methods, simulation, integer scores, factor predictors, more than three categories, sparse categories, extreme probabilities, and malformed responses. | Covered for preview as location-only ordinal. |
| Poisson mean | `tests/testthat/test-poisson-mean.R` checks fitting, independent `dpois()` likelihood agreement, row weights, base `glm()` overlap, exposure offsets, simulation, complete-case filtering, and invalid inputs. | Covered for preview. |
| Zero-inflated Poisson | `tests/testthat/test-zi-poisson.R` checks fitting through `zi ~`, independent likelihood agreement, exposure offsets, count-scale methods, simulation, near-zero zero inflation, near-certain structural zeros, complete-case filtering, and invalid inputs. | Covered for preview. |
| Negative-binomial 2 | `tests/testthat/test-nbinom2-location-scale.R` checks fitting, independent `dnbinom()` likelihood agreement, exposure offsets, likelihood weights, methods, simulation, complete-case filtering, small-overdispersion Poisson limit, and invalid inputs. | Covered for preview. |
| Zero-inflated NB2 | `tests/testthat/test-zi-nbinom2.R` checks fitting through `zi ~`, independent likelihood agreement, exposure offsets, methods, simulation, near-zero zero inflation, near-certain structural zeros, complete-case filtering, and invalid inputs. | Covered for preview. |
| Zero-truncated NB2 | `tests/testthat/test-truncated-nbinom2-location-scale.R` checks fitting, independent truncated `dnbinom()` likelihood agreement, positive-count methods, simulation, complete-case filtering, small-overdispersion zero-truncated Poisson limit, factor predictors, scale extremes, and invalid inputs. | Covered for preview. |
| Hurdle NB2 | `tests/testthat/test-hurdle-nbinom2.R` checks fitting through `hu ~`, independent likelihood agreement, unconditional summaries, simulation, complete-case filtering, small-overdispersion hurdle Poisson limit, and invalid inputs. | Covered for preview. |
| Intercept-only phylogenetic Gaussian `mu` | `tests/testthat/test-phylo-gaussian.R` and `tests/testthat/test-phylo-utils.R` check fitted phylogenetic `mu`, dense marginal likelihood agreement, known `V` composition, conditional predictions, missingness, tree validation, dense Brownian covariance helpers, sparse augmented precision helpers, and TMB prior parity. | Covered for preview as intercept-only `mu`. |

## Audit Searches

The audit used these source scans:

```sh
rg -n "test_that\\(" tests/testthat/test-{beta-binomial,beta-location-scale,biv-gaussian,cumulative-logit,gamma-location-scale,gaussian-location-scale,gaussian-random-effect-scale,gaussian-random-intercepts,hurdle-nbinom2,lognormal-location-scale,meta-known-v,nbinom2-location-scale,phylo-gaussian,poisson-mean,student-location-scale,truncated-nbinom2-location-scale,zi-nbinom2,zi-poisson}.R
rg -n "likelihood matches independent|matches independent|comparator|recover|reject|unsupported|malformed|boundary|edge|complete-case|weights|simulation|simulate|finite|approaches|offset|zero" tests/testthat/test-{beta-binomial,beta-location-scale,biv-gaussian,cumulative-logit,gamma-location-scale,gaussian-location-scale,gaussian-random-effect-scale,gaussian-random-intercepts,hurdle-nbinom2,lognormal-location-scale,meta-known-v,nbinom2-location-scale,phylo-gaussian,poisson-mean,student-location-scale,truncated-nbinom2-location-scale,zi-nbinom2,zi-poisson}.R
```

## Gaps Kept Out Of 0.1.0

The audit does not clear the following for release because they are not claimed
as implemented preview features:

- ordinal scale or discrimination formulae;
- denominator aliases beyond `cbind(successes, failures)`;
- bivariate random-effect covariance and cross-parameter correlation pairs;
- non-Gaussian random effects and structured effects;
- skew-normal or skew-t families;
- routine spatial fitting;
- phylogenetic terms outside intercept-only Gaussian `mu`.

## Release Judgement

The implemented family surface is adequately covered for a `0.1.0` preview,
provided the full test suite and package checks continue to pass. The next
quality improvement is not more release-gate wording; it is executable paper
replication scripts for selected Gaussian individual-difference location-scale
examples after data and transformations are pinned.
