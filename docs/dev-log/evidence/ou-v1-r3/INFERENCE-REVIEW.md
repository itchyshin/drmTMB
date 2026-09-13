# Fisher review of R3 likelihood geometry

## Verdict

**G15 remains a no-go.** R3 establishes a strong rate--amplitude and
scale-boundary geometry problem in the stored R2 likelihood, but it does not
fully exclude a high-dimensional Laplace-approximation contribution.

For the retained data set generated at `(alpha_mu, alpha_sigma) = (0.7, 1.3)`,
the grid truth point is 2.885 objective units above the grid minimum at `(8,
8)`. Moving toward that minimum reduces the fitted field SDs from about
`(0.53, 0)` at truth to `(0.19, 0.057)` at the grid optimum. Across much of
the profile, the fitted sigma-field SD collapses to roughly `1e-6` or lower
while the objective barely changes over `alpha_sigma = 0.3` to `3`.

The complementary retained data set is healthier for `alpha_mu` but retains a
shallow sigma-rate direction: its truth `(1.3, 0.7)` is only 0.040 objective
units above the grid minimum `(1.3, 1.3)`.

The three-tip Gauss--Hermite and TMB Laplace objectives agree to about
`4.4e-10` at the one plug-in fitted hyperparameter point. That validates the
small fixed-point calculation, but it is not evidence that the 128-tip
Laplace approximation is negligible: the receipt does not retain the plug-in
intercepts/SDs and does not establish that the scale field is interior.

## Required next scope: R3.1

Do not launch G15. A separate R3.1 exact-marginal diagnostic must compare TMB
Laplace and independent quadrature at two fully retained small-tree points:

1. the interior truth `(alpha_mu, alpha_sigma, sd_mu, sd_sigma) =
   (0.7, 1.3, 0.45, 0.25)`; and
2. a prespecified high-alpha/low-SD ridge point.

It must retain fixed intercepts, both SDs, both rates, data/tree hashes, and
the quadrature-refinement error at both points. Agreement at the interior
point would support a genuine-information-geometry conclusion; material
divergence would require repairing or changing the marginal estimator before
any recovery campaign.
