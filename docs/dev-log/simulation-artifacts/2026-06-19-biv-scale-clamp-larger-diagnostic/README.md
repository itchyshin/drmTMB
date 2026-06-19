# Bivariate Scale Clamp Larger Diagnostic

This artifact deepens the fixed-effect bivariate Gaussian `sigma1`/`sigma2`
scale-clamp diagnostic for `drmTMB#59`. It is native R/TMB evidence only.
It does not test direct DRM.jl or the R-side Julia bridge.

The fitted model is
`bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ z1, sigma2 = ~ z2, rho12 = ~ 1)`
with `family = biv_gaussian()`. The runner compares the unclamped reference,
the default `log(sigma)` clamp, and a wide `c(-25, 25)` clamp.

The runner deliberately uses the default optimizer preset, one start, no
fallback optimizer, no manual retries, no profile intervals, and no bootstrap
intervals. Optimizer attempts, retry counts, clamp deltas, warnings,
`check_drm()` rows, and failures are recorded as data.

## Outputs

- `biv-scale-clamp-conditions.csv`: ten bivariate scale cells.
- `biv-scale-clamp-configs.csv`: off/default/wide clamp controls and intervention flags.
- `biv-scale-clamp-fit-diagnostics.csv`: per-fit coefficients, status, gradients, raw and reported scales, clamp deltas, and optimizer attempts.
- `biv-scale-clamp-comparisons.csv`: per-fit differences against the replicate-matched unclamped reference.
- `biv-scale-clamp-aggregate-summary.csv`: per-condition and per-config rates and differences.
- `biv-scale-clamp-condition-summary.csv`: condition-level denominators.
- `biv-scale-clamp-check-drm.csv`: full `check_drm()` rows for each fit.
- `biv-scale-clamp-failures.csv`: unexpected fit errors, if any.
- `biv-scale-clamp-run-summary.csv`: compact run-level counts.
- `session-info.txt`: software and platform details.

## Results

The diagnostic ran 1500 requested fits: 10 cells, 50 replicates per cell, and 3 clamp controls per replicate. There were 0 fit errors. 1492 fits converged and 1497 had `pdHess = TRUE`.

The default upper-clamp warning appeared 150 times, matching the three upper out-of-band cells. Raw-versus-reported log-scale deltas recorded 150 upper-side clamp-active fits and 100 lower-side clamp-active fits. The lower-side deltas are visible only through raw-versus-reported scale comparisons because `check_drm()` intentionally warns only for upper scale overflow.

Across all comparisons, the maximum absolute log-likelihood difference against the unclamped reference was 644.592.

The ordinary `rho12 = 0`, `rho12 = 0.8`, and `rho12 = -0.8` cells and the
near-upper in-band cell converged cleanly with no clamp-active fits. The
near-lower in-band cell also converged with `pdHess = TRUE`, but it retained
many fixed-gradient warnings and automatic optimizer preset escalations. The
lower out-of-band cells were rougher than the upper out-of-band cells: the
`sigma1_below_default` and `sigma2_below_default` rows retained fixed-gradient
warnings, some non-converged fits, and automatic optimizer escalation. The
`sigma2_below_default` wide-band row did not match the unclamped reference as
closely as the other wide-band rows. These rows remain diagnostic evidence
and should not be described as recovery or interval support.

This artifact extends diagnostic depth only. It does not show bivariate
scale-route recovery accuracy, interval coverage, power, q2/q4/q8 covariance
readiness, random effects in `rho12`, structured correlation readiness,
Julia bridge parity, release readiness, CRAN readiness, missing-data
behavior, or non-Gaussian REML/AI-REML claims.
