# Lane C Z6a — zero-one-beta zoi q1 slope receipt

Exact ML target: `bf(y ~ x, sigma ~ 1, zoi ~ x + (0 + x | id), coi ~ 1)`.
Only the zero/one atom probability receives `x_i exp(log_sd_zoi) u_id[i]`;
the interior beta component and conditional-one atom remain fixed-effect.

The source SHA is `ad317a6398900014aaf5c55aa815798b11e81d53` and runner MD5 is
`fef1515856261491a53bd9f46f1bfa29`. The retained four seeds pass the local
gate (mean SD relative error 0.1345; convergence zero, `pdHess`, finite
non-boundary SD, gradient <= 0.01, and mode correlation > 0.45). Every group
has at least one zero, one one, and one interior response; the separate
per-group minima are retained rather than rounded up to a stronger support
claim. The zero-true-SD fit is a source-authenticated boundary diagnostic only.
This receipt supplies no profile, interval, coverage, calibration, or
inference-ready evidence.
