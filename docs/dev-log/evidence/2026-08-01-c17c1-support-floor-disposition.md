# C17-C1 support-floor disposition

## Owner decision

On 2026-08-01, after reviewing the prospective run and the exact
attainability audit, Shinichi directed the team not to make the capability gate
overly harsh or restrictive: proceed with the scoped implementation and test
the sparse-support limitation further later.

Accordingly, the rule requiring at least two observed zeroes and two observed
ones in every one of 64 groups is reclassified from a promotion block to a
sample-information warning for `mc-0570`. This is a deliberate owner decision,
not a claim that the frozen run passed its original hard support gate.

## Evidence basis

- The exact DGP gives the original all-four support rule only a `0.3701`
  probability of passing; it therefore has a `0.6299` stochastic false-block
  probability even under a correct generator.
- The prospective run retained all four unconditional M=64 attempts. All four
  passed convergence, Hessian, gradient, non-boundary SD, mode-correlation,
  rung-mean fixed-effect/SD recovery, and boundary-only comparator gates.
- The full mixture plus normalized latent-density oracle and central finite-
  difference gradient check pass against TMB.
- Current-source non-regression for `mc-0568`, `mc-0569`, and `mc-0576` passed
  12/12 with `n_coi_re_terms = 0`.

The raw prospective receipt remains `BLOCKED_POINT_RECOVERY` under its original
contract and is not rewritten. The promotion evidence cites this disposition
and the unconditional estimator results together.

## Earned claim

Only the exact complete-response ML-Laplace route is admitted:

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))
```

The maximum tier is `implemented / verified / point_fit_recovery`. The model
recovered population-level fixed effects and latent `sd_coi` at the M=64,
50-observations-per-group rung. Conditional modes for groups with fewer than
two observed zeroes or ones may be weakly identified; users should inspect the
within-group atom counts and interpret those modes cautiously.

## Deferred validation

Later work may vary observations per group, atom probabilities, latent SD, and
the frequency of sparse group-specific atom support. That work does not block
the exact point-fit implementation and must not be described as profile,
interval, coverage, inference-ready, or package-level support evidence.

`coi` slopes, simultaneous atom random effects, structured/q2-plus effects,
missing responses, REML/AGHQ, formula-grammar changes, profiles, intervals,
coverage, Lane A, and Lane B remain outside C17-C1.
