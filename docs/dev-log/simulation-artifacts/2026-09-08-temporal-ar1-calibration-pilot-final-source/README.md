# Temporal AR1 final-source calibration pilot

This is the five-seed-per-cell timing and completeness pilot repeated at the
final temporal-AR1 estimator source. It preserves the historical pilot and
does not start the proposed 1,000-replicate-per-cell campaign.

The exact ADEMP cells are C1: 80 by 6, persistence `0.4`; C2: 80 by 24,
persistence `0.85`; C3: 80 by 12, persistence `-0.6`; C4: AR1-only, 80 by
12, persistence `0.4`; and C5: stress, 20 by 6, persistence `0.85`. Data use
`beta = (0, 0.5, 0.5)`, temporal-process SD `0.8`, residual SD `0.4`, and
ordinary-intercept SD `0.6` where applicable. Each series is generated with
an independent dense Cholesky AR1 draw.

The outputs retain all signed-start attempts, selected-fit diagnostics, mean-
coefficient interval availability, elapsed times, source commit, runner
checksum, session information, and macOS `/usr/bin/time -l` resource record.
It measures resource needs and output completeness only; it cannot authorize
the claim-bearing campaign.
