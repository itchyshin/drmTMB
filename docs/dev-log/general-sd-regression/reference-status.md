# Independent scalar-integration sensitivity

The one-seed logit Bernoulli pilot passed on Totoro in 75.932 seconds of
reference evaluation and optimization. It uses the predeclared 160-group,
16-repeat synthetic design. The native point has converged optimizer,
positive Hessian, small gradient and inactive clamp. The adaptive-reference
optimizer converged inside its stated numerical bounds, with largest absolute
finite-difference gradient 7.92e-5.

At the Laplace fitted parameters, native negative log likelihood was
1584.12455852288; the independent scalar Laplace calculation was
1584.12455851891. Adaptive integration gave 1583.14725278793. The independent
Laplace calculation checks implementation, while the adaptive reference
measures approximation sensitivity. These objectives need not be identical.

The fitted SD slope was 0.39830105 under Laplace and 0.39659931 under adaptive
integration, a difference of -0.00170174. The log-SD intercept changed by
0.01212253. These are one-seed sensitivity results, not calibration evidence.

Supplementary checks evaluated each of 160 clusters at the native fitted,
adaptive fitted and generating-truth parameters. Changing relative tolerance
from 1e-8 to 1e-10 changed any cluster log integral by at most 3.13e-13. Default
relative error estimates stayed below 1e-8 and tighter estimates below 1e-10.
The reference also passed 25 pure assertions, including probit-normal closed
form, normalization over count outcomes, logit symmetry and extreme
complementary-log-log lower-tail behaviour. The original lower-tail defect
and its RED/GREEN receipts remain visible.

Evidence lives in `evidence/reference-pilot-20261017/`, including both exact
reference-code versions. The original logit run preceded the complementary
log-log tail repair; that repair does not change its logit integrand. The
native point was checked from its frozen health record before interpreting
this result. The later supplementary checker enforces that health gate and
retains per-cluster diagnostics. Future sensitivity runs enforce health before
starting integration.

The production harness remains blocked until its separate generator,
source-binding, supervision and summary-identity repairs pass review.
Prose assessment: NOTASSESSED.
