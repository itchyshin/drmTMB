# Scalar A1 ML-versus-REML attribution protocol

## Question and boundary

This diagnostic asks whether ordinary Gaussian REML changes the scalar A1
random-intercept SD profile's directional-miss pattern relative to ML.  The
Gaussian random-intercept integral is exact in this design; this is not a
Laplace-refit-bias study.  The target is the natural-scale
`sd:mu:(1 | g)` with truth 0.5, for iid Gaussian random intercepts at 10, 25,
and 50 groups and 10 observations per group.

This protocol does not implement Arc D, reinterpret a clamped endpoint, expose
the association engine, change an interval default, add a bootstrap correction,
or make a public capability claim.  It also does not authorize remote compute.

## Paired arms and accounting

For every generated outer dataset, the runner fits both `REML = FALSE` (ML) and
`REML = TRUE` (REML).  The pair shares `cell_id`, `seed`, and `attempt_id`.
Every fit, non-converged fit, unavailable interval, and estimator-only failure
writes a row.  Unavailable intervals are noncoverage on a future campaign's
all-attempt denominator; an estimator-only failure is retained as a one-sided
paired failure, not removed from a contrast.

Profile and Wald endpoints are recorded.  Wald calls specify
`small_sample_df = "none"` and `bias_correct = "none"` in both arms.

## Oracle gate and symbolic alignment

For the fixed fixture, both implementations fit

\[
y = X\beta + Zu + \epsilon,\qquad
u \sim N(0,\tau^2 I),\quad \epsilon \sim N(0,\sigma^2 I),
\]

with `X = [1, x]`, a random-intercept incidence matrix `Z`, and target
\(\tau = \texttt{sd:mu:(1 | g)}\).  The ML reference profiles the ordinary
Gaussian likelihood.  The REML endpoint reference profiles the restricted
likelihood

\[
\ell_R(\tau,\sigma) = -\tfrac12\{\log|V| + \log|X^\top V^{-1}X|
+ y^\top P_Vy\}+C,
\quad V=\tau^2ZZ^\top+\sigma^2I,
\]

where \(P_V=V^{-1}-V^{-1}X(X^\top V^{-1}X)^{-1}X^\top V^{-1}\).

At every group count, `lme4::lmer()` must match the `drmTMB` ML and REML
point estimate and log likelihood within `1e-5`.  `lme4`'s ordinary ML profile
is the ML endpoint reference, with tolerance
`max(0.01, 0.02 * lme4_interval_width)`.  In lme4 2.0.1 its REML `profile()`
path reproduces the ML variance-component curve, so it is deliberately not a
REML endpoint oracle.  The direct restricted-likelihood profile above is used
for REML endpoint checks, with absolute endpoint tolerance `2e-4`.

A target mismatch, non-finite profile, or failed tolerance stops this protocol
before campaign preparation.  One local one-attempt-per-arm plumbing smoke may
run only after this oracle passes; it is not coverage evidence and cannot
advance the compute path.

## Future campaign interpretation

The future campaign reports, by group count and estimator, all-attempt coverage,
upper and lower miss probabilities, and their difference.  It repeats that
table for genuine zero lower profile endpoints and interior endpoints.

REML is a material contributor in a cell only if its paired reduction in the
directional-miss gap is at least 0.020 with a paired 95% confidence interval
excluding zero, without an all-attempt coverage loss of at least 0.020.  Passing
this diagnostic does not establish a public recommendation or eliminate
boundary/pivot geometry as a remaining explanation.
