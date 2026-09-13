# Draft update for issue #1302: temporal random-effects follow-up

## Current state to retain

The initial stable-phylogeny-plus-independent-temporal-OU slice is no longer
an open design choice. It is implemented for univariate Gaussian ML, but its
retained calibration showed undercoverage for intercept-profile intervals.
It therefore remains diagnostic rather than inference-ready. This is an
additive covariance model, not a separable phylogeny-by-time process.

Independent temporal work that is complete at its earned scope is also
available: irregular-time OU location intercepts have calibrated fixed-mean
profile intervals only in their retained primary cells; homogeneous Toeplitz
has a regular-panel, marginal fixed-mean profile route; and heterogeneous AR1
has regular-panel fixed-mean Wald availability but no coverage calibration.
None of these results establishes a general temporal random-effects framework.

## Remaining programme

1. **Phylogenetically correlated temporal OU.** Derive and test the proposed
   separable field, with covariance
   `sigma_a^2 * A[i, j] * exp(-decay * abs(t - s))`, separately from the
   already implemented additive stable-phylogeny-plus-independent-time model.
   It needs an independent dense oracle, reductions, shuffled/unbalanced and
   irregular-time tests, simulation, and recovery before any public promotion.

2. **Temporal inference boundaries.** Do not infer interval support across
   structures. OU has a qualified fixed-mean profile result only in specified
   cells; homogeneous Toeplitz has a separate primary-cell profile result;
   heterogeneous AR1 has fit-level fixed-mean Wald availability only; and the
   additive phylogeny-plus-time model has failed its intercept-profile
   calibration. Variance, decay, persistence, residual-scale, forecast, and
   `newdata` intervals remain separate work.

3. **Temporal effects in `sigma`.** A residual-scale temporal field is not a
   location-side temporal intercept. Each structure needs a separate
   likelihood/identifiability decision, dense oracle, recovery and reader
   workflow; it cannot borrow location-side evidence.

4. **Broader grammar and response structures.** Temporal slopes, multiple or
   labelled temporal blocks, bivariate temporal correlation, missing-response
   routing, non-Gaussian temporal models, REML, forecasting, and `newdata` are
   not enabled by the existing univariate Gaussian ML slices.

## Reopen discipline

Take one estimand and one covariance structure at a time. Before an evidence
campaign, freeze the formula grammar, observation grain, covariance
decomposition, independent oracle, recovery conditions, and uncertainty claim.
Do not use clean convergence or a positive Hessian as a substitute for
identifiability or calibration.
