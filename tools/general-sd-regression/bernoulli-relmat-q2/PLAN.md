# Native Bernoulli logit relmat q2 fixed-seed check

Frozen before native fitting on 2026-10-28. This is one local implementation
check, not interval calibration or a Julia parity claim.

- Seed `2026102817`; 160 groups and 32 observations per group. Fixed effects
  `(0.2, 0.3)`. Independent latent vectors are drawn from the supplied named
  full `K`. The kernel is AR(0.25) with diagonal `seq(0.8, 1.3)`; the fitted K
  order is even groups then odd groups, while the factor levels are reversed.
  A Q fit independently permutes `solve(K)`.
- Intercept SD truth is `(log(0.8), +0.6)` with group predictor alternating
  `-1,+1`; slope SD truth is `(log(0.6), -0.5)` with group predictor `-1`
  for the first half and `+1` for the second half. Within-group `x` spans
  `[-1.2,1.2]`. Outcomes are one Bernoulli draw per row, with no clipping,
  centering, or forced outcome counts.
- Main fit: convergence 0; each SD slope absolute error below 0.4. Dense
  independent Laplace NLL and conditional linear predictors differ from native
  by at most `1e-4`; independently optimized mode gradient infinity norm
  below `1e-5`. An analytic score and Hessian are checked against finite
  differences away from the mode.
- The two SD slopes are the only preregistered truth-recovery gates. Fixed
  effects and SD intercepts are reported, without post-fit truth thresholds.
- A second fixed fixture uses 32 groups and 12 repeats for comparator fits.
  K/Q and reversed-SD-order negative log likelihoods must agree within
  `1e-4`; named fixed and SD coefficients within `1e-3`. Constant-SD and
  no-SD base likelihoods must agree within `1e-4`, and their two field SD
  scales within `1e-3`. Report each fit's convergence, `pdHess` when present,
  and maximum fixed-parameter gradient.
- Checks also cover K/Q and reversed SD order agreement, constant-SD/base
  equivalence, two canonical coefficient target names, all observation row
  mappings, no free field scalar scales or correlation, target discovery,
  fresh marginal simulation, storage, and a two-replicate bootstrap refit.
  The bootstrap check is workflow evidence only. It does not establish interval
  coverage, and successful q2 profile interval execution remains open.
- Estimated wall time before runs: native package rebuild at most 120 seconds;
  focused fit and independent oracle at most 300 seconds; affected Binomial
  neighbors at most 300 seconds; standalone example at most 60 seconds.
  Stop and report if an estimate is exceeded. One compiler process and one
  BLAS/OpenMP thread on the Mac.
