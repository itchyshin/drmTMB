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

## Oracle gate

Before remote campaign preparation or compute, one deterministic fixture at each group count must
match `lme4::lmer()` under both ML and REML.  Absolute random-effect SD and log
likelihood deltas must not exceed `1e-5`; each profile endpoint delta must not
exceed `max(0.01, 0.02 * lme4_interval_width)`.  A target mismatch, non-finite
profile, or failed tolerance stops this protocol before campaign preparation.
One local one-attempt-per-arm plumbing smoke may run before the oracle; it is
not coverage evidence and cannot advance the compute path.

## Future campaign interpretation

The future campaign reports, by group count and estimator, all-attempt coverage,
upper and lower miss probabilities, and their difference.  It repeats that
table for genuine zero lower profile endpoints and interior endpoints.

REML is a material contributor in a cell only if its paired reduction in the
directional-miss gap is at least 0.020 with a paired 95% confidence interval
excluding zero, without an all-attempt coverage loss of at least 0.020.  Passing
this diagnostic does not establish a public recommendation or eliminate
boundary/pivot geometry as a remaining explanation.
