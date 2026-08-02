# C17-C1 prospective recovery contract

## Purpose

This contract prospectively adjudicates the exact complete-response ML-Laplace
`zero_one_beta()` route

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))
```

after two retained exploratory runs exposed ambiguity in factor-level ordering.
It is committed before execution. No outcome from the seeds below has been
inspected when this contract is written.

## Frozen denominator

- Runner: `tools/run-lane-c-c17c1-zob-coi-intercept-recovery.R`
- Groups: `M = 16, 32, 64`, with 50 observations per group
- Seeds: `2026081711:2026081714`
- Group levels: declared and asserted as `g1, ..., gM`
- Random-effect target: `sd_coi = 0.45`
- Generation: exactly once per `(M, seed)`, without support-conditioned
  resampling, replacement, filtering, or seed substitution
- Compute: Totoro, single process, single-threaded BLAS/OpenMP

The DGP otherwise remains the approved C17-C1 contract: centred-within-group
and globally scaled `x`; `mu = logit^-1(-0.15 + 0.35 x)`;
`sigma = exp(-1)`; `zoi = logit^-1(-0.40)`; and
`coi = logit^-1(0.10 + b_g)` with `b_g ~ N(0, 0.45^2)`.

## Hard M=64 gate

All four M=64 attempts must have convergence zero, `pdHess = TRUE`, maximum
gradient at most `0.01`, `0.05 < sd_coi_hat < 2.5`, mode correlation above
`0.45`, and at least two zeroes, two ones, and ten interior observations in
every group. Rung-mean absolute errors must be at most `0.20` for the four
fixed effects, at most `0.15` for `log_sigma`, and mean relative `sd_coi` error
at most `0.40`. The maximum common-parameter difference from the boundary-only
`lme4::glmer()` comparator must be at most `1e-3`.

`M = 16` and `M = 32` remain diagnostic only. Every attempt is retained.

## Interpretation boundary

A pass supports only `implemented / verified / point_fit_recovery` for the
exact route above. A failure remains load-bearing. Neither result supports a
`coi` slope, simultaneous atom random effects, structured/q2-plus effects,
missing responses, REML/AGHQ, profiles, intervals, coverage, inference
readiness, or package-level support.

The historical M=32 boundary collapse, Totoro run 1, and corrected-order run 2
remain visible and are not replaced by this prospective denominator.
