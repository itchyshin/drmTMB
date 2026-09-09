# Temporal AR1 calibration pilot

This is the measured five-seed-per-cell pilot that precedes the proposed
1,000-replicate-per-cell Wald-interval campaign. It uses the exact five
predeclared ADEMP cells: C1 80 by 6 with persistence 0.4, C2 80 by 24 with
persistence 0.85, C3 80 by 12 with persistence -0.6, C4 AR1-only 80 by 12
with persistence 0.4, and stress cell C5 20 by 6 with persistence 0.85.

All data use `beta = (0, 0.5, 0.5)`, ordinary-intercept SD `0.6` where that
term is present, temporal-process SD `0.8`, and residual SD `0.4`. The data
generator uses a dense Cholesky AR1 covariance independently for every series.

The runner retains all two-start attempts, selected-fit diagnostics, interval
availability for all three mean coefficients, and elapsed times. The enclosing
`/usr/bin/time -l` command writes peak-memory information to `resource.txt`.
This pilot tests output completeness and measures resources; it makes no
coverage decision and cannot substitute for G17 authorization of the campaign.
