# Task B — TMB 1.9.21 adaptive marginal-GK probe

## Verdict

The isolated mechanism is numerically promising but **the approved gate did
not pass**. TMB 1.9.21 successfully removed and integrated all 40 independent
random intercepts with adaptive marginal Gauss-Kronrod integration, and its
normalized objective was within about `1.07e-9` of the direct integral.
However, that discrepancy is outside the direct oracle's propagated normalized
negative-log-likelihood error estimate (about `2.98e-10`, or 3.6 times smaller).
More decisively, the frozen
fixture has its maximum at the zero random-effect-SD boundary: the TMB
log-SD fits stopped at different tiny positive SDs with nonzero convergence
codes, while both `glmer` fits reached effectively zero. Parameter agreement
cannot be assessed at an identified interior optimum, so the parameter part of
the approved gate also fails.

This is a negative/inconclusive Slice-0 result. It does **not** greenlight
drmTMB package wiring, establish an approximately unbiased SD, or support
`mc-0061` (which is a random slope, whereas this probe is a random intercept).

## Frozen fixture and methods

The probe preserves the exact seed-`20260801` cell from the prior 80-seed
study: `M=40`, two Bernoulli observations per group, true random-intercept SD
0.8, and fixed coefficients -0.2 and 0.7. The prior fixture mean-centers its 40
simulated effects. That choice is retained only to make this a same-data
mechanism comparison; it is not valid population-SD evidence.

The standalone `binomial_ri.cpp` template was compiled with TMB 1.9.21's
`TMBad` framework. The five comparators were:

- ordinary TMB Laplace integration;
- TMB adaptive marginal Gauss-Kronrod via
  `integrate = list(u = TMB:::GK(adaptive = TRUE))`;
- `lme4::glmer(nAGQ=1)`;
- `lme4::glmer(nAGQ=25)`;
- a direct sum of 40 independently tightened one-dimensional
  `stats::integrate()` calls after standard-normal reparameterization.

Each optimizer used three starts. The direct oracle used 2,000 subdivisions,
`rel.tol=1e-11`, and `abs.tol=1e-12`; outer optimizers used tightened iteration
and relative-tolerance controls. TMB 1.9.21 exposes only `adaptive` and `debug`
for marginal-GK, so its internal integration tolerances could not be tightened
from R and were not represented as tightened.

## Structural integration check

The transformed TMB objective contained only `beta`, `beta`, and `log_sd` in
its outer parameter vector, and `length(obj_gk$env$random)` was zero. Thus all
intended `u` entries were removed from the active domain rather than silently
left for Laplace integration.

## Returned parameter candidates

| Method | beta0 | beta1 | fitted SD | convergence | max absolute gradient |
|---|---:|---:|---:|---:|---:|
| Direct independent integrals | 0.06718284 | 0.54554562 | 4.94e-5 | 1 | 1.39e-8 |
| `glmer(nAGQ=1)` | 0.06718287 | 0.54554561 | 4.85e-8 | 0 | 1.64e-5 |
| `glmer(nAGQ=25)` | 0.06718286 | 0.54554562 | 4.26e-8 | 0 | 1.63e-5 |
| TMB adaptive marginal-GK | 0.06718284 | 0.54554562 | 7.77e-6 | 1 (false convergence) | 2.62e-7 |
| TMB Laplace | 0.06718284 | 0.54554562 | 5.59e-5 | 1 (singular convergence) | 1.01e-8 |

The table selects the lowest objective returned by each method's three starts;
it does not claim that any selected row is an attained optimum. All reported
gradients are finite, but the three starts stopped at different tiny SDs on the
nearly flat boundary. Cross-evaluation on the common grid found a direct-oracle
value `3.89e-9` below the selected direct row and a marginal-GK value `3.64e-11`
below the selected GK row. These small improvements reinforce the
boundary/nonconvergence diagnosis. The SD values are numerical representations
of a singular boundary solution, not evidence of parameter agreement at an
identified interior solution.

## Common-vector objective result

At the true positive-SD vector, the TMB marginal-GK raw negative
log-likelihood differed from the direct oracle by `7.17e-9`. At the fitted
near-boundary vectors the raw difference was about `8.23e-9`; after normalizing
each objective at the true vector, the difference was about `1.07e-9`.
`stats::integrate()` reports error on the probability-integral scale, so the
runner propagates every group error estimate through `-log()` before summing.
The resulting negative-log-likelihood error estimate was `1.09e-10` at the truth and
about `1.89e-10` near the boundary. Combining the evaluated point and the truth
reference gives a normalized-objective estimate of about `2.98e-10`.

`glmer(nAGQ=25)` matched the direct objective within `1.42e-14` after
normalization, and repeated stateful deviance-function calls differed by zero
at the printed precision. TMB Laplace and `glmer(nAGQ=1)` differed by about
`3.04e-6` after normalization near the boundary.

These checks show that TMB's transformation is integrating the intended
one-dimensional factors and closely approximates the high-accuracy marginal
objective. They do not satisfy the approved stronger gate, because neither
the objective discrepancy falls inside the corrected recorded numerical-error
envelope nor is
parameter agreement assessable at an identified interior optimum.

## Retained evidence and boundaries

- `fixture.tsv`: exact frozen data;
- `fit-results.tsv`: all methods and all three starts;
- `best-fits.tsv`: lowest returned objective row per method, not a demonstrated
  optimum;
- `objective-grid.tsv`: raw and truth-normalized common-vector objectives,
  repeat-call checks, probability-integral errors, propagated
  negative-log-likelihood error estimates, and normalized error estimates;
- `manifest.tsv`: versions, method, structural check, and source hashes;
- `run-probe.R` and `binomial_ri.cpp`: complete reproducer.

No drmTMB R or C++ package path changed. A later probe would need a
pre-specified non-singular fixture or small design set and a declared tolerance
policy for TMB's non-user-configurable marginal-GK error before Slice 1 could
be reconsidered. That follow-up, AGHQ package integration, bias campaigns,
Task C, and any `mc-0061` inference claim remain outside this probe.
