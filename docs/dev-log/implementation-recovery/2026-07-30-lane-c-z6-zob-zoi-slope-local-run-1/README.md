# Lane C Z6a — zero-one-beta zoi q1 slope receipt

Exact ML target: `bf(y ~ x, sigma ~ 1, zoi ~ x + (0 + x | id), coi ~ 1)`.
Only the zero/one atom probability receives `x_i exp(log_sd_zoi) u_id[i]`;
the interior beta component and conditional-one atom remain fixed-effect.

The source SHA is `acdf89928ba55246a65ecd7ffb3e5ac284dbc7a3`. The retained four
seeds pass the local gate (mean SD relative error 0.1345; convergence zero,
`pdHess`, finite non-boundary SD, gradient <= 0.01, atom and interior support
per group, and mode correlation > 0.45). The zero-true-SD fit is a boundary
diagnostic only. This receipt supplies no profile, interval, coverage,
calibration, or inference-ready evidence.
