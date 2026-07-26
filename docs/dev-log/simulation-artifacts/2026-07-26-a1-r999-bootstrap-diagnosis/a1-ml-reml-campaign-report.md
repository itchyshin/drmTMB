# Scalar A1 ML-versus-REML profile-attribution result

## Result

For the frozen Gaussian iid random-intercept design (`tau = 0.5`, ten
observations per group), ordinary REML materially reduced the profile interval's
upper-minus-lower miss gap at 10 and 25 groups.  It did not meet the same
pre-registered threshold at 50 groups.

| Groups | ML gap | REML gap | Paired reduction (95% bootstrap CI) | ML coverage | REML coverage | Verdict |
| ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 10 | 0.043 | 0.009 | 0.034 (0.023, 0.046) | 0.937 | 0.955 | material contributor |
| 25 | 0.028 | 0.007 | 0.021 (0.013, 0.030) | 0.942 | 0.953 | material contributor |
| 50 | 0.033 | 0.017 | 0.016 (0.009, 0.024) | 0.941 | 0.953 | not material by rule |

The rule required a paired directional-gap reduction of at least 0.020, a
paired 95% interval excluding zero, and no all-attempt coverage reduction of
at least 0.020.  Coverage increased by 0.018, 0.011, and 0.012 respectively.
At 25 groups the interval includes reductions below 0.020; the point estimate
meets the pre-registered materiality threshold, while the interval establishes
a positive—not necessarily at-least-0.020—reduction.

## Interpretation

This rejects the phrasing “Laplace refit bias” for this exact Gaussian design:
the random-effect integral is exact.  It supports a narrower conclusion that
ordinary ML variance-component centring contributes materially to the observed
profile upper-tail asymmetry at low and moderate group counts.  It does not
eliminate profile-boundary or pivot geometry as additional explanations, and it
does not establish a general profile-first recommendation.

All 6,000 estimator-attempt rows were retained; profile intervals were finite
in every row.  The result is limited to this scalar iid Gaussian random
intercept, ten-observations-per-group design and the tested automatic profile
route.
