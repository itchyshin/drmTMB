# Figure Audit: Gaussian Sigma Profile-Likelihood Curve

## Purpose

Check whether the new `plot.profile.drmTMB()` method can render a real fitted
profile-likelihood curve clearly enough for a later article slice.

## Evidence

- Source curve data:
  `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/sigma-profile-curve.csv`
- Rendered image:
  `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/sigma-profile-curve.png`
- Article source curve data:
  `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/model-workflow-site-sigma-profile-curve.csv`
- Rendered article image:
  `docs/dev-log/figure-audits/2026-05-27-profile-likelihood-sigma/model-workflow-site-sigma-profile-plot.png`
- Image size: 1152 by 720 pixels.
- Curve rows: 31 profile points plus a header row in the CSV.
- Rendered article image size: 1843 by 1152 pixels.
- Article curve rows: 30 profile points plus a header row in the CSV.

## Audit Table

| Figure | Source object | Visual data grain | Uncertainty source | Reader risk | Verdict | Fix |
| --- | --- | --- | --- | --- | --- | --- |
| Gaussian sigma profile-likelihood curve | `profile(fit, parm = "sigma", level = 0.80, profile_precision = "fast")` | Full `TMB::tmbprofile()` curve points for one fitted Gaussian `sigma` target | Likelihood-ratio cutoff and profile confidence endpoints from `stats::confint()` on the profile object | Generic x-axis label does not name `sigma`; later article readers may need target-specific wording | Pass for method evidence; not yet final article figure | In the article slice, relabel the x-axis or caption to name `sigma` explicitly |
| Model-workflow site `sigma` profile | `profile(fit_site, parm = "sigma", level = 0.95, profile_precision = "fast")` | Full `TMB::tmbprofile()` curve points for the article's site random-intercept model | Likelihood-ratio cutoff and 95% profile confidence endpoints from `stats::confint()` on the profile object | Figure is useful, but the article should keep telling readers that this is confidence/compatibility evidence, not posterior probability | Pass for article integration evidence | Keep this as the compact article figure; broader examples can wait |

## Role Notes

- Florence: the line and hollow points are legible, the estimate and endpoint
  guides are visible, and both plots are not blank or clipped.
- Fisher: the figure shows likelihood-ratio distance, not a posterior density
  or Wald interval. The cutoff and dashed endpoints are profile-derived.
- Noether: the x-axis is on the public positive `sigma` scale and the y-axis is
  `2 * (profile_nll - min(profile_nll))`.
- Pat: the article plot now names residual `sigma` in the x-axis and caption,
  which is clearer than the generic method label alone.
- Grace: the rendered PNG and source CSV are durable local evidence for this
  slice.
