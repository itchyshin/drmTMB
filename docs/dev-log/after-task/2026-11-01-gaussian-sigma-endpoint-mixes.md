# After-task note: Gaussian sigma-endpoint SD guard, untested mixes

Date: 2026-11-01. Branch codex/general-sd-regression. Test file added:
tests/testthat/test-gaussian-sigma-endpoint-mixes-sd.R (no R/ changes).

## What was probed and evidenced

The guard admits one independent sigma random intercept or slope with an SD
formula. Three mixes had no test. All three fit (convergence 0, interior SDs) and
all match an independent dense Laplace oracle over the joint mu and sigma random
effects. The oracle is written from the per-observation Gaussian density with
analytic gradient and Hessian, finds the mode by nlminb plus Newton polishing,
and is evaluated at the fitted parameters. Tolerances were fixed before the first
run: absolute logLik difference below 1e-4, oracle mode gradient below 1e-8,
oracle Hessian positive definite.

- (a) y ~ x + (1 + x | id), sigma ~ 1 + (1 | g), sd(id, coef = "x") ~ w,
  sd(g, dpar = "sigma") ~ z. Oracle includes the 2x2 correlated block with
  constant intercept SD, varying slope SD and the fitted correlation.
- (b) y ~ x + (1 | id), sigma ~ 1 + (1 | id), each with an SD formula. The mu and
  sigma effects on the same group are independent in the model and in the oracle.
- (c) Each of the above, plus the different-group (1 | id) and (1 | g) pair, with
  meta_V(V = V) and a diagonal V. The oracle uses residual variance
  exp(2 eta) + V. A further test shows the V-free oracle misses a meta_V fit by
  more than 1 logLik unit, so the V term is genuinely in the likelihood.
- Constant SD formulas (sd ~ 1) reproduce the ordinary fit to 1e-5 logLik for (a),
  (b) and the meta_V version of (b).

## What is not covered

- No recovery, coverage or calibration claim; the fixtures are single seeds.
- Only sigma intercept effects were put in the sigma slot for these mixes; sigma
  slopes in the mixes, mu (1 + x | id) with sigma (1 | id) on the same group, and a
  correlated mu-sigma block are not tested.
- Dense (non-diagonal) meta_V matrices: the C++ builds Omega = V + diag(sigma^2),
  which is the right likelihood, but it was not oracle-tested. It is also
  impractically slow with a sigma random effect (n = 60: 19 s against 0.4 s for
  diagonal V; n = 100 and n = 200 did not finish in 80 s and 6 min). A usability
  refusal is proposed in batch7-gaussian-sigma-endpoint-mixes.patch; it is not
  applied. Nothing admitted by the guard was found to be unidentifiable or to use
  a wrong likelihood.
- Same-group mu and sigma effects are identified by within-group scale versus
  location heterogeneity; at small group sizes they can be weakly identified. Not
  stress-tested here.
